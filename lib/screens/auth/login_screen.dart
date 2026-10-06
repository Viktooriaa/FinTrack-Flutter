import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
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
              children: [
                const SizedBox(height: 35),

                // =========================
                // LOGO
                // =========================

                Image.asset(
                  'assets/icons/logo_fintrack.png',
                  width: 68,
                  height: 68,
                ),

                const SizedBox(height: 22),

                // =========================
                // TITLE
                // =========================

                Text(
                  'Вітаємо в FinTrack!',
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 18),

                Text(
                  'Увійдіть у свій акаунт',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 14.6,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // =========================
                // EMAIL
                // =========================

                _buildTextField(
                  controller: _emailController,
                  hintText: 'Email або телефон',
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                // =========================
                // PASSWORD
                // =========================

                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Пароль',
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

                // =========================
                // FORGOT PASSWORD
                // =========================

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Відновлення пароля
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(
                        top: 8,
                        bottom: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Забули пароль?',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // =========================
                // LOGIN
                // =========================

                PrimaryButton(
                  text: 'Увійти',
                  onPressed: () {
                    // Тут пізніше буде API авторизації
                  },
                ),

                const SizedBox(height: 24),

                // =========================
                // OR
                // =========================

                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppColors.border,
                        thickness: 1,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      child: Text(
                        'або',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ),

                    Expanded(
                      child: Divider(
                        color: AppColors.border,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                // Відступ до Apple / Google
                const SizedBox(height: 32),

                // =========================
                // APPLE
                // =========================

                _buildSocialButton(
                  iconPath: 'assets/icons/Apple.svg',
                  text: 'Продовжити з Apple',
                  onPressed: () {
                    // Apple авторизація
                  },
                ),

                const SizedBox(height: 8),

                // =========================
                // GOOGLE
                // =========================

                _buildSocialButton(
                  iconPath: 'assets/icons/Google.svg',
                  text: 'Продовжити з Google',
                  onPressed: () {
                    // Google авторизація
                  },
                ),

                const SizedBox(height: 14),

                // =========================
                // SIGN UP
                // =========================

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Немає акаунту? ',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 15,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.go('/sign-up');
                      },
                      child: Text(
                        'Зареєструватися',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 15,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
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
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w400,
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
  // SOCIAL BUTTON
  // =========================

  Widget _buildSocialButton({
    required String iconPath,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(
            color: AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 18,
              height: 18,
            ),

            const SizedBox(width: 10),

            Text(
              text,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}