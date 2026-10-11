import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 14),
                    _buildBalanceCard(),
                    const SizedBox(height: 14),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      'Рахунки та картки',
                      'Усі (4)',
                      onTap: () => _showMessage('Усі рахунки'),
                    ),
                    const SizedBox(height: 10),
                    _buildAccounts(),
                    const SizedBox(height: 18),
                    _buildSectionHeader(
                      'Останні транзакції',
                      'Більше',
                      onTap: () => _showMessage('Усі транзакції'),
                    ),
                    const SizedBox(height: 10),
                    _buildTransactions(),
                  ],
                ),
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  // HEADER

  Widget _buildHeader() {
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'І',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Вітаємо назад,',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
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
                width: 42,
                height: 42,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF185442), Color(0xFF1D5945)],
        ),
        borderRadius: BorderRadius.circular(23),
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
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: '124,850.00 ',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.7,
                    ),
                  ),
                  TextSpan(
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
          const SizedBox(height: 15),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _buildBalanceDetail(
                  icon: Icons.south_west_rounded,
                  iconColor: const Color(0xFF6FE0B5),
                  background: const Color(0xFF286D58),
                  title: 'Дохід (місяць)',
                  amount: '+45,000 грн',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBalanceDetail(
                  icon: Icons.north_east_rounded,
                  iconColor: const Color(0xFFFFA5A5),
                  background: const Color(0xFF53675F),
                  title: 'Витрати (місяць)',
                  amount: '-18,340 грн',
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
          width: 27,
          height: 27,
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
                style: const TextStyle(color: Color(0xFFB8D9C9), fontSize: 9),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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
        onTap: () => _showMessage('Додавання доходу'),
      ),
      _QuickAction(
        title: 'Витрати',
        assetPath: 'assets/icons/vutratu.svg',
        background: const Color(0xFFFFF0F2),
        onTap: () => _showMessage('Додавання витрати'),
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(3, 9, 3, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
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
                height: 25,
                child: Center(
                  child: Text(
                    action.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
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
              fontSize: 13,
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
              fontSize: 10,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 19),
      child: Row(
        children: [
          Expanded(
            child: _buildAccountCard(
              name: 'mono',
              balance: '48,200 ₴',
              subtitle: 'Чорна картка',
              isMono: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildAccountCard(
              name: 'Приват24',
              balance: '76,650 ₴',
              subtitle: 'Універсальна',
              isMono: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard({
    required String name,
    required String balance,
    required String subtitle,
    required bool isMono,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
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
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
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
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              balance,
              style: const TextStyle(
                fontSize: 13,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          _buildTransactionRow(
            icon: Icons.shopping_cart_outlined,
            iconBackground: const Color(0xFFFFF0C2),
            title: 'Сільпо',
            subtitle: 'Продукти • Сьогодні',
            amount: '-845.00 ₴',
            amountColor: AppColors.textPrimary,
          ),
          Container(height: 1, color: const Color(0xFFF1F2F1)),
          _buildTransactionRow(
            icon: Icons.savings_outlined,
            iconBackground: const Color(0xFFD5F8E8),
            title: 'Зарплата',
            subtitle: 'Дохід • Вчора',
            amount: '+35,000.00 ₴',
            amountColor: AppColors.income,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow({
    required IconData icon,
    required Color iconBackground,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: amountColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BOTTOM NAVIGATION

  Widget _buildBottomNavigation() {
    const items = [
      (icon: Icons.home_outlined, label: 'Головна'),
      (icon: Icons.format_list_numbered_rounded, label: 'Операції'),
      (icon: Icons.add_rounded, label: ''),
      (icon: Icons.pie_chart_outline_rounded, label: 'Аналітика'),
      (icon: Icons.more_horiz_rounded, label: 'Ще'),
    ];

    return Container(
      height: 64,
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
                  onTap: () => _showMessage('Нова операція'),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFDCE9E1),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            );
          }

          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedNavIndex = index;
                });

                if (index != 0) {
                  _showMessage(item.label);
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: 21,
                    color: isSelected ? AppColors.primary : AppColors.inactive,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 9,
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
