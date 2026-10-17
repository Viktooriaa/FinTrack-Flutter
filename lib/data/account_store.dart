import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AccountRecord {
  const AccountRecord({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.balanceCents,
  });

  final String id;
  final String name;
  final String subtitle;
  final int balanceCents;

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'subtitle': subtitle,
    'balanceCents': balanceCents,
  };

  factory AccountRecord.fromJson(Map<String, dynamic> json) => AccountRecord(
    id: json['id'] as String,
    name: json['name'] as String,
    subtitle: json['subtitle'] as String,
    balanceCents: json['balanceCents'] as int,
  );
}

class AccountStore extends ChangeNotifier {
  AccountStore._();

  static final AccountStore instance = AccountStore._();
  static const _storageKey = 'fintrack.accounts.v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final List<AccountRecord> _accounts = [];
  bool _loaded = false;
  Future<void>? _loading;
  Future<void> _pendingSave = Future<void>.value();

  List<AccountRecord> get accounts => List.unmodifiable(_accounts);

  int get totalBalanceCents =>
      _accounts.fold<int>(0, (total, account) => total + account.balanceCents);

  Future<void> load() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved != null) {
        final decoded = jsonDecode(saved) as List<dynamic>;
        _accounts
          ..clear()
          ..addAll(
            decoded.map(
              (item) => AccountRecord.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );
      }
    } catch (_) {
      _accounts.clear();
    } finally {
      _loaded = true;
      _loading = null;
      notifyListeners();
    }
  }

  Future<void> add(AccountRecord account) async {
    if (!_loaded) await load();
    _accounts.add(account);
    notifyListeners();
    await _save();
  }

  Future<void> _save() {
    final snapshot = jsonEncode(
      _accounts.map((account) => account.toJson()).toList(),
    );
    _pendingSave = _pendingSave.then((_) async {
      try {
        await _storage.write(key: _storageKey, value: snapshot);
      } catch (_) {
        // Keep the account available for the current app session.
      }
    });
    return _pendingSave;
  }
}
