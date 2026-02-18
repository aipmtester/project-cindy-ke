import { IsString, IsNotEmpty, Length, Matches } from 'class-validator';

export class RequestOtpDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^254\d{9}$/, { message: 'Phone number must be in format 254XXXXXXXXX' })
  phoneNumber: string;
}

export class VerifyOtpDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^254\d{9}$/, { message: 'Phone number must be in format 254XXXXXXXXX' })
  phoneNumber: string;

  @IsString()
  @Length(6, 6, { message: 'OTP must be 6 digits' })
  otp: string;
}

export class SetPinDto {
  @IsString()
  @Length(4, 4, { message: 'PIN must be 4 digits' })
  @Matches(/^\d{4}$/, { message: 'PIN must be numeric' })
  pin: string;
}

export class LoginDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^254\d{9}$/, { message: 'Phone number must be in format 254XXXXXXXXX' })
  phoneNumber: string;

  @IsString()
  @Length(4, 4)
  pin: string;
}

export class RegisterDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^254\d{9}$/, { message: 'Phone number must be in format 254XXXXXXXXX' })
  phoneNumber: string;

  @IsString()
  @Length(6, 6)
  otp: string;

  @IsString()
  @Length(4, 4)
  @Matches(/^\d{4}$/, { message: 'PIN must be numeric' })
  pin: string;

  @IsString()
  @IsNotEmpty()
  firstName: string;

  @IsString()
  @IsNotEmpty()
  lastName: string;

  @IsString()
  @IsNotEmpty()
  businessName: string;
}
