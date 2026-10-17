import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../data/transaction_store.dart';

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

  List<TransactionRecord> get _visibleItems {
    return TransactionStore.instance.transactions.where((item) {
      final matchesFilter = switch (_filter) {
        _TransactionFilter.all => true,
        _TransactionFilter.income => item.isIncome,
        _TransactionFilter.expense => !item.isIncome,
      };
      final matchesQuery =
          _query.isEmpty ||
          item.title.toLowerCase().contains(_query.toLowerCase()) ||
          item.category.toLowerCase().contains(_query.toLowerCase()) ||
          transactionDateLabel(
            item.date,
          ).toLowerCase().contains(_query.toLowerCase());
      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedBuilder(
      animation: TransactionStore.instance,
      builder: (context, _) => _buildTransactionsPage(),
    );
  }

  Widget _buildTransactionsPage() {
    final items = _visibleItems;
    final groups = <String, List<TransactionRecord>>{};
    for (final item in items) {
      groups.putIfAbsent(transactionDateLabel(item.date), () => []).add(item);
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
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFDDE5EC)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _query = value.trim()),
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Пошук...',
                hintStyle: TextStyle(fontSize: 15, color: Color(0xFF91A2B9)),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF8FA1B8),
                ),
                prefixIconConstraints: BoxConstraints(
                  minWidth: 48,
                  minHeight: 42,
                ),
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _FilterTabs(
            selected: _filter,
            onSelect: (filter) => setState(() => _filter = filter),
          ),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(
                child: Text(
                  _query.isEmpty
                      ? 'Транзакцій ще немає'
                      : 'Операцій не знайдено',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else if (_filter == _TransactionFilter.income) ...[
            const SizedBox(height: 10),
            _TransactionGroup(items: items, showIncomeIcons: true),
          ] else
            for (final group in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 17, 2, 8),
                child: Text(
                  group.key,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
  const _TransactionGroup({required this.items, this.showIncomeIcons = false});

  final List<TransactionRecord> items;
  final bool showIncomeIcons;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF253A30).withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            _TransactionRow(
              item: items[index],
              showIncomeIcons: showIncomeIcons,
            ),
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
  const _TransactionRow({required this.item, this.showIncomeIcons = false});

  final TransactionRecord item;
  final bool showIncomeIcons;

  @override
  Widget build(BuildContext context) {
    final iconAssetPath = transactionIconAsset(item);
    final rowSubtitle = showIncomeIcons
        ? '${item.category} • ${transactionDateLabel(item.date)}'
        : '${item.category} • ${transactionTimeLabel(item.date)}';
    final amountText =
        '${item.isIncome ? '+' : '−'}${formatMoneyCents(item.amountCents)} ₴';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconAssetPath == null
                  ? transactionTint(item)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: iconAssetPath != null
                ? SvgPicture.asset(
                    iconAssetPath,
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  )
                : Icon(
                    transactionIcon(item),
                    size: 18,
                    color: item.isIncome
                        ? AppColors.income
                        : AppColors.textPrimary,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rowSubtitle,
                  style: const TextStyle(
                    fontSize: 10,
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
                amountText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: item.isIncome
                      ? AppColors.income
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
