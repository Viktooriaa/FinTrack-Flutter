import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/logo_fintrack.svg',
              width: 120,
              height: 120,
            ),

            const SizedBox(height: 24),

            Text(
              'FinTrack',
              style: AppTextStyles.h1.copyWith(
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

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
    );
  }
}