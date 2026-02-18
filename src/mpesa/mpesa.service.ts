import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
  InternalServerErrorException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import axios from 'axios';
import { v4 as uuidv4 } from 'uuid';
import {
  User,
  Wallet,
  WalletStatus,
  Transaction,
  TransactionType,
  TransactionStatus,
  LedgerEntry,
  EntryType,
} from '../database/entities';
import { MpesaDepositDto, MpesaWithdrawDto } from './dto/mpesa.dto';

@Injectable()
export class MpesaService {
  private baseUrl: string;

  constructor(
    private configService: ConfigService,
    @InjectRepository(User) private userRepo: Repository<User>,
    @InjectRepository(Wallet) private walletRepo: Repository<Wallet>,
    @InjectRepository(Transaction) private txRepo: Repository<Transaction>,
    @InjectRepository(LedgerEntry) private ledgerRepo: Repository<LedgerEntry>,
    private dataSource: DataSource,
  ) {
    const env = this.configService.get<string>('MPESA_ENV', 'sandbox');
    this.baseUrl =
      env === 'production'
        ? 'https://api.safaricom.co.ke'
        : 'https://sandbox.safaricom.co.ke';
  }

  private async getAccessToken(): Promise<string> {
    const consumerKey = this.configService.get<string>('MPESA_CONSUMER_KEY');
    const consumerSecret = this.configService.get<string>('MPESA_CONSUMER_SECRET');

    const auth = Buffer.from(`${consumerKey}:${consumerSecret}`).toString('base64');

    const response = await axios.get(
      `${this.baseUrl}/oauth/v1/generate?grant_type=client_credentials`,
      { headers: { Authorization: `Basic ${auth}` } },
    );

    return response.data.access_token;
  }

  async initiateDeposit(userId: string, dto: MpesaDepositDto) {
    const wallet = await this.walletRepo.findOne({ where: { userId } });
    if (!wallet || wallet.status !== WalletStatus.ACTIVE) {
      throw new BadRequestException('Wallet is not active');
    }

    const reference = `DEP-${uuidv4().slice(0, 8).toUpperCase()}`;
    const shortcode = this.configService.get<string>('MPESA_SHORTCODE');
    const passkey = this.configService.get<string>('MPESA_PASSKEY');
    const callbackUrl = this.configService.get<string>('MPESA_CALLBACK_URL');

    const timestamp = new Date()
      .toISOString()
      .replace(/[-T:\.Z]/g, '')
      .slice(0, 14);
    const password = Buffer.from(`${shortcode}${passkey}${timestamp}`).toString('base64');

    // Create pending transaction
    const tx = await this.txRepo.save({
      reference,
      type: TransactionType.DEPOSIT,
      status: TransactionStatus.PENDING,
      amount: dto.amount,
      currency: 'KES',
      receiverWalletId: wallet.id,
      description: 'M-Pesa deposit',
      metadata: { phoneNumber: dto.phoneNumber },
    });

    try {
      const accessToken = await this.getAccessToken();

      const stkResponse = await axios.post(
        `${this.baseUrl}/mpesa/stkpush/v1/processrequest`,
        {
          BusinessShortCode: shortcode,
          Password: password,
          Timestamp: timestamp,
          TransactionType: 'CustomerPayBillOnline',
          Amount: Math.round(dto.amount),
          PartyA: dto.phoneNumber,
          PartyB: shortcode,
          PhoneNumber: dto.phoneNumber,
          CallBackURL: `${callbackUrl}/deposit`,
          AccountReference: reference,
          TransactionDesc: 'PesaVault Deposit',
        },
        { headers: { Authorization: `Bearer ${accessToken}` } },
      );

      // Store M-Pesa checkout request ID
      await this.txRepo.update(tx.id, {
        metadata: {
          ...(tx.metadata || {}),
          checkoutRequestId: stkResponse.data.CheckoutRequestID,
          merchantRequestId: stkResponse.data.MerchantRequestID,
        } as any,
      });

      return {
        message: 'STK push sent. Check your phone to complete the deposit.',
        reference,
        checkoutRequestId: stkResponse.data.CheckoutRequestID,
      };
    } catch (error: any) {
      await this.txRepo.update(tx.id, { status: TransactionStatus.FAILED });
      throw new InternalServerErrorException(
        'Failed to initiate M-Pesa payment. Please try again.',
      );
    }
  }

  async handleDepositCallback(body: any) {
    const resultCode = body.Body?.stkCallback?.ResultCode;
    const checkoutRequestId = body.Body?.stkCallback?.CheckoutRequestID;

    if (!checkoutRequestId) return;

    // Find the pending transaction
    const tx = await this.txRepo
      .createQueryBuilder('tx')
      .where("tx.metadata->>'checkoutRequestId' = :checkoutRequestId", { checkoutRequestId })
      .getOne();

    if (!tx) return;

    if (resultCode === 0) {
      // Payment successful
      const callbackMetadata = body.Body.stkCallback.CallbackMetadata?.Item || [];
      const mpesaReceipt = callbackMetadata.find((i: any) => i.Name === 'MpesaReceiptNumber');

      await this.dataSource.transaction(async (manager) => {
        const wallet = await manager
          .createQueryBuilder(Wallet, 'w')
          .setLock('pessimistic_write')
          .where('w.id = :id', { id: tx.receiverWalletId })
          .getOne();

        if (!wallet) return;

        const newBalance = Number(wallet.balance) + Number(tx.amount);
        await manager.update(Wallet, wallet.id, { balance: newBalance });

        await manager.update(Transaction, tx.id, {
          status: TransactionStatus.COMPLETED,
          mpesaReceiptNumber: mpesaReceipt?.Value || null,
        });

        await manager.save(LedgerEntry, {
          transactionId: tx.id,
          walletId: wallet.id,
          entryType: EntryType.CREDIT,
          amount: Number(tx.amount),
          balanceAfter: newBalance,
          description: 'M-Pesa deposit',
        });
      });
    } else {
      // Payment failed
      await this.txRepo.update(tx.id, { status: TransactionStatus.FAILED });
    }
  }

  async initiateWithdrawal(userId: string, dto: MpesaWithdrawDto) {
    // Verify PIN
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new BadRequestException('User not found');

    const pinValid = await bcrypt.compare(dto.pin, user.pinHash);
    if (!pinValid) throw new UnauthorizedException('Invalid PIN');

    const wallet = await this.walletRepo.findOne({ where: { userId } });
    if (!wallet || wallet.status !== WalletStatus.ACTIVE) {
      throw new BadRequestException('Wallet is not active');
    }
    if (Number(wallet.balance) < dto.amount) {
      throw new BadRequestException('Insufficient balance');
    }

    const reference = `WDR-${uuidv4().slice(0, 8).toUpperCase()}`;

    // Debit wallet and create transaction atomically
    const tx = await this.dataSource.transaction(async (manager) => {
      const lockedWallet = await manager
        .createQueryBuilder(Wallet, 'w')
        .setLock('pessimistic_write')
        .where('w.id = :id', { id: wallet.id })
        .getOne();

      if (!lockedWallet || Number(lockedWallet.balance) < dto.amount) {
        throw new BadRequestException('Insufficient balance');
      }

      const newBalance = Number(lockedWallet.balance) - dto.amount;
      await manager.update(Wallet, lockedWallet.id, { balance: newBalance });

      const transaction = await manager.save(Transaction, {
        reference,
        type: TransactionType.WITHDRAWAL,
        status: TransactionStatus.PENDING,
        amount: dto.amount,
        currency: 'KES',
        senderWalletId: lockedWallet.id,
        description: `M-Pesa withdrawal to ${dto.phoneNumber}`,
        metadata: { phoneNumber: dto.phoneNumber },
      });

      await manager.save(LedgerEntry, {
        transactionId: transaction.id,
        walletId: lockedWallet.id,
        entryType: EntryType.DEBIT,
        amount: dto.amount,
        balanceAfter: newBalance,
        description: 'M-Pesa withdrawal',
      });

      return transaction;
    });

    // TODO: Initiate B2C payment via Daraja API to send money to user's M-Pesa
    // For sandbox, mark as completed
    if (this.configService.get<string>('MPESA_ENV') === 'sandbox') {
      await this.txRepo.update(tx.id, { status: TransactionStatus.COMPLETED });
    }

    return {
      message: 'Withdrawal initiated. You will receive the money on M-Pesa shortly.',
      reference,
      amount: dto.amount,
      phoneNumber: dto.phoneNumber,
    };
  }
}
