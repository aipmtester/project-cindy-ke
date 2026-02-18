import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { Wallet } from './wallet.entity';
import { Transaction } from './transaction.entity';

export enum EntryType {
  DEBIT = 'debit',
  CREDIT = 'credit',
}

@Entity('ledger_entries')
export class LedgerEntry {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Transaction)
  @JoinColumn()
  transaction: Transaction;

  @Column()
  @Index()
  transactionId: string;

  @ManyToOne(() => Wallet)
  @JoinColumn()
  wallet: Wallet;

  @Column()
  @Index()
  walletId: string;

  @Column({ type: 'enum', enum: EntryType })
  entryType: EntryType;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  amount: number;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  balanceAfter: number;

  @Column({ nullable: true })
  description: string;

  @CreateDateColumn()
  @Index()
  createdAt: Date;
}
