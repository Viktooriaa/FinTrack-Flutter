import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _controller.addListener(() {
      final index = (_controller.value * 3).floor() % 3;

      if (index != _activeIndex) {
        setState(() {
          _activeIndex = index;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _loadingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
            (index) {
          final isActive = index == _activeIndex;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 20 : 4,
            height: 4,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icons/logo_fintrack.png',
                    width: 80,
                    height: 80,
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'FinTrack',
                    style: AppTextStyles.h1.copyWith(
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 11),

                  Text(
                    'Керуйте своїми фінансами легко',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 18,
              left: 0,
              right: 0,
              child: Center(
                child: _loadingIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}