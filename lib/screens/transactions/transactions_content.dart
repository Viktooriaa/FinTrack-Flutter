import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum _TransactionFilter { all, income, expense }

class TransactionsContent extends StatefulWidget {
  const TransactionsContent({super.key});

  @override
  State<TransactionsContent> createState() => _TransactionsContentState();
}

class _TransactionsContentState extends State<TransactionsContent>
    with AutomaticKeepAliveClientMixin<TransactionsContent> {
  _TransactionFilter _filter = _TransactionFilter.all;
  String _query = '';

  static const _transactions = <_TransactionItem>[
    _TransactionItem(
      title: 'Кав’ярня «Арома»',
      category: 'Продукти',
      date: 'Сьогодні, 20 Вересня',
      time: '12:12',
      amount: '-120.00 ₴',
      expense: true,
      icon: Icons.coffee_rounded,
      tint: Color(0xFFFFF2D6),
    ),
    _TransactionItem(
      title: 'Ulan / Uber',
      category: 'Транспорт',
      date: 'Сьогодні, 20 Вересня',
      time: '08:30',
      amount: '-240.00 ₴',
      expense: true,
      icon: Icons.directions_car_filled_rounded,
      tint: Color(0xFFE5F0FF),
    ),
    _TransactionItem(
      title: 'Зарплата',
      category: 'Дохід',
      date: 'Вчора, 19 Вересня',
      time: '09:00',
      amount: '+35,000.00 ₴',
      expense: false,
      icon: Icons.savings_rounded,
      iconAssetPath: 'assets/images/zarplata.png',
      tint: Color(0xFFDDF5E8),
    ),
    _TransactionItem(
      title: 'Фріланс проект',
      category: 'Дохід',
      date: 'Вчора, 19 Вересня',
      time: '14:45',
      amount: '+10,000.00 ₴',
      expense: false,
      icon: Icons.laptop_mac_rounded,
      tint: Color(0xFFE2F3EA),
    ),
    _TransactionItem(
      title: 'Сільпо',
      category: 'Продукти',
      date: 'Сьогодні',
      time: '14:32',
      amount: '₴520',
      expense: true,
      icon: Icons.shopping_cart_outlined,
      iconAssetPath: 'assets/images/products.png',
      tint: Color(0xFFFFF0F2),
      showTimeTrailing: true,
      highlightExpense: true,
    ),
    _TransactionItem(
      title: 'Кава',
      category: 'Кафе',
      date: 'Сьогодні',
      time: '10:05',
      amount: '₴120',
      expense: true,
      icon: Icons.coffee_rounded,
      tint: Color(0xFFFFF0F2),
      showTimeTrailing: true,
      highlightExpense: true,
    ),
    _TransactionItem(
      title: 'WOG',
      category: 'Транспорт',
      date: 'Вчора',
      time: '18:20',
      amount: '₴1 200',
      expense: true,
      icon: Icons.local_gas_station_rounded,
      tint: Color(0xFFFFF0F2),
      showTimeTrailing: true,
      highlightExpense: true,
    ),
    _TransactionItem(
      title: 'Rozetka',
      category: 'Покупки',
      date: 'Вчора',
      time: '16:11',
      amount: '₴890',
      expense: true,
      icon: Icons.shopping_bag_outlined,
      tint: Color(0xFFFFF0F2),
      showTimeTrailing: true,
      highlightExpense: true,
    ),
    _TransactionItem(
      title: 'Аптека',
      category: 'Здоров’я',
      date: 'Вчора',
      time: '11:42',
      amount: '₴350',
      expense: true,
      icon: Icons.medication_outlined,
      tint: Color(0xFFFFF0F2),
      showTimeTrailing: true,
      highlightExpense: true,
    ),
    _TransactionItem(
      title: 'Netflix',
      category: 'Розваги',
      date: 'Вчора, 19 Вересня',
      time: '12:00',
      amount: '-400.00 ₴',
      expense: true,
      icon: Icons.movie_outlined,
      tint: Color(0xFFF2E9FF),
    ),
  ];

  List<_TransactionItem> get _visibleItems {
    return _transactions.where((item) {
      final matchesFilter = switch (_filter) {
        _TransactionFilter.all =>
          item.title == 'Кав’ярня «Арома»' ||
              item.title == 'Ulan / Uber' ||
              item.title == 'Фріланс проект' ||
              item.title == 'Netflix',
        _TransactionFilter.income =>
          item.title == 'Зарплата' || item.title == 'Фріланс проект',
        _TransactionFilter.expense =>
          item.expense &&
              (item.title == 'Сільпо' ||
                  item.title == 'Кава' ||
                  item.title == 'WOG' ||
                  item.title == 'Rozetka' ||
                  item.title == 'Аптека'),
      };
      final matchesQuery =
          _query.isEmpty ||
          item.title.toLowerCase().contains(_query.toLowerCase()) ||
          item.category.toLowerCase().contains(_query.toLowerCase());
      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final items = _visibleItems;
    final groups = <String, List<_TransactionItem>>{};
    for (final item in items) {
      groups.putIfAbsent(item.date, () => []).add(item);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Транзакції',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE6EAED)),
              borderRadius: BorderRadius.circular(13),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _query = value.trim()),
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Пошук...',
                hintStyle: TextStyle(fontSize: 12, color: Color(0xFF9AA6B2)),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF91A0AF),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _FilterTabs(
            selected: _filter,
            onSelect: (filter) => setState(() => _filter = filter),
          ),
          if (groups.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(
                child: Text(
                  'Операцій не знайдено',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            for (final group in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 17, 2, 8),
                child: Text(
                  group.key,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_filter == _TransactionFilter.expense)
                for (int i = 0; i < group.value.length; i++) ...[
                  _TransactionGroup(items: [group.value[i]]),
                  if (i != group.value.length - 1) const SizedBox(height: 8),
                ]
              else
                _TransactionGroup(items: group.value),
            ],
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onSelect});

  final _TransactionFilter selected;
  final ValueChanged<_TransactionFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    const entries = [
      (filter: _TransactionFilter.all, label: 'Усі'),
      (filter: _TransactionFilter.income, label: 'Дохід'),
      (filter: _TransactionFilter.expense, label: 'Витрати'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDEF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final entry in entries)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(entry.filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == entry.filter
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    entry.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected == entry.filter
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: selected == entry.filter
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TransactionGroup extends StatelessWidget {
  const _TransactionGroup({required this.items});

  final List<_TransactionItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            _TransactionRow(item: items[index]),
            if (index != items.length - 1)
              const Divider(
                height: 1,
                thickness: 0.6,
                color: Color(0xFFF0F2F2),
              ),
          ],
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.item});

  final _TransactionItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.tint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: item.iconAssetPath == null
                ? Icon(
                    item.icon,
                    size: 18,
                    color: item.highlightExpense
                        ? AppColors.expense
                        : item.expense
                        ? AppColors.textPrimary
                        : AppColors.income,
                  )
                : Image.asset(
                    item.iconAssetPath!,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.showTimeTrailing
                      ? item.category
                      : '${item.category} • ${item.time}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.amount,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: !item.expense
                      ? AppColors.income
                      : item.highlightExpense
                      ? AppColors.expense
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              if (item.showTimeTrailing)
                Text(
                  item.time,
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionItem {
  const _TransactionItem({
    required this.title,
    required this.category,
    required this.date,
    required this.time,
    required this.amount,
    required this.expense,
    required this.icon,
    required this.tint,
    this.iconAssetPath,
    this.showTimeTrailing = false,
    this.highlightExpense = false,
  });

  final String title;
  final String category;
  final String date;
  final String time;
  final String amount;
  final bool expense;
  final IconData icon;
  final String? iconAssetPath;
  final Color tint;
  final bool showTimeTrailing;
  final bool highlightExpense;
}
