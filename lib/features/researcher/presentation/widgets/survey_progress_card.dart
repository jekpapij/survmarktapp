import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/survey_entity.dart';

/// Card "Progress Survey" — 4 tampilan beda tergantung [SurveyEntity.status]
/// (+ [SurveyEntity.featured]/[expiringSoon]), nyamain persis frame Figma
/// `researcher-dashboard` (get_design_context, node 77:2446): OPEN (hijau),
/// PAUSED (amber), FEATURED (border amber tebal + dual badge), CLOSED
/// (netral, opacity diturunin). Lihat CLAUDE.md "Keputusan produk penting"
/// soal kenapa CLOSED sengaja netral (biar nggak ketuker warna "bahaya").
///
/// Dibikin reusable (bukan langsung ditulis di screen) karena bakal dipakai
/// ulang persis di `detail-modal-kelola-survei` nanti — sesuai rubrik CPMK 2
/// "pemisahan widget secara modular".
class SurveyProgressCard extends StatelessWidget {
  const SurveyProgressCard({super.key, required this.survey, this.onTap});

  final SurveyEntity survey;
  final VoidCallback? onTap;

  bool get _isClosed => survey.status == SurveyStatus.closed;
  bool get _isPaused => survey.status == SurveyStatus.paused;
  bool get _isFeatured => survey.featured;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _isFeatured ? AppColors.amber500.withValues(alpha: 0.04) : Colors.white,
        border: Border.all(
          color: _isFeatured ? AppColors.amber500 : AppColors.primary100,
          width: _isFeatured ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: (_isFeatured ? AppColors.amber500 : AppColors.indigoAccent).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTopRow(),
          const SizedBox(height: AppSpacing.sm),
          if (_isFeatured) ...[
            _buildDualBadges(),
            const SizedBox(height: AppSpacing.sm),
          ],
          _buildProgress(),
          const SizedBox(height: AppSpacing.sm),
          _buildStatsRow(),
        ],
      ),
    );

    final opacity = _isClosed ? 0.8 : 1.0;
    return Opacity(
      opacity: opacity,
      child: onTap != null ? InkWell(onTap: onTap, child: card) : card,
    );
  }

  Widget _buildTopRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            survey.title,
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.slate900,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (_isFeatured)
          const StatusBadge(
            label: 'FEATURED',
            background: Color(0xFFFFC25B),
            foreground: Color(0xFFB45309),
            icon: Icons.star_rounded,
            fontSize: 9,
          )
        else if (_isClosed)
          const StatusBadge(
            label: 'CLOSED',
            background: AppColors.slate200,
            foreground: AppColors.slate600,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          )
        else if (_isPaused)
          StatusBadge(label: 'PAUSED', background: const Color(0xFFFEF3C7), foreground: AppColors.amber500)
        else
          const StatusBadge(label: 'OPEN', background: Color(0xFFD1FAE5), foreground: Color(0xFF047857)),
      ],
    );
  }

  Widget _buildDualBadges() {
    return Row(
      children: [
        const StatusBadge(
          label: 'OPEN',
          background: Color(0xFFD1FAE5),
          foreground: Color(0xFF047857),
          fontSize: 10,
        ),
        if (survey.expiringSoon) ...[
          const SizedBox(width: AppSpacing.xs),
          StatusBadge(
            label: 'Expiring Soon',
            background: const Color(0xFFFFDBDB),
            foreground: AppColors.amber500,
            fontSize: 10,
          ),
        ],
      ],
    );
  }

  Widget _buildProgress() {
    final fillColor = _isClosed
        ? AppColors.slate600
        : _isFeatured
            ? AppColors.amber500
            : AppColors.indigoAccent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: survey.progressPercent / 100,
            minHeight: 6,
            backgroundColor: AppColors.slate200,
            valueColor: AlwaysStoppedAnimation(fillColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${survey.progressPercent}% Terisi',
          style: AppTypography.monoSmall.copyWith(fontSize: 11, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final metaIcon = switch (survey.metaKind) {
      SurveyMetaKind.deadline => Icons.calendar_today_outlined,
      SurveyMetaKind.paused => Icons.pause_circle_outline,
      SurveyMetaKind.completed => Icons.check_circle_outline,
    };
    final metaColor = survey.metaKind == SurveyMetaKind.completed ? AppColors.success : AppColors.slate600;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.visibility_outlined, size: 14, color: AppColors.slate600),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${survey.views} views · ${survey.conversionPercent.toStringAsFixed(1)}% konversi',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(fontSize: 12, color: AppColors.slate600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(metaIcon, size: 14, color: metaColor),
            const SizedBox(width: 4),
            Text(
              survey.metaText,
              style: AppTypography.bodySmall.copyWith(fontSize: 12, color: AppColors.slate600),
            ),
          ],
        ),
      ],
    );
  }
}
