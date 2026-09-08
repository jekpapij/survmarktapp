import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_colors.dart';
import 'features/auth/domain/entities/user_entity.dart';
import 'features/auth/presentation/screens/change_password_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';
import 'features/researcher/presentation/screens/create_survey_screen.dart';
import 'features/researcher/presentation/screens/researcher_dashboard_screen.dart';
import 'features/researcher/presentation/screens/researcher_profile_edit_screen.dart';
import 'features/researcher/presentation/screens/researcher_profile_screen.dart';
import 'features/researcher/presentation/screens/researcher_wallet_screen.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

/// Route constants — SCREAMING_SNAKE_CASE per PROMPT_SPEC.md §2.3 (di sini
/// ditulis sebagai path string konstan, dipakai bareng go_router).
abstract class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';

  // Update 2026-09-08: "Ubah Password"/"Lupa Password" self-designed
  // (nggak ada frame Figma, lihat CLAUDE.md) — lintas-role kayak
  // `notifications` (bukan di-nest di bawah `/researcher/...`), karena
  // ubah password sama aja buat semua role.
  static const changePassword = '/account/change-password';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  // Update 2026-09-08: lintas-role (bukan spesifik researcher/respondent/
  // admin) — bell icon di app-bar tiap role bakal nunjuk ke sini juga
  // nantinya. Dibuka lewat `context.push` (bukan `go`) biar tombol back
  // natural balik ke dashboard asal.
  static const notifications = '/notifications';

  // Placeholder — dashboard beneran per role nyusul pas fitur
  // researcher/respondent/admin diimplementasi (di luar scope translate
  // auth ini).
  static const researcherHome = '/researcher/home';
  static const createSurvey = '/researcher/create-survey';
  static const researcherWallet = '/researcher/wallet';
  static const researcherProfile = '/researcher/profile';

  // Update 2026-09-08: bukan placeholder lagi — frame Figma
  // `researcher-profile-edit` (node 77:2654), lihat CLAUDE.md.
  static const researcherProfileEdit = '/researcher/profile/edit';
  static const respondentHome = '/respondent/home';
  static const adminHome = '/admin/home';

  static String homeForRole(UserRole role) => switch (role) {
        UserRole.peneliti => researcherHome,
        UserRole.responden => respondentHome,
        UserRole.admin => adminHome,
      };
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (context, state) => const RegisterScreen()),
      // Update 2026-09-08: "Ubah Password"/"Lupa Password" self-designed —
      // lihat CLAUDE.md.
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        // `extra` dari ForgotPasswordScreen (String identifier) — bukan
        // token/OTP beneran, lihat catatan di ResetPasswordScreen.
        builder: (context, state) => ResetPasswordScreen(identifier: state.extra as String? ?? ''),
      ),
      // Update 2026-09-08: bukan placeholder lagi — udah ditranslate dari
      // frame Figma `researcher-dashboard`, lihat CLAUDE.md.
      GoRoute(
        path: AppRoutes.researcherHome,
        builder: (context, state) => const ResearcherDashboardScreen(),
      ),
      // Update 2026-09-08: bukan placeholder lagi — udah ditranslate dari
      // frame Figma `create-survey`, lihat CLAUDE.md.
      GoRoute(
        path: AppRoutes.createSurvey,
        builder: (context, state) => const CreateSurveyScreen(),
      ),
      // Update 2026-09-08: bukan placeholder lagi — udah ditranslate dari
      // frame Figma `researcher-wallet`, lihat CLAUDE.md.
      GoRoute(
        path: AppRoutes.researcherWallet,
        builder: (context, state) => const ResearcherWalletScreen(),
      ),
      // Update 2026-09-08: bukan placeholder lagi — udah ditranslate dari
      // frame Figma `researcher-profile`, lihat CLAUDE.md.
      GoRoute(
        path: AppRoutes.researcherProfile,
        builder: (context, state) => const ResearcherProfileScreen(),
      ),
      // Update 2026-09-08: bukan placeholder lagi — udah ditranslate dari
      // frame Figma `researcher-profile-edit`, lihat CLAUDE.md.
      GoRoute(
        path: AppRoutes.researcherProfileEdit,
        builder: (context, state) => const ResearcherProfileEditScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.respondentHome,
        builder: (context, state) => const _PlaceholderHomeScreen(
          title: 'Discover',
          subtitle: 'Layar ini nyusul pas fitur Respondent diimplementasi (CPMK 3 lanjutan).',
        ),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (context, state) => const _PlaceholderHomeScreen(
          title: 'Dashboard Admin',
          subtitle: 'Layar ini nyusul pas fitur Admin diimplementasi (CPMK 3 lanjutan).',
        ),
      ),
    ],
  );
});

/// Stand-in sementara biar alur login end-to-end bisa dites (login berhasil
/// -> mendarat di sini), sampai dashboard beneran per role digarap.
class _PlaceholderHomeScreen extends StatelessWidget {
  const _PlaceholderHomeScreen({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_outlined, size: 48, color: AppColors.slate400),
              const SizedBox(height: 16),
              Text(subtitle, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Kembali ke Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
