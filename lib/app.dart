import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_colors.dart';
import 'router.dart';

class SurvMarktApp extends ConsumerWidget {
  const SurvMarktApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SurvMarkt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary600,
          primary: AppColors.primary600,
          surface: AppColors.primary50,
        ),
        scaffoldBackgroundColor: AppColors.primary50,
        fontFamily: 'Inter',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary600,
          brightness: Brightness.dark,
          surface: AppColors.darkBg,
        ),
        scaffoldBackgroundColor: AppColors.darkBg,
        fontFamily: 'Inter',
      ),
      themeMode: ThemeMode.system, // Ikut sistem, konsisten dengan web
      routerConfig: router,
    );
  }
}
