import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SavingsPotsService } from './savings-pots.service';
import { SavingsPotsController } from './savings-pots.controller';
import { User, Wallet, SavingsPot, Transaction, LedgerEntry } from '../database/entities';

@Module({
  imports: [TypeOrmModule.forFeature([User, Wallet, SavingsPot, Transaction, LedgerEntry])],
  controllers: [SavingsPotsController],
  providers: [SavingsPotsService],
  exports: [SavingsPotsService],
})
export class SavingsPotsModule {}
