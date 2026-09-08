import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/survey_entity.dart';
import '../providers/researcher_providers.dart';

/// Modal "Kelola Survey" — frame Figma `detail-modal-kelola-survei` (node
/// 77:2588, fileKey sh3QGUb2P6BHPTIbtxXjOT).
///
/// PENTING (konfirmasi user 2026-09-08 via AskUserQuestion — lihat CLAUDE.md):
/// ini WAJIB overlay beneran (`showModalBottomSheet`), BUKAN route/page
/// terpisah, meskipun ada keputusan lama (2026-09-02) yang sempat jadiin ini
/// full page. User eksplisit milih "Modal/bottom-sheet beneran" buat nyamain
/// logic asli di web (`dashboard.html`).
Future<void> showKelolaSurveyModal(BuildContext context, SurveyEntity survey) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => KelolaSurveyModal(survey: survey),
  );
}

class KelolaSurveyModal extends ConsumerStatefulWidget {
  const KelolaSurveyModal({super.key, required this.survey});

  final SurveyEntity survey;

  @override
  ConsumerState<KelolaSurveyModal> createState() => _KelolaSurveyModalState();
}

class _KelolaSurveyModalState extends ConsumerState<KelolaSurveyModal> {
  bool _busy = false;

  Future<void> _togglePause() async {
    final nextStatus =
        widget.survey.status == SurveyStatus.paused ? SurveyStatus.open : SurveyStatus.paused;
    setState(() => _busy = true);
    try {
      await ref.read(researcherRepositoryProvider).updateSurveyStatus(widget.survey.id, nextStatus);
      ref.invalidate(researcherDashboardProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal mengubah status survey: $e')));
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Survey?'),
        content: Text(
          '"${widget.survey.title}" akan dihapus dan tidak akan muncul lagi di dashboard. '
          'Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(researcherRepositoryProvider).deleteSurvey(widget.survey.id);
      ref.invalidate(researcherDashboardProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menghapus survey: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final survey = widget.survey;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
                  child: AbsorbPointer(
                    absorbing: _busy,
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
                          _ProgressCard(survey: survey),
                          const SizedBox(height: AppSpacing.sm),
                          _AnalyticsCard(survey: survey),
                          const SizedBox(height: AppSpacing.lg),
                          _Actions(
                            survey: survey,
                            busy: _busy,
                            onTogglePause: _togglePause,
                            onDelete: _confirmDelete,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
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

  final SurveyEntity survey;
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
                'KELOLA SURVEY',
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
            survey.category,
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

  final SurveyEntity survey;

  Color get _statusBg => switch (survey.status) {
        SurveyStatus.open => const Color(0xFFD1FAE5),
        SurveyStatus.paused => const Color(0xFFFEF3C7),
        SurveyStatus.closed => AppColors.slate200,
        SurveyStatus.deleted => AppColors.slate200,
      };

  Color get _statusFg => switch (survey.status) {
        SurveyStatus.open => const Color(0xFF047857),
        SurveyStatus.paused => AppColors.amber500,
        SurveyStatus.closed => AppColors.slate600,
        SurveyStatus.deleted => AppColors.slate600,
      };

  String get _statusLabel => switch (survey.status) {
        SurveyStatus.open => 'OPEN',
        SurveyStatus.paused => 'PAUSED',
        SurveyStatus.closed => 'CLOSED',
        SurveyStatus.deleted => 'DELETED',
      };

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _InfoItem(label: 'DURASI', value: '${survey.durationMinutes} menit')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _InfoItem(label: 'INSENTIF', value: Formatters.rupiahShort(survey.incentiveAmount)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _InfoItem(label: 'TARGET', value: survey.targetLabel)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'STATUS',
                      style: AppTypography.eyebrowMuted.copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    StatusBadge(label: _statusLabel, background: _statusBg, foreground: _statusFg),
                  ],
                ),
              ),
            ],
          ),
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

  final SurveyEntity survey;

  @override
  Widget build(BuildContext context) {
    if (survey.status == SurveyStatus.closed || survey.status == SurveyStatus.deleted) {
      return const SizedBox.shrink();
    }
    return _SectionCard(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.indigoAccent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Deadline · ${Formatters.shortDate(survey.deadlineDate)}',
                  style: AppTypography.monoSmall.copyWith(fontSize: 11, color: AppColors.slate600),
                ),
                Text(
                  Formatters.relativeDays(survey.deadlineDate),
                  style: AppTypography.displaySmall.copyWith(color: AppColors.slate900, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.survey});

  final SurveyEntity survey;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress Responden',
                style: AppTypography.eyebrowMuted.copyWith(fontSize: 9, fontWeight: FontWeight.bold),
              ),
              Text(
                '${survey.respondentCount}/${survey.targetCount} (${survey.progressPercent}%)',
                style: AppTypography.monoSmall.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: survey.progressPercent / 100,
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

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.survey});

  final SurveyEntity survey;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        children: [
          Expanded(child: _AnalyticsItem(label: 'VIEWS', value: Formatters.thousands(survey.views))),
          Container(width: 1, height: 32, color: AppColors.primary100),
          Expanded(child: _AnalyticsItem(label: 'RESPONDEN', value: '${survey.respondentCount}')),
          Container(width: 1, height: 32, color: AppColors.primary100),
          Expanded(
            child: _AnalyticsItem(label: 'CONVERSION', value: '${survey.conversionPercent.toStringAsFixed(1)}%'),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsItem extends StatelessWidget {
  const _AnalyticsItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.monoNumber.copyWith(fontSize: 16, color: AppColors.primary900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.eyebrowMuted.copyWith(fontSize: 9, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.survey,
    required this.busy,
    required this.onTogglePause,
    required this.onDelete,
  });

  final SurveyEntity survey;
  final bool busy;
  final VoidCallback onTogglePause;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isClosedOrDeleted = survey.status == SurveyStatus.closed || survey.status == SurveyStatus.deleted;
    final isPaused = survey.status == SurveyStatus.paused;

    return Column(
      children: [
        // Update 2026-09-08: survey CLOSED itu status final (lihat state
        // machine di CLAUDE.md, OPEN ⇄ PAUSED → CLOSED), jadi tombol jeda/
        // lanjut sengaja disembunyiin — cuma "Hapus Survey" yang selalu
        // tersedia dari status manapun.
        if (!isClosedOrDeleted) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onTogglePause,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber500),
                    )
                  : Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 18),
              label: Text(isPaused ? 'Lanjutkan Survei' : 'Jeda Survei'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.amber500,
                side: const BorderSide(color: AppColors.amber500, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                textStyle: AppTypography.buttonText.copyWith(color: AppColors.amber500),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: busy ? null : onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Hapus Survei'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
              textStyle: AppTypography.buttonText.copyWith(color: AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }
}
