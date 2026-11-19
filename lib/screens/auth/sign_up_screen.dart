import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/auth_service.dart';
import '../../widgets/primary_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _agreeTerms = false;
  bool _receiveTips = false;
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // =========================
                  // BACK BUTTON
                  // =========================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => context.go('/login'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          size: 24,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Створити акаунт',
                              style: AppTextStyles.h2.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              'Заповни дані для початку роботи',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // =========================
                  // NAME
                  // =========================
                  _buildLabel('Ім’я'),

                  const SizedBox(height: 6),

                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Ірина',
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? 'Введи ім’я' : null,
                  ),

                  const SizedBox(height: 18),

                  // =========================
                  // EMAIL
                  // =========================
                  _buildLabel('Email'),

                  const SizedBox(height: 6),

                  _buildTextField(
                    controller: _emailController,
                    hintText: 'iryna@gmail.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final email = (value ?? '').trim();
                      return RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(email)
                          ? null
                          : 'Введи коректний email';
                    },
                  ),

                  const SizedBox(height: 18),

                  // =========================
                  // PASSWORD
                  // =========================
                  _buildLabel('Пароль'),

                  const SizedBox(height: 6),

                  _buildTextField(
                    controller: _passwordController,
                    hintText: '••••••••',
                    obscureText: _obscurePassword,
                    validator: (value) => (value ?? '').length >= 8
                        ? null
                        : 'Пароль має містити щонайменше 8 символів',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.inactive,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // =========================
                  // TERMS CHECKBOX
                  // =========================
                  _buildCheckbox(
                    value: _agreeTerms,
                    text: 'Я погоджуюсь з Умовами використання',
                    onChanged: (value) {
                      setState(() {
                        _agreeTerms = value ?? false;
                      });
                    },
                  ),

                  const SizedBox(height: 6),

                  // =========================
                  // TIPS CHECKBOX
                  // =========================
                  _buildCheckbox(
                    value: _receiveTips,
                    text: 'Я хочу отримувати корисні фінансові поради',
                    onChanged: (value) {
                      setState(() {
                        _receiveTips = value ?? false;
                      });
                    },
                  ),

                  const SizedBox(height: 29),

                  // =========================
                  // SIGN UP BUTTON
                  // =========================
                  PrimaryButton(
                    text: _submitting ? 'Створюємо акаунт…' : 'Зареєструватися',
                    onPressed: _submitting ? null : _submit,
                  ),

                  // =========================
                  // BOTTOM LOGIN
                  // =========================
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Вже є акаунт? ',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Увійти',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Потрібно погодитися з умовами використання.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!AuthService.isConfigured) {
      _showMessage(
        'Email-підтвердження ще не налаштоване. Додайте Firebase API key — інструкція в docs/firebase_auth_setup.md.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final session = await AuthService.createAccount(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) context.go('/verify-email', extra: session);
    } on AuthException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // =========================
  // LABEL
  // =========================

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // =========================
  // TEXT FIELD
  // =========================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: validator,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: AppColors.background,
          errorStyle: const TextStyle(fontSize: 10, height: 1),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1),
          ),
        ),
      ),
    );
  }

  // =========================
  // CHECKBOX
  // =========================

  Widget _buildCheckbox({
    required bool value,
    required String text,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
