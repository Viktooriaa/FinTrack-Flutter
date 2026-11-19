import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/budget_store.dart';
import '../../data/goal_store.dart';
import '../../data/transaction_store.dart';

enum _NoticeType { budget, goal, transaction }

class _Notice {
  const _Notice({
    required this.type,
    required this.title,
    required this.message,
    required this.date,
    required this.emoji,
    required this.tint,
  });

  final _NoticeType type;
  final String title;
  final String message;
  final DateTime date;
  final String emoji;
  final Color tint;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _filters = ['Усі', 'Бюджет', 'Цілі', 'Транзакції'];
  int _selectedFilter = 0;
  late final Listenable _data = Listenable.merge([
    TransactionStore.instance,
    BudgetStore.instance,
    GoalStore.instance,
  ]);

  @override
  void initState() {
    super.initState();
    unawaited(TransactionStore.instance.load());
    unawaited(BudgetStore.instance.load());
    unawaited(GoalStore.instance.load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: AnimatedBuilder(
        animation: _data,
        builder: (context, _) => _buildPage(_notices()),
      ),
    ),
  );

  Widget _buildPage(List<_Notice> notices) {
    final visible = notices.where((notice) {
      if (_selectedFilter == 0) return true;
      return notice.type.index == _selectedFilter - 1;
    }).toList();
    return Column(
      children: [
        _buildHeader(),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final selected = index == _selectedFilter;
              return ChoiceChip(
                label: Text(_filters[index]),
                selected: selected,
                onSelected: (_) => setState(() => _selectedFilter = index),
                backgroundColor: const Color(0xFFF0F4F1),
                selectedColor: AppColors.primary,
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: visible.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _NoticeCard(notice: visible[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 6, 18, 14),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Text(
            'Сповіщення',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          tooltip: 'Фільтр',
          onPressed: () => setState(() => _selectedFilter = 0),
          icon: const Icon(Icons.filter_list_rounded),
          color: AppColors.primary,
        ),
      ],
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F3EC),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Поки немає сповіщень',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Тут з’являться оновлення про бюджет, цілі та операції.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );

  List<_Notice> _notices() {
    final notices = <_Notice>[];
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    final transactions = TransactionStore.instance.newestFirst;

    for (final budget in BudgetStore.instance.budgets) {
      final categoryTransactions = transactions.where(
        (item) =>
            !item.isIncome &&
            item.category.toLowerCase() == budget.category.toLowerCase() &&
            !item.date.isBefore(monthStart) &&
            item.date.isBefore(nextMonth),
      );
      final spent = categoryTransactions.fold<int>(
        0,
        (sum, item) => sum + item.amountCents,
      );
      final ratio = budget.limitCents == 0 ? 0.0 : spent / budget.limitCents;
      if (ratio < .8) continue;
      final over = spent > budget.limitCents;
      final percent = (spent * 100 / budget.limitCents).round();
      notices.add(
        _Notice(
          type: _NoticeType.budget,
          title: over ? 'Перевищено ліміт' : 'Наближення до ліміту',
          message: over
              ? 'Витрати в категорії «${budget.category}» перевищили ліміт на ${_money(spent - budget.limitCents)}.'
              : 'Використано $percent% місячного ліміту в категорії «${budget.category}».',
          date: categoryTransactions.isEmpty
              ? now
              : categoryTransactions.first.date,
          emoji: over ? '⚠️' : '🔔',
          tint: over ? const Color(0xFFFFF1DA) : const Color(0xFFFFF4DA),
        ),
      );
    }

    for (final goal in GoalStore.instance.goals.where(
      (item) => item.isComplete,
    )) {
      notices.add(
        _Notice(
          type: _NoticeType.goal,
          title: 'Досягнуто цілі! 🎉',
          message: 'Ціль «${goal.name}» виконана. Час порадувати себе!',
          date: now,
          emoji: '🎯',
          tint: const Color(0xFFE8F0FF),
        ),
      );
    }

    for (final transaction in transactions.take(20)) {
      notices.add(
        _Notice(
          type: _NoticeType.transaction,
          title: transaction.isIncome ? 'Новий дохід' : 'Нова витрата',
          message:
              '${transaction.isIncome ? '+' : '−'}${_money(transaction.amountCents)} · ${transaction.category}${transaction.accountName == null ? '' : ' · ${transaction.accountName}'}',
          date: transaction.date,
          emoji: transaction.isIncome
              ? '💚'
              : _transactionEmoji(transaction.category),
          tint: transaction.isIncome
              ? const Color(0xFFDFF8EC)
              : _transactionTint(transaction.category),
        ),
      );
    }
    notices.sort((left, right) => right.date.compareTo(left.date));
    return notices;
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});

  final _Notice notice;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFF0F2F2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: notice.tint,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(notice.emoji, style: const TextStyle(fontSize: 17)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notice.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                notice.message,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _timeLabel(notice.date),
                style: const TextStyle(fontSize: 10, color: Color(0xFF8EA0B7)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _money(int cents) =>
    '${formatMoneyCents(cents, groupSeparator: ' ', decimalSeparator: ',', showDecimals: cents % 100 != 0)} ₴';

String _timeLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final eventDay = DateTime(date.year, date.month, date.day);
  final difference = today.difference(eventDay).inDays;
  final time = transactionTimeLabel(date);
  if (difference == 0) return 'Сьогодні, $time';
  if (difference == 1) return 'Вчора, $time';
  return transactionDateLabel(date);
}

String _transactionEmoji(String category) {
  final value = category.toLowerCase();
  if (value.contains('продукт')) return '🛒';
  if (value.contains('транспорт')) return '🚘';
  if (value.contains('кафе') || value.contains('ресторан')) return '☕';
  if (value.contains('покуп')) return '🛍️';
  if (value.contains('здоров') || value.contains('аптек')) return '❤️';
  if (value.contains('розваг')) return '🎮';
  return '💸';
}

Color _transactionTint(String category) {
  final value = category.toLowerCase();
  if (value.contains('транспорт')) return const Color(0xFFE5F0FF);
  if (value.contains('розваг')) return const Color(0xFFF2E9FF);
  if (value.contains('продукт')) return const Color(0xFFFFF3C4);
  return const Color(0xFFFFF0F2);
}
