import { IsString, IsNotEmpty, IsNumber, Min, Matches, IsOptional } from 'class-validator';

export class TransferDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^254\d{9}$/, { message: 'Recipient phone must be in format 254XXXXXXXXX' })
  recipientPhone: string;

  @IsNumber()
  @Min(1, { message: 'Minimum transfer amount is KSH 1' })
  amount: number;

  @IsOptional()
  @IsString()
  description?: string;

  @IsString()
  @IsNotEmpty()
  pin: string;
}

export class TransactionFilterDto {
  @IsOptional()
  @IsString()
  type?: string;

  @IsOptional()
  @IsString()
  startDate?: string;

  @IsOptional()
  @IsString()
  endDate?: string;

  @IsOptional()
  @IsNumber()
  page?: number;

  @IsOptional()
  @IsNumber()
  limit?: number;
}
