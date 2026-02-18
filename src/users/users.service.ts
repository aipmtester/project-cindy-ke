import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, KycStatus } from '../database/entities';
import { UpdateProfileDto, SubmitKycDto } from './dto/user.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User) private userRepo: Repository<User>,
  ) {}

  async getProfile(userId: string) {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    return {
      id: user.id,
      phoneNumber: user.phoneNumber,
      firstName: user.firstName,
      lastName: user.lastName,
      businessName: user.businessName,
      email: user.email,
      kycStatus: user.kycStatus,
      createdAt: user.createdAt,
    };
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    Object.assign(user, dto);
    await this.userRepo.save(user);

    return this.getProfile(userId);
  }

  async submitKyc(userId: string, dto: SubmitKycDto) {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    user.nationalId = dto.nationalId;
    user.kraPin = dto.kraPin;
    user.kycStatus = KycStatus.SUBMITTED;

    // TODO: Call external KYC provider (Smile ID, etc.) to verify documents
    // For now, auto-verify in development
    if (process.env.APP_ENV === 'development') {
      user.kycStatus = KycStatus.VERIFIED;
    }

    await this.userRepo.save(user);

    return {
      message: 'KYC submitted successfully',
      kycStatus: user.kycStatus,
    };
  }
}
