import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToOne,
  Index,
} from 'typeorm';

export enum KycStatus {
  PENDING = 'pending',
  SUBMITTED = 'submitted',
  VERIFIED = 'verified',
  REJECTED = 'rejected',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  @Index()
  phoneNumber: string;

  @Column({ nullable: true })
  firstName: string;

  @Column({ nullable: true })
  lastName: string;

  @Column({ nullable: true })
  businessName: string;

  @Column({ nullable: true })
  email: string;

  @Column()
  pinHash: string;

  @Column({ nullable: true })
  nationalId: string;

  @Column({ nullable: true })
  kraPin: string;

  @Column({ type: 'enum', enum: KycStatus, default: KycStatus.PENDING })
  kycStatus: KycStatus;

  @Column({ default: true })
  isActive: boolean;

  @Column({ nullable: true })
  lastLoginAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
