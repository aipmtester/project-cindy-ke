import {
  Injectable,
  NotFoundException,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';
import {
  User,
  Wallet,
  WalletStatus,
  SavingsPot,
  Transaction,
  TransactionType,
  TransactionStatus,
  LedgerEntry,
  EntryType,
} from '../database/entities';
import { CreatePotDto, TransferToPotDto, WithdrawFromPotDto } from './dto/savings-pot.dto';

@Injectable()
export class SavingsPotsService {
  constructor(
    @InjectRepository(SavingsPot) private potRepo: Repository<SavingsPot>,
    @InjectRepository(Wallet) private walletRepo: Repository<Wallet>,
    @InjectRepository(User) private userRepo: Repository<User>,
    @InjectRepository(Transaction) private txRepo: Repository<Transaction>,
    @InjectRepository(LedgerEntry) private ledgerRepo: Repository<LedgerEntry>,
    private dataSource: DataSource,
  ) {}

  async createPot(userId: string, dto: CreatePotDto) {
    const wallet = await this.walletRepo.findOne({ where: { userId } });
    if (!wallet) throw new NotFoundException('Wallet not found');

    const pot = await this.potRepo.save({
      walletId: wallet.id,
      name: dto.name,
      emoji: dto.emoji,
      targetAmount: dto.targetAmount,
      targetDate: dto.targetDate ? new Date(dto.targetDate) : undefined,
    });

    return {
      id: pot.id,
      name: pot.name,
      emoji: pot.emoji,
      currentAmount: 0,
      targetAmount: pot.targetAmount ? Number(pot.targetAmount) : null,
      targetDate: pot.targetDate,
      progress: 0,
    };
  }

  async getPots(userId: string) {
    const wallet = await this.walletRepo.findOne({ where: { userId } });
    if (!wallet) throw new NotFoundException('Wallet not found');

    const pots = await this.potRepo.find({
      where: { walletId: wallet.id, isActive: true },
      order: { createdAt: 'DESC' },
    });

    return pots.map((pot) => ({
      id: pot.id,
      name: pot.name,
      emoji: pot.emoji,
      currentAmount: Number(pot.currentAmount),
      targetAmount: pot.targetAmount ? Number(pot.targetAmount) : null,
      targetDate: pot.targetDate,
      progress: pot.targetAmount
        ? Math.round((Number(pot.currentAmount) / Number(pot.targetAmount)) * 100)
        : null,
    }));
  }

  async transferToPot(userId: string, potId: string, dto: TransferToPotDto) {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    const pinValid = await bcrypt.compare(dto.pin, user.pinHash);
    if (!pinValid) throw new UnauthorizedException('Invalid PIN');

    const wallet = await this.walletRepo.findOne({ where: { userId } });
    if (!wallet || wallet.status !== WalletStatus.ACTIVE) {
      throw new BadRequestException('Wallet is not active');
    }

    const pot = await this.potRepo.findOne({ where: { id: potId, walletId: wallet.id } });
    if (!pot || !pot.isActive) throw new NotFoundException('Savings pot not found');

    if (Number(wallet.balance) < dto.amount) {
      throw new BadRequestException('Insufficient balance');
    }

    const reference = `SAV-${uuidv4().slice(0, 8).toUpperCase()}`;

    await this.dataSource.transaction(async (manager) => {
      const lockedWallet = await manager
        .createQueryBuilder(Wallet, 'w')
        .setLock('pessimistic_write')
        .where('w.id = :id', { id: wallet.id })
        .getOne();

      if (!lockedWallet || Number(lockedWallet.balance) < dto.amount) {
        throw new BadRequestException('Insufficient balance');
      }

      const newWalletBalance = Number(lockedWallet.balance) - dto.amount;
      const newPotAmount = Number(pot.currentAmount) + dto.amount;

      await manager.update(Wallet, lockedWallet.id, { balance: newWalletBalance });
      await manager.update(SavingsPot, pot.id, { currentAmount: newPotAmount });

      const tx = await manager.save(Transaction, {
        reference,
        type: TransactionType.SAVINGS_IN,
        status: TransactionStatus.COMPLETED,
        amount: dto.amount,
        currency: 'KES',
        senderWalletId: lockedWallet.id,
        description: `Saved to "${pot.name}"`,
        metadata: { potId: pot.id, potName: pot.name },
      });

      await manager.save(LedgerEntry, {
        transactionId: tx.id,
        walletId: lockedWallet.id,
        entryType: EntryType.DEBIT,
        amount: dto.amount,
        balanceAfter: newWalletBalance,
        description: `Saved to "${pot.name}"`,
      });
    });

    return {
      message: `KSH ${dto.amount} saved to "${pot.name}"`,
      reference,
      potBalance: Number(pot.currentAmount) + dto.amount,
      walletBalance: Number(wallet.balance) - dto.amount,
    };
  }

  async withdrawFromPot(userId: string, potId: string, dto: WithdrawFromPotDto) {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    const pinValid = await bcrypt.compare(dto.pin, user.pinHash);
    if (!pinValid) throw new UnauthorizedException('Invalid PIN');

    const wallet = await this.walletRepo.findOne({ where: { userId } });
    if (!wallet) throw new NotFoundException('Wallet not found');

    const pot = await this.potRepo.findOne({ where: { id: potId, walletId: wallet.id } });
    if (!pot || !pot.isActive) throw new NotFoundException('Savings pot not found');

    if (Number(pot.currentAmount) < dto.amount) {
      throw new BadRequestException('Insufficient savings pot balance');
    }

    const reference = `SOUT-${uuidv4().slice(0, 8).toUpperCase()}`;

    await this.dataSource.transaction(async (manager) => {
      const lockedWallet = await manager
        .createQueryBuilder(Wallet, 'w')
        .setLock('pessimistic_write')
        .where('w.id = :id', { id: wallet.id })
        .getOne();

      if (!lockedWallet) throw new BadRequestException('Wallet not found');

      const newWalletBalance = Number(lockedWallet.balance) + dto.amount;
      const newPotAmount = Number(pot.currentAmount) - dto.amount;

      await manager.update(Wallet, lockedWallet.id, { balance: newWalletBalance });
      await manager.update(SavingsPot, pot.id, { currentAmount: newPotAmount });

      const tx = await manager.save(Transaction, {
        reference,
        type: TransactionType.SAVINGS_OUT,
        status: TransactionStatus.COMPLETED,
        amount: dto.amount,
        currency: 'KES',
        receiverWalletId: lockedWallet.id,
        description: `Withdrawn from "${pot.name}"`,
        metadata: { potId: pot.id, potName: pot.name },
      });

      await manager.save(LedgerEntry, {
        transactionId: tx.id,
        walletId: lockedWallet.id,
        entryType: EntryType.CREDIT,
        amount: dto.amount,
        balanceAfter: newWalletBalance,
        description: `Withdrawn from "${pot.name}"`,
      });
    });

    return {
      message: `KSH ${dto.amount} withdrawn from "${pot.name}"`,
      reference,
      potBalance: Number(pot.currentAmount) - dto.amount,
      walletBalance: Number(wallet.balance) + dto.amount,
    };
  }

  async deletePot(userId: string, potId: string) {
    const wallet = await this.walletRepo.findOne({ where: { userId } });
    if (!wallet) throw new NotFoundException('Wallet not found');

    const pot = await this.potRepo.findOne({ where: { id: potId, walletId: wallet.id } });
    if (!pot) throw new NotFoundException('Savings pot not found');

    if (Number(pot.currentAmount) > 0) {
      throw new BadRequestException(
        'Please withdraw all funds from this pot before deleting it',
      );
    }

    await this.potRepo.update(pot.id, { isActive: false });
    return { message: 'Savings pot deleted' };
  }
}
