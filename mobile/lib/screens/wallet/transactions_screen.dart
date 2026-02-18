import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/wallet_provider.dart';
import '../../utils/formatters.dart';
import '../../models/wallet_model.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: wallet.transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('No transactions yet', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => wallet.loadTransactions(),
              color: AppColors.primaryLight,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: wallet.transactions.length,
                itemBuilder: (_, i) => _TransactionItem(tx: wallet.transactions[i]),
              ),
            ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionItem({required this.tx});

  IconData get _icon {
    switch (tx.type) {
      case 'deposit':
        return Icons.add_circle_outline;
      case 'withdrawal':
        return Icons.remove_circle_outline;
      case 'savings_in':
        return Icons.savings_rounded;
      case 'savings_out':
        return Icons.savings_outlined;
      default:
        return tx.isIncoming ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    }
  }

  String get _typeLabel {
    switch (tx.type) {
      case 'deposit':
        return 'M-Pesa Deposit';
      case 'withdrawal':
        return 'M-Pesa Withdrawal';
      case 'transfer':
        return tx.isIncoming ? 'Received' : 'Sent';
      case 'savings_in':
        return 'Saved to Pot';
      case 'savings_out':
        return 'Withdrawn from Pot';
      default:
        return tx.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (tx.isIncoming ? AppColors.incoming : AppColors.outgoing).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: tx.isIncoming ? AppColors.incoming : AppColors.outgoing, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  tx.description,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  formatDateTime(tx.createdAt),
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tx.isIncoming ? '+' : '-'} ${formatKsh(tx.amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: tx.isIncoming ? AppColors.incoming : AppColors.outgoing,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tx.status == 'completed'
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tx.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: tx.status == 'completed' ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
