import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/simple_app_bar.dart';
import '../../../../core/widgets/survmarkt_button.dart';
import '../../../../core/widgets/survmarkt_dropdown_field.dart';
import '../../../../core/widgets/survmarkt_text_field.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

const _peranOptions = ['Dosen', 'Mahasiswa', 'Peneliti Independen', 'Staf Institusi'];

/// Layar "Edit Profil" — frame Figma `researcher-profile-edit` (get_design_
/// context, node 77:2654), dibuka dari pensil/menu "Edit Profil" di
/// `researcher-profile`.
///
/// **Interpretasi field "Peran" (deviasi/klarifikasi disadari):** field ini
/// di Figma cuma placeholder "Pilih peran" tanpa opsi eksplisit, ditaruh di
/// card "Afiliasi" bareng Institusi/Bidang Penelitian. Ini DIBACA sebagai
/// status akademik/profesional TAMBAHAN di dalam institusi (Dosen/
/// Mahasiswa/dst.) — BUKAN `UserRole` (peneliti/responden/admin) yang
/// nentuin dashboard & routing, yang emang nggak masuk akal diubah bebas
/// dari form ini. Disimpan sebagai `UserEntity.academicRole` (String bebas,
/// bukan enum) — lihat catatan lengkap di `user_entity.dart`.
///
/// State management: pola sama kayak `ChangePasswordScreen` — local
/// `_isSubmitting` + `AuthRepository.updateProfile(...)` dipanggil LANGSUNG
/// (bukan lewat UseCase baru), ditangani pakai `.fold(...)`. Bedanya di
/// sini: sukses juga manggil `AuthNotifier.updateUser(...)` biar
/// `researcher-profile` yang nge-`watch` `authNotifierProvider` otomatis
/// ke-rebuild nampilin data baru begitu balik ke situ.
class ResearcherProfileEditScreen extends ConsumerStatefulWidget {
  const ResearcherProfileEditScreen({super.key});

  @override
  ConsumerState<ResearcherProfileEditScreen> createState() => _ResearcherProfileEditScreenState();
}

class _ResearcherProfileEditScreenState extends ConsumerState<ResearcherProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _institutionController;
  late final TextEditingController _researchFieldController;
  String? _academicRole;
  bool _isSubmitting = false;

  UserEntity? get _user => ref.read(authNotifierProvider).user;

  @override
  void initState() {
    super.initState();
    final user = _user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _institutionController = TextEditingController(text: user?.institution ?? '');
    _researchFieldController = TextEditingController(text: user?.researchField ?? '');
    _academicRole = (user?.academicRole ?? '').isEmpty ? null : user!.academicRole;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _institutionController.dispose();
    _researchFieldController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_academicRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peran wajib dipilih.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await ref.read(authRepositoryProvider).updateProfile(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          institution: _institutionController.text.trim(),
          academicRole: _academicRole!,
          researchField: _researchFieldController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message), backgroundColor: AppColors.danger)),
      (updatedUser) {
        ref.read(authNotifierProvider.notifier).updateUser(updatedUser);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profil berhasil disimpan.')));
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: const SimpleAppBar(eyebrow: 'EDIT PROFIL', title: 'SurvMarkt'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _InfoBanner(),
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  eyebrow: 'IDENTITAS',
                  title: 'Data Diri',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SurvMarktTextField(
                        label: 'Nama Lengkap',
                        controller: _nameController,
                        isRequired: true,
                        hintText: 'Masukkan nama lengkap',
                        validator: Validators.name,
                      ),
                      const SizedBox(height: 14),
                      SurvMarktTextField(
                        label: 'Email',
                        controller: TextEditingController(text: email),
                        readOnly: true,
                      ),
                      const SizedBox(height: 14),
                      SurvMarktTextField(
                        label: 'Nomor HP',
                        controller: _phoneController,
                        isRequired: true,
                        keyboardType: TextInputType.phone,
                        hintText: 'Contoh: 08123456789',
                        validator: Validators.phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  eyebrow: 'INFORMASI INSTITUSI',
                  title: 'Afiliasi',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SurvMarktDropdownField(
                        label: 'Peran',
                        value: _academicRole,
                        options: _peranOptions,
                        hintText: 'Pilih peran',
                        isRequired: true,
                        onChanged: (v) => setState(() => _academicRole = v),
                      ),
                      const SizedBox(height: 14),
                      SurvMarktTextField(
                        label: 'Institusi / Universitas',
                        controller: _institutionController,
                        isRequired: true,
                        hintText: 'Nama institusi atau universitas',
                        validator: (v) => Validators.required(v, 'Institusi'),
                      ),
                      const SizedBox(height: 14),
                      SurvMarktTextField(
                        label: 'Bidang Penelitian / Jurusan',
                        controller: _researchFieldController,
                        hintText: 'Contoh: Ilmu Komunikasi',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SurvMarktButton(
                  label: 'Simpan Profil',
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        border: const Border(left: BorderSide(color: AppColors.indigoAccent, width: 3)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.indigoAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Profil & institusi yang lengkap meningkatkan kepercayaan responden terhadap survei kamu.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.slate600, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.eyebrow, required this.title, required this.child});

  final String eyebrow;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary100),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(color: AppColors.primary900.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            eyebrow,
            style: AppTypography.monoSmall.copyWith(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.indigoAccent),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.displaySmall.copyWith(color: AppColors.slate900, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
