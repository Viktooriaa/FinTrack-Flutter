import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.targetCents,
    this.savedCents = 0,
  });

  final String id;
  final String name;
  final String emoji;
  final int targetCents;
  final int savedCents;

  int get remainingCents =>
      (targetCents - savedCents).clamp(0, targetCents).toInt();
  int get progressPercent => targetCents == 0
      ? 0
      : (savedCents * 100 / targetCents).round().clamp(0, 100).toInt();
  bool get isComplete => savedCents >= targetCents;

  SavingsGoal copyWith({int? savedCents}) => SavingsGoal(
    id: id,
    name: name,
    emoji: emoji,
    targetCents: targetCents,
    savedCents: savedCents ?? this.savedCents,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'targetCents': targetCents,
    'savedCents': savedCents,
  };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String? ?? '🎯',
    targetCents: json['targetCents'] as int,
    savedCents: json['savedCents'] as int? ?? 0,
  );
}

class GoalStore extends ChangeNotifier {
  GoalStore._();

  static final GoalStore instance = GoalStore._();
  static const _storageKey = 'fintrack.goals.v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final List<SavingsGoal> _goals = [];
  bool _loaded = false;
  Future<void>? _loading;
  Future<void> _pendingSave = Future<void>.value();

  List<SavingsGoal> get goals => List.unmodifiable(_goals);

  Future<void> load() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved != null) {
        final decoded = jsonDecode(saved) as List<dynamic>;
        _goals
          ..clear()
          ..addAll(
            decoded.map(
              (item) =>
                  SavingsGoal.fromJson(Map<String, dynamic>.from(item as Map)),
            ),
          );
      }
    } catch (_) {
      _goals.clear();
    } finally {
      _loaded = true;
      _loading = null;
      notifyListeners();
    }
  }

  Future<void> add(SavingsGoal goal) async {
    if (!_loaded) await load();
    _goals.insert(0, goal);
    notifyListeners();
    await _save();
  }

  Future<void> contribute(String id, int amountCents) async {
    if (!_loaded) await load();
    final index = _goals.indexWhere((goal) => goal.id == id);
    if (index == -1 || amountCents <= 0) return;
    final goal = _goals[index];
    _goals[index] = goal.copyWith(
      savedCents: (goal.savedCents + amountCents)
          .clamp(0, goal.targetCents)
          .toInt(),
    );
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    if (!_loaded) await load();
    _goals.removeWhere((goal) => goal.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> _save() {
    final snapshot = jsonEncode(_goals.map((goal) => goal.toJson()).toList());
    _pendingSave = _pendingSave.then((_) async {
      try {
        await _storage.write(key: _storageKey, value: snapshot);
      } catch (_) {
        // Keep goals available for the current app session.
      }
    });
    return _pendingSave;
  }
}
