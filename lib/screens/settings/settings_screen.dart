import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/app_settings_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkTheme = false;
  bool _pushNotifications = true;
  bool _biometrics = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final store = AppSettingsStore.instance;
    final values = await Future.wait([
      store.readDarkTheme(),
      store.readPushNotifications(),
      store.readBiometrics(),
    ]);
    if (!mounted) return;
    setState(() {
      _darkTheme = values[0] ?? false;
      _pushNotifications = values[1] ?? true;
      _biometrics = values[2] ?? true;
    });
  }

  Future<void> _setDarkTheme(bool value) async {
    setState(() => _darkTheme = value);
    await AppSettingsStore.instance.setDarkTheme(value);
  }

  Future<void> _setPush(bool value) async {
    setState(() => _pushNotifications = value);
    await AppSettingsStore.instance.setPushNotifications(value);
  }

  Future<void> _setBiometrics(bool value) async {
    setState(() => _biometrics = value);
    await AppSettingsStore.instance.setBiometrics(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 19,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'Налаштування',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _SettingsRow(
                      title: 'Темна тема',
                      value: _darkTheme,
                      onChanged: _setDarkTheme,
                    ),
                    const Divider(height: 1, thickness: 0.5),
                    _SettingsRow(
                      title: 'Push-сповіщення',
                      value: _pushNotifications,
                      onChanged: _setPush,
                    ),
                    const Divider(height: 1, thickness: 0.5),
                    _SettingsRow(
                      title: 'Face ID / Touch ID',
                      value: _biometrics,
                      onChanged: _setBiometrics,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.7,
            alignment: Alignment.centerRight,
            child: CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
