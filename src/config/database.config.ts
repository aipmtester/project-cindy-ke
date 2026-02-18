import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';

export const getDatabaseConfig = (configService: ConfigService): TypeOrmModuleOptions => ({
  type: 'postgres',
  host: configService.get<string>('DB_HOST', 'localhost'),
  port: configService.get<number>('DB_PORT', 5432),
  username: configService.get<string>('DB_USERNAME', 'pesavault'),
  password: configService.get<string>('DB_PASSWORD', 'pesavault_dev'),
  database: configService.get<string>('DB_NAME', 'pesavault'),
  entities: [__dirname + '/../database/entities/*.entity{.ts,.js}'],
  synchronize: configService.get<string>('APP_ENV') === 'development',
  logging: configService.get<string>('APP_ENV') === 'development',
});
