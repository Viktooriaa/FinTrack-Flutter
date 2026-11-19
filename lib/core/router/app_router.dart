import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../screens/analytics/analytics_content.dart';
import '../../screens/assistant/assistant_screen.dart';
import '../../screens/auth/sign_up_screen.dart';
import '../../screens/auth/email_verification_screen.dart';
import '../../data/auth_service.dart';
import '../../screens/budget/budget_screen.dart';
import '../../screens/goals/goals_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/home/transaction_entry_sheet.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/receipt/receipt_scan_screen.dart';
import '../../screens/settings/security_pin_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/transactions/transactions_content.dart';
import '../../screens/wallets/wallets_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',

  routes: [
    // =========================
    // ROOT
    // =========================
    GoRoute(path: '/', redirect: (context, state) => '/splash'),

    // =========================
    // SPLASH
    // =========================
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),

    // =========================
    // ONBOARDING
    // =========================
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // =========================
    // LOGIN
    // =========================
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    GoRoute(
      path: '/sign-up',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) {
        final session = state.extra;
        return session is AuthSession
            ? EmailVerificationScreen(session: session)
            : const SignUpScreen();
      },
    ),

    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/transaction/new',
      builder: (context, state) => TransactionEntryScreen(
        isIncome: state.uri.queryParameters['type'] != 'expense',
      ),
    ),
    GoRoute(
      path: '/more',
      builder: (context, state) => const HomeScreen(initialPage: 3),
    ),
    GoRoute(
      path: '/transactions',
      builder: (context, state) => const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: TransactionsContent()),
      ),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: AnalyticsContent()),
      ),
    ),
    GoRoute(path: '/goals', builder: (context, state) => const GoalsScreen()),
    GoRoute(path: '/budget', builder: (context, state) => const BudgetScreen()),
    GoRoute(
      path: '/assistant',
      builder: (context, state) => const AssistantScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/wallets',
      builder: (context, state) => const WalletsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/security-pin',
      builder: (context, state) => const SecurityPinScreen(),
    ),
    GoRoute(
      path: '/receipt-scan',
      builder: (context, state) => const ReceiptScanScreen(),
    ),
  ],
);
