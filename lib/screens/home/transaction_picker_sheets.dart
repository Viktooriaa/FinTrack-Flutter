import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/account_store.dart';
import 'account_entry_sheet.dart';

class TransactionCategoryChoice {
  const TransactionCategoryChoice({required this.isIncome, required this.name});

  final bool isIncome;
  final String name;
}

class TransactionAccountChoice {
  const TransactionAccountChoice({required this.id, required this.name});

  final String? id;
  final String name;
}

Future<TransactionCategoryChoice?> showTransactionCategoryPicker(
  BuildContext context, {
  required bool isIncome,
}) {
  return showModalBottomSheet<TransactionCategoryChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x40000000),
    builder: (context) => _PickerSheetFrame(
      heightFactor: .785,
      child: _CategoryPicker(isIncome: isIncome),
    ),
  );
}

Future<TransactionAccountChoice?> showTransactionAccountPicker(
  BuildContext context, {
  required String? selectedId,
  required String? selectedName,
}) {
  return showModalBottomSheet<TransactionAccountChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x40000000),
    builder: (context) => _PickerSheetFrame(
      heightFactor: .505,
      child: _AccountPicker(selectedId: selectedId, selectedName: selectedName),
    ),
  );
}

Future<DateTime?> showTransactionDatePicker(
  BuildContext context, {
  required DateTime selectedDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x40000000),
    builder: (context) => _PickerSheetFrame(
      heightFactor: .48,
      child: _DatePicker(selectedDate: selectedDate),
    ),
  );
}

class _PickerSheetFrame extends StatelessWidget {
  const _PickerSheetFrame({required this.child, required this.heightFactor});

  final Widget child;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        widthFactor: 1,
        heightFactor: heightFactor,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D8D4),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerHeader extends StatelessWidget {
  const _PickerHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Material(
            color: const Color(0xFFF1F3F4),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClose,
              child: const SizedBox(
                width: 28,
                height: 28,
                child: Icon(Icons.close_rounded, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _expenseCategories = [
  ('Продукти', '🛒'),
  ('Транспорт', '🚘'),
  ('Ресторани та кафе', '🍴'),
  ('Покупки', '🛍️'),
  ('Здоров’я', '❤️'),
  ('Розваги', '🎮'),
  ('Освіта', '🎓'),
  ('Дім', '🏠'),
  ('Інше', '•••'),
];

const _incomeCategories = [
  ('Зарплата', '💰'),
  ('Фріланс', '💻'),
  ('Інвестиції', '📈'),
  ('Подарунок', '🎁'),
  ('Інше', '•••'),
];

class _CategoryPicker extends StatefulWidget {
  const _CategoryPicker({required this.isIncome});

  final bool isIncome;

  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  late bool _isIncome = widget.isIncome;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final categories = _isIncome ? _incomeCategories : _expenseCategories;
    final filtered = categories
        .where((item) => item.$1.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        _PickerHeader(
          title: 'Виберіть категорію',
          onClose: () => Navigator.pop(context),
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 38,
          child: TextField(
            onChanged: (value) => setState(() => _query = value.trim()),
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Пошук категорій',
              hintStyle: const TextStyle(
                color: Color(0xFF89958F),
                fontSize: 11,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 15,
                color: Color(0xFF89958F),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 34,
                minHeight: 38,
              ),
              filled: true,
              fillColor: const Color(0xFFF1F5F2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CategoryTypePill(
                label: 'Витрати',
                selected: !_isIncome,
                onTap: () => setState(() => _isIncome = false),
              ),
              const SizedBox(width: 6),
              _CategoryTypePill(
                label: 'Доходи',
                selected: _isIncome,
                onTap: () => setState(() => _isIncome = true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE8ECE9)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 54,
                  color: Color(0xFFE9EDEB),
                ),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return SizedBox(
                    height: 50,
                    child: InkWell(
                      onTap: () => Navigator.pop(
                        context,
                        TransactionCategoryChoice(
                          isIncome: _isIncome,
                          name: item.$1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            _PickerIcon(label: item.$2),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.$1,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: AppColors.textPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryTypePill extends StatelessWidget {
  const _CategoryTypePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : const Color(0xFFF0F4F1),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF65746B),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerIcon extends StatelessWidget {
  const _PickerIcon({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: const TextStyle(fontSize: 15)),
    );
  }
}

class _AccountPicker extends StatefulWidget {
  const _AccountPicker({required this.selectedId, required this.selectedName});

  final String? selectedId;
  final String? selectedName;

  @override
  State<_AccountPicker> createState() => _AccountPickerState();
}

class _AccountPickerState extends State<_AccountPicker> {
  static const _presets = [
    _AccountPreset('ПриватБанк', 'privat', '▣'),
    _AccountPreset('monobank', 'mono', 'm'),
    _AccountPreset('Готівка', 'cash', '💵'),
    _AccountPreset('Універсальна', 'universal', '▤'),
    _AccountPreset('Кредитна картка', 'credit', '💳'),
  ];

  List<_AccountOption> get _options {
    final accounts = AccountStore.instance.accounts;
    final usedIds = <String>{};
    final result = <_AccountOption>[];
    for (final preset in _presets) {
      AccountRecord? match;
      for (final account in accounts) {
        if (usedIds.contains(account.id)) continue;
        final text = '${account.name} ${account.subtitle}'.toLowerCase();
        final matched = switch (preset.key) {
          'privat' => text.contains('приват') || text.contains('privat'),
          'mono' => text.contains('mono'),
          'cash' => text.contains('готів') || text.contains('cash'),
          'universal' => text.contains('універс') || text.contains('universal'),
          _ => text.contains('кредит') || text.contains('credit'),
        };
        if (matched) {
          match = account;
          usedIds.add(account.id);
          break;
        }
      }
      result.add(
        _AccountOption(
          name: preset.name,
          key: preset.key,
          icon: preset.icon,
          account: match,
        ),
      );
    }
    for (final account in accounts) {
      if (!usedIds.contains(account.id)) {
        result.add(
          _AccountOption(
            name: account.name,
            key: account.id,
            icon: '▤',
            account: account,
          ),
        );
      }
    }
    return result;
  }

  bool _isSelected(_AccountOption option) {
    if (widget.selectedId != null) {
      return option.account?.id == widget.selectedId;
    }
    return option.name.toLowerCase() == widget.selectedName?.toLowerCase();
  }

  Future<void> _addAccount() async {
    final before = AccountStore.instance.accounts
        .map((item) => item.id)
        .toSet();
    await showAccountEntrySheet(context);
    if (!mounted) return;
    AccountRecord? added;
    for (final account in AccountStore.instance.accounts) {
      if (!before.contains(account.id)) {
        added = account;
        break;
      }
    }
    if (added != null) {
      Navigator.pop(
        context,
        TransactionAccountChoice(id: added.id, name: added.name),
      );
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        _PickerHeader(
          title: 'Виберіть рахунок',
          onClose: () => Navigator.pop(context),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE8ECE9)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 52,
                  color: Color(0xFFE9EDEB),
                ),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final selected = _isSelected(option);
                  return SizedBox(
                    height: 50,
                    child: Material(
                      color: selected ? const Color(0xFFF0F7F3) : Colors.white,
                      child: InkWell(
                        onTap: () => Navigator.pop(
                          context,
                          TransactionAccountChoice(
                            id: option.account?.id,
                            name: option.account?.name ?? option.name,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              _PickerIcon(label: option.icon),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  option.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Icon(
                                selected
                                    ? Icons.check_rounded
                                    : Icons.chevron_right_rounded,
                                size: 16,
                                color: selected
                                    ? AppColors.income
                                    : AppColors.textPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        CustomPaint(
          painter: const _DashedRoundedBorderPainter(
            color: Color(0xFFC8D8CE),
            radius: 13,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton.icon(
              onPressed: _addAccount,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Додати рахунок'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountPreset {
  const _AccountPreset(this.name, this.key, this.icon);

  final String name;
  final String key;
  final String icon;
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(.5, .5, size.width - 1, size.height - 1);
    final borderPath = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final metric in borderPath.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 8) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}

class _AccountOption {
  const _AccountOption({
    required this.name,
    required this.key,
    required this.icon,
    required this.account,
  });

  final String name;
  final String key;
  final String icon;
  final AccountRecord? account;
}

const _ukrainianMonths = [
  'Січень',
  'Лютий',
  'Березень',
  'Квітень',
  'Травень',
  'Червень',
  'Липень',
  'Серпень',
  'Вересень',
  'Жовтень',
  'Листопад',
  'Грудень',
];

class _DatePicker extends StatefulWidget {
  const _DatePicker({required this.selectedDate});

  final DateTime selectedDate;

  @override
  State<_DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<_DatePicker> {
  late DateTime _selected = DateTime(
    widget.selectedDate.year,
    widget.selectedDate.month,
    widget.selectedDate.day,
  );
  late DateTime _month = DateTime(_selected.year, _selected.month);

  void _changeMonth(int amount) {
    setState(() {
      _month = DateTime(_month.year, _month.month + amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday - 1;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final cellCount = ((firstWeekday + daysInMonth + 6) ~/ 7) * 7;
    final today = DateTime.now();

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        _PickerHeader(
          title: 'Виберіть дату',
          onClose: () => Navigator.pop(context),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: Row(
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  '${_ukrainianMonths[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed:
                    _month.year == today.year && _month.month == today.month
                    ? null
                    : () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        color: Color(0xFF9AA59F),
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cellCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 33,
          ),
          itemBuilder: (context, index) {
            final day = index - firstWeekday + 1;
            if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
            final date = DateTime(_month.year, _month.month, day);
            final isSelected =
                date.year == _selected.year &&
                date.month == _selected.month &&
                date.day == _selected.day;
            final isFuture = date.isAfter(
              DateTime(today.year, today.month, today.day),
            );
            return Center(
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: isFuture ? null : () => setState(() => _selected = date),
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isFuture
                          ? const Color(0xFFCDD2D0)
                          : AppColors.textPrimary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _selected = DateTime(today.year, today.month, today.day);
                    _month = DateTime(today.year, today.month);
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0xFFDCE2E6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Сьогодні'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 42,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF163D2D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Готово'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
