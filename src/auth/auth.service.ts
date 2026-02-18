import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
  ConflictException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, MoreThan } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User, Wallet, Otp } from '../database/entities';
import { RequestOtpDto, VerifyOtpDto, RegisterDto, LoginDto } from './dto/auth.dto';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User) private userRepo: Repository<User>,
    @InjectRepository(Wallet) private walletRepo: Repository<Wallet>,
    @InjectRepository(Otp) private otpRepo: Repository<Otp>,
    private jwtService: JwtService,
    private dataSource: DataSource,
  ) {}

  async requestOtp(dto: RequestOtpDto): Promise<{ message: string }> {
    // Invalidate any existing unused OTPs
    await this.otpRepo.update(
      { phoneNumber: dto.phoneNumber, isUsed: false },
      { isUsed: true },
    );

    // Generate 6-digit OTP
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

    await this.otpRepo.save({
      phoneNumber: dto.phoneNumber,
      code,
      expiresAt,
    });

    // TODO: Send OTP via Africa's Talking SMS API
    // In development, log the OTP
    console.log(`[DEV] OTP for ${dto.phoneNumber}: ${code}`);

    return { message: 'OTP sent successfully' };
  }

  async register(dto: RegisterDto): Promise<{ accessToken: string; user: Partial<User> }> {
    // Check if user already exists
    const existing = await this.userRepo.findOne({ where: { phoneNumber: dto.phoneNumber } });
    if (existing) {
      throw new ConflictException('Phone number already registered');
    }

    // Verify OTP
    await this.verifyOtpCode(dto.phoneNumber, dto.otp);

    // Hash PIN
    const pinHash = await bcrypt.hash(dto.pin, 12);

    // Create user and wallet in a transaction
    const result = await this.dataSource.transaction(async (manager) => {
      const user = manager.create(User, {
        phoneNumber: dto.phoneNumber,
        firstName: dto.firstName,
        lastName: dto.lastName,
        businessName: dto.businessName,
        pinHash,
      });
      const savedUser = await manager.save(user);

      const wallet = manager.create(Wallet, {
        userId: savedUser.id,
        balance: 0,
        currency: 'KES',
      });
      await manager.save(wallet);

      return savedUser;
    });

    const accessToken = this.generateToken(result);

    return {
      accessToken,
      user: {
        id: result.id,
        phoneNumber: result.phoneNumber,
        firstName: result.firstName,
        lastName: result.lastName,
        businessName: result.businessName,
        kycStatus: result.kycStatus,
      },
    };
  }

  async login(dto: LoginDto): Promise<{ accessToken: string; user: Partial<User> }> {
    const user = await this.userRepo.findOne({ where: { phoneNumber: dto.phoneNumber } });
    if (!user) {
      throw new UnauthorizedException('Invalid phone number or PIN');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Account has been deactivated');
    }

    const pinValid = await bcrypt.compare(dto.pin, user.pinHash);
    if (!pinValid) {
      throw new UnauthorizedException('Invalid phone number or PIN');
    }

    // Update last login
    await this.userRepo.update(user.id, { lastLoginAt: new Date() });

    const accessToken = this.generateToken(user);

    return {
      accessToken,
      user: {
        id: user.id,
        phoneNumber: user.phoneNumber,
        firstName: user.firstName,
        lastName: user.lastName,
        businessName: user.businessName,
        kycStatus: user.kycStatus,
      },
    };
  }

  private async verifyOtpCode(phoneNumber: string, code: string): Promise<void> {
    const otp = await this.otpRepo.findOne({
      where: {
        phoneNumber,
        code,
        isUsed: false,
        expiresAt: MoreThan(new Date()),
      },
    });

    if (!otp) {
      throw new BadRequestException('Invalid or expired OTP');
    }

    await this.otpRepo.update(otp.id, { isUsed: true });
  }

  private generateToken(user: User): string {
    return this.jwtService.sign({
      sub: user.id,
      phone: user.phoneNumber,
    });
  }
}
