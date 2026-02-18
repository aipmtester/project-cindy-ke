import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MpesaService } from './mpesa.service';
import { MpesaController } from './mpesa.controller';
import { User, Wallet, Transaction, LedgerEntry } from '../database/entities';

@Module({
  imports: [TypeOrmModule.forFeature([User, Wallet, Transaction, LedgerEntry])],
  controllers: [MpesaController],
  providers: [MpesaService],
  exports: [MpesaService],
})
export class MpesaModule {}
