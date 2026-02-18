import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { Wallet } from './wallet.entity';

@Entity('savings_pots')
export class SavingsPot {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Wallet)
  @JoinColumn()
  wallet: Wallet;

  @Column()
  @Index()
  walletId: string;

  @Column()
  name: string;

  @Column({ nullable: true })
  emoji: string;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  currentAmount: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, nullable: true })
  targetAmount: number;

  @Column({ nullable: true })
  targetDate: Date;

  @Column({ default: true })
  isActive: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
