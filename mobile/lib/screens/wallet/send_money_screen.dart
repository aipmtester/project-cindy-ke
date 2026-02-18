import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/wallet_provider.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _pinController = TextEditingController();
  bool _showConfirm = false;

  String get _fullPhone {
    final phone = _phoneController.text.trim();
    if (phone.startsWith('0')) return '254${phone.substring(1)}';
    if (phone.startsWith('+254')) return phone.substring(1);
    return phone;
  }

  void _proceed() {
    if (_phoneController.text.trim().length < 9 || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter recipient and amount')),
      );
      return;
    }
    setState(() => _showConfirm = true);
  }

  Future<void> _send() async {
    final wallet = context.read<WalletProvider>();
    final success = await wallet.transfer(
      recipientPhone: _fullPhone,
      amount: double.parse(_amountController.text),
      pin: _pinController.text,
      description: _descController.text.isNotEmpty ? _descController.text : null,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Money sent successfully!'), backgroundColor: AppColors.success),
      );
    } else if (mounted && wallet.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(wallet.error!), backgroundColor: AppColors.error),
      );
      setState(() => _showConfirm = false);
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Send Money')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: !_showConfirm ? _buildForm() : _buildConfirm(wallet),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recipient', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: '0712 345 678',
            prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Amount (KSH)', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: '0.00',
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 16, right: 8),
              child: Text('KSH', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryLight)),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Note (optional)', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _descController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'What\'s this for?'),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: _proceed, child: const Text('Continue')),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildConfirm(WalletProvider wallet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Confirm Transfer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _confirmRow('To', _phoneController.text),
              const Divider(color: AppColors.surfaceLight, height: 24),
              _confirmRow('Amount', 'KSH ${_amountController.text}'),
              if (_descController.text.isNotEmpty) ...[
                const Divider(color: AppColors.surfaceLight, height: 24),
                _confirmRow('Note', _descController.text),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text('Enter PIN to confirm', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
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
            onPressed: wallet.isLoading ? null : _send,
            child: wallet.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Send Money'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _confirmRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _descController.dispose();
    _pinController.dispose();
    super.dispose();
  }
}
