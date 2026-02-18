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

export enum TransactionType {
  DEPOSIT = 'deposit',
  WITHDRAWAL = 'withdrawal',
  TRANSFER = 'transfer',
  SAVINGS_IN = 'savings_in',
  SAVINGS_OUT = 'savings_out',
}

export enum TransactionStatus {
  PENDING = 'pending',
  COMPLETED = 'completed',
  FAILED = 'failed',
  REVERSED = 'reversed',
}

@Entity('transactions')
export class Transaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  @Index()
  reference: string;

  @Column({ type: 'enum', enum: TransactionType })
  type: TransactionType;

  @Column({ type: 'enum', enum: TransactionStatus, default: TransactionStatus.PENDING })
  status: TransactionStatus;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  amount: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  fee: number;

  @Column({ default: 'KES' })
  currency: string;

  @ManyToOne(() => Wallet, { nullable: true })
  @JoinColumn()
  senderWallet: Wallet;

  @Column({ nullable: true })
  senderWalletId: string;

  @ManyToOne(() => Wallet, { nullable: true })
  @JoinColumn()
  receiverWallet: Wallet;

  @Column({ nullable: true })
  receiverWalletId: string;

  @Column({ nullable: true })
  description: string;

  @Column({ nullable: true })
  mpesaReceiptNumber: string;

  @Column({ type: 'jsonb', nullable: true })
  metadata: Record<string, any>;

  @CreateDateColumn()
  @Index()
  createdAt: Date;
}
