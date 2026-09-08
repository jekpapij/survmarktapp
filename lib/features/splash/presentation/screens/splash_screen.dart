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
    // Update 2026-09-07: visual diganti nyamain persis frame Figma
    // `splash-screen` (get_design_context, node 2:3) — exchange-visual
    // MiniCard versi awal CPMK 1 udah nggak ada di desain final, diganti
    // logo besar + tagline + badge partner. Logic auto-login di atas
    // (initState/_checkSession) TIDAK disentuh.
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary900, Color(0xFF0A0A1B)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/survmarkt_logo.png', width: 140),
                    const SizedBox(height: 24),
                    Text(
                      'SurvMarkt',
                      textAlign: TextAlign.center,
                      style: AppTypography.displayLarge.copyWith(
                        color: const Color(0xFFEEF2FF),
                        fontSize: 32,
                        letterSpacing: 1.28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Marketplace Responden Penelitian',
                      textAlign: TextAlign.center,
                      style: AppTypography.monoSmall.copyWith(
                        color: const Color(0xFFA5B4FC),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const CircularProgressIndicator(
                      color: AppColors.amber500,
                      strokeWidth: 2,
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  // Update 2026-09-08: fix overflow — sebelumnya Row badge
                  // `mainAxisSize.min` + teksnya nggak dibungkus Flexible,
                  // jadi "QUALITY EDUCATION COMMUNITY PARTNER" overflow ke
                  // kanan di HP fisik user (lebar layar lebih sempit dari
                  // yang keukur pas dev, kelihatan dari screenshot RenderFlex
                  // overflow stripe kuning-hitam). Fix: Column footer
                  // di-stretch penuh biar Container badge punya lebar
                  // pasti (nggak cuma sebesar konten), teksnya dibungkus
                  // Flexible + softWrap biar jatuh ke baris ke-2 kalau
                  // beneran nggak muat, bukan overflow horizontal.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_outlined, size: 14, color: AppColors.amber500),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'QUALITY EDUCATION COMMUNITY PARTNER',
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: AppTypography.eyebrowMuted.copyWith(
                                color: AppColors.amber500,
                                fontSize: 11,
                                fontFamily: 'Lora',
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SurvMarkt Initiative © 2026',
                      style: AppTypography.monoSmall.copyWith(
                        color: const Color(0xFF818CF8).withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
