import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  healthCheck() {
    return {
      app: 'PesaVault API',
      status: 'running',
      version: '1.0.0',
      endpoints: {
        auth: {
          'POST /api/auth/otp/request': 'Request OTP',
          'POST /api/auth/register': 'Register with OTP + PIN',
          'POST /api/auth/login': 'Login with phone + PIN',
        },
        users: {
          'GET /api/users/profile': 'Get profile',
          'PATCH /api/users/profile': 'Update profile',
          'POST /api/users/kyc': 'Submit KYC',
        },
        wallet: {
          'GET /api/wallet/balance': 'Check balance',
          'POST /api/wallet/transfer': 'P2P transfer',
          'GET /api/wallet/transactions': 'Transaction history',
        },
        mpesa: {
          'POST /api/mpesa/deposit': 'Deposit via M-Pesa',
          'POST /api/mpesa/withdraw': 'Withdraw to M-Pesa',
        },
        savingsPots: {
          'POST /api/savings-pots': 'Create savings pot',
          'GET /api/savings-pots': 'List savings pots',
          'POST /api/savings-pots/:id/deposit': 'Save to pot',
          'POST /api/savings-pots/:id/withdraw': 'Withdraw from pot',
          'DELETE /api/savings-pots/:id': 'Delete pot',
        },
      },
    };
  }
}
