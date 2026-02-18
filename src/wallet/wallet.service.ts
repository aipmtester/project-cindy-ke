import {
  Injectable,
  NotFoundException,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, Between } from 'typeorm';
import * as bcrypt from 'bcrypt';
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
import { TransferDto } from './dto/wallet.dto';

@Injectable()
export class WalletService {
  constructor(
    @InjectRepository(Wallet) private walletRepo: Repository<Wallet>,
    @InjectRepository(User) private userRepo: Repository<User>,
    @InjectRepository(Transaction) private txRepo: Repository<Transaction>,
    @InjectRepository(LedgerEntry) private ledgerRepo: Repository<LedgerEntry>,
    private dataSource: DataSource,
  ) {}

  async getBalance(userId: string) {
    const wallet = await this.walletRepo.findOne({ where: { userId } });
    if (!wallet) throw new NotFoundException('Wallet not found');

    return {
      balance: Number(wallet.balance),
      currency: wallet.currency,
      status: wallet.status,
    };
  }

  async transfer(userId: string, dto: TransferDto) {
    // Verify PIN
    const sender = await this.userRepo.findOne({ where: { id: userId } });
    if (!sender) throw new NotFoundException('User not found');

    const pinValid = await bcrypt.compare(dto.pin, sender.pinHash);
    if (!pinValid) throw new UnauthorizedException('Invalid PIN');

    // Find recipient
    const recipient = await this.userRepo.findOne({
      where: { phoneNumber: dto.recipientPhone },
    });
    if (!recipient) throw new BadRequestException('Recipient not found on PesaVault');

    if (recipient.id === userId) {
      throw new BadRequestException('Cannot transfer to yourself');
    }

    const senderWallet = await this.walletRepo.findOne({ where: { userId } });
    const recipientWallet = await this.walletRepo.findOne({
      where: { userId: recipient.id },
    });

    if (!senderWallet || senderWallet.status !== WalletStatus.ACTIVE) {
      throw new BadRequestException('Your wallet is not active');
    }
    if (!recipientWallet || recipientWallet.status !== WalletStatus.ACTIVE) {
      throw new BadRequestException('Recipient wallet is not active');
    }
    if (Number(senderWallet.balance) < dto.amount) {
      throw new BadRequestException('Insufficient balance');
    }

    // Execute transfer in a transaction with row-level locking
    const reference = `TRF-${uuidv4().slice(0, 8).toUpperCase()}`;

    const transaction = await this.dataSource.transaction(async (manager) => {
      // Lock wallets to prevent race conditions
      const lockedSender = await manager
        .createQueryBuilder(Wallet, 'w')
        .setLock('pessimistic_write')
        .where('w.id = :id', { id: senderWallet.id })
        .getOne();

      const lockedRecipient = await manager
        .createQueryBuilder(Wallet, 'w')
        .setLock('pessimistic_write')
        .where('w.id = :id', { id: recipientWallet.id })
        .getOne();

      if (!lockedSender || !lockedRecipient) {
        throw new BadRequestException('Wallet lock failed');
      }

      // Double-check balance after lock
      if (Number(lockedSender.balance) < dto.amount) {
        throw new BadRequestException('Insufficient balance');
      }

      // Update balances
      const newSenderBalance = Number(lockedSender.balance) - dto.amount;
      const newRecipientBalance = Number(lockedRecipient.balance) + dto.amount;

      await manager.update(Wallet, lockedSender.id, { balance: newSenderBalance });
      await manager.update(Wallet, lockedRecipient.id, { balance: newRecipientBalance });

      // Create transaction record
      const tx = manager.create(Transaction, {
        reference,
        type: TransactionType.TRANSFER,
        status: TransactionStatus.COMPLETED,
        amount: dto.amount,
        currency: 'KES',
        senderWalletId: lockedSender.id,
        receiverWalletId: lockedRecipient.id,
        description: dto.description || `Transfer to ${dto.recipientPhone}`,
      });
      const savedTx = await manager.save(tx);

      // Create double-entry ledger records
      await manager.save(LedgerEntry, {
        transactionId: savedTx.id,
        walletId: lockedSender.id,
        entryType: EntryType.DEBIT,
        amount: dto.amount,
        balanceAfter: newSenderBalance,
        description: `Transfer to ${recipient.firstName} ${recipient.lastName}`,
      });

      await manager.save(LedgerEntry, {
        transactionId: savedTx.id,
        walletId: lockedRecipient.id,
        entryType: EntryType.CREDIT,
        amount: dto.amount,
        balanceAfter: newRecipientBalance,
        description: `Transfer from ${sender.firstName} ${sender.lastName}`,
      });

      return savedTx;
    });

    return {
      message: 'Transfer successful',
      reference: transaction.reference,
      amount: dto.amount,
      currency: 'KES',
      recipient: {
        phoneNumber: dto.recipientPhone,
        name: `${recipient.firstName} ${recipient.lastName}`,
      },
    };
  }

  async getTransactions(
    userId: string,
    filters: { type?: string; startDate?: string; endDate?: string; page?: number; limit?: number },
  ) {
    const wallet = await this.walletRepo.findOne({ where: { userId } });
    if (!wallet) throw new NotFoundException('Wallet not found');

    const page = filters.page || 1;
    const limit = Math.min(filters.limit || 20, 100);

    const qb = this.txRepo
      .createQueryBuilder('tx')
      .where('(tx.senderWalletId = :walletId OR tx.receiverWalletId = :walletId)', {
        walletId: wallet.id,
      })
      .orderBy('tx.createdAt', 'DESC')
      .skip((page - 1) * limit)
      .take(limit);

    if (filters.type) {
      qb.andWhere('tx.type = :type', { type: filters.type });
    }

    if (filters.startDate && filters.endDate) {
      qb.andWhere('tx.createdAt BETWEEN :start AND :end', {
        start: new Date(filters.startDate),
        end: new Date(filters.endDate),
      });
    }

    const [transactions, total] = await qb.getManyAndCount();

    return {
      transactions: transactions.map((tx) => ({
        id: tx.id,
        reference: tx.reference,
        type: tx.type,
        status: tx.status,
        amount: Number(tx.amount),
        fee: Number(tx.fee),
        currency: tx.currency,
        description: tx.description,
        direction: tx.senderWalletId === wallet.id ? 'outgoing' : 'incoming',
        createdAt: tx.createdAt,
      })),
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }
}
