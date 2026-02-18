import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { SavingsPotsService } from './savings-pots.service';
import { CreatePotDto, TransferToPotDto, WithdrawFromPotDto } from './dto/savings-pot.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../database/entities';

@Controller('api/savings-pots')
@UseGuards(JwtAuthGuard)
export class SavingsPotsController {
  constructor(private savingsPotsService: SavingsPotsService) {}

  @Post()
  async createPot(@CurrentUser() user: User, @Body() dto: CreatePotDto) {
    return this.savingsPotsService.createPot(user.id, dto);
  }

  @Get()
  async getPots(@CurrentUser() user: User) {
    return this.savingsPotsService.getPots(user.id);
  }

  @Post(':id/deposit')
  async transferToPot(
    @CurrentUser() user: User,
    @Param('id') potId: string,
    @Body() dto: TransferToPotDto,
  ) {
    return this.savingsPotsService.transferToPot(user.id, potId, dto);
  }

  @Post(':id/withdraw')
  async withdrawFromPot(
    @CurrentUser() user: User,
    @Param('id') potId: string,
    @Body() dto: WithdrawFromPotDto,
  ) {
    return this.savingsPotsService.withdrawFromPot(user.id, potId, dto);
  }

  @Delete(':id')
  async deletePot(@CurrentUser() user: User, @Param('id') potId: string) {
    return this.savingsPotsService.deletePot(user.id, potId);
  }
}
