import 'package:go_router/go_router.dart';

import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/splash/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',

  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
  ],
);