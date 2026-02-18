import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/wallet_provider.dart';
import '../../utils/formatters.dart';
import '../../models/wallet_model.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  void _showCreatePotSheet(BuildContext context) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    String selectedEmoji = '💰';
    final emojis = ['💰', '🏠', '📱', '🚗', '✈️', '📚', '🏥', '🛒', '💼', '🎯'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Savings Pot', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                children: emojis.map((e) {
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedEmoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selectedEmoji == e ? AppColors.primary.withValues(alpha: 0.3) : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: selectedEmoji == e ? Border.all(color: AppColors.primaryLight) : null,
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Pot name (e.g., Rent, Stock)'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Target amount (optional)'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;
                    final wallet = ctx.read<WalletProvider>();
                    await wallet.createPot(
                      name: nameController.text,
                      emoji: selectedEmoji,
                      targetAmount: targetController.text.isNotEmpty ? double.tryParse(targetController.text) : null,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Create Pot'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPotActions(BuildContext context, SavingsPotModel pot) {
    final amountController = TextEditingController();
    final pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${pot.emoji ?? "💰"} ${pot.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(formatKsh(pot.currentAmount), style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Amount (KSH)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'PIN', counterText: ''),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (amountController.text.isEmpty || pinController.text.length != 4) return;
                      final wallet = ctx.read<WalletProvider>();
                      final success = await wallet.depositToPot(
                        potId: pot.id,
                        amount: double.parse(amountController.text),
                        pin: pinController.text,
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(success ? 'Saved to ${pot.name}!' : wallet.error ?? 'Failed'),
                          backgroundColor: success ? AppColors.success : AppColors.error,
                        ));
                      }
                    },
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (amountController.text.isEmpty || pinController.text.length != 4) return;
                      final wallet = ctx.read<WalletProvider>();
                      final success = await wallet.withdrawFromPot(
                        potId: pot.id,
                        amount: double.parse(amountController.text),
                        pin: pinController.text,
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(success ? 'Withdrawn from ${pot.name}!' : wallet.error ?? 'Failed'),
                          backgroundColor: success ? AppColors.success : AppColors.error,
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                    child: const Text('Withdraw'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Savings Pots')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePotSheet(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: wallet.pots.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.savings_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('No savings pots yet', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('Tap + to create your first pot', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => wallet.loadPots(),
              color: AppColors.primaryLight,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: wallet.pots.length,
                itemBuilder: (_, i) {
                  final pot = wallet.pots[i];
                  return GestureDetector(
                    onTap: () => _showPotActions(context, pot),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(pot.emoji ?? '💰', style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pot.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    Text(
                                      pot.targetAmount != null ? 'Target: ${formatKsh(pot.targetAmount!)}' : 'No target set',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatKsh(pot.currentAmount),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          if (pot.progress != null) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pot.progress! / 100,
                                      backgroundColor: AppColors.surfaceLight,
                                      valueColor: AlwaysStoppedAnimation(
                                        pot.progress! >= 100 ? AppColors.success : AppColors.primaryLight,
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${pot.progress}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: pot.progress! >= 100 ? AppColors.success : AppColors.primaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
