import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const FinTrackApp());
}

class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'FinTrack',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}