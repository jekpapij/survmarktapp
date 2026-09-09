import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/survey_listing_entity.dart';

/// Card survei di `respondent-discover` — satu widget nyakup DUA varian
/// visual dari Figma (`featured-survey-card` & `normal-survey-card`),
/// dibedain lewat `survey.featured` (reusable widget, CPMK 2, daripada 2
/// class kepisah buat struktur yang sama persis, cuma beda styling
/// container + 1 badge).
class SurveyListingCard extends StatelessWidget {
  const SurveyListingCard({super.key, required this.survey, this.onTap});

  final SurveyListingEntity survey;
  final VoidCallback? onTap;

  static const _expiringSoonBg = Color(0xFFFFF7ED);
  static const _expiringSoonFg = Color(0xFFEA580C);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(survey.featured ? 18 : 16),
        decoration: survey.featured
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.amber50, Colors.white],
                ),
                border: Border.all(color: AppColors.amber500, width: 1.5),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x0F1E293B), blurRadius: 12, offset: Offset(0, 4)),
                ],
              )
            : BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.primary100),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x081E293B), blurRadius: 5, offset: Offset(0, 4)),
                ],
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                else
                  StatusBadge(
                    label: Formatters.rupiahFull(survey.incentiveAmount),
                    background: AppColors.amber50,
                    foreground: AppColors.amber500,
                    fontSize: 13,
                  ),
                if (survey.featured)
                  StatusBadge(
                    label: Formatters.rupiahFull(survey.incentiveAmount),
                    background: AppColors.amber500,
                    foreground: Colors.white,
                    fontSize: 13,
                  )
                else if (survey.badge != null)
                  _CustomBadge(badge: survey.badge!),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              survey.title,
              style: AppTypography.displaySmall.copyWith(
                fontSize: survey.featured ? 18 : 15,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              survey.authorLabel,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: survey.featured ? 13 : 12,
                color: AppColors.slate600,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.primary100),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetaItem(icon: Icons.access_time_rounded, label: survey.durationLabel),
                _MetaItem(icon: Icons.people_alt_outlined, label: survey.progressLabel),
                _MetaItem(icon: Icons.calendar_month_outlined, label: survey.daysLeftLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomBadge extends StatelessWidget {
  const _CustomBadge({required this.badge});

  final SurveyListingBadge badge;

  @override
  Widget build(BuildContext context) {
    return switch (badge) {
      SurveyListingBadge.matched => const StatusBadge(
          label: 'Cocok untukmu',
          background: AppColors.primary50,
          foreground: AppColors.indigoAccent,
          fontSize: 10,
        ),
      SurveyListingBadge.expiringSoon => const StatusBadge(
          label: 'Segera Berakhir',
          background: SurveyListingCard._expiringSoonBg,
          foreground: SurveyListingCard._expiringSoonFg,
          fontSize: 10,
        ),
    };
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.slate400),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.monoSmall.copyWith(fontSize: 11, color: AppColors.slate400),
        ),
      ],
    );
  }
}
