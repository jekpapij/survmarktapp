import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/survmarkt_app_bar.dart';
import '../../../../core/widgets/survmarkt_bottom_nav.dart';
import '../../../../core/widgets/survmarkt_button.dart';
import '../../../../core/widgets/survmarkt_dropdown_field.dart';
import '../../../../core/widgets/survmarkt_text_field.dart';
import '../../../../router.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../providers/researcher_providers.dart';

/// Kategori default buat survey yang dibuat lewat form ini — Figma
/// `create-survey` (node 77:2097) NGGAK punya field "Kategori" sama sekali
/// (beda dari `SurveyEntity.category` yang dipakai di dashboard/modal buat
/// nampilin subjudul). Sengaja dikasih 1 nilai tetap (bukan nambah field
/// baru di luar Figma — prinsip project ini "ambil PERSIS yang di Figma
/// aja") — dicatet di CLAUDE.md sebagai deviasi yang disadari.
const _defaultCategory = 'Survei Kustom';

const _deadlineOptions = [7, 14, 30, 60, 90];
const _defaultDeadlineDays = 30;

const _genderOptions = ['Semua', 'Laki-laki', 'Perempuan'];
const _ageOptions = ['Semua', '18-25', '26-35', '36-45', '46+'];
// Update 2026-09-08: 3 pilihan Mahasiswa/Pekerja/Masyarakat Umum — sama
// persis daftar status responden yang udah didokumentasiin di CLAUDE.md
// "Keputusan produk penting" (Admin itu ROLE terpisah, bukan bagian dari
// dropdown status ini).
const _statusOptions = ['Semua', 'Mahasiswa', 'Pekerja', 'Masyarakat Umum'];

/// Form "Buat Survei" — frame Figma `create-survey` (get_design_context,
/// node 77:2097): 4 Section Card (Detail Survei, Kalkulator Insentif &
/// Biaya, Targeting Filter Responden, Estimasi Matching Responden+Submit).
///
/// State management: field form pakai `TextEditingController`/state lokal
/// (pola sama kayak `RegisterScreen`), submit-nya lewat
/// `ResearcherRepository.createSurvey` dibungkus try/catch + `_isSubmitting`
/// lokal (pola sama kayak mutation di `KelolaSurveyModal` — bukan
/// `FutureProvider` baru, karena ini aksi submit sekali-jalan bukan data
/// yang di-watch terus-terusan). Loading/Error/Success (CPMK 3) kelihatan
/// dari: tombol submit disabled+spinner (loading), SnackBar merah (error),
/// SnackBar hijau + balik ke dashboard yang otomatis nampilin survey baru
/// (success, lewat `ref.invalidate(researcherDashboardProvider)`).
class CreateSurveyScreen extends ConsumerStatefulWidget {
  const CreateSurveyScreen({super.key});

  @override
  ConsumerState<CreateSurveyScreen> createState() => _CreateSurveyScreenState();
}

class _CreateSurveyScreenState extends ConsumerState<CreateSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetCountController = TextEditingController();
  final _linkController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _incentiveController = TextEditingController();

  int? _selectedDeadlineDays = _defaultDeadlineDays;
  DateTime? _customDeadlineDate;
  bool _featured = false;
  String _gender = 'Semua';
  String _ageRange = 'Semua';
  String _status = 'Semua';
  bool _isSubmitting = false;

  DateTime get _deadlineDate =>
      _customDeadlineDate ?? DateTime.now().add(Duration(days: _selectedDeadlineDays ?? _defaultDeadlineDays));

  int get _targetCount => int.tryParse(_targetCountController.text) ?? 0;
  int get _incentiveAmount => int.tryParse(_incentiveController.text) ?? 0;
  int get _subtotal => _targetCount * _incentiveAmount;
  int get _platformFee => (_subtotal * 0.2).round();
  int get _featuredFee => _featured ? 5000 : 0;
  int get _total => _subtotal + _platformFee + _featuredFee;

  int get _estimatedMatch {
    var pool = 500.0;
    if (_gender != 'Semua') pool *= 0.5;
    if (_ageRange != 'Semua') pool *= 0.6;
    if (_status != 'Semua') pool *= 0.65;
    return pool.round();
  }

  String get _targetLabel {
    final parts = [
      if (_gender != 'Semua') _gender,
      if (_ageRange != 'Semua') _ageRange,
      if (_status != 'Semua') _status,
    ];
    return parts.isEmpty ? 'Semua kalangan' : parts.join(' · ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetCountController.dispose();
    _linkController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _incentiveController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: _defaultDeadlineDays)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _customDeadlineDate = picked;
      _selectedDeadlineDays = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(researcherRepositoryProvider).createSurvey(
            title: _titleController.text,
            category: _defaultCategory,
            description: _descriptionController.text,
            surveyLink: _linkController.text,
            durationMinutes: int.parse(_durationController.text),
            incentiveAmount: _incentiveAmount,
            targetCount: _targetCount,
            targetLabel: _targetLabel,
            deadlineDate: _deadlineDate,
            featured: _featured,
          );
      ref.invalidate(researcherDashboardProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Survey berhasil dibuat!')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final message = e is ValidationException ? e.message : 'Gagal membuat survey: $e';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SurvMarktAppBar(
              eyebrow: 'BUAT SURVEI',
              unreadCount: ref.watch(unreadNotificationCountProvider),
              onBellTap: () => context.push(AppRoutes.notifications),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSurveiCard(),
                      const SizedBox(height: AppSpacing.md),
                      _buildKalkulatorCard(),
                      const SizedBox(height: AppSpacing.md),
                      _buildTargetingCard(),
                      const SizedBox(height: AppSpacing.md),
                      _buildEstimasiCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SurvMarktBottomNav(
        currentIndex: 1,
        items: const [
          SurvMarktNavItem(icon: Icons.home_rounded, label: 'Dashboard'),
          SurvMarktNavItem(icon: Icons.add_circle_outline, label: 'Buat Survei'),
          SurvMarktNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Wallet'),
          SurvMarktNavItem(icon: Icons.person_outline, label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 1) return;
          if (index == 0) {
            context.canPop() ? context.pop() : context.go(AppRoutes.researcherHome);
            return;
          }
          if (index == 2) {
            context.push(AppRoutes.researcherWallet);
            return;
          }
          // Update 2026-09-08: tab Profil (index 3) sekarang beneran buka
          // layar `researcher-profile` (bukan logout-langsung-hack lagi —
          // tombol Logout beneran sekarang ada DI layar itu, sesuai Figma).
          context.push(AppRoutes.researcherProfile);
        },
      ),
    );
  }

  Widget _buildDetailSurveiCard() {
    return _SectionCard(
      eyebrow: 'BUAT SURVEI',
      title: 'Detail Survei',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SurvMarktTextField(
            label: 'Judul Survei',
            controller: _titleController,
            hintText: 'Masukkan judul survei...',
            validator: (v) => Validators.required(v, 'Judul survei'),
          ),
          const SizedBox(height: 14),
          SurvMarktTextField(
            label: 'Jumlah Responden',
            controller: _targetCountController,
            keyboardType: TextInputType.number,
            hintText: '100',
            onChanged: (_) => setState(() {}),
            validator: (v) => Validators.positiveNumber(v, 'Jumlah responden'),
          ),
          const SizedBox(height: 14),
          SurvMarktTextField(
            label: 'Link Survei',
            controller: _linkController,
            keyboardType: TextInputType.url,
            hintText: 'https://forms.google.com/...',
            validator: (v) => Validators.required(v, 'Link survei'),
          ),
          const SizedBox(height: 14),
          SurvMarktTextField(
            label: 'Deskripsi',
            controller: _descriptionController,
            maxLines: 4,
            hintText: 'Jelaskan tujuan survei Anda...',
          ),
          const SizedBox(height: 14),
          SurvMarktTextField(
            label: 'Estimasi Waktu (menit)',
            controller: _durationController,
            keyboardType: TextInputType.number,
            hintText: '15',
            validator: (v) => Validators.positiveNumber(v, 'Estimasi waktu'),
          ),
          const SizedBox(height: 16),
          _buildDeadlineSection(),
          const SizedBox(height: 8),
          _buildFeaturedRow(),
        ],
      ),
    );
  }

  Widget _buildDeadlineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deadline',
          style: AppTypography.monoSmall.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate900),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final days in _deadlineOptions)
              _DeadlineChip(
                label: '$days hari',
                selected: _selectedDeadlineDays == days,
                onTap: () => setState(() {
                  _selectedDeadlineDays = days;
                  _customDeadlineDate = null;
                }),
              ),
            _DeadlineChip(
              label: _customDeadlineDate != null ? Formatters.shortDate(_customDeadlineDate!) : 'Custom',
              selected: _customDeadlineDate != null,
              onTap: _pickCustomDeadline,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturedRow() {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 20, color: AppColors.amber500),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tampilkan sebagai Featured',
                style: AppTypography.monoSmall.copyWith(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate900),
              ),
              Text(
                '(+Rp 5.000)',
                style: AppTypography.monoSmall.copyWith(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.amber500),
              ),
            ],
          ),
        ),
        Switch(
          value: _featured,
          activeTrackColor: AppColors.indigoAccent,
          onChanged: (value) => setState(() => _featured = value),
        ),
      ],
    );
  }

  Widget _buildKalkulatorCard() {
    return _SectionCard(
      eyebrow: 'KALKULATOR',
      title: 'Insentif & Biaya',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nominal Insentif per Responden',
            style: AppTypography.monoSmall.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate900),
          ),
          const SizedBox(height: 6),
          _CurrencyField(controller: _incentiveController, onChanged: (_) => setState(() {})),
          const SizedBox(height: 14),
          _CostRow(
            label: 'Subtotal ($_targetCount × ${Formatters.rupiahFull(_incentiveAmount)})',
            value: _subtotal,
          ),
          const SizedBox(height: 10),
          _CostRow(label: 'Platform Fee (20%)', value: _platformFee),
          const SizedBox(height: 10),
          _CostRow(label: 'Featured Fee', value: _featuredFee),
          const SizedBox(height: 10),
          const Divider(color: AppColors.primary100, height: 1),
          const SizedBox(height: 10),
          _CostRow(label: 'Total Pembayaran', value: _total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildTargetingCard() {
    return _SectionCard(
      eyebrow: 'TARGETING',
      title: 'Filter Responden',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SurvMarktDropdownField(
            label: 'Gender',
            value: _gender,
            options: _genderOptions,
            onChanged: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 14),
          SurvMarktDropdownField(
            label: 'Usia',
            value: _ageRange,
            options: _ageOptions,
            onChanged: (v) => setState(() => _ageRange = v),
          ),
          const SizedBox(height: 14),
          SurvMarktDropdownField(
            label: 'Status',
            value: _status,
            options: _statusOptions,
            onChanged: (v) => setState(() => _status = v),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimasiCard() {
    return _SectionCard(
      eyebrow: 'ESTIMASI',
      title: 'Matching Responden',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Estimasi responden yang cocok:',
                  style: AppTypography.monoSmall.copyWith(fontSize: 14, color: AppColors.slate600),
                ),
              ),
              Text(
                '$_estimatedMatch',
                style: AppTypography.monoSmall.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.amber500),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SurvMarktButton(
            label: 'Submit Survei →',
            isLoading: _isSubmitting,
            onPressed: _submit,
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
          BoxShadow(color: AppColors.slate900.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            eyebrow,
            style: AppTypography.eyebrowMuted.copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate600),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.displayMedium.copyWith(color: AppColors.slate900, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DeadlineChip extends StatelessWidget {
  const _DeadlineChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.indigoAccent : AppColors.primary50,
          border: selected ? null : Border.all(color: AppColors.primary100),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: AppTypography.monoSmall.copyWith(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? Colors.white : AppColors.slate600,
          ),
        ),
      ),
    );
  }
}

class _CurrencyField extends StatelessWidget {
  const _CurrencyField({required this.controller, this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // #cbd5e1 — border input standar di frame ini, dicek via
        // get_design_context (beda dikit dari AppColors.slate200 #e2e8f0).
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(AppRadius.md - 1)),
            ),
            child: Text(
              'Rp',
              style: AppTypography.monoSmall.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate600),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              onChanged: onChanged,
              validator: (v) => Validators.positiveNumber(v, 'Nominal insentif'),
              style: AppTypography.monoSmall.copyWith(fontSize: 14, color: AppColors.slate900),
              decoration: const InputDecoration(
                hintText: '10.000',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 1 baris di card "Kalkulator Insentif & Biaya" — label kiri + nominal
/// kanan, style beda buat baris "Total Pembayaran" (lebih besar + warna
/// indigoAccent) vs baris breakdown biasa. Nyamain persis "Cost Row" di
/// Figma (`get_design_context` node 77:2168-2181).
class _CostRow extends StatelessWidget {
  const _CostRow({required this.label, required this.value, this.isTotal = false});

  final String label;
  final int value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.monoSmall.copyWith(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w400,
            color: isTotal ? AppColors.slate900 : AppColors.slate600,
          ),
        ),
        Text(
          Formatters.rupiahFull(value),
          style: AppTypography.monoSmall.copyWith(
            fontSize: isTotal ? 16 : 13,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.indigoAccent : AppColors.slate900,
          ),
        ),
      ],
    );
  }
}

// Update 2026-09-08: `_DropdownField` privat dulu di sini udah diekstrak
// jadi `SurvMarktDropdownField` (`core/widgets/survmarkt_dropdown_field.
// dart`) — dipakai ulang lagi di `researcher_profile_edit_screen.dart`
// (field "Peran"), lihat CLAUDE.md.
