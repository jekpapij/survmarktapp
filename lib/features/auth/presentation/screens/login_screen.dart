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

/// Login screen — satu widget buat dua state Figma (`login-page` &
/// `recurring-login-page`): headline & subcopy berubah otomatis kalau ada
/// identifier login terakhir tersimpan (returning user), field-nya pun
/// langsung ke-prefill.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Login dengan Google belum tersedia.')),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Login admin akan diimplementasikan terpisah.')),
                      );
                    },
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
