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
import '../widgets/role_select_field.dart';

/// Register screen — frame `register-page` di Figma. Sengaja cuma
/// nama/no.HP/email/password/role (data matching kaya umur/gender/status
/// BELUM ada di sini) — progressive profiling, lihat "Keputusan produk
/// penting" di CLAUDE.md.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole? _role;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState!.validate();
    if (_role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih peran (Peneliti/Responden) dulu ya.')),
      );
      return;
    }
    if (!isFormValid) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setujui syarat & ketentuan dulu ya.')),
      );
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).register(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _role!,
        );
    if (!mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Akun berhasil dibuat. Silakan masuk.')),
    );
    context.go(AppRoutes.login);
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
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        backgroundColor: AppColors.primary50,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary900),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SURVMARKT', style: AppTypography.eyebrow),
                const SizedBox(height: AppSpacing.xs),
                const Text('Buat Akun Baru', style: AppTypography.displayLarge),
                const SizedBox(height: AppSpacing.xl),
                SurvMarktTextField(
                  label: 'Nama Lengkap',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  validator: Validators.name,
                ),
                const SizedBox(height: AppSpacing.md),
                SurvMarktTextField(
                  label: 'No. HP',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: Validators.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                SurvMarktTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSpacing.md),
                SurvMarktTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: Validators.password,
                ),
                const SizedBox(height: AppSpacing.md),
                SurvMarktTextField(
                  label: 'Konfirmasi Password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) => Validators.confirmPassword(value, _passwordController.text),
                ),
                const SizedBox(height: AppSpacing.md),
                RoleSelectField(
                  value: _role,
                  onChanged: (role) => setState(() => _role = role),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      activeColor: AppColors.primary600,
                      onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Saya setuju dengan Syarat & Ketentuan serta Kebijakan Privasi SurvMarkt.',
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SurvMarktButton(
                  label: 'Daftar',
                  isLoading: authState.status == AuthStatus.loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: RichText(
                      text: TextSpan(
                        style: AppTypography.bodyMedium,
                        children: [
                          const TextSpan(text: 'Sudah punya akun? '),
                          TextSpan(
                            text: 'Masuk',
                            style: AppTypography.labelSemibold.copyWith(color: AppColors.primary600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
