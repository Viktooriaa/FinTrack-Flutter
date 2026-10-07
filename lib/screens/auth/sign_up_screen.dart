import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  bool _agreeTerms = false;
  bool _receiveTips = false;
  bool _obscurePassword = true;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // =========================
                // BACK BUTTON
                // =========================

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(-20, 0),
                      child: IconButton(
                        onPressed: () {
                          context.go('/login');
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 24,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(width: 28),

                    Expanded(
                      child: Transform.translate(
                        offset: const Offset(-40, 0),
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
                  text: 'Зареєструватися',
                  onPressed: () {
                    // Тут пізніше буде API реєстрації
                  },
                ),

                // =========================
                // BOTTOM LOGIN
                // =========================

                SizedBox(
                  height: 250,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Вже є акаунт? ',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.go('/login');
                            },
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    Widget? suffixIcon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1,
            ),
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
            side: const BorderSide(
              color: AppColors.border,
            ),
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