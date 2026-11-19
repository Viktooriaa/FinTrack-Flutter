import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/budget_store.dart';
import '../../data/transaction_store.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    await Future.wait([
      TransactionStore.instance.load(),
      BudgetStore.instance.load(),
    ]);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _messages
        ..clear()
        ..add(_ChatMessage(text: _initialInsight(), isUser: false));
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? suggestion]) {
    if (_isLoading) return;
    final question = (suggestion ?? _messageController.text).trim();
    if (question.isEmpty) return;
    _messageController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _messages
        ..add(_ChatMessage(text: question, isUser: true))
        ..add(_ChatMessage(text: _answer(question), isUser: false));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    resizeToAvoidBottomInset: true,
    body: SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                    itemCount:
                        _messages.length + (_messages.length == 1 ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_messages.length == 1 && index == 1) {
                        return _buildSuggestions();
                      }
                      return _ChatBubble(message: _messages[index]);
                    },
                  ),
          ),
          _buildComposer(),
        ],
      ),
    ),
  );

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.fromLTRB(12, 5, 18, 12),
    decoration: const BoxDecoration(
      color: AppColors.background,
      border: Border(bottom: BorderSide(color: Color(0xFFE9EDEC))),
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          visualDensity: VisualDensity.compact,
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FinAI Помічник',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.circle, color: AppColors.income, size: 7),
                  SizedBox(width: 5),
                  Text(
                    'Аналізує твої дані',
                    style: TextStyle(
                      color: AppColors.income,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildSuggestions() => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SuggestionChip(
          label: 'Підсумок місяця',
          onTap: () => _send('Покажи підсумок місяця'),
        ),
        _SuggestionChip(
          label: 'Найбільші витрати',
          onTap: () => _send('Яка категорія витрат найбільша?'),
        ),
      ],
    ),
  );

  Widget _buildComposer() => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE9EDEC))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Запитати FinAI...',
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: const Color(0xFFF1F3F5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _isLoading ? null : _send,
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.send_rounded, color: Colors.white, size: 19),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  String _initialInsight() {
    final transactions = _currentMonthTransactions();
    if (transactions.isEmpty) {
      return 'Привіт! Я FinAI Помічник. Додай кілька операцій, і я зможу підсумувати витрати та знайти найбільші категорії.';
    }
    final expenses = transactions.where((item) => !item.isIncome).toList();
    final total = expenses.fold<int>(0, (sum, item) => sum + item.amountCents);
    if (expenses.isEmpty) {
      return 'Привіт! За цей місяць у тебе поки є доходи, але ще немає витрат. Коли вони з’являться, я допоможу розібрати їх за категоріями.';
    }
    final byCategory = _expenseTotals(expenses);
    final top = byCategory.entries.reduce(
      (left, right) => left.value >= right.value ? left : right,
    );
    final percent = (top.value * 100 / total).round();
    return 'Привіт! За цей місяць витратили ${_money(total)}. Найбільше пішло на «${top.key}» — ${_money(top.value)} ($percent%). Запитай, якщо хочеш побачити інший підсумок.';
  }

  String _answer(String question) {
    final normalized = question.toLowerCase();
    final transactions = _currentMonthTransactions();
    final expenses = transactions.where((item) => !item.isIncome).toList();
    final incomes = transactions.where((item) => item.isIncome).toList();
    final expenseTotal = expenses.fold<int>(
      0,
      (sum, item) => sum + item.amountCents,
    );
    final incomeTotal = incomes.fold<int>(
      0,
      (sum, item) => sum + item.amountCents,
    );
    if (transactions.isEmpty) {
      return 'Поки немає операцій за цей місяць. Додай дохід або витрату — і я зможу зробити точний підсумок.';
    }
    if (normalized.contains('дох')) {
      return 'Доходи за цей місяць: ${_money(incomeTotal)}.';
    }
    if (normalized.contains('бюджет') || normalized.contains('ліміт')) {
      final budgets = BudgetStore.instance.budgets;
      if (budgets.isEmpty) {
        return 'Ти ще не встановив бюджетні ліміти. Створи їх у розділі «Бюджет», і я допоможу оцінити витрати відносно плану.';
      }
      final spentByCategory = _expenseTotals(expenses);
      final exceeded = budgets.where(
        (budget) => (spentByCategory[budget.category] ?? 0) > budget.limitCents,
      );
      if (exceeded.isEmpty) {
        return 'За поточними лімітами перевищень немає. Витрати за місяць — ${_money(expenseTotal)}.';
      }
      final first = exceeded.first;
      final overBy = (spentByCategory[first.category] ?? 0) - first.limitCents;
      return 'Ліміт перевищено в категорії «${first.category}» на ${_money(overBy)}. Загальні витрати за місяць — ${_money(expenseTotal)}.';
    }
    if (normalized.contains('катег') ||
        normalized.contains('більш') ||
        normalized.contains('витрат')) {
      if (expenses.isEmpty) return 'За цей місяць витрат поки немає.';
      final byCategory = _expenseTotals(expenses);
      final top = byCategory.entries.reduce(
        (left, right) => left.value >= right.value ? left : right,
      );
      final percent = expenseTotal == 0
          ? 0
          : (top.value * 100 / expenseTotal).round();
      return 'Найбільша категорія — «${top.key}»: ${_money(top.value)}, це $percent% витрат. Усього витратили ${_money(expenseTotal)}.';
    }
    return 'За цей місяць: доходи ${_money(incomeTotal)}, витрати ${_money(expenseTotal)}. Можеш запитати про найбільші витрати, бюджет або доходи.';
  }

  List<TransactionRecord> _currentMonthTransactions() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final end = DateTime(now.year, now.month + 1);
    return TransactionStore.instance.transactions
        .where((item) => !item.date.isBefore(start) && item.date.isBefore(end))
        .toList();
  }

  Map<String, int> _expenseTotals(List<TransactionRecord> expenses) {
    final totals = <String, int>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amountCents,
        ifAbsent: () => expense.amountCents,
      );
    }
    return totals;
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) => Align(
    alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .78,
      ),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: message.isUser ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(message.isUser ? 16 : 5),
          bottomRight: Radius.circular(message.isUser ? 5 : 16),
        ),
        boxShadow: message.isUser
            ? null
            : const [
                BoxShadow(
                  color: Color(0x08253A30),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: message.isUser ? Colors.white : AppColors.textPrimary,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    ),
  );
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(label),
    onPressed: onTap,
    labelStyle: const TextStyle(
      color: AppColors.primary,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
    side: const BorderSide(color: Color(0xFFD5E2DA)),
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    visualDensity: VisualDensity.compact,
  );
}

String _money(int cents) =>
    '${formatMoneyCents(cents, groupSeparator: ' ', decimalSeparator: ',', showDecimals: cents % 100 != 0)} ₴';
