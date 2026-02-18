import { Controller, Post, Body, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { MpesaService } from './mpesa.service';
import { MpesaDepositDto, MpesaWithdrawDto } from './dto/mpesa.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../database/entities';

@Controller('api/mpesa')
export class MpesaController {
  constructor(private mpesaService: MpesaService) {}

  @Post('deposit')
  @UseGuards(JwtAuthGuard)
  async deposit(@CurrentUser() user: User, @Body() dto: MpesaDepositDto) {
    return this.mpesaService.initiateDeposit(user.id, dto);
  }

  @Post('withdraw')
  @UseGuards(JwtAuthGuard)
  async withdraw(@CurrentUser() user: User, @Body() dto: MpesaWithdrawDto) {
    return this.mpesaService.initiateWithdrawal(user.id, dto);
  }

  // M-Pesa callback endpoints (no auth — called by Safaricom)
  @Post('callback/deposit')
  @HttpCode(HttpStatus.OK)
  async depositCallback(@Body() body: any) {
    await this.mpesaService.handleDepositCallback(body);
    return { ResultCode: 0, ResultDesc: 'Success' };
  }
}
