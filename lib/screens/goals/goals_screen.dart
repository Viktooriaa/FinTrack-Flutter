import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../data/goal_store.dart';
import '../../data/transaction_store.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  static const _goalEmojis = ['🚗', '✈️', '🛡️', '💻', '🏠', '📱', '🎓', '🎯'];
  static const _goalColors = [
    Color(0xFF2563EB),
    Color(0xFFF97316),
    Color(0xFF059669),
    Color(0xFF7C3AED),
    Color(0xFF0F766E),
    Color(0xFFDB2777),
    Color(0xFF4F46E5),
    AppColors.primary,
  ];

  @override
  void initState() {
    super.initState();
    unawaited(GoalStore.instance.load());
  }

  Future<void> _showAddGoalSheet() async {
    final goal = await showModalBottomSheet<SavingsGoal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddGoalSheet(emojis: _goalEmojis),
    );
    if (goal != null) await GoalStore.instance.add(goal);
  }

  Future<void> _showGoalActions(SavingsGoal goal) async {
    final action = await showModalBottomSheet<_GoalAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalActionSheet(goal: goal),
    );
    if (!mounted || action == null) return;
    if (action == _GoalAction.contribute) {
      final amount = await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ContributionSheet(goal: goal),
      );
      if (amount != null) await GoalStore.instance.contribute(goal.id, amount);
    } else if (action == _GoalAction.delete) {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Видалити ціль?'),
          content: Text('«${goal.name}» буде видалено разом із її прогресом.'),
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
      if (shouldDelete == true) await GoalStore.instance.remove(goal.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: GoalStore.instance,
          builder: (context, _) {
            final goals = GoalStore.instance.goals;
            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: goals.isEmpty
                      ? _buildEmptyState()
                      : _buildGoalList(goals),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Мої цілі',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Material(
            color: const Color(0xFFDDF8E9),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _showAddGoalSheet,
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F3EB),
                borderRadius: BorderRadius.circular(28),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.flag_rounded,
                color: AppColors.primary,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Поки немає цілей',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Створи ціль і відстежуй, як накопичення наближають тебе до неї.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _showAddGoalSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Створити ціль'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalList(List<SavingsGoal> goals) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 28),
      children: [
        for (var index = 0; index < goals.length; index++) ...[
          _GoalCard(
            goal: goals[index],
            color: _goalColors[index % _goalColors.length],
            onTap: () => _showGoalActions(goals[index]),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        CustomPaint(
          painter: const _DashedGoalBorderPainter(),
          child: SizedBox(
            height: 54,
            child: TextButton.icon(
              onPressed: _showAddGoalSheet,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Додати нову ціль'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF42566B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
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

class _DashedGoalBorderPainter extends CustomPainter {
  const _DashedGoalBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(.5, .5, size.width - 1, size.height - 1),
          const Radius.circular(16),
        ),
      );
    final paint = Paint()
      ..color = const Color(0xFFCBD8E4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 10) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedGoalBorderPainter oldDelegate) => false;
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.color,
    required this.onTap,
  });

  final SavingsGoal goal;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetCents == 0
        ? 0.0
        : (goal.savedCents / goal.targetCents).clamp(0.0, 1.0);
    return Material(
      color: Colors.white,
      elevation: 1.2,
      shadowColor: const Color(0x25253A30),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      goal.emoji,
                      style: const TextStyle(fontSize: 25),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Ціль: ${_formatGoalMoney(goal.targetCents)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${goal.progressPercent}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF0F2F4),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Зібрано ${_formatGoalMoney(goal.savedCents)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      goal.isComplete
                          ? 'Досягнуто 🎉'
                          : 'Залишилось ${_formatGoalMoney(goal.remainingCents)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: goal.isComplete
                            ? AppColors.income
                            : AppColors.inactive,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _GoalAction { contribute, delete }

class _GoalActionSheet extends StatelessWidget {
  const _GoalActionSheet({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) => _SheetFrame(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(goal.emoji, style: const TextStyle(fontSize: 29)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                goal.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.background,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${_formatGoalMoney(goal.savedCents)} накопичено з ${_formatGoalMoney(goal.targetCents)}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 18),
        if (goal.isComplete)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7EC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.income,
                  size: 19,
                ),
                SizedBox(width: 8),
                Text(
                  'Ціль досягнута 🎉',
                  style: TextStyle(
                    color: AppColors.income,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context, _GoalAction.contribute),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Додати кошти до цілі'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context, _GoalAction.delete),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Видалити ціль'),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
          ),
        ),
      ],
    ),
  );
}

class _AddGoalSheet extends StatefulWidget {
  const _AddGoalSheet({required this.emojis});

  final List<String> emojis;

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  String _emoji = '🎯';
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final target = _parseMoneyCents(_targetController.text);
    if (name.isEmpty || target == null || target <= 0) {
      setState(() => _error = 'Вкажи назву цілі та суму більше нуля.');
      return;
    }
    Navigator.pop(
      context,
      SavingsGoal(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        emoji: _emoji,
        targetCents: target,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetTitle(
              title: 'Нова ціль',
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 18),
            const Text('Назва цілі', style: _FormLabel.style),
            const SizedBox(height: 7),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration('Наприклад, Новий ноутбук'),
            ),
            const SizedBox(height: 16),
            const Text('Сума цілі', style: _FormLabel.style),
            const SizedBox(height: 7),
            TextField(
              controller: _targetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              decoration: _inputDecoration('0,00 ₴'),
            ),
            const SizedBox(height: 16),
            const Text('Стікер', style: _FormLabel.style),
            const SizedBox(height: 9),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: widget.emojis.map((emoji) {
                final selected = emoji == _emoji;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _emoji = emoji),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFE1F4E9)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 1.4,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 23)),
                  ),
                );
              }).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.expense, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text('Створити ціль'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ContributionSheet extends StatefulWidget {
  const _ContributionSheet({required this.goal});

  final SavingsGoal goal;

  @override
  State<_ContributionSheet> createState() => _ContributionSheetState();
}

class _ContributionSheetState extends State<_ContributionSheet> {
  final _amountController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _add() {
    final amount = _parseMoneyCents(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Вкажи суму більше нуля.');
      return;
    }
    Navigator.pop(context, amount);
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetTitle(
              title: 'Додати до цілі',
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.goal.emoji}  ${widget.goal.name} · залишилось ${_formatGoalMoney(widget.goal.remainingCents)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              decoration: _inputDecoration('Сума, ₴'),
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
                onPressed: _add,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text('Додати суму'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

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
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
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

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      IconButton(
        onPressed: onClose,
        icon: const Icon(Icons.close_rounded, size: 20),
        style: IconButton.styleFrom(backgroundColor: AppColors.background),
      ),
    ],
  );
}

class _FormLabel {
  static const style = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: AppColors.background,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE9EEEB)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
  ),
);

int? _parseMoneyCents(String raw) {
  final value = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (value.isEmpty || '.'.allMatches(value).length > 1) return null;
  final parts = value.split('.');
  final whole = int.tryParse(parts.first);
  if (whole == null) return null;
  final fraction = parts.length == 1 ? '' : parts[1];
  if (fraction.length > 2 || (parts.length > 1 && fraction.isEmpty)) {
    return null;
  }
  final cents = fraction.isEmpty ? 0 : int.parse(fraction.padRight(2, '0'));
  return whole * 100 + cents;
}

String _formatGoalMoney(int cents) =>
    '${formatMoneyCents(cents, groupSeparator: ' ', decimalSeparator: ',', showDecimals: cents % 100 != 0)} ₴';
