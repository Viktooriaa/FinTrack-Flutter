import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/transaction_store.dart';

class AnalyticsContent extends StatefulWidget {
  const AnalyticsContent({super.key});

  @override
  State<AnalyticsContent> createState() => _AnalyticsContentState();
}

class _AnalyticsContentState extends State<AnalyticsContent>
    with AutomaticKeepAliveClientMixin<AnalyticsContent> {
  int _period = 0;
  final List<int?> _selectedChartIndices = [null, null, null];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnimatedBuilder(
      animation: TransactionStore.instance,
      builder: (context, _) => _buildAnalyticsPage(),
    );
  }

  Widget _buildAnalyticsPage() {
    final period = _buildPeriodData(
      _period,
      TransactionStore.instance.transactions,
    );
    final selectedIndex = _selectedChartIndices[_period] ?? period.defaultIndex;
    final showSelectedBucket = _selectedChartIndices[_period] != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          const Text(
            'Аналітика',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          _PeriodTabs(
            selected: _period,
            onSelect: (value) => setState(() => _period = value),
          ),
          const SizedBox(height: 14),
          _buildSpendingCard(period, selectedIndex, showSelectedBucket),
          const SizedBox(height: 18),
          _buildCategoryCard(period, selectedIndex, showSelectedBucket),
        ],
      ),
    );
  }

  _AnalyticsPeriodData _buildPeriodData(
    int periodIndex,
    List<TransactionRecord> transactions,
  ) {
    final now = DateTime.now();
    late DateTime start;
    late DateTime end;
    late DateTime previousStart;
    late List<String> labels;
    late List<int> bucketTotals;
    late int defaultIndex;

    switch (periodIndex) {
      case 0:
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        end = start.add(const Duration(days: 7));
        previousStart = start.subtract(const Duration(days: 7));
        labels = const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
        bucketTotals = List.filled(7, 0);
        defaultIndex = now.weekday - 1;
        break;
      case 1:
        start = DateTime(now.year, now.month);
        end = DateTime(now.year, now.month + 1);
        previousStart = DateTime(now.year, now.month - 1);
        final daysInMonth = end.subtract(const Duration(days: 1)).day;
        labels = List.generate(
          7,
          (index) => '${((index * daysInMonth + 6) ~/ 7) + 1}',
        );
        bucketTotals = List.filled(7, 0);
        defaultIndex = ((now.day - 1) * 7 ~/ daysInMonth).clamp(0, 6).toInt();
        break;
      default:
        start = DateTime(now.year);
        end = DateTime(now.year + 1);
        previousStart = DateTime(now.year - 1);
        labels = const [
          'Січ',
          'Лют',
          'Бер',
          'Кві',
          'Тра',
          'Чер',
          'Лип',
          'Сер',
          'Вер',
          'Жов',
          'Лис',
          'Гру',
        ];
        bucketTotals = List.filled(12, 0);
        defaultIndex = now.month - 1;
    }

    final previousEnd = start;
    final expenses = transactions
        .where(
          (item) =>
              !item.isIncome &&
              !item.date.isBefore(start) &&
              item.date.isBefore(end),
        )
        .toList();
    final totalCents = expenses.fold<int>(
      0,
      (total, item) => total + item.amountCents,
    );
    final previousTotalCents = transactions
        .where(
          (item) =>
              !item.isIncome &&
              !item.date.isBefore(previousStart) &&
              item.date.isBefore(previousEnd),
        )
        .fold<int>(0, (total, item) => total + item.amountCents);

    final categoryTotals = <String, int>{};
    final bucketCategoryTotals = List.generate(
      bucketTotals.length,
      (_) => <String, int>{},
    );
    for (final item in expenses) {
      final category = item.category.trim().isEmpty ? 'Інше' : item.category;
      categoryTotals.update(
        category,
        (value) => value + item.amountCents,
        ifAbsent: () => item.amountCents,
      );
      final index = switch (periodIndex) {
        0 => item.date.weekday - 1,
        1 =>
          ((item.date.day - 1) * 7 ~/ (end.difference(start).inDays))
              .clamp(0, 6)
              .toInt(),
        _ => item.date.month - 1,
      };
      bucketTotals[index] += item.amountCents;
      bucketCategoryTotals[index].update(
        category,
        (value) => value + item.amountCents,
        ifAbsent: () => item.amountCents,
      );
    }

    const colors = [
      Color(0xFFFF6B16),
      Color(0xFF4E82A8),
      Color(0xFF9C4EF0),
      Color(0xFFF0444D),
      Color(0xFF20B88A),
      Color(0xFFA4ACB7),
    ];
    List<_AnalyticsCategory> categoriesForBucket(
      Map<String, int> totals,
      int bucketTotal,
    ) {
      final sorted = totals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (sorted.length > 6) {
        final largest = sorted.take(5).toList();
        final otherTotal = sorted
            .skip(5)
            .fold<int>(0, (sum, entry) => sum + entry.value);
        final existingOther = largest.indexWhere(
          (entry) => entry.key.toLowerCase() == 'інше',
        );
        if (existingOther >= 0) {
          final entry = largest[existingOther];
          largest[existingOther] = MapEntry(
            entry.key,
            entry.value + otherTotal,
          );
        } else {
          largest.add(MapEntry('Інше', otherTotal));
        }
        sorted
          ..clear()
          ..addAll(largest);
      }
      return [
        for (var index = 0; index < sorted.length; index++)
          _AnalyticsCategory(
            sorted[index].key,
            bucketTotal == 0
                ? 0
                : (sorted[index].value * 100 / bucketTotal).round(),
            _categoryColor(sorted[index].key, colors, index),
            sorted[index].value,
          ),
      ];
    }

    final bucketCategories = [
      for (var index = 0; index < bucketTotals.length; index++)
        categoriesForBucket(bucketCategoryTotals[index], bucketTotals[index]),
    ];
    final periodCategories = categoriesForBucket(categoryTotals, totalCents);
    final maxBucketTotal = bucketTotals.fold<int>(
      0,
      (maximum, value) => math.max(maximum, value).toInt(),
    );
    final chartValues = bucketTotals
        .map((value) => maxBucketTotal == 0 ? 0.0 : value / maxBucketTotal)
        .toList();
    final spendingIncreased = totalCents >= previousTotalCents;
    final trend = previousTotalCents == 0
        ? (totalCents == 0 ? '—' : '↑ нові')
        : '${spendingIncreased ? '↑' : '↓'} ${((totalCents - previousTotalCents).abs() * 100 ~/ previousTotalCents)}%';

    return _AnalyticsPeriodData(
      totalCents: totalCents,
      trend: trend,
      spendingIncreased: spendingIncreased,
      chartLabels: labels,
      chartValues: chartValues,
      defaultIndex: defaultIndex,
      bucketTotals: bucketTotals,
      bucketCategories: bucketCategories,
      categories: periodCategories,
    );
  }

  Color _categoryColor(String category, List<Color> palette, int index) {
    final name = category.toLowerCase();
    if (name.contains('їж') ||
        name.contains('продукт') ||
        name.contains('ресторан') ||
        name.contains('каф')) {
      return const Color(0xFFFF6B16);
    }
    if (name.contains('транспорт')) return const Color(0xFF4E82A8);
    if (name.contains('покуп')) return const Color(0xFF9C4EF0);
    if (name.contains('комун')) return const Color(0xFFF0444D);
    if (name.contains('розваг')) return const Color(0xFF20B88A);
    if (name == 'інше') return const Color(0xFFA4ACB7);
    return palette[index % palette.length];
  }

  Widget _buildSpendingCard(
    _AnalyticsPeriodData period,
    int selectedChartIndex,
    bool showSelectedBucket,
  ) {
    final selectedTotal = showSelectedBucket
        ? period.bucketTotals[selectedChartIndex]
        : period.totalCents;
    final neutralTrend = period.trend == '—';
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Витрати',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: neutralTrend
                      ? const Color(0xFFF1F3F4)
                      : period.spendingIncreased
                      ? const Color(0xFFFFEFF0)
                      : const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  period.trend,
                  style: TextStyle(
                    fontSize: 10,
                    color: neutralTrend
                        ? AppColors.textSecondary
                        : period.spendingIncreased
                        ? AppColors.expense
                        : AppColors.income,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₴ ${formatMoneyCents(selectedTotal, groupSeparator: ' ', decimalSeparator: ',')}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 122,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final index =
                      (details.localPosition.dx /
                              constraints.maxWidth *
                              period.chartValues.length)
                          .floor()
                          .clamp(0, period.chartValues.length - 1)
                          .toInt();
                  if (index != _selectedChartIndices[_period]) {
                    setState(() => _selectedChartIndices[_period] = index);
                  }
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 122),
                  painter: _BarChartPainter(
                    values: period.chartValues,
                    labels: period.chartLabels,
                    selectedIndex: selectedChartIndex,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    _AnalyticsPeriodData period,
    int selectedChartIndex,
    bool showSelectedBucket,
  ) {
    final selectedTotal = showSelectedBucket
        ? period.bucketTotals[selectedChartIndex]
        : period.totalCents;
    final selectedCategories = showSelectedBucket
        ? period.bucketCategories[selectedChartIndex]
        : period.categories;
    final totalLabel =
        '₴${formatMoneyCents(selectedTotal, groupSeparator: ' ', decimalSeparator: ',')}';

    Widget buildDonut(double size) => SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutChartPainter(
          categories: selectedCategories,
          totalLabel: totalLabel,
        ),
      ),
    );

    Widget buildLegend({required bool compact}) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selectedCategories.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Ще немає витрат',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          )
        else
          for (final category in selectedCategories)
            Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 5 : 8),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: category.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${category.percent}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 15, 22, 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Витрати за категоріями',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 280;
              if (compact) {
                return Column(
                  children: [
                    Center(child: buildDonut(112)),
                    const SizedBox(height: 10),
                    buildLegend(compact: true),
                  ],
                );
              }
              return Row(
                children: [
                  const SizedBox(width: 8),
                  buildDonut(124),
                  const SizedBox(width: 24),
                  Expanded(child: buildLegend(compact: false)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(24),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF253A30).withValues(alpha: 0.045),
      blurRadius: 14,
      offset: const Offset(0, 3),
    ),
  ],
);

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const labels = ['Тиждень', 'Місяць', 'Рік'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEEF0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == i ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected == i
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: selected == i
                          ? AppColors.textPrimary
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

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({
    required this.values,
    required this.labels,
    required this.selectedIndex,
  });

  final List<double> values;
  final List<String> labels;
  final int selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    const labelHeight = 18.0;
    final chartHeight = size.height - labelHeight;
    final barWidth = math.min(20.0, size.width / (values.length * 1.75));
    final slotWidth = size.width / values.length;
    final baseY = chartHeight - 4;

    for (int i = 0; i < values.length; i++) {
      final height = values[i] * (chartHeight - 22);
      final left = i * slotWidth + (slotWidth - barWidth) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, baseY - height, barWidth, height),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = i == selectedIndex
              ? AppColors.primary
              : const Color(0xFFD6EEDD),
      );

      final painter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: 10,
            color: i == selectedIndex
                ? AppColors.primary
                : const Color(0xFF9AA5AE),
            fontWeight: i == selectedIndex ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: slotWidth);
      painter.paint(
        canvas,
        Offset(
          i * slotWidth + (slotWidth - painter.width) / 2,
          chartHeight + 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.labels != labels ||
      oldDelegate.selectedIndex != selectedIndex;
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({
    required this.categories,
    required this.totalLabel,
  });

  final List<_AnalyticsCategory> categories;
  final String totalLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 3;
    const strokeWidth = 13.0;
    var startAngle = -math.pi / 2;
    const gap = 0.035;
    final total = categories.fold<int>(
      0,
      (sum, category) => sum + category.amountCents,
    );

    if (total == 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFFE7ECE9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }

    if (total > 0) {
      for (final category in categories) {
        final sweep = math
            .max(0.0, math.pi * 2 * category.amountCents / total - gap)
            .toDouble();
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweep,
          false,
          Paint()
            ..color = category.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.butt,
        );
        startAngle += sweep + gap;
      }
    }

    final amount = TextPainter(
      text: TextSpan(
        text: totalLabel,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    amount.paint(canvas, Offset(center.dx - amount.width / 2, center.dy - 8));

    final caption = TextPainter(
      text: const TextSpan(
        text: 'всього',
        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    caption.paint(canvas, Offset(center.dx - caption.width / 2, center.dy + 4));
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}

class _AnalyticsPeriodData {
  const _AnalyticsPeriodData({
    required this.totalCents,
    required this.trend,
    required this.spendingIncreased,
    required this.chartLabels,
    required this.chartValues,
    required this.defaultIndex,
    required this.bucketTotals,
    required this.bucketCategories,
    required this.categories,
  });

  final int totalCents;
  final String trend;
  final bool spendingIncreased;
  final List<String> chartLabels;
  final List<double> chartValues;
  final int defaultIndex;
  final List<int> bucketTotals;
  final List<List<_AnalyticsCategory>> bucketCategories;
  final List<_AnalyticsCategory> categories;
}

class _AnalyticsCategory {
  const _AnalyticsCategory(
    this.name,
    this.percent,
    this.color,
    this.amountCents,
  );

  final String name;
  final int percent;
  final Color color;
  final int amountCents;
}
