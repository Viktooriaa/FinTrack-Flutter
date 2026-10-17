import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum TransactionType { income, expense }

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.amountCents,
    required this.type,
    required this.date,
    this.accountId,
    this.accountName,
    this.comment = '',
  });

  final String id;
  final String title;
  final String category;
  final int amountCents;
  final TransactionType type;
  final DateTime date;
  final String? accountId;
  final String? accountName;
  final String comment;

  bool get isIncome => type == TransactionType.income;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'amountCents': amountCents,
    'type': type.name,
    'date': date.toIso8601String(),
    'accountId': accountId,
    'accountName': accountName,
    'comment': comment,
  };

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      amountCents: json['amountCents'] as int,
      type: TransactionType.values.byName(json['type'] as String),
      date: DateTime.parse(json['date'] as String),
      accountId: json['accountId'] as String?,
      accountName: json['accountName'] as String?,
      comment: json['comment'] as String? ?? '',
    );
  }
}

class TransactionStore extends ChangeNotifier {
  TransactionStore._();

  static final TransactionStore instance = TransactionStore._();
  static const _storageKey = 'fintrack.transactions.v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final List<TransactionRecord> _transactions = [];
  bool _loaded = false;
  Future<void>? _loading;
  Future<void> _pendingSave = Future<void>.value();

  List<TransactionRecord> get transactions => List.unmodifiable(_transactions);

  Future<void> load() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved != null) {
        final decoded = jsonDecode(saved) as List<dynamic>;
        _transactions
          ..clear()
          ..addAll(
            decoded.map(
              (item) => TransactionRecord.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );
      }
    } catch (_) {
      _transactions.clear();
    } finally {
      _loaded = true;
      _loading = null;
      notifyListeners();
    }
  }

  int sumBetween(
    DateTime start,
    DateTime end, {
    required TransactionType type,
  }) {
    return _transactions
        .where(
          (item) =>
              item.type == type &&
              !item.date.isBefore(start) &&
              item.date.isBefore(end),
        )
        .fold(0, (sum, item) => sum + item.amountCents);
  }

  Future<void> add(TransactionRecord transaction) async {
    if (!_loaded) await load();
    _transactions.insert(0, transaction);
    notifyListeners();
    await _save();
  }

  Future<void> _save() {
    final snapshot = jsonEncode(
      _transactions.map((item) => item.toJson()).toList(),
    );
    _pendingSave = _pendingSave.then((_) async {
      try {
        await _storage.write(key: _storageKey, value: snapshot);
      } catch (_) {
        // Keep the transaction available for the current app session.
      }
    });
    return _pendingSave;
  }
}

String formatMoneyCents(
  int cents, {
  String groupSeparator = ',',
  String decimalSeparator = '.',
  bool showDecimals = true,
}) {
  final absoluteCents = cents.abs();
  final digits = (absoluteCents ~/ 100).toString();
  final whole = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      whole.write(groupSeparator);
    }
    whole.write(digits[index]);
  }
  final sign = cents < 0 ? '−' : '';
  if (!showDecimals) return '$sign$whole';
  final decimal = (absoluteCents % 100).toString().padLeft(2, '0');
  return '$sign$whole$decimalSeparator$decimal';
}

String? transactionIconAsset(TransactionRecord transaction) {
  final value = transaction.category.toLowerCase();
  if (transaction.isIncome) {
    return transaction.title.toLowerCase().contains('зарплат')
        ? 'assets/icons/zarplata.svg'
        : 'assets/icons/income.svg';
  }
  if (value.contains('продукт')) return 'assets/icons/products.svg';
  if (value.contains('каф') ||
      value.contains('ресторан') ||
      value.contains('їж')) {
    return 'assets/icons/restaurant.svg';
  }
  if (value.contains('транспорт')) return 'assets/icons/transport.svg';
  if (value.contains('покуп')) return 'assets/icons/shopping.svg';
  if (value.contains('здоров') || value.contains('аптек')) {
    return 'assets/icons/pharmacy.svg';
  }
  if (value.contains('розваг')) return 'assets/icons/entertainment.svg';
  return null;
}

IconData transactionIcon(TransactionRecord transaction) {
  if (transaction.isIncome) return Icons.savings_rounded;
  final value = transaction.category.toLowerCase();
  if (value.contains('транспорт')) return Icons.directions_car_filled_rounded;
  if (value.contains('здоров') || value.contains('аптек')) {
    return Icons.medication_outlined;
  }
  if (value.contains('каф') || value.contains('ресторан')) {
    return Icons.coffee_rounded;
  }
  if (value.contains('покуп')) return Icons.shopping_bag_outlined;
  if (value.contains('розваг')) return Icons.movie_outlined;
  return Icons.shopping_cart_outlined;
}

Color transactionTint(TransactionRecord transaction) {
  if (transaction.isIncome) return const Color(0xFFD5F8E8);
  final value = transaction.category.toLowerCase();
  if (value.contains('транспорт')) return const Color(0xFFE5F0FF);
  if (value.contains('розваг')) return const Color(0xFFF2E9FF);
  if (value.contains('продукт')) return const Color(0xFFFFF3C4);
  return const Color(0xFFFFF0F2);
}

String transactionDateLabel(DateTime date, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final localDate = DateTime(date.year, date.month, date.day);
  final todayDate = DateTime(today.year, today.month, today.day);
  final difference = todayDate.difference(localDate).inDays;
  final month = _ukrainianMonths[date.month - 1];
  final formattedDate = '${date.day} $month';
  if (difference == 0) return 'Сьогодні, $formattedDate';
  if (difference == 1) return 'Вчора, $formattedDate';
  return formattedDate;
}

String transactionTimeLabel(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

const _ukrainianMonths = [
  'Січня',
  'Лютого',
  'Березня',
  'Квітня',
  'Травня',
  'Червня',
  'Липня',
  'Серпня',
  'Вересня',
  'Жовтня',
  'Листопада',
  'Грудня',
];
