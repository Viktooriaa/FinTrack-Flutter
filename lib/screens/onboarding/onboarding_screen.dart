import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // =========================
              // HEADER
              // =========================
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/icons/logo_fintrack.png',
                        width: 38,
                        height: 38,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'FinTrack',
                        style: AppTextStyles.h3,
                      ),
                    ],
                  ),
                ),
              ),

              // Відступ до ілюстрації
              const SizedBox(height: 39),

              // =========================
              // ILLUSTRATION
              // =========================
              SizedBox(
                width: 260,
                height: 220,
                child: Image.asset(
                  'assets/images/onboarding_balance.png',
                  fit: BoxFit.contain,
                ),
              ),

              // Відступ від ілюстрації до тексту
              const SizedBox(height: 58),

              // =========================
              // TEXT CONTENT
              // =========================
              SizedBox(
                width: 339,
                child: Column(
                  children: [
                    Text(
                      'Контролюй свої\nфінанси легко',
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Автоматичний облік, аналітика та розумні поради\n'
                          'в одному застосунку.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Відступ до pagination
              const SizedBox(height: 48),

              // =========================
              // PAGINATION
              // =========================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 18,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 5),
                  _dot(),
                  const SizedBox(width: 5),
                  _dot(),
                  const SizedBox(width: 5),
                  _dot(),
                ],
              ),

              // Все вільне місце
              const Spacer(),

              // =========================
              // BUTTON
              // =========================
              PrimaryButton(
                text: 'Далі',
                onPressed: () {
                  // Наступний onboarding
                },
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot() {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: Color(0xFFD1D5DB),
        shape: BoxShape.circle,
      ),
    );
  }
}