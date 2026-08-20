import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_typography.dart';

void main() {
  runApp(
    const ProviderScope(
      child: SurvMarktApp(),
    ),
  );
}

class SurvMarktApp extends StatelessWidget {
  const SurvMarktApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Exchange visual — dua kartu yang saling bertukar (signature SurvMarkt)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ignore: prefer_const_constructors
                _MiniCard(
                  eyebrow: 'PENELITI',
                  label: 'Setor dana',
                  borderColor: AppColors.primary600,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      const Icon(Icons.arrow_forward,
                          color: AppColors.primary100, size: 16),
                      const SizedBox(height: 4),
                      Text('match',
                          style: AppTypography.monoSmall
                              .copyWith(color: AppColors.primary100)),
                      const SizedBox(height: 4),
                      const Icon(Icons.arrow_back,
                          color: AppColors.amber500, size: 16),
                    ],
                  ),
                ),
                // ignore: prefer_const_constructors
                _MiniCard(
                  eyebrow: 'RESPONDEN',
                  label: 'Terima insentif',
                  borderColor: AppColors.amber500,
                  eyebrowColor: AppColors.amber500,
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Logo
            Text(
              'SurvMarkt',
              style: AppTypography.displayLarge.copyWith(
                color: Colors.white,
                fontSize: 36,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'MARKETPLACE RESPONDEN PENELITIAN',
              style: AppTypography.eyebrow.copyWith(
                color: AppColors.primary100,
              ),
            ),

            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppColors.amber500,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String eyebrow;
  final String label;
  final Color borderColor;
  final Color eyebrowColor;

  const _MiniCard({
    required this.eyebrow,
    required this.label,
    required this.borderColor,
    this.eyebrowColor = AppColors.primary100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow,
              style:
                  AppTypography.eyebrow.copyWith(color: eyebrowColor)),
          const SizedBox(height: 6),
          Text(label,
              style: AppTypography.displaySmall.copyWith(
                color: Colors.white,
                fontSize: 15,
              )),
        ],
      ),
    );
  }
}