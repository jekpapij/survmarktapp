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
import '../../domain/entities/user_entity.dart';
import '../providers/auth_providers.dart';
import '../state/auth_state.dart';

/// Login screen — satu widget buat dua state Figma (`login-page` &
/// `recurring-login-page`): headline & subcopy berubah otomatis kalau ada
/// identifier login terakhir tersimpan (returning user), field-nya pun
/// langsung ke-prefill.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.prefillIdentifier});

  /// Update 2026-09-09 (laporan user — abis register akun PENELITI baru
  /// "Budi", pas masuk profil nama-nya stay "Peneliti Dummy"): root cause-
  /// nya BUKAN bug di `AuthRemoteDataSourceMock` (login/register di situ
  /// role-agnostic, disamain persis buat semua role) — tapi field
  /// identifier di layar ini kepake ulang PREFILL dari `lastLoginIdentifier
  /// Provider` (identifier LOGIN SUKSES TERAKHIR, fitur "Selamat Datang
  /// Kembali"), yang kalau user abis register akun BARU tapi lupa nge-clear
  /// field itu sebelum tap "Masuk", bakal login ULANG ke akun LAMA yang
  /// keprefill situ — bukan ke akun baru yang baru aja didaftarin. Ini
  /// kejadian karena udah ada sesi peneliti dummy lama dari testing
  /// jauh-jauh hari sebelum sesi ini (makanya sisi Responden nggak kena —
  /// belum ada sesi respondent lama yang keprefill).
  ///
  /// Fix: `register_screen.dart` sekarang nge-`push` ke sini bawa email
  /// yang BARU AJA didaftarin lewat parameter ini — field identifier
  /// diprioritasin dari SINI (bukan `lastLoginIdentifierProvider`) kalau
  /// dikasih, jadi abis register field-nya otomatis keisi akun yang BENERAN
  /// baru didaftarin, bukan sesi lama yang nggak sengaja ke-reuse.
  final String? prefillIdentifier;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isGoogleSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefillIdentifier != null && widget.prefillIdentifier!.isNotEmpty) {
      // Datang dari Register — prioritaskan identifier yang BARU AJA
      // didaftarin, JANGAN timpa/dicampur sama `lastLoginIdentifierProvider`
      // (lihat catatan lengkap di `prefillIdentifier`).
      _identifierController.text = widget.prefillIdentifier!;
      return;
    }
    Future.microtask(() async {
      final last = await ref.read(lastLoginIdentifierProvider.future);
      if (mounted && last != null) {
        setState(() => _identifierController.text = last);
      }
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authNotifierProvider.notifier).login(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted || !success) return;
    final user = ref.read(authNotifierProvider).user;
    if (user != null) context.go(AppRoutes.homeForRole(user.role));
  }

  /// "Masuk dengan Google" — Google Sign-In BENERAN via Firebase, lewat
  /// pipeline `AuthNotifier`/`AuthRepositoryImpl` yang sama persis kayak
  /// `_submit()` di atas, jadi hasilnya juga ke-cache ke Secure Storage
  /// kayak login biasa. Lihat catatan lengkap di `FirebaseGoogleAuthService`.
  ///
  /// Update (pertanyaan user — "kok akun Google baru selalu Responden?"):
  /// akun yang UDAH terdaftar langsung "selesai" (state auto ke
  /// `authenticated`, `outcome` balik `null`). Akun BARU (`outcome` non-
  /// null) BELUM final — WAJIB nampilin `_GooglePickRoleDialog` dulu,
  /// tunggu user milih role, baru panggil
  /// `AuthNotifier.completeGoogleRegistration(...)`. Kalau user BATAL di
  /// dialog itu (nutup tanpa milih), nggak ada akun "nyangkut" setengah
  /// jadi di `_registeredUsers` (`AuthRemoteDataSourceMock`) — TAPI (bugfix
  /// laporan user) sesi Google/Firebase-nya SENDIRI tetap perlu di-
  /// `cancelGoogleSignIn()`, kalau nggak SDK Google Sign-In nge-cache akun
  /// yang tadi dipilih, bikin tap "Masuk dengan Google" berikutnya LANGSUNG
  /// ke dialog pilih role akun itu lagi tanpa nampilin pilihan akun Google.
  Future<void> _submitGoogle() async {
    setState(() => _isGoogleSubmitting = true);
    final outcome = await ref.read(authNotifierProvider.notifier).loginWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleSubmitting = false);

    if (outcome != null) {
      final role = await showDialog<UserRole>(
        context: context,
        builder: (context) => _GooglePickRoleDialog(name: outcome.name!),
      );
      if (!mounted) return;

      if (role == null) {
        // Bugfix (laporan user — abis Batal di sini, tap "Masuk dengan
        // Google" lagi malah LANGSUNG ke dialog pilih role akun yang tadi,
        // bukan balik nampilin pilihan akun Google): `signIn()` di atas
        // udah kepake buat mastiin akun, jadi SDK Google Sign-In nge-cache
        // akun itu — WAJIB di-`signOut()` lewat `cancelGoogleSignIn()`
        // biar tap berikutnya nampilin lagi dialog pilih akun. Nggak ada
        // akun "nyangkut" di `_registeredUsers` sama sekali di sini (itu
        // baru kebentuk di `completeGoogleRegistration`), jadi cukup clear
        // sesi Google/Firebase-nya doang, nggak perlu bersih-bersih lain.
        await ref.read(authNotifierProvider.notifier).cancelGoogleSignIn();
        return;
      }

      setState(() => _isGoogleSubmitting = true);
      final success = await ref.read(authNotifierProvider.notifier).completeGoogleRegistration(
            googleId: outcome.googleId!,
            email: outcome.email!,
            name: outcome.name!,
            role: role,
          );
      if (!mounted) return;
      setState(() => _isGoogleSubmitting = false);
      if (!success) return;
    }

    final user = ref.read(authNotifierProvider).user;
    if (user != null) context.go(AppRoutes.homeForRole(user.role));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final lastIdentifierAsync = ref.watch(lastLoginIdentifierProvider);
    final isReturningUser = lastIdentifierAsync.valueOrNull != null;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.danger),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary50,
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
                      Image.asset(
                        'assets/images/survmarkt_logo.png',
                        width: 90,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'SurvMarkt',
                        style: AppTypography.displayMedium.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isReturningUser ? 'Selamat Datang Kembali' : 'Selamat Datang',
                        style: AppTypography.displaySmall.copyWith(
                          color: AppColors.slate900,
                          fontWeight: FontWeight.w400,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isReturningUser
                            ? 'Masuk lagi buat lanjutin aktivitas kamu di SurvMarkt.'
                            : 'Masuk buat mulai cari survei atau kelola penelitianmu.',
                        textAlign: TextAlign.center,
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SurvMarktTextField(
                  label: 'Email atau No. HP',
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
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v ?? false),
                            activeColor: AppColors.primary600,
                            side: const BorderSide(color: AppColors.primary600, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Text('Ingat Saya', style: AppTypography.monoSmall),
                      ],
                    ),
                    GestureDetector(
                      // Update 2026-09-08: bukan stub lagi — beneran buka
                      // alur "Lupa Password" (self-designed, mock, lihat
                      // CLAUDE.md).
                      onTap: () => context.push(AppRoutes.forgotPassword),
                      child: Text(
                        'Lupa Password?',
                        style: AppTypography.monoSmall.copyWith(
                          color: AppColors.primary600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SurvMarktButton(
                  label: 'Masuk',
                  isLoading: authState.status == AuthStatus.loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.md),
                SurvMarktButton(
                  label: 'Masuk dengan Google',
                  variant: SurvMarktButtonVariant.outline,
                  isLoading: _isGoogleSubmitting,
                  onPressed: _isGoogleSubmitting ? null : _submitGoogle,
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: TextButton(
                    // Update 2026-09-09: bukan stub SnackBar lagi — beneran
                    // ngelink ke `admin-login` (frame Figma node 77:3299,
                    // fileKey sh3QGUb2P6BHPTIbtxXjOT). `push` (bukan `go`)
                    // biar tombol back di layar admin-login balik natural
                    // ke sini, pola sama kayak `forgotPassword`/`register`.
                    onPressed: () => context.push(AppRoutes.adminLogin),
                    child: const Text('Masuk Sebagai Admin', style: AppTypography.bodyMedium),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.register),
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.bodyMedium,
                        children: [
                          const TextSpan(text: 'Belum punya akun? '),
                          TextSpan(
                            text: 'Daftar Sekarang',
                            style: AppTypography.labelSemibold.copyWith(color: AppColors.primary600),
                          ),
                        ],
                      ),
                    ),
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

/// Dialog pilih role buat akun Google BARU (belum pernah kedaftar) —
/// self-designed (nggak ada frame Figma buat ini, sama pola kayak "Ubah
/// Password"/"Lupa Password"/"Tarik Dana"). Cuma 2 pilihan yang dikasih
/// (Peneliti/Responden) — Admin SENGAJA nggak ada di sini, alur Admin
/// tetap PERSIS lewat `AdminLoginScreen` (kredensial dummy fixed, bukan
/// Google Sign-In). Bisa di-dismiss (tap di luar / tombol Batal) tanpa
/// efek samping apapun — lihat catatan lengkap di `_submitGoogle`.
class _GooglePickRoleDialog extends StatelessWidget {
  const _GooglePickRoleDialog({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Daftar Sebagai?'),
      content: Text(
        'Halo $name! Akun Google ini belum pernah dipakai di SurvMarkt — mau daftar sebagai apa?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(UserRole.peneliti),
          child: const Text('Peneliti'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(UserRole.responden),
          child: const Text('Responden'),
        ),
      ],
    );
  }
}
