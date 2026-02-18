import { Controller, Get, Post, Body, Query, UseGuards } from '@nestjs/common';
import { WalletService } from './wallet.service';
import { TransferDto } from './dto/wallet.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../database/entities';

@Controller('api/wallet')
@UseGuards(JwtAuthGuard)
export class WalletController {
  constructor(private walletService: WalletService) {}

  @Get('balance')
  async getBalance(@CurrentUser() user: User) {
    return this.walletService.getBalance(user.id);
  }

  @Post('transfer')
  async transfer(@CurrentUser() user: User, @Body() dto: TransferDto) {
    return this.walletService.transfer(user.id, dto);
  }

  @Get('transactions')
  async getTransactions(
    @CurrentUser() user: User,
    @Query('type') type?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.walletService.getTransactions(user.id, {
      type,
      startDate,
      endDate,
      page: page ? parseInt(page) : undefined,
      limit: limit ? parseInt(limit) : undefined,
    });
  }
}
