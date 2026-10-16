import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AnalyticsContent extends StatefulWidget {
  const AnalyticsContent({super.key});

  @override
  State<AnalyticsContent> createState() => _AnalyticsContentState();
}

class _AnalyticsContentState extends State<AnalyticsContent>
    with AutomaticKeepAliveClientMixin<AnalyticsContent> {
  int _period = 1;

  @override
  bool get wantKeepAlive => true;

  static const _labels = [
    ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'],
    ['Січ', 'Лют', 'Бер', 'Кві', 'Тра', 'Чер', 'Лип', 'Сер', 'Вер'],
    ['2018', '2019', '2020', '2021', '2022', '2023', '2024', '2025', '2026'],
  ];

  static const _values = [
    [0.46, 0.62, 0.40, 0.70, 0.55, 0.85, 0.38],
    [0.42, 0.60, 0.48, 0.68, 0.54, 0.74, 0.62, 0.88, 0.40],
    [0.32, 0.44, 0.58, 0.48, 0.62, 0.54, 0.71, 0.80, 0.56],
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          const Text(
            'Аналітика',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          _PeriodTabs(
            selected: _period,
            onSelect: (value) => setState(() => _period = value),
          ),
          const SizedBox(height: 14),
          _buildSpendingCard(),
          const SizedBox(height: 14),
          _buildCategoryCard(),
        ],
      ),
    );
  }

  Widget _buildSpendingCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
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
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFF0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '↗ 5%',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.expense,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '₴ 7 420,00',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 134,
            width: double.infinity,
            child: CustomPaint(
              painter: _BarChartPainter(
                values: _values[_period],
                labels: _labels[_period],
                selectedIndex: _period == 0
                    ? 5
                    : _period == 1
                    ? 7
                    : 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    const categories = [
      _Category('Їжа', '28%', Color(0xFFFF6B16)),
      _Category('Транспорт', '15%', Color(0xFF4E82A8)),
      _Category('Покупки', '18%', Color(0xFF9C4EF0)),
      _Category('Комунальні', '12%', Color(0xFFF0444D)),
      _Category('Розваги', '10%', Color(0xFF20B88A)),
      _Category('Інше', '17%', Color(0xFFA4ACB7)),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 13, 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Витрати за категоріями',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const SizedBox(
                width: 132,
                height: 132,
                child: CustomPaint(painter: _DonutChartPainter()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    for (final category in categories)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
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
                                  fontSize: 9,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              category.percent,
                              style: const TextStyle(
                                fontSize: 9,
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
  borderRadius: BorderRadius.circular(18),
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
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 31,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == i ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
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
    final barWidth = math.min(18.0, size.width / (values.length * 1.75));
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
            fontSize: 8,
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
  const _DonutChartPainter();

  static const _segments = [
    (color: Color(0xFFFF6B16), value: 28.0),
    (color: Color(0xFF4E82A8), value: 15.0),
    (color: Color(0xFF9C4EF0), value: 18.0),
    (color: Color(0xFFF0444D), value: 12.0),
    (color: Color(0xFF20B88A), value: 10.0),
    (color: Color(0xFFA4ACB7), value: 17.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 3;
    const strokeWidth = 13.0;
    var startAngle = -math.pi / 2;
    const gap = 0.035;

    for (final segment in _segments) {
      final sweep = math.pi * 2 * segment.value / 100 - gap;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = segment.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep + gap;
    }

    final amount = TextPainter(
      text: const TextSpan(
        text: '₴7 420',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    amount.paint(canvas, Offset(center.dx - amount.width / 2, center.dy - 8));

    final caption = TextPainter(
      text: const TextSpan(
        text: 'Всього',
        style: TextStyle(fontSize: 8, color: AppColors.textSecondary),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    caption.paint(canvas, Offset(center.dx - caption.width / 2, center.dy + 4));
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => false;
}

class _Category {
  const _Category(this.name, this.percent, this.color);

  final String name;
  final String percent;
  final Color color;
}
