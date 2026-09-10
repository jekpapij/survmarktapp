import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/survmarkt_button.dart';
import '../../../../core/widgets/survmarkt_text_field.dart';
import '../../../../router.dart';
import '../providers/auth_providers.dart';
import '../state/auth_state.dart';

/// Login Admin — frame Figma `admin-login` (get_design_context, node
/// `77:3299`, fileKey `sh3QGUb2P6BHPTIbtxXjOT`). Ditaruh di `features/auth/`
/// (bukan `features/admin/`) karena ini tetep bagian dari ALUR AUTH, sama
/// kayak `LoginScreen`/`RegisterScreen` — cuma beda tujuan role.
///
/// **Keputusan produk penting (konfirmasi user eksplisit, 2026-09-09):**
/// TIDAK ADA alur "Daftar sebagai Admin" — akun admin FULL DUMMY, kredensial
/// udah ke-PREFILL otomatis di 2 field di bawah, user tinggal tap "Masuk
/// sebagai Admin" tanpa perlu ngetik apa-apa. Ini konsisten sama
/// `UserEntity.role` doc-comment: "Admin (dibuat manual, bukan lewat
/// register-page)".
///
/// **Update/bugfix 2026-09-10:** awalnya `_submit()` reuse
/// `authNotifierProvider.notifier.login(identifier, password)` yang sama
/// kayak `LoginScreen`, mengandalkan `AuthRemoteDataSourceMock._dummyUserFor`
/// nebak role dari substring "admin" di identifier — TAPI begitu CPMK 5
/// nyalain `ApiConstants.useFirebaseBackend=true` (buat testing Auth+Wallet
/// Researcher/Respondent beneran), datasource yang aktif app-wide ganti ke
/// Firebase buat SEMUA layar login (termasuk ini), dan kredensial dummy
/// `admin@survmarkt.com`/`admin123` ditolak beneran sama Firebase Auth
/// (akun itu emang nggak pernah didaftarin di sana) — muncul error
/// "Email/No. HP atau password salah.". Fix: `_submit()` sekarang manggil
/// `loginAsDummyAdmin()` (method BARU di `AuthNotifier`, lihat doc-comment
/// lengkap di `AuthRepository.loginAsDummyAdmin`) yang SAMA SEKALI TIDAK
/// nyentuh remote datasource apapun — Admin tetap FULL DUMMY 1-tap terlepas
/// dari backend apa yang lagi aktif, sesuai keputusan produk 2026-09-09
/// (field identifier/password di bawah TETAP di-prefill & ditampilin, cuma
/// buat visual, isinya nggak lagi beneran dipakai/dikirim kemana-mana).
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(text: 'admin@survmarkt.com');
  final _passwordController = TextEditingController(text: 'admin123');

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // Bugfix 2026-09-10: BUKAN `login(identifier, password)` lagi — lihat
    // doc-comment class di atas. `loginAsDummyAdmin()` nggak butuh 2 field
    // ini sama sekali (dummy penuh, local-only), tapi form tetap divalidasi
    // & ditampilin biar UX-nya nggak berubah dari sebelumnya.
    final success = await ref.read(authNotifierProvider.notifier).loginAsDummyAdmin();
    if (!mounted || !success) return;
    final user = ref.read(authNotifierProvider).user;
    if (user != null) context.go(AppRoutes.homeForRole(user.role));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.danger),
        );
      }
    });

    return Scaffold(
      // Update: Figma `admin-login` background PUTIH — beda dari
      // `LoginScreen`/`RegisterScreen` yang pakai `AppColors.primary50`.
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/survmarkt_logo.png', width: 90),
                      const SizedBox(height: AppSpacing.md),
                      Text('SurvMarkt', style: AppTypography.displayMedium.copyWith(fontSize: 24)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary900,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Masuk untuk mengelola platform',
                        textAlign: TextAlign.center,
                        style: AppTypography.monoSmall.copyWith(fontSize: 13, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SurvMarktTextField(
                  label: 'ID Admin / Email',
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.person_outline,
                  validator: Validators.emailOrPhone,
                ),
                const SizedBox(height: AppSpacing.md),
                SurvMarktTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: Validators.password,
                ),
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.forgotPassword),
                    child: Text(
                      'Lupa Password?',
                      style: AppTypography.monoSmall.copyWith(
                        color: AppColors.primary600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Update: bukan bagian Figma, ditambahin biar eksplisit ke
                // user KENAPA 2 field di atas udah keisi — sesuai permintaan
                // "info credentialsnya udah ada (as dummy)".
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.primary100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kredensial dummy sudah terisi otomatis — tinggal tap "Masuk sebagai Admin".',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11.5, color: AppColors.slate600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SurvMarktButton(
                  label: 'Masuk sebagai Admin',
                  isLoading: authState.status == AuthStatus.loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTypography.bodyMedium,
                      children: [
                        const TextSpan(text: 'Butuh bantuan? Hubungi '),
                        TextSpan(
                          text: 'Tim Support',
                          style: AppTypography.labelSemibold.copyWith(color: AppColors.primary600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: TextButton(
                    onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.login),
                    child: const Text('Bukan Admin? Kembali ke Login', style: AppTypography.bodyMedium),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
