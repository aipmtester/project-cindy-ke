import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_provider.dart';
import '../../services/wallet_provider.dart';
import '../../utils/formatters.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();

  Future<void> _withdraw() async {
    if (_amountController.text.isEmpty || _pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter amount and PIN')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();

    final success = await wallet.withdraw(
      amount: double.parse(_amountController.text),
      phoneNumber: auth.user!.phoneNumber,
      pin: _pinController.text,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal initiated! Check your M-Pesa.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted && wallet.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(wallet.error!), backgroundColor: AppColors.error),
      );
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw to M-Pesa')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Text('Available: ', style: TextStyle(color: AppColors.textSecondary)),
                    Text(
                      formatKsh(wallet.wallet?.balance ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Amount (KSH)', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(hintText: '0'),
              ),
              const SizedBox(height: 24),
              const Text('Enter PIN', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                style: const TextStyle(fontSize: 24, letterSpacing: 12, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(counterText: ''),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: wallet.isLoading ? null : _withdraw,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                  child: wallet.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Withdraw to M-Pesa'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }
}
