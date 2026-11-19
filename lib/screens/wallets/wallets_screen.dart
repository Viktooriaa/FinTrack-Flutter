import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/account_store.dart';
import '../../data/transaction_store.dart';
import '../home/account_entry_sheet.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  late final Listenable _data = Listenable.merge([
    AccountStore.instance,
    TransactionStore.instance,
  ]);

  @override
  void initState() {
    super.initState();
    unawaited(AccountStore.instance.load());
    unawaited(TransactionStore.instance.load());
  }

  Future<void> _addAccount() async {
    await showAccountEntrySheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _data,
          builder: (context, _) {
            final accounts = AccountStore.instance.accounts;
            return Column(
              children: [
                _buildHeader(accounts.length),
                Expanded(
                  child: accounts.isEmpty
                      ? _buildEmptyState()
                      : _buildAccountList(accounts),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 18, 14),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            visualDensity: VisualDensity.compact,
          ),
          const Expanded(
            child: Text(
              'Рахунки',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          if (count > 0)
            Text(
              '$count ${_accountWord(count)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFFDDF8E9),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _addAccount,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.add_rounded, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F3EC),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ще немає рахунків',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          const Text(
            'Додай картку або готівковий рахунок, щоб бачити баланс у FinTrack.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _addAccount,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Додати рахунок'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(190, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildAccountList(List<AccountRecord> accounts) {
    final transactions = TransactionStore.instance.transactions;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 24),
      itemCount: accounts.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == accounts.length) {
          return OutlinedButton.icon(
            onPressed: _addAccount,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Додати рахунок'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: Color(0xFFCBD8E4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          );
        }
        final account = accounts[index];
        final currentBalance = transactions
            .where((transaction) => transaction.accountId == account.id)
            .fold<int>(
              account.balanceCents,
              (balance, transaction) =>
                  balance +
                  (transaction.isIncome
                      ? transaction.amountCents
                      : -transaction.amountCents),
            );
        return _AccountCard(
          account: account,
          balanceCents: currentBalance,
          index: index,
          isPrimary: index == 0,
        );
      },
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.balanceCents,
    required this.index,
    required this.isPrimary,
  });

  final AccountRecord account;
  final int balanceCents;
  final int index;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    const tints = [
      Color(0xFFE5F2EB),
      Color(0xFFEDF4FF),
      Color(0xFFFFF3DF),
      Color(0xFFF1EAFE),
    ];
    final accountName = account.name.toLowerCase();
    final isMonobank = accountName.contains('mono');
    final isApplePay = accountName.contains('apple');
    final isDarkCard = isMonobank || isApplePay || isPrimary;
    final icon = isMonobank
        ? Icons.credit_card_rounded
        : accountName.contains('готів')
        ? Icons.payments_outlined
        : isApplePay
        ? Icons.apple_rounded
        : Icons.account_balance_rounded;
    final foreground = isDarkCard ? Colors.white : AppColors.textPrimary;
    final secondary = isDarkCard
        ? Colors.white.withValues(alpha: 0.62)
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkCard
            ? (isMonobank ? const Color(0xFF111827) : Colors.black)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B253A30),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDarkCard
                  ? Colors.white.withValues(alpha: 0.12)
                  : tints[index % tints.length],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDarkCard ? Colors.white : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  account.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: secondary),
                ),
              ],
            ),
          ),
          if (isPrimary) ...[
            const SizedBox(width: 8),
            Text(
              'Основний',
              style: TextStyle(
                color: isDarkCard ? const Color(0xFF80E6B8) : AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${formatMoneyCents(balanceCents)} ₴',
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _accountWord(int count) {
  if (count % 10 == 1 && count % 100 != 11) return 'рахунок';
  if (count % 10 >= 2 &&
      count % 10 <= 4 &&
      (count % 100 < 12 || count % 100 > 14)) {
    return 'рахунки';
  }
  return 'рахунків';
}
