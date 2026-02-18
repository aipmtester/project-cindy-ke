import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_provider.dart';
import '../../services/wallet_provider.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _amountController = TextEditingController();
  final _quickAmounts = [500, 1000, 2500, 5000, 10000, 25000];

  Future<void> _deposit() async {
    if (_amountController.text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final wallet = context.read<WalletProvider>();

    final success = await wallet.deposit(
      amount: double.parse(_amountController.text),
      phoneNumber: auth.user!.phoneNumber,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('M-Pesa STK push sent! Check your phone.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted && wallet.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(wallet.error!), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Deposit via M-Pesa')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Amount',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'You\'ll receive an M-Pesa prompt on your phone',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
                  prefixText: 'KSH  ',
                  prefixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _quickAmounts.map((amount) {
                  return GestureDetector(
                    onTap: () => _amountController.text = amount.toString(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'KSH ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primaryLight, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You\'ll receive an M-Pesa STK push. Enter your M-Pesa PIN to complete.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: wallet.isLoading ? null : _deposit,
                  child: wallet.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Deposit'),
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
    super.dispose();
  }
}
