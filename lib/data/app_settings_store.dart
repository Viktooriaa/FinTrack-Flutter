import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppSettingsStore {
  AppSettingsStore._();

  static final AppSettingsStore instance = AppSettingsStore._();
  static const _darkThemeKey = 'fintrack.settings.darkTheme';
  static const _pushKey = 'fintrack.settings.pushNotifications';
  static const _biometricKey = 'fintrack.settings.biometrics';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool?> readDarkTheme() => _readBool(_darkThemeKey);
  Future<bool?> readPushNotifications() => _readBool(_pushKey);
  Future<bool?> readBiometrics() => _readBool(_biometricKey);

  Future<void> setDarkTheme(bool value) => _writeBool(_darkThemeKey, value);
  Future<void> setPushNotifications(bool value) => _writeBool(_pushKey, value);
  Future<void> setBiometrics(bool value) => _writeBool(_biometricKey, value);

  Future<bool?> _readBool(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value == null ? null : value == 'true';
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeBool(String key, bool value) async {
    try {
      await _storage.write(key: key, value: value.toString());
    } catch (_) {
      // Preferences remain active for the current screen if storage is unavailable.
    }
  }
}
