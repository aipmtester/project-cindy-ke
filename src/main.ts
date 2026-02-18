import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
import { GlobalExceptionFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Global validation pipe — strips unknown properties, transforms types
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  // Global exception handler
  app.useGlobalFilters(new GlobalExceptionFilter());

  // CORS for mobile app
  app.enableCors({
    origin: true,
    credentials: true,
  });

  const port = process.env.APP_PORT || 3000;
  await app.listen(port);
  console.log(`🚀 PesaVault API running on http://localhost:${port}`);
  console.log(`📱 Environment: ${process.env.APP_ENV || 'development'}`);
}

bootstrap();
