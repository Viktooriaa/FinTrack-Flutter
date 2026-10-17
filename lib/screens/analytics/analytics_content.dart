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
          _buildSpendingCard(period, selectedIndex),
          const SizedBox(height: 14),
          _buildCategoryCard(period),
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
          (index) => '${(index * daysInMonth ~/ 7) + 1}',
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
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    const colors = [
      Color(0xFFFF6B16),
      Color(0xFF4E82A8),
      Color(0xFF9C4EF0),
      Color(0xFFF0444D),
      Color(0xFF20B88A),
      Color(0xFFA4ACB7),
    ];
    final categories = [
      for (var index = 0; index < sortedCategories.length; index++)
        _AnalyticsCategory(
          sortedCategories[index].key,
          totalCents == 0
              ? 0
              : (sortedCategories[index].value * 100 / totalCents).round(),
          colors[index % colors.length],
        ),
    ];
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
      categories: categories,
    );
  }

  Widget _buildSpendingCard(
    _AnalyticsPeriodData period,
    int selectedChartIndex,
  ) {
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
                  color: period.spendingIncreased
                      ? const Color(0xFFFFEFF0)
                      : const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  period.trend,
                  style: TextStyle(
                    fontSize: 10,
                    color: period.spendingIncreased
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
            '₴ ${formatMoneyCents(period.totalCents, groupSeparator: ' ', decimalSeparator: ',')}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 148,
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
                  size: Size(constraints.maxWidth, 148),
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

  Widget _buildCategoryCard(_AnalyticsPeriodData period) {
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
          Row(
            children: [
              const SizedBox(width: 8),
              SizedBox(
                width: 124,
                height: 124,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    categories: period.categories,
                    totalLabel:
                        '₴${formatMoneyCents(period.totalCents, groupSeparator: ' ', decimalSeparator: ',')}',
                  ),
                ),
              ),
              const SizedBox(width: 34),
              Expanded(
                child: Column(
                  children: [
                    if (period.categories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Ще немає витрат',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      for (final category in period.categories)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
                ),
              ),
            ],
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
    final baseY = chartHeight - 2;

    for (int i = 0; i < values.length; i++) {
      final height = values[i] * (chartHeight - 13);
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

    for (final category in categories) {
      final sweep = math.pi * 2 * category.percent / 100 - gap;
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
    required this.categories,
  });

  final int totalCents;
  final String trend;
  final bool spendingIncreased;
  final List<String> chartLabels;
  final List<double> chartValues;
  final int defaultIndex;
  final List<_AnalyticsCategory> categories;
}

class _AnalyticsCategory {
  const _AnalyticsCategory(this.name, this.percent, this.color);

  final String name;
  final int percent;
  final Color color;
}
