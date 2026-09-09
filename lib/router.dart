import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/admin/presentation/screens/admin_audit_log_screen.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'features/admin/presentation/screens/admin_profile_screen.dart';
import 'features/admin/presentation/screens/admin_withdrawal_screen.dart';
import 'features/auth/domain/entities/user_entity.dart';
import 'features/auth/presentation/screens/admin_login_screen.dart';
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
import 'features/respondent/presentation/screens/respondent_activity_screen.dart';
import 'features/respondent/presentation/screens/respondent_discover_screen.dart';
import 'features/respondent/presentation/screens/respondent_edit_profile_screen.dart';
import 'features/respondent/presentation/screens/respondent_profile_screen.dart';
import 'features/respondent/presentation/screens/respondent_wallet_screen.dart';
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
  // auth ini). Update 2026-09-09: researcher & respondent bukan placeholder
  // lagi (lihat GoRoute masing-masing di bawah) — admin masih.
  static const researcherHome = '/researcher/home';
  static const createSurvey = '/researcher/create-survey';
  static const researcherWallet = '/researcher/wallet';
  static const researcherProfile = '/researcher/profile';

  // Update 2026-09-08: bukan placeholder lagi — frame Figma
  // `researcher-profile-edit` (node 77:2654), lihat CLAUDE.md.
  static const researcherProfileEdit = '/researcher/profile/edit';
  static const respondentHome = '/respondent/home';

  // Update 2026-09-09: bukan placeholder lagi — frame Figma
  // `respondent-profil` (node 89:4765), dibikin LOMPAT duluan (di luar
  // urutan standar) atas permintaan user biar bisa dites logout + ganti
  // role — lihat CLAUDE.md.
  static const respondentProfile = '/respondent/profile';

  // Update 2026-09-09: bukan placeholder lagi — frame Figma
  // `respondent-activity` (node 77:2902), lihat CLAUDE.md.
  static const respondentActivity = '/respondent/activity';

  // Update 2026-09-09: bukan placeholder lagi — frame Figma
  // `respondent-wallet` (node 77:3000), lihat CLAUDE.md.
  static const respondentWallet = '/respondent/wallet';

  // Update 2026-09-09: bukan placeholder lagi — frame Figma
  // `respondent-edit-profile` (node 77:3214), lihat CLAUDE.md.
  static const respondentEditProfile = '/respondent/profile/edit';
  static const adminHome = '/admin/home';

  // Update 2026-09-09: bukan placeholder lagi — 5 frame Figma `admin-*`
  // (login `77:3299`, dashboard `88:52`, withdrawal `86:52`, audit-log
  // `86:170`, profil `89:4492`) ditranslate sekaligus. `adminLogin` PUSH
  // dari `login_screen.dart` (bukan nested di bawah `/admin/...` yang
  // butuh session admin dulu) — pola sama kayak `register`/`forgotPassword`,
  // karena ini bagian dari ALUR AUTH, dijalanin SEBELUM ada session admin.
  static const adminLogin = '/admin/login';
  static const adminWithdrawal = '/admin/withdrawal';
  static const adminAuditLog = '/admin/audit-log';
  static const adminProfile = '/admin/profile';

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
      // Update 2026-09-09: `extra` opsional dari `register_screen.dart`
      // (email yang baru aja didaftarin) — lihat catatan lengkap di
      // `LoginScreen.prefillIdentifier`.
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginScreen(prefillIdentifier: state.extra as String?),
      ),
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
      // Update 2026-09-09: bukan placeholder lagi — udah ditranslate dari
      // frame Figma `respondent-discover` (node 77:2719), lihat CLAUDE.md.
      // 4 frame respondent lain (activity/wallet/edit-profile/profil)
      // masih menyusul, jadi tab lain di bottom-nav layar ini masih stub.
      GoRoute(
        path: AppRoutes.respondentHome,
        builder: (context, state) => const RespondentDiscoverScreen(),
      ),
      // Update 2026-09-09: bukan placeholder lagi — udah ditranslate dari
      // frame Figma `respondent-profil` (node 89:4765), lihat CLAUDE.md.
      GoRoute(
        path: AppRoutes.respondentProfile,
        builder: (context, state) => const RespondentProfileScreen(),
      ),
      // Update 2026-09-09: bukan placeholder lagi — udah ditranslate dari
      // frame Figma `respondent-activity` (node 77:2902), lihat CLAUDE.md.
      GoRoute(
        path: AppRoutes.respondentActivity,
        builder: (context, state) => const RespondentActivityScreen(),
      ),
      // Update 2026-09-09: bukan placeholder lagi — udah ditranslate dari
      // frame Figma `respondent-wallet` (node 77:3000), lihat CLAUDE.md.
      GoRoute(
        path: AppRoutes.respondentWallet,
        builder: (context, state) => const RespondentWalletScreen(),
      ),
      // Update 2026-09-09: bukan placeholder lagi — udah ditranslate dari
      // frame Figma `respondent-edit-profile` (node 77:3214), lihat
      // CLAUDE.md. SEMUA 5 frame respondent (16 frame MVP) SELESAI.
      GoRoute(
        path: AppRoutes.respondentEditProfile,
        builder: (context, state) => const RespondentEditProfileScreen(),
      ),
      // Update 2026-09-09: login Admin — dummy full, TANPA alur register
      // (lihat CLAUDE.md "Keputusan produk penting" & doc-comment
      // `AdminLoginScreen`).
      GoRoute(
        path: AppRoutes.adminLogin,
        builder: (context, state) => const AdminLoginScreen(),
      ),
      // Update 2026-09-09: bukan placeholder lagi — udah ditranslate dari
      // frame Figma `admin-dashboard` (node 88:52), lihat CLAUDE.md.
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminWithdrawal,
        builder: (context, state) => const AdminWithdrawalScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAuditLog,
        builder: (context, state) => const AdminAuditLogScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminProfile,
        builder: (context, state) => const AdminProfileScreen(),
      ),
    ],
  );
});
