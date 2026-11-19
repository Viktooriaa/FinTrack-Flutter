import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CategoryBudget {
  const CategoryBudget({required this.category, required this.limitCents});

  final String category;
  final int limitCents;

  Map<String, Object> toJson() => {
    'category': category,
    'limitCents': limitCents,
  };

  factory CategoryBudget.fromJson(Map<String, dynamic> json) => CategoryBudget(
    category: json['category'] as String,
    limitCents: json['limitCents'] as int,
  );
}

class BudgetStore extends ChangeNotifier {
  BudgetStore._();

  static final BudgetStore instance = BudgetStore._();
  static const _storageKey = 'fintrack.budgets.v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final List<CategoryBudget> _budgets = [];
  bool _loaded = false;
  Future<void>? _loading;
  Future<void> _pendingSave = Future<void>.value();

  List<CategoryBudget> get budgets => List.unmodifiable(_budgets);

  int get totalLimitCents =>
      _budgets.fold(0, (total, budget) => total + budget.limitCents);

  Future<void> load() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved != null) {
        final decoded = jsonDecode(saved) as List<dynamic>;
        _budgets
          ..clear()
          ..addAll(
            decoded.map(
              (item) => CategoryBudget.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );
      }
    } catch (_) {
      _budgets.clear();
    } finally {
      _loaded = true;
      _loading = null;
      notifyListeners();
    }
  }

  Future<void> upsert(CategoryBudget budget) async {
    if (!_loaded) await load();
    final index = _budgets.indexWhere(
      (item) => item.category.toLowerCase() == budget.category.toLowerCase(),
    );
    if (index == -1) {
      _budgets.add(budget);
    } else {
      _budgets[index] = budget;
    }
    _budgets.sort((left, right) => left.category.compareTo(right.category));
    notifyListeners();
    await _save();
  }

  Future<void> remove(String category) async {
    if (!_loaded) await load();
    _budgets.removeWhere(
      (item) => item.category.toLowerCase() == category.toLowerCase(),
    );
    notifyListeners();
    await _save();
  }

  Future<void> _save() {
    final snapshot = jsonEncode(
      _budgets.map((budget) => budget.toJson()).toList(),
    );
    _pendingSave = _pendingSave.then((_) async {
      try {
        await _storage.write(key: _storageKey, value: snapshot);
      } catch (_) {
        // Keep budgets available for the current app session.
      }
    });
    return _pendingSave;
  }
}
