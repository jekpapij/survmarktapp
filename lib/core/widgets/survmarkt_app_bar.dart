import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// App-bar indigo900 standar SurvMarkt — eyebrow (JetBrains Mono kecil) +
/// judul "SurvMarkt" (Lora Bold) + bell icon notifikasi dengan badge unread.
///
/// Update 2026-09-08: diekstrak dari `_AppBar` privat di
/// `researcher_dashboard_screen.dart` jadi widget reusable di `core/widgets/`
/// — dipakai lagi persis sama di `create_survey_screen.dart` (cuma beda teks
/// eyebrow), dan bakal dipakai ulang lagi di layar-layar researcher/
/// respondent/admin selanjutnya. Sengaja TERIMA `unreadCount` sebagai
/// parameter (bukan `ref.watch` provider notifikasi sendiri) — biar widget
/// ini tetap murni data-in/callback-out kayak `StatusBadge`/`MetricCard`,
/// nggak nge-couple `core/` ke `features/notifications/`.
class SurvMarktAppBar extends StatelessWidget {
  const SurvMarktAppBar({
    super.key,
    required this.eyebrow,
    required this.onBellTap,
    this.unreadCount = 0,
  });

  final String eyebrow;
  final VoidCallback onBellTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: AppColors.primary900,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eyebrow,
                style: AppTypography.eyebrow.copyWith(
                  color: const Color(0xFFA5B4FC),
                  fontSize: 10,
                ),
              ),
              Text(
                'SurvMarkt',
                style: AppTypography.displayMedium.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onBellTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.notifications_none_rounded, size: 18, color: Colors.white),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary900, width: 1.5),
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
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
