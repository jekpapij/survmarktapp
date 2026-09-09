import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/survmarkt_button.dart';
import '../../domain/entities/survey_listing_entity.dart';

/// Modal "Detail Survei" — self-designed (nggak ada frame Figma buat ini di
/// sisi respondent, user konfirmasi 2026-09-09: "gw di figma bagian
/// responden ga bikin detail modal survei"). Dibikin NYAMAIN pola visual
/// `KelolaSurveyModal` (`features/researcher/presentation/widgets/
/// kelola_survey_modal.dart`) SESUAI keputusan produk yang udah
/// didokumentasiin di CLAUDE.md "Keputusan produk penting": "UX detail
/// survey: card ringkas + tombol 'Detail' → buka modal isi lengkap →
/// tombol 'Isi Survey' ada di dalam modal (bukan langsung di card)" — jadi
/// walau nggak ada frame Figma spesifik, POLA INTERAKSI-nya emang udah
/// diputuskan dari awal proyek (nyamain `dashboard.html` versi web),
/// tinggal diterapin ke sisi respondent.
///
/// **Beda dari `KelolaSurveyModal`:** itu buat PENELITI ngelola survey
/// (aksi Jeda/Lanjutkan/Hapus, mutasi status), ini buat RESPONDEN liat
/// detail sebelum ikutan (aksi TUNGGAL "Isi Survei", bukan mutasi status
/// apapun — `SurveyListingEntity` murni data buat DIBACA, nggak ada
/// `updateStatus`/`delete` di `RespondentRepository`).
Future<void> showSurveyDetailModal(BuildContext context, SurveyListingEntity survey) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SurveyDetailModal(survey: survey),
  );
}

class SurveyDetailModal extends StatelessWidget {
  const SurveyDetailModal({super.key, required this.survey});

  final SurveyListingEntity survey;

  /// **Stub yang disadari (bukan silent/nggak ngapa-ngapain):** "Isi
  /// Survei" seharusnya buka link survei eksternal (Google Form dkk, sama
  /// kayak `surveyLink` di sisi researcher) lalu nyatet aktivitas baru
  /// dengan status "Menunggu Verifikasi" — tapi `SurveyListingEntity`
  /// belum punya field link, dan belum ada tempat buat nyimpen
  /// aktivitas itu (frame `respondent-activity` yang bakal jadi rumahnya
  /// belum ditranslate). Daripada nge-block modal ini nunggu 2 fitur lain
  /// kelar, tombolnya SENGAJA distub dulu (pola sama kayak "Deposit
  /// Dana"/Google Sign-In) — bakal disambung beneran begitu
  /// `respondent-activity` digarap.
  void _handleIsiSurvei(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Isi Survei (buka link eksternal + catat ke Aktivitas) nyusul pas frame respondent-activity digarap.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            color: AppColors.primary50,
            child: Column(
              children: [
                _Header(survey: survey, onClose: () => Navigator.of(context).pop()),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoGrid(survey: survey),
                        const SizedBox(height: AppSpacing.sm),
                        _DeadlineCard(survey: survey),
                        const SizedBox(height: AppSpacing.sm),
                        _QuotaCard(survey: survey),
                        const SizedBox(height: AppSpacing.lg),
                        SurvMarktButton(
                          label: 'Isi Survei →',
                          icon: Icons.edit_note_rounded,
                          onPressed: () => _handleIsiSurvei(context),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.survey, required this.onClose});

  final SurveyListingEntity survey;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.primary900,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DETAIL SURVEI',
                style: AppTypography.eyebrow.copyWith(color: const Color(0xFFA5B4FC), fontSize: 10),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            survey.title,
            style: AppTypography.displaySmall.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${survey.authorLabel} · ${survey.category.label}',
            style: AppTypography.monoSmall.copyWith(color: const Color(0xFFC7D2FE), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

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
      ),
      child: child,
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.survey});

  final SurveyListingEntity survey;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _InfoItem(label: 'DURASI', value: survey.durationLabel)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _InfoItem(label: 'INSENTIF', value: Formatters.rupiahFull(survey.incentiveAmount)),
              ),
            ],
          ),
          if (survey.featured || survey.badge != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (survey.featured)
                  const StatusBadge(
                    label: 'FEATURED',
                    background: AppColors.amber500,
                    foreground: Colors.white,
                    icon: Icons.star_rounded,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  )
                else if (survey.badge == SurveyListingBadge.matched)
                  const StatusBadge(
                    label: 'Cocok untukmu',
                    background: AppColors.primary50,
                    foreground: AppColors.indigoAccent,
                    fontSize: 10,
                  )
                else if (survey.badge == SurveyListingBadge.expiringSoon)
                  const StatusBadge(
                    label: 'Segera Berakhir',
                    background: Color(0xFFFFF7ED),
                    foreground: Color(0xFFEA580C),
                    fontSize: 10,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTypography.eyebrowMuted.copyWith(fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.displaySmall.copyWith(color: AppColors.slate900, fontSize: 14),
        ),
      ],
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  const _DeadlineCard({required this.survey});

  final SurveyListingEntity survey;

  @override
  Widget build(BuildContext context) {
    // Update 2026-09-09: `SurveyListingEntity.daysLeft` itu int statis
    // (bukan `DateTime` yang di-diff live kayak sisi researcher — lihat
    // catatan di entity), jadi teksnya dihitung langsung dari situ, bukan
    // lewat `Formatters.relativeDays`.
    final isUrgent = survey.daysLeft <= 3;
    return _SectionCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isUrgent ? const Color(0xFFFFF7ED) : AppColors.primary50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: isUrgent ? const Color(0xFFEA580C) : AppColors.indigoAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Batas Waktu Pengisian',
                  style: AppTypography.monoSmall.copyWith(fontSize: 11, color: AppColors.slate600),
                ),
                Text(
                  'Berakhir dalam ${survey.daysLeftLabel}',
                  style: AppTypography.displaySmall.copyWith(
                    color: isUrgent ? const Color(0xFFEA580C) : AppColors.slate900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({required this.survey});

  final SurveyListingEntity survey;

  @override
  Widget build(BuildContext context) {
    final percent = survey.targetCount == 0
        ? 0.0
        : (survey.respondentCount / survey.targetCount).clamp(0.0, 1.0);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kuota Responden',
                style: AppTypography.eyebrowMuted.copyWith(fontSize: 9, fontWeight: FontWeight.bold),
              ),
              Text(
                survey.progressLabel,
                style: AppTypography.monoSmall.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: AppColors.slate200,
              valueColor: const AlwaysStoppedAnimation(AppColors.indigoAccent),
            ),
          ),
        ],
      ),
    );
  }
}
