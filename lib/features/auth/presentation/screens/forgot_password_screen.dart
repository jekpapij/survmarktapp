import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/simple_app_bar.dart';
import '../../../../core/widgets/survmarkt_button.dart';
import '../../../../core/widgets/survmarkt_text_field.dart';
import '../../../../router.dart';
import '../providers/auth_providers.dart';

/// Langkah 1 dari alur "Lupa Password" — self-designed (nggak ada frame
/// Figma referensi), dibuka dari link "Lupa Password?" di `login_screen`.
///
/// Karena backend-nya emang mock semua (sama kayak login/register), alur
/// ini didemoin FUNGSIONAL end-to-end TANPA beneran ngirim email/OTP
/// (itu baru scope CPMK 5 kalau diintegrasi ke email service/backend
/// asli) — user isi identifier di sini, lanjut langsung ke
/// `ResetPasswordScreen` buat set password baru.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    final identifier = _identifierController.text.trim();
    final result = await ref.read(authRepositoryProvider).requestPasswordReset(identifier: identifier);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message), backgroundColor: AppColors.danger)),
      (_) => context.push(AppRoutes.resetPassword, extra: identifier),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: const SimpleAppBar(title: 'Lupa Password'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masukkan email atau nomor HP akun kamu. Kami bakal bantu kamu set password baru.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.slate600),
                ),
                const SizedBox(height: AppSpacing.lg),
                SurvMarktTextField(
                  label: 'Email atau No. HP',
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.person_outline,
                  validator: Validators.emailOrPhone,
                ),
                const SizedBox(height: AppSpacing.lg),
                SurvMarktButton(
                  label: 'Lanjutkan',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
