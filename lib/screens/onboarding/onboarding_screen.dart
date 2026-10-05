import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    const OnboardingData(
      image: 'assets/images/onboarding_balance.png',
      imageWidth: 260,
      imageHeight: 220,
      title: 'Контролюй свої\nфінанси легко',
      description:
      'Автоматичний облік, аналітика та розумні поради\n'
          'в одному застосунку.',
    ),

    const OnboardingData(
      image: 'assets/images/onboarding_transactions.png',
      imageWidth: 327,
      imageHeight: 280,
      title: 'Автоматичний\nімпорт транзакцій',
      description:
      'Підключи свої банки, Apple Pay або Google Pay,\n'
          'і ми самі підтягнемо твої витрати.',
    ),

    const OnboardingData(
      image: 'assets/images/onboarding_ai.png',
      imageWidth: 342,
      imageHeight: 260,
      title: 'ШІ аналізує\nтвої витрати',
      description:
      'Розумна категоризація, статистика та персональні\n'
          'рекомендації.',
    ),

    const OnboardingData(
      image: 'assets/images/onboarding_goals.png',
      imageWidth: 342,
      imageHeight: 260,
      title: 'Досягай\nсвоїх фінансових цілей',
      description:
      'Створюй цілі, відстежуй прогрес та\n'
          'рухайся до бажаного результату.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

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
                      const Text(
                        'FinTrack',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // =========================
              // ONBOARDING PAGES
              // =========================

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];

                    return Column(
                      children: [
                        // Відступ від Header
                        const SizedBox(height: 34),

                        // =========================
                        // ILLUSTRATION
                        // =========================

                        SizedBox(
                          width: page.imageWidth,
                          height: page.imageHeight,
                          child: Image.asset(
                            page.image,
                            fit: BoxFit.contain,
                          ),
                        ),

                        // Відступ до тексту
                        const SizedBox(height: 42),

                        // =========================
                        // TITLE
                        // =========================

                        SizedBox(
                          width: 339,
                          child: Text(
                            page.title,
                            style: AppTextStyles.h2,
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // =========================
                        // DESCRIPTION
                        // =========================

                        SizedBox(
                          width: 339,
                          child: Text(
                            page.description,
                            style: AppTextStyles.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // =========================
              // PAGINATION
              // =========================

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                      (index) {
                    final isActive = index == _currentPage;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 18 : 5,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 58),

              // =========================
              // BUTTON
              // =========================

              PrimaryButton(
                text: _currentPage == _pages.length - 1
                    ? 'Почати'
                    : 'Далі',
                onPressed: _nextPage,
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================
// ONBOARDING DATA
// =========================

class OnboardingData {
  final String image;
  final double imageWidth;
  final double imageHeight;
  final String title;
  final String description;

  const OnboardingData({
    required this.image,
    required this.imageWidth,
    required this.imageHeight,
    required this.title,
    required this.description,
  });
}