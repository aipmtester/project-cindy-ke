import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WalletService } from './wallet.service';
import { WalletController } from './wallet.controller';
import { User, Wallet, Transaction, LedgerEntry } from '../database/entities';

@Module({
  imports: [TypeOrmModule.forFeature([User, Wallet, Transaction, LedgerEntry])],
  controllers: [WalletController],
  providers: [WalletService],
  exports: [WalletService],
})
export class WalletModule {}
