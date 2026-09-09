import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/simple_app_bar.dart';
import '../../../../core/widgets/survmarkt_button.dart';
import '../../../../core/widgets/survmarkt_dropdown_field.dart';
import '../../../../core/widgets/survmarkt_text_field.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Self-designed (bukan dari Figma) — "Status" mengikuti 3 pilihan yang
/// udah didokumentasiin di CLAUDE.md "Keputusan produk penting" ("Status
/// responden ada 4 pilihan: Mahasiswa, Pekerja, Masyarakat Umum..." — Admin
/// eksplisit DIKECUALIKAN di situ, itu `UserRole` beda, bukan status).
const _statusOptions = ['Mahasiswa', 'Pekerja', 'Masyarakat Umum'];

/// Self-designed — Figma cuma nunjukin placeholder "Pilih pendidikan" tanpa
/// opsi eksplisit, jadi dipilih jenjang pendidikan formal Indonesia standar.
const _pendidikanOptions = [
  'SD', 'SMP', 'SMA/SMK', 'Diploma (D3)', 'Sarjana (S1)', 'Magister (S2)', 'Doktor (S3)',
];

/// Self-designed — Figma cuma nunjukin placeholder "Pilih kota" tanpa opsi
/// eksplisit. Dipilih kota-kota besar Indonesia + "Kota Lainnya" sebagai
/// fallback (biar responden di luar daftar ini tetep bisa lanjut, bukan
/// nge-block form).
const _kotaOptions = [
  'Jakarta', 'Bandung', 'Surabaya', 'Yogyakarta', 'Semarang', 'Malang', 'Medan', 'Makassar',
  'Palembang', 'Denpasar', 'Bekasi', 'Tangerang', 'Depok', 'Bogor', 'Batam', 'Balikpapan',
  'Pekanbaru', 'Padang', 'Manado', 'Banjarmasin', 'Kota Lainnya',
];

/// Layar "Edit Profil" sisi Responden — frame Figma `respondent-edit-
/// profile` (get_design_context, node `77:3214`, fileKey
/// `sh3QGUb2P6BHPTIbtxXjOT`), dibuka dari pensil header card atau menu
/// "Edit Profil" di `respondent-profil`.
///
/// Strukturnya nyontek pola `ResearcherProfileEditScreen` (state management:
/// local `_isSubmitting` + `AuthRepository.updateProfile(...)` dipanggil
/// LANGSUNG + `.fold(...)`, sukses juga manggil `AuthNotifier.updateUser`
/// biar `respondent-profil` yang nge-`watch` `authNotifierProvider`
/// otomatis ke-rebuild) — TAPI beda field total (data MATCHING responden,
/// bukan identitas/afiliasi institusi kayak Peneliti), makanya
/// `AuthRepository.updateProfile` diperluas jadi 1 method yang dipakai
/// bersama 2 role sekaligus, lihat catatan lengkap di `AuthRepository`.
///
/// **Field "Tanggal Lahir" -> `birthDate` (BUKAN `age`):** lihat catatan
/// lengkap di `UserEntity.birthDate`/`Formatters.ageLabelFromBirthDate` —
/// disimpen MENTAH sebagai tanggal (biar bisa di-prefill ulang tiap buka
/// form ini lagi), umur dihitung LIVE pas ditampilin di `respondent-
/// profil`, bukan disimpen dobel sebagai angka umur yang bisa basi.
///
/// **2 field baru (`education`/`fieldOfWork`) SENGAJA nggak muncul** di
/// card ringkasan "Data Responden" `respondent-profil` — pola sama kayak
/// `academicRole`/`researchField` sisi Peneliti yang juga nggak semuanya
/// keliatan di card ringkasan `researcher-profile`.
class RespondentEditProfileScreen extends ConsumerStatefulWidget {
  const RespondentEditProfileScreen({super.key});

  @override
  ConsumerState<RespondentEditProfileScreen> createState() => _RespondentEditProfileScreenState();
}

class _RespondentEditProfileScreenState extends ConsumerState<RespondentEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _fieldOfWorkController;
  String? _gender;
  DateTime? _birthDate;
  String? _domicile;
  String? _status;
  String? _education;
  bool _isSubmitting = false;

  UserEntity? get _user => ref.read(authNotifierProvider).user;

  @override
  void initState() {
    super.initState();
    final user = _user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _fieldOfWorkController = TextEditingController(text: user?.fieldOfWork ?? '');
    _gender = (user?.gender ?? '').isEmpty ? null : user!.gender;
    _domicile = (user?.domicile ?? '').isEmpty ? null : user!.domicile;
    _status = (user?.respondentStatus ?? '').isEmpty ? null : user!.respondentStatus;
    _education = (user?.education ?? '').isEmpty ? null : user!.education;
    _birthDate = DateTime.tryParse(user?.birthDate ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fieldOfWorkController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  String _isoDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final missing = <String>[
      if (_birthDate == null) 'Tanggal Lahir',
      if (_gender == null) 'Jenis Kelamin',
      if (_domicile == null) 'Domisili / Kota',
      if (_status == null) 'Status',
      if (_education == null) 'Pendidikan Terakhir',
    ];
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lengkapi dulu: ${missing.join(', ')}.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await ref.read(authRepositoryProvider).updateProfile(
          name: _nameController.text.trim(),
          phone: _user?.phone ?? '',
          gender: _gender!,
          birthDate: _isoDate(_birthDate!),
          respondentStatus: _status!,
          domicile: _domicile!,
          education: _education!,
          fieldOfWork: _fieldOfWorkController.text.trim(),
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
                  eyebrow: 'DATA DIRI',
                  title: 'Identitas',
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
                      _DateField(
                        label: 'Tanggal Lahir',
                        value: _birthDate,
                        onTap: _pickBirthDate,
                      ),
                      const SizedBox(height: 14),
                      _GenderSegmented(
                        value: _gender,
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                      const SizedBox(height: 14),
                      SurvMarktDropdownField(
                        label: 'Domisili / Kota',
                        value: _domicile,
                        options: _kotaOptions,
                        hintText: 'Pilih kota',
                        isRequired: true,
                        onChanged: (v) => setState(() => _domicile = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionCard(
                  eyebrow: 'LATAR BELAKANG',
                  title: 'Profil Responden',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SurvMarktDropdownField(
                        label: 'Status',
                        value: _status,
                        options: _statusOptions,
                        hintText: 'Pilih status',
                        isRequired: true,
                        onChanged: (v) => setState(() => _status = v),
                      ),
                      const SizedBox(height: 14),
                      SurvMarktDropdownField(
                        label: 'Pendidikan Terakhir',
                        value: _education,
                        options: _pendidikanOptions,
                        hintText: 'Pilih pendidikan',
                        isRequired: true,
                        onChanged: (v) => setState(() => _education = v),
                      ),
                      const SizedBox(height: 14),
                      SurvMarktTextField(
                        label: 'Bidang Pekerjaan / Jurusan',
                        controller: _fieldOfWorkController,
                        isRequired: true,
                        hintText: 'Contoh: Teknik Informatika',
                        validator: (v) => Validators.required(v, 'Bidang Pekerjaan / Jurusan'),
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
        border: const Border(left: BorderSide(color: AppColors.amber500, width: 3)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.amber500),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Data ini dipakai untuk mencocokkan kamu dengan survei yang relevan.',
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

/// Field "Tanggal Lahir" — visual shell NYAMAIN `SurvMarktTextField`
/// (border/radius/padding sama) tapi read-only + tap buka `showDatePicker`,
/// pola sama kayak field "Deadline" di `create-survey`.
class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.monoSmall.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate900),
            ),
            const SizedBox(width: 2),
            const Text('*', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary100),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? 'Pilih tanggal lahir' : Formatters.longDate(value!),
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 14,
                      color: value == null ? AppColors.slate400 : AppColors.slate900,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.slate400),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "Jenis Kelamin" — segmented control 2 opsi (persis Figma: pill container
/// border indigo-100, opsi aktif fill indigo600 teks putih bold). Nggak ada
/// widget shared yang cocok (`SurvMarktDropdownField` beda visual total),
/// jadi dibikin lokal di sini.
class _GenderSegmented extends StatelessWidget {
  const _GenderSegmented({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String> onChanged;

  static const _options = ['Laki-laki', 'Perempuan'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Jenis Kelamin',
              style: AppTypography.monoSmall.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate900),
            ),
            const SizedBox(width: 2),
            const Text('*', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.primary100),
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              for (final option in _options)
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(option),
                    child: Container(
                      height: double.infinity,
                      color: value == option ? AppColors.indigoAccent : Colors.white,
                      alignment: Alignment.center,
                      child: Text(
                        option,
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 13,
                          fontWeight: value == option ? FontWeight.bold : FontWeight.w500,
                          color: value == option ? Colors.white : AppColors.slate600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
