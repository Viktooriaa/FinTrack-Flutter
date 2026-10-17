import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/account_store.dart';
import '../../data/transaction_store.dart';
import '../analytics/analytics_content.dart';
import '../transactions/transactions_content.dart';
import 'account_entry_sheet.dart';
import 'transaction_entry_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  final PageController _pageController = PageController();
  late final Listenable _homeData = Listenable.merge([
    TransactionStore.instance,
    AccountStore.instance,
  ]);

  @override
  void initState() {
    super.initState();
    unawaited(TransactionStore.instance.load());
    unawaited(AccountStore.instance.load());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _selectedNavIndex = switch (page) {
                      0 => 0,
                      1 => 1,
                      2 => 3,
                      _ => 4,
                    };
                  });
                },
                children: [
                  AnimatedBuilder(
                    animation: _homeData,
                    builder: (context, _) => _buildHomeContent(),
                  ),
                  const TransactionsContent(),
                  const AnalyticsContent(key: ValueKey('analytics-page')),
                  _buildMoreContent(),
                ],
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 4),
          _buildBalanceCard(),
          const SizedBox(height: 14),
          _buildQuickActions(),
          const SizedBox(height: 22),
          _buildSectionHeader(
            'Рахунки та картки',
            'Додати +',
            onTap: () => showAccountEntrySheet(context),
          ),
          const SizedBox(height: 8),
          _buildAccounts(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Останні транзакції',
            'Більше',
            onTap: () => _onNavigationTap(1),
          ),
          const SizedBox(height: 6),
          _buildTransactions(),
        ],
      ),
    );
  }

  Widget _buildMoreContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ще',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          for (final item in const [
            (Icons.account_balance_wallet_outlined, 'Рахунки та картки'),
            (Icons.flag_outlined, 'Фінансові цілі'),
            (Icons.settings_outlined, 'Налаштування'),
            (Icons.help_outline_rounded, 'Допомога'),
          ]) ...[
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                leading: Icon(item.$1, color: AppColors.primary),
                title: Text(item.$2),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  if (item.$2 == 'Рахунки та картки') {
                    showAccountEntrySheet(context);
                  } else {
                    _showMessage(item.$2);
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  // HEADER

  Widget _buildHeader() {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'І',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Вітаю назад,',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ірина 👋',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _showMessage('Сповіщення'),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/dzvinok.svg',
                      width: 20,
                      height: 20,
                    ),
                    const Positioned(
                      top: 8,
                      right: 9,
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BALANCE CARD

  Widget _buildBalanceCard() {
    final store = TransactionStore.instance;
    final accountStore = AccountStore.instance;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    final balanceCents =
        accountStore.totalBalanceCents +
        store.transactions.fold<int>(
          0,
          (balance, transaction) =>
              balance +
              (transaction.isIncome
                  ? transaction.amountCents
                  : -transaction.amountCents),
        );
    final monthlyIncomeCents = store.sumBetween(
      monthStart,
      nextMonth,
      type: TransactionType.income,
    );
    final monthlyExpenseCents = store.sumBetween(
      monthStart,
      nextMonth,
      type: TransactionType.expense,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D5947), Color(0xFF285E50)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.13),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Загальний баланс',
            style: TextStyle(color: Color(0xFFB8D9C9), fontSize: 12),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${formatMoneyCents(balanceCents)} ',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const TextSpan(
                    text: 'грн',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9BE7CB),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBalanceDetail(
                  icon: Icons.south_west_rounded,
                  iconColor: const Color(0xFF6FE0B5),
                  background: const Color(0xFF286D58),
                  title: 'Дохід (місяць)',
                  amount: monthlyIncomeCents == 0
                      ? '0 грн'
                      : '+${formatMoneyCents(monthlyIncomeCents, showDecimals: false)} грн',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBalanceDetail(
                  icon: Icons.north_east_rounded,
                  iconColor: const Color(0xFFFFA5A5),
                  background: const Color(0xFF53675F),
                  title: 'Витрати (місяць)',
                  amount: monthlyExpenseCents == 0
                      ? '0 грн'
                      : '−${formatMoneyCents(monthlyExpenseCents, showDecimals: false)} грн',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceDetail({
    required IconData icon,
    required Color iconColor,
    required Color background,
    required String title,
    required String amount,
  }) {
    return Row(
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFB8D9C9), fontSize: 10),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // QUICK ACTIONS

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        title: 'Дохід',
        assetPath: 'assets/icons/dohid.svg',
        background: const Color(0xFFE8F4EE),
        onTap: () => showTransactionEntrySheet(context, isIncome: true),
      ),
      _QuickAction(
        title: 'Витрати',
        assetPath: 'assets/icons/vutratu.svg',
        background: const Color(0xFFFFF0F2),
        onTap: () => showTransactionEntrySheet(context, isIncome: false),
      ),
      _QuickAction(
        title: 'Бюджет',
        assetPath: 'assets/icons/budget.svg',
        background: const Color(0xFFE8F4EE),
        onTap: () => _showMessage('Бюджет'),
      ),
      _QuickAction(
        title: 'Фінансові\nцілі',
        assetPath: 'assets/icons/finansu.svg',
        background: const Color(0xFFEDF4FF),
        onTap: () => _showMessage('Фінансові цілі'),
      ),
      _QuickAction(
        title: 'Сканувати\nчек',
        assetPath: 'assets/icons/check.svg',
        background: const Color(0xFFFFF8E3),
        onTap: () => _showMessage('Сканування чека'),
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: _buildQuickActionCard(actions[i])),
        ],
      ],
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: const Color(0x1A1D4D3E),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(3, 11, 3, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: action.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  action.assetPath,
                  width: 23,
                  height: 23,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 27,
                child: Center(
                  child: Text(
                    action.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SECTION HEADERS

  Widget _buildSectionHeader(
    String title,
    String action, {
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ACCOUNTS

  Widget _buildAccounts() {
    final accounts = AccountStore.instance.accounts;
    if (accounts.isEmpty) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: TextButton.icon(
            onPressed: () => showAccountEntrySheet(context),
            icon: const Icon(Icons.add_card_rounded, size: 18),
            label: const Text('Додайте картку та суму'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ),
      );
    }

    final cardWidth = (MediaQuery.sizeOf(context).width - 48) / 2;
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: cardWidth,
          child: _buildAccountCard(accounts[index]),
        ),
      ),
    );
  }

  Widget _buildAccountCard(AccountRecord account) {
    final isMono = account.name.toLowerCase().contains('mono');
    return Container(
      height: 96,
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  account.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isMono ? AppColors.textPrimary : AppColors.income,
                  ),
                ),
              ),
              if (isMono)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(left: 3),
                  decoration: const BoxDecoration(
                    color: AppColors.income,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            account.subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${formatMoneyCents(account.balanceCents)} ₴',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // RECENT TRANSACTIONS

  Widget _buildTransactions() {
    final transactions = TransactionStore.instance.transactions
        .take(2)
        .toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: transactions.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  'Транзакцій ще немає',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < transactions.length; index++) ...[
                  _buildTransactionRow(
                    icon: transactionIcon(transactions[index]),
                    iconAssetPath: transactionIconAsset(transactions[index]),
                    iconBackground: transactionTint(transactions[index]),
                    title: transactions[index].title,
                    subtitle:
                        '${transactions[index].category} • ${transactionDateLabel(transactions[index].date)}',
                    amount:
                        '${transactions[index].isIncome ? '+' : '−'}${formatMoneyCents(transactions[index].amountCents)} ₴',
                    amountColor: transactions[index].isIncome
                        ? AppColors.income
                        : AppColors.textPrimary,
                  ),
                  if (index != transactions.length - 1)
                    Container(height: 1, color: const Color(0xFFF1F2F1)),
                ],
              ],
            ),
    );
  }

  Widget _buildTransactionRow({
    required IconData icon,
    String? iconAssetPath,
    required Color iconBackground,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconAssetPath == null
                  ? iconBackground
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: iconAssetPath == null
                ? Icon(icon, size: 18, color: AppColors.textPrimary)
                : SvgPicture.asset(
                    iconAssetPath,
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            amount,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  // BOTTOM NAVIGATION

  Widget _buildBottomNavigation() {
    const items = [
      (iconPath: 'assets/icons/home.svg', label: 'Головна'),
      (iconPath: 'assets/icons/operation.svg', label: 'Операції'),
      (iconPath: 'assets/icons/button_add.svg', label: ''),
      (iconPath: 'assets/icons/analis.svg', label: 'Аналітика'),
      (iconPath: 'assets/icons/dots.svg', label: 'Ще'),
    ];

    return Container(
      height: 54,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDEFEF), width: 0.7)),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = _selectedNavIndex == index;

          if (index == 2) {
            return Expanded(
              child: Center(
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _showAddTransactionSheet,
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: Center(
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.14),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 29,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return Expanded(
            child: InkWell(
              onTap: () => _onNavigationTap(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    item.iconPath,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      isSelected ? AppColors.primary : AppColors.inactive,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.inactive,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _onNavigationTap(int index) {
    if (index == 2) {
      _showAddTransactionSheet();
      return;
    }

    final page = switch (index) {
      0 => 0,
      1 => 1,
      3 => 2,
      _ => 3,
    };
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _showAddTransactionSheet() async {
    final isIncome = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Нова операція',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _AddActionButton(
                      label: 'Дохід',
                      icon: Icons.south_west_rounded,
                      color: AppColors.income,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AddActionButton(
                      label: 'Витрата',
                      icon: Icons.north_east_rounded,
                      color: AppColors.expense,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (isIncome != null && mounted) {
      await showTransactionEntrySheet(context, isIncome: isIncome);
    }
  }
}

class _AddActionButton extends StatelessWidget {
  const _AddActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _QuickAction {
  final String title;
  final String assetPath;
  final Color background;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.assetPath,
    required this.background,
    required this.onTap,
  });
}
