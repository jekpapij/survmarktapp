import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/simple_app_bar.dart';
import '../../../../core/widgets/survmarkt_button.dart';
import '../../../../core/widgets/survmarkt_text_field.dart';
import '../providers/auth_providers.dart';

/// Layar "Ubah Password" — self-designed (nggak ada frame Figma referensi,
/// sama kayak fitur Notifikasi), dibuka dari menu "Ubah Password" di
/// `researcher-profile`. Buat user yang LAGI LOGIN (beda dari "Lupa
/// Password" yang buat sebelum login).
///
/// State management: pola sama kayak submit `create-survey`/"Kelola
/// Survey" — local `_isSubmitting` bool, manggil
/// `AuthRepository.changePassword(...)` langsung (bukan lewat UseCase baru,
/// konsisten sama pola mutation 1x-jalan di module researcher). Bedanya:
/// `AuthRepository` balikin `Either<Failure, void>` (bukan throw exception
/// mentah kayak `ResearcherRepository`) — ditangani pakai `.fold(...)`,
/// pola yang sama kayak `AuthNotifier.login`.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    final result = await ref.read(authRepositoryProvider).changePassword(
          oldPassword: _oldPasswordController.text,
          newPassword: _newPasswordController.text,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message), backgroundColor: AppColors.danger)),
      (_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Password berhasil diubah.')));
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: const SimpleAppBar(title: 'Ubah Password'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SurvMarktTextField(
                  label: 'Password Lama',
                  controller: _oldPasswordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: Validators.password,
                ),
                const SizedBox(height: AppSpacing.md),
                SurvMarktTextField(
                  label: 'Password Baru',
                  controller: _newPasswordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: Validators.password,
                ),
                const SizedBox(height: AppSpacing.md),
                SurvMarktTextField(
                  label: 'Konfirmasi Password Baru',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) => Validators.confirmPassword(v, _newPasswordController.text),
                ),
                const SizedBox(height: AppSpacing.lg),
                SurvMarktButton(
                  label: 'Simpan Password Baru',
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
