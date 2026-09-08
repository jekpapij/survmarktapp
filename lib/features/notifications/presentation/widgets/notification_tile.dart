import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/notification_entity.dart';

/// 1 baris notifikasi — icon-badge bulat warna sesuai [NotificationType] +
/// judul/isi + timestamp relatif, dot indigo kecil kalau belum dibaca.
/// Self-designed (nggak ada frame Figma referensi, lihat catatan di
/// `NotificationEntity`) tapi tetep ngikutin token warna/tipografi yang
/// sama kayak `SurveyProgressCard`/`MetricCard` biar konsisten 1 sistem.
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, this.onTap});

  final NotificationEntity notification;
  final VoidCallback? onTap;

  (IconData, Color) get _iconAndColor => switch (notification.type) {
        NotificationType.payment => (Icons.account_balance_wallet_outlined, AppColors.success),
        NotificationType.survey => (Icons.bar_chart_rounded, AppColors.indigoAccent),
        NotificationType.respondent => (Icons.person_add_alt_1_outlined, AppColors.info),
        NotificationType.system => (Icons.campaign_outlined, AppColors.amber500),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor;
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.primary50 : Colors.white,
          border: Border.all(color: isUnread ? AppColors.primary100 : AppColors.slate100),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTypography.labelSemibold.copyWith(
                            fontSize: 14,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.indigoAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: AppTypography.bodyMedium.copyWith(fontSize: 13, color: AppColors.slate600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.relativeTime(notification.createdAt),
                    style: AppTypography.monoSmall.copyWith(fontSize: 11, color: AppColors.slate400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
