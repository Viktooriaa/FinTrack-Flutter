import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../data/account_store.dart';
import '../../data/transaction_store.dart';
import 'transaction_picker_sheets.dart';

Future<void> showTransactionEntrySheet(
  BuildContext context, {
  required bool isIncome,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (context) => TransactionEntryScreen(isIncome: isIncome),
    ),
  );
}

class TransactionEntryScreen extends StatefulWidget {
  const TransactionEntryScreen({super.key, required this.isIncome});

  final bool isIncome;

  @override
  State<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends State<TransactionEntryScreen> {
  static const _expenseCategories = [
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
  static const _incomeCategories = [
    ('Зарплата', '💰'),
    ('Фріланс', '💻'),
    ('Інвестиції', '📈'),
    ('Подарунок', '🎁'),
    ('Інше', '•••'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _amountController = TextEditingController.fromValue(
    const TextEditingValue(
      text: '0',
      selection: TextSelection.collapsed(offset: 1),
    ),
  );
  late bool _isIncome = widget.isIncome;
  late String _category = _categoriesFor(widget.isIncome).first.$1;
  late DateTime _date = DateTime.now();
  String? _accountId;
  String? _accountName;
  bool _accountChosen = false;
  bool _saving = false;

  static List<(String, String)> _categoriesFor(bool isIncome) =>
      isIncome ? _incomeCategories : _expenseCategories;

  @override
  void initState() {
    super.initState();
    _setDefaultAccount();
    unawaited(_loadAccounts());
  }

  Future<void> _loadAccounts() async {
    final store = AccountStore.instance;
    await store.load();
    if (!mounted || store.accounts.isEmpty || _accountChosen) return;
    final account = _preferredAccount(store.accounts);
    setState(() {
      _accountId = account.id;
      _accountName = account.name;
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final amount = _parseAmount(_amountController.text)!;
    setState(() => _saving = true);
    await TransactionStore.instance.add(
      TransactionRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _commentController.text.trim().isEmpty
            ? _category
            : _commentController.text.trim(),
        category: _category,
        amountCents: (amount * 100).round(),
        type: _isIncome ? TransactionType.income : TransactionType.expense,
        date: _date,
        accountId: _accountId,
        accountName: _accountName ?? 'Готівка',
        comment: _commentController.text.trim(),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _selectCategory() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showTransactionCategoryPicker(
      context,
      isIncome: _isIncome,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _isIncome = selected.isIncome;
      _category = selected.name;
      if (!_accountChosen) _setDefaultAccount();
    });
  }

  Future<void> _selectAccount() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final store = AccountStore.instance;
    await store.load();
    if (!mounted) return;
    final selected = await showTransactionAccountPicker(
      context,
      selectedId: _accountId,
      selectedName: _accountName,
    );
    if (selected != null && mounted) {
      setState(() {
        _accountId = selected.id;
        _accountName = selected.name;
        _accountChosen = true;
      });
    }
  }

  Future<void> _selectDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showTransactionDatePicker(
      context,
      selectedDate: _date,
    );
    if (selected != null && mounted) {
      setState(() {
        _date = DateTime(
          selected.year,
          selected.month,
          selected.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isIncome ? AppColors.income : AppColors.expense;
    final categoryEmoji = _categoriesFor(
      _isIncome,
    ).firstWhere((item) => item.$1 == _category).$2;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 14),
              _buildTopBar(accent),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTypeSelector(),
                      const SizedBox(height: 34),
                      Text(
                        'Сума',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: (MediaQuery.sizeOf(context).width * .58)
                                .clamp(150.0, 250.0)
                                .toDouble(),
                            child: TextFormField(
                              controller: _amountController,
                              textAlign: TextAlign.center,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) =>
                                  FocusManager.instance.primaryFocus?.unfocus(),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]'),
                                ),
                                const _AmountInputFormatter(),
                              ],
                              style: TextStyle(
                                color: accent,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                              cursorColor: accent,
                              showCursor: true,
                              decoration: const InputDecoration.collapsed(
                                hintText: '',
                              ),
                              validator: (value) {
                                final amount = _parseAmount(value);
                                if (amount == null || amount <= 0) {
                                  return 'Вкажи суму';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₴',
                            style: TextStyle(
                              color: accent,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _SelectionRow(
                        label: 'Категорія',
                        value: '$categoryEmoji  $_category',
                        onTap: _selectCategory,
                      ),
                      const SizedBox(height: 10),
                      _SelectionRow(
                        label: 'Рахунок',
                        value: _accountDisplayLabel,
                        onTap: _selectAccount,
                      ),
                      const SizedBox(height: 10),
                      _SelectionRow(
                        label: 'Дата',
                        value: transactionDateLabel(_date),
                        onTap: _selectDate,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Коментар',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextField(
                              controller: _commentController,
                              textCapitalization: TextCapitalization.sentences,
                              maxLines: 2,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: _isIncome
                                    ? 'Аванс за вересень...'
                                    : 'Покупки в Сільпо',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: _isIncome
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.only(top: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(Color accent) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Скасувати', style: TextStyle(fontSize: 13)),
          ),
          const Expanded(
            child: Text(
              'Нова операція',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            style: TextButton.styleFrom(
              foregroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Зберегти',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE7E9EC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          _TypeOption(
            label: 'Дохід',
            selected: _isIncome,
            color: AppColors.income,
            onTap: () => _setType(true),
          ),
          _TypeOption(
            label: 'Витрата',
            selected: !_isIncome,
            color: AppColors.expense,
            onTap: () => _setType(false),
          ),
        ],
      ),
    );
  }

  void _setType(bool isIncome) {
    if (_isIncome == isIncome) return;
    setState(() {
      _isIncome = isIncome;
      _category = _categoriesFor(isIncome).first.$1;
      if (!_accountChosen) _setDefaultAccount();
    });
  }

  void _setDefaultAccount() {
    _accountId = null;
    _accountName = _isIncome ? 'ПриватБанк' : 'monobank';
    final accounts = AccountStore.instance.accounts;
    if (accounts.isNotEmpty) {
      final account = _preferredAccount(accounts);
      _accountId = account.id;
      _accountName = account.name;
    }
  }

  AccountRecord _preferredAccount(List<AccountRecord> accounts) {
    final query = _isIncome ? 'приват' : 'mono';
    for (final account in accounts) {
      final name = '${account.name} ${account.subtitle}'.toLowerCase();
      if (name.contains(query)) return account;
    }
    return accounts.first;
  }

  String get _accountDisplayLabel {
    final normalized = (_accountName ?? '').toLowerCase();
    if (normalized.contains('mono')) return '🖤 monobank';
    if (normalized.contains('приват') || normalized.contains('privat')) {
      return '💳 ПриватБанк';
    }
    return _accountName ?? 'Готівка';
  }
}

double? _parseAmount(String? value) {
  final input = (value ?? '').replaceAll(' ', '').trim();
  if (input.isEmpty) return null;
  final usesThousandsCommas = RegExp(
    r'^\d{1,3}(,\d{3})+(\.\d+)?$',
  ).hasMatch(input);
  final normalized = usesThousandsCommas
      ? input.replaceAll(',', '')
      : input.replaceAll(',', '.');
  return double.tryParse(normalized);
}

class _AmountInputFormatter extends TextInputFormatter {
  const _AmountInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    if (raw.isEmpty) {
      return const TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
    }

    final commaParts = raw.split(',');
    final hasDot = raw.contains('.');
    final commaPartsAreGrouped =
        commaParts.length > 1 &&
        commaParts.first.replaceAll(RegExp(r'\D'), '').length <= 3 &&
        commaParts.skip(1).every((part) => part.length == 3);
    final commaContinuesGrouping =
        oldValue.text.contains(',') && raw.startsWith(oldValue.text) && !hasDot;
    final commaIsGrouping =
        !hasDot && (commaPartsAreGrouped || commaContinuesGrouping);
    final decimalSeparatorIndex = hasDot
        ? raw.indexOf('.')
        : commaIsGrouping
        ? -1
        : raw.indexOf(',');
    final integerSource = decimalSeparatorIndex >= 0
        ? raw.substring(0, decimalSeparatorIndex)
        : raw;
    final decimalSource = decimalSeparatorIndex >= 0
        ? raw.substring(decimalSeparatorIndex + 1)
        : '';
    var integerDigits = integerSource.replaceAll(RegExp(r'\D'), '');
    integerDigits = integerDigits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (integerDigits.isEmpty) integerDigits = '0';
    final allDecimalDigits = decimalSource.replaceAll(RegExp(r'\D'), '');
    final decimalDigits = allDecimalDigits.substring(
      0,
      allDecimalDigits.length.clamp(0, 2).toInt(),
    );
    final groupedInteger = integerDigits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final text = decimalSeparatorIndex >= 0
        ? '$groupedInteger.$decimalDigits'
        : groupedInteger;

    final rawOffset = newValue.selection.extentOffset
        .clamp(0, raw.length)
        .toInt();
    final prefix = raw.substring(0, rawOffset);
    final digitsBeforeCaret = prefix
        .replaceAll(RegExp(r'\D'), '')
        .length
        .clamp(0, text.replaceAll(RegExp(r'\D'), '').length)
        .toInt();
    final caretInFraction =
        decimalSeparatorIndex >= 0 &&
        prefix.contains(RegExp(r'[.,]')) &&
        (hasDot || !commaIsGrouping);
    int offset = 0;
    if (caretInFraction) {
      final pointIndex = text.indexOf('.');
      final fractionDigitsBeforeCaret = prefix
          .substring(prefix.lastIndexOf(RegExp(r'[.,]')) + 1)
          .replaceAll(RegExp(r'\D'), '')
          .length;
      offset = pointIndex + 1 + fractionDigitsBeforeCaret;
    } else if (digitsBeforeCaret > 0) {
      var digitsSeen = 0;
      for (var index = 0; index < text.length; index++) {
        if (RegExp(r'\d').hasMatch(text[index])) digitsSeen++;
        if (digitsSeen >= digitsBeforeCaret) {
          offset = index + 1;
          break;
        }
      }
    }
    offset = offset.clamp(0, text.length).toInt();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
      composing: TextRange.empty,
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF667085),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionRow extends StatelessWidget {
  const _SelectionRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: const Color(0x12000000),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 42,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF7B8494),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF98A2B3),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
