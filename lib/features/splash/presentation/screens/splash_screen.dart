import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/state/auth_state.dart';

/// Splash screen — dipindah dari main.dart (implementasi CPMK 1) ke sini
/// sebagai bagian restrukturisasi Clean Architecture CPMK 3, plus tambahan:
/// cek sesi tersimpan (auto-login) dan badge SDG yang sebelumnya ada di
/// frame Figma `splash-screen` tapi belum ke-port.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  Future<void> _checkSession() async {
    // Delay dikit biar splash kerasa (bukan cuma flash sekilas), sambil
    // nunggu pengecekan sesi tersimpan di secure storage kelar.
    await Future.wait<void>([
      ref.read(authNotifierProvider.notifier).checkAuthStatus(),
      Future.delayed(const Duration(milliseconds: 1200)),
    ]);
    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    if (authState.status == AuthStatus.authenticated && authState.user != null) {
      context.go(AppRoutes.homeForRole(authState.user!.role));
    } else {
      context.go(AppRoutes.login);
    }
  }

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
                const _MiniCard(
                  eyebrow: 'PENELITI',
                  label: 'Setor dana',
                  borderColor: AppColors.primary600,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      const Icon(Icons.arrow_forward, color: AppColors.primary100, size: 16),
                      const SizedBox(height: 4),
                      Text('match', style: AppTypography.monoSmall.copyWith(color: AppColors.primary100)),
                      const SizedBox(height: 4),
                      const Icon(Icons.arrow_back, color: AppColors.amber500, size: 16),
                    ],
                  ),
                ),
                const _MiniCard(
                  eyebrow: 'RESPONDEN',
                  label: 'Terima insentif',
                  borderColor: AppColors.amber500,
                  eyebrowColor: AppColors.amber500,
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'SurvMarkt',
              style: AppTypography.displayLarge.copyWith(color: Colors.white, fontSize: 36),
            ),
            const SizedBox(height: 8),
            Text(
              'MARKETPLACE RESPONDEN PENELITIAN',
              style: AppTypography.eyebrow.copyWith(color: AppColors.primary100),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.amber500.withValues(alpha: 0.4)),
              ),
              child: Text(
                'SDG QUALITY EDUCATION PARTNER',
                style: AppTypography.eyebrowMuted.copyWith(color: AppColors.amber100, fontSize: 9),
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
  const _MiniCard({
    required this.eyebrow,
    required this.label,
    required this.borderColor,
    this.eyebrowColor = AppColors.primary100,
  });

  final String eyebrow;
  final String label;
  final Color borderColor;
  final Color eyebrowColor;

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
          Text(eyebrow, style: AppTypography.eyebrow.copyWith(color: eyebrowColor)),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.displaySmall.copyWith(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }
}
