import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../data/budget_store.dart';
import '../../data/transaction_store.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  static const _categories = [
    'Продукти',
    'Транспорт',
    'Ресторани та кафе',
    'Покупки',
    'Здоров’я',
    'Розваги',
    'Освіта',
    'Дім',
    'Інше',
  ];
  late final Listenable _data = Listenable.merge([
    BudgetStore.instance,
    TransactionStore.instance,
  ]);

  @override
  void initState() {
    super.initState();
    unawaited(BudgetStore.instance.load());
    unawaited(TransactionStore.instance.load());
  }

  Future<void> _editBudget([CategoryBudget? budget]) async {
    final currentBudgets = BudgetStore.instance.budgets;
    if (budget == null && currentBudgets.length >= _categories.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Для всіх категорій уже задано ліміти.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final result = await showModalBottomSheet<CategoryBudget>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetFormSheet(
        categories: _categories,
        existing: budget == null
            ? currentBudgets.map((item) => item.category).toSet()
            : const {},
        budget: budget,
      ),
    );
    if (result != null) await BudgetStore.instance.upsert(result);
  }

  Future<void> _removeBudget(CategoryBudget budget) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видалити ліміт?'),
        content: Text(
          'Ліміт для категорії «${budget.category}» буде видалено.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
    if (remove == true) await BudgetStore.instance.remove(budget.category);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: AnimatedBuilder(
        animation: _data,
        builder: (context, _) {
          final budgets = BudgetStore.instance.budgets;
          final totals = _currentMonthSpending();
          final totalSpent = totals.values.fold<int>(0, (a, b) => a + b);
          final totalLimit = BudgetStore.instance.totalLimitCents;
          return Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                  children: [
                    _buildDaysRemaining(),
                    const SizedBox(height: 12),
                    _buildTotalCard(totalSpent, totalLimit),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'За категоріями',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .4,
                            ),
                          ),
                        ),
                        if (budgets.isNotEmpty)
                          Text(
                            '${budgets.length} ${_categoryCountLabel(budgets.length)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (budgets.isEmpty)
                      _buildEmptyState()
                    else
                      _buildBudgetList(budgets, totals),
                    if (budgets.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () => _editBudget(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Додати ліміт'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: Color(0xFFCBD8E4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _buildHeader() {
    final month = _ukrainianMonths[DateTime.now().month - 1];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 18, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              'Бюджет на $month',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFFDDF8E9),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _editBudget(),
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

  Widget _buildDaysRemaining() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final remaining = daysInMonth - now.day;
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        remaining == 0 ? 'Останній день місяця' : 'Залишилося $remaining днів',
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildTotalCard(int spent, int limit) {
    final over = limit > 0 && spent > limit;
    final color = over ? AppColors.expense : AppColors.primary;
    final progress = limit == 0
        ? 0.0
        : (spent / limit).clamp(0.0, 1.0).toDouble();
    final percent = limit == 0 ? 0 : (spent * 100 / limit).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B253A30),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Загальний ліміт',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${_money(spent)} / ${_money(limit)}',
                style: TextStyle(
                  color: over ? AppColors.expense : AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFF0F2F4),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              limit == 0
                  ? 'Додай ліміти для категорій'
                  : over
                  ? 'Перевищено на ${_money(spent - limit)}'
                  : 'Використано $percent%',
              style: TextStyle(
                color: over ? AppColors.expense : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: over ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Container(
    padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F3EC),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(Icons.tune_rounded, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        const Text(
          'Ще немає бюджету',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text(
          'Задай ліміт для категорії, щоб стежити за витратами.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => _editBudget(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Створити бюджет'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildBudgetList(
    List<CategoryBudget> budgets,
    Map<String, int> totals,
  ) => Container(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0B253A30),
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        for (var index = 0; index < budgets.length; index++) ...[
          _BudgetRow(
            budget: budgets[index],
            spent: totals[budgets[index].category] ?? 0,
            onEdit: () => _editBudget(budgets[index]),
            onDelete: () => _removeBudget(budgets[index]),
          ),
          if (index < budgets.length - 1)
            const Divider(height: 1, color: Color(0xFFF0F2F2)),
        ],
      ],
    ),
  );

  Map<String, int> _currentMonthSpending() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);
    final totals = <String, int>{};
    for (final transaction in TransactionStore.instance.transactions) {
      if (transaction.isIncome ||
          transaction.date.isBefore(start) ||
          !transaction.date.isBefore(end)) {
        continue;
      }
      totals.update(
        transaction.category,
        (sum) => sum + transaction.amountCents,
        ifAbsent: () => transaction.amountCents,
      );
    }
    return totals;
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.budget,
    required this.spent,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryBudget budget;
  final int spent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final over = spent > budget.limitCents;
    final ratio = budget.limitCents == 0
        ? 0.0
        : (spent / budget.limitCents).clamp(0.0, 1.0).toDouble();
    final color = over
        ? AppColors.expense
        : ratio >= .8
        ? AppColors.warning
        : AppColors.income;
    final percent = budget.limitCents == 0
        ? 0
        : (spent * 100 / budget.limitCents).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _categoryEmoji(budget.category),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: onEdit,
                  child: Text(
                    budget.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 124),
                iconSize: 18,
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.inactive,
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Змінити ліміт')),
                  PopupMenuItem(value: 'delete', child: Text('Видалити')),
                ],
              ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  '${_money(spent)} / ${_money(budget.limitCents)}',
                  style: TextStyle(
                    color: over ? AppColors.expense : AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  color: over ? AppColors.expense : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 7,
                backgroundColor: const Color(0xFFF0F2F4),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          if (over) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  'Перевищено на ${_money(spent - budget.limitCents)}',
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetFormSheet extends StatefulWidget {
  const _BudgetFormSheet({
    required this.categories,
    required this.existing,
    this.budget,
  });

  final List<String> categories;
  final Set<String> existing;
  final CategoryBudget? budget;

  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet> {
  late String _category = widget.budget?.category ?? _availableCategories.first;
  late final TextEditingController _amountController = TextEditingController(
    text: widget.budget == null
        ? ''
        : _formatAmountForInput(widget.budget!.limitCents),
  );
  String? _error;

  List<String> get _availableCategories => [
    if (widget.budget != null) widget.budget!.category,
    ...widget.categories.where(
      (item) =>
          !widget.existing.contains(item) || item == widget.budget?.category,
    ),
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final limit = _parseCents(_amountController.text);
    if (limit == null || limit <= 0) {
      setState(() => _error = 'Введи ліміт більше нуля.');
      return;
    }
    Navigator.pop(
      context,
      CategoryBudget(category: _category, limitCents: limit),
    );
  }

  @override
  Widget build(BuildContext context) => _BudgetSheetFrame(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.budget == null ? 'Новий ліміт' : 'Змінити ліміт',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Категорія',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              decoration: _budgetInputDecoration(),
              items: _availableCategories
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text('${_categoryEmoji(item)}  $item'),
                    ),
                  )
                  .toList(),
              onChanged: widget.budget == null
                  ? (value) {
                      if (value != null) setState(() => _category = value);
                    }
                  : null,
            ),
            const SizedBox(height: 14),
            const Text(
              'Місячний ліміт',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              decoration: _budgetInputDecoration().copyWith(suffixText: '₴'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.expense, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Зберегти ліміт'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BudgetSheetFrame extends StatelessWidget {
  const _BudgetSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      20,
      10,
      20,
      20 + MediaQuery.paddingOf(context).bottom,
    ),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFCFD8D3),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

InputDecoration _budgetInputDecoration() => InputDecoration(
  filled: true,
  fillColor: AppColors.background,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: const BorderSide(color: Color(0xFFE7ECE9)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: const BorderSide(color: AppColors.primary),
  ),
);

int? _parseCents(String raw) {
  final value = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (value.isEmpty || '.'.allMatches(value).length > 1) return null;
  final parts = value.split('.');
  final whole = int.tryParse(parts.first);
  if (whole == null) return null;
  final fraction = parts.length == 1 ? '' : parts[1];
  if (fraction.length > 2 || (parts.length > 1 && fraction.isEmpty)) {
    return null;
  }
  return whole * 100 +
      (fraction.isEmpty ? 0 : int.parse(fraction.padRight(2, '0')));
}

String _formatAmountForInput(int cents) => formatMoneyCents(
  cents,
  groupSeparator: '',
  decimalSeparator: ',',
  showDecimals: cents % 100 != 0,
);

String _money(int cents) =>
    '${formatMoneyCents(cents, groupSeparator: ' ', decimalSeparator: ',', showDecimals: cents % 100 != 0)} ₴';

String _categoryEmoji(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('продукт')) return '🛒';
  if (normalized.contains('транспорт')) return '🚘';
  if (normalized.contains('ресторан') || normalized.contains('кафе')) {
    return '🍴';
  }
  if (normalized.contains('покуп')) {
    return '🛍️';
  }
  if (normalized.contains('здоров')) {
    return '❤️';
  }
  if (normalized.contains('розваг')) {
    return '🎮';
  }
  if (normalized.contains('освіт')) {
    return '🎓';
  }
  if (normalized.contains('дім')) {
    return '🏠';
  }
  return '•••';
}

String _categoryCountLabel(int count) {
  final lastTwo = count % 100;
  if (lastTwo >= 11 && lastTwo <= 14) return 'категорій';
  return switch (count % 10) {
    1 => 'категорія',
    2 || 3 || 4 => 'категорії',
    _ => 'категорій',
  };
}

const _ukrainianMonths = [
  'Січні',
  'Лютому',
  'Березні',
  'Квітні',
  'Травні',
  'Червні',
  'Липні',
  'Серпні',
  'Вересні',
  'Жовтні',
  'Листопаді',
  'Грудні',
];
