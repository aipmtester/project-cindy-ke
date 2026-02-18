import { IsString, IsNotEmpty, IsNumber, Min, Matches } from 'class-validator';

export class MpesaDepositDto {
  @IsNumber()
  @Min(1, { message: 'Minimum deposit is KSH 1' })
  amount: number;

  @IsString()
  @IsNotEmpty()
  @Matches(/^254\d{9}$/, { message: 'Phone number must be in format 254XXXXXXXXX' })
  phoneNumber: string;
}

export class MpesaWithdrawDto {
  @IsNumber()
  @Min(1, { message: 'Minimum withdrawal is KSH 1' })
  amount: number;

  @IsString()
  @IsNotEmpty()
  @Matches(/^254\d{9}$/, { message: 'Phone number must be in format 254XXXXXXXXX' })
  phoneNumber: string;

  @IsString()
  @IsNotEmpty()
  pin: string;
}
