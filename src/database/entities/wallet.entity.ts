import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from './user.entity';

export enum WalletStatus {
  ACTIVE = 'active',
  FROZEN = 'frozen',
  CLOSED = 'closed',
}

@Entity('wallets')
export class Wallet {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @OneToOne(() => User)
  @JoinColumn()
  user: User;

  @Column()
  @Index()
  userId: string;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  balance: number;

  @Column({ type: 'enum', enum: WalletStatus, default: WalletStatus.ACTIVE })
  status: WalletStatus;

  @Column({ default: 'KES' })
  currency: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
