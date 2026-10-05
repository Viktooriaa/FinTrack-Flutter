import 'package:go_router/go_router.dart';

import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/splash/splash_screen.dart';
//import '../../screens/auth/login_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',

  routes: [
    // =========================
    // ROOT
    // =========================

    GoRoute(
      path: '/',
      redirect: (context, state) => '/splash',
    ),

    // =========================
    // SPLASH
    // =========================

    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

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

    //GoRoute(
    //path: '/login',
     // builder: (context, state) => const LoginScreen(),
    //),
  ],
);