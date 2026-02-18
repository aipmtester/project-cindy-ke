import { Controller, Get, Patch, Post, Body, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service';
import { UpdateProfileDto, SubmitKycDto } from './dto/user.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { User } from '../database/entities';

@Controller('api/users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get('profile')
  async getProfile(@CurrentUser() user: User) {
    return this.usersService.getProfile(user.id);
  }

  @Patch('profile')
  async updateProfile(@CurrentUser() user: User, @Body() dto: UpdateProfileDto) {
    return this.usersService.updateProfile(user.id, dto);
  }

  @Post('kyc')
  async submitKyc(@CurrentUser() user: User, @Body() dto: SubmitKycDto) {
    return this.usersService.submitKyc(user.id, dto);
  }
}
