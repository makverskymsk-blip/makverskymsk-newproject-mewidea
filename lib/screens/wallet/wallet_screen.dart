import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/wallet_provider.dart';

import '../../theme/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_button.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>();
    final community = context.watch<CommunityProvider>();
    final user = auth.currentUser;
    final balance = user?.balance ?? 0;
    final txList = wallet.getUserTransactions(user?.id ?? '');
    final bank = community.activeCommunity?.bankBalance ?? 0;

    return Scaffold(
      backgroundColor: AppColors.of(context).scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 32),
                Text('Мой Кошелёк', style: Theme.of(context).textTheme.headlineMedium?.copyWith(decoration: TextDecoration.none)),
                const SizedBox(height: 24),

                // Balance card
                _buildBalanceCard(balance),
                const SizedBox(height: 20),

                // Actions
                SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    text: 'Пополнить',
                    icon: Icons.add_rounded,
                    color: AppColors.accent,
                    onPressed: () => _showTopUp(context, auth),
                  ),
                ),
                const SizedBox(height: 28),

                // Community bank
                if (community.activeCommunity != null)
                  _buildBankWidget(community.activeCommunity!.name, bank, community.activeCommunity!.logoUrl),
                if (community.activeCommunity != null) const SizedBox(height: 28),

                // Transactions
                const Text(
                  'Последние операции',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                ),
                const SizedBox(height: 16),

                if (txList.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Text('Операций пока нет', style: TextStyle(color: AppColors.textHint, decoration: TextDecoration.none)),
                    ),
                  )
                else
                  ...txList.take(10).map((tx) => _buildTxTile(context, tx)),

                const SizedBox(height: 120),
              ],
            ),
          ),
      ),
    );
  }

  Widget _buildHeader() => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.sports_soccer, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('PERFORMANCE LAB',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, decoration: TextDecoration.none)),
        ],
      );

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Текущий баланс',
              style: TextStyle(color: Colors.white70, fontSize: 14, decoration: TextDecoration.none)),
          const SizedBox(height: 10),
          Text(
            Helpers.formatCurrency(balance),
            style: TextStyle(
              color: balance < 0 ? AppColors.error : Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ID: 4502-8831',
                  style: TextStyle(color: Colors.white70, fontSize: 13, decoration: TextDecoration.none)),
              const Icon(Icons.contactless_rounded, color: Colors.white, size: 26),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankWidget(String communityName, double bank, String? logoUrl) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: logoUrl != null && logoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      logoUrl,
                      width: 48, height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.account_balance_rounded, color: AppColors.accent, size: 24),
                    ),
                  )
                : const Icon(Icons.account_balance_rounded, color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Общий банк',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12, decoration: TextDecoration.none)),
                Text(
                  Helpers.formatCurrency(bank),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(communityName,
                    style: const TextStyle(color: AppColors.textHint, fontSize: 11, decoration: TextDecoration.none)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTxTile(BuildContext context, dynamic tx) {
    final isIncome = tx.isIncome;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isIncome ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isIncome ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.description,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  '${tx.status.displayName} • ${Helpers.formatDate(tx.dateTime)}',
                  style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            tx.formattedAmount,
            style: TextStyle(
              color: isIncome ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showTopUp(BuildContext context, AuthProvider auth) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.of(context).dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.borderLight),
          ),
          title: const Text('Пополнение баланса', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: TextStyle(color: AppColors.of(context).textPrimary),
            decoration: const InputDecoration(
              labelText: 'Сумма (₽)',
              prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final amount = double.tryParse(ctrl.text);
                if (amount != null && amount > 0) {
                  auth.updateBalance(amount);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Пополнить', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
    );
  }
}
