import { IsString, IsNotEmpty, IsOptional, IsEmail, Matches } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  firstName?: string;

  @IsOptional()
  @IsString()
  lastName?: string;

  @IsOptional()
  @IsString()
  businessName?: string;

  @IsOptional()
  @IsEmail()
  email?: string;
}

export class SubmitKycDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{7,8}$/, { message: 'Invalid National ID number' })
  nationalId: string;

  @IsString()
  @IsNotEmpty()
  @Matches(/^[A-Z]\d{9}[A-Z]$/, { message: 'Invalid KRA PIN format (e.g., A123456789B)' })
  kraPin: string;
}
