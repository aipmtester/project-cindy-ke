import { IsString, IsNotEmpty, IsNumber, IsOptional, Min } from 'class-validator';

export class CreatePotDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsOptional()
  @IsString()
  emoji?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  targetAmount?: number;

  @IsOptional()
  @IsString()
  targetDate?: string;
}

export class TransferToPotDto {
  @IsNumber()
  @Min(1, { message: 'Minimum amount is KSH 1' })
  amount: number;

  @IsString()
  @IsNotEmpty()
  pin: string;
}

export class WithdrawFromPotDto {
  @IsNumber()
  @Min(1, { message: 'Minimum amount is KSH 1' })
  amount: number;

  @IsString()
  @IsNotEmpty()
  pin: string;
}
