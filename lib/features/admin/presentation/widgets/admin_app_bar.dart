import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

/// App-bar khusus Admin — nyontek abis-abisan `SurvMarktAppBar` (eyebrow +
/// judul "SurvMarkt" + bell notifikasi, PERSIS style/warna/spacing yang
/// sama), tapi nambahin pill "ADMIN" di sebelah judul. Ke-4 frame Figma
/// `admin-dashboard`/`admin-withdrawal`/`admin-audit-log`/`admin-profil`
/// konsisten nunjukin pill ini di app-bar-nya — beda dari researcher/
/// respondent yang nggak punya. Dibikin widget terpisah di
/// `features/admin/presentation/widgets/` (BUKAN nambah parameter opsional
/// ke `SurvMarktAppBar` core yang dipakai IDENTIK di 2 role lain) — biar
/// widget shared itu tetep bersih dari parameter yang cuma relevan buat 1
/// role.
///
/// Soal warna pill: Figma nunjukin bg `#312E81` (= `AppColors.primary900`)
/// — cocok di frame `admin-login` (background PUTIH di situ), tapi bakal
/// nyaris nggak keliatan kalau dipasang literal DI SINI (background app-bar
/// ini JUGA primary900). Disesuaikan pakai putih transparan tipis (pola
/// sama kayak bg lingkaran bell icon di `SurvMarktAppBar`) biar tetep kebaca
/// kontras di atas app-bar indigo900 — deviasi disadari, demi kontras.
class AdminAppBar extends StatelessWidget {
  const AdminAppBar({super.key, required this.eyebrow, required this.onBellTap, this.unreadCount = 0});

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
                style: AppTypography.eyebrow.copyWith(color: const Color(0xFFA5B4FC), fontSize: 10),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SurvMarkt',
                    style: AppTypography.displayMedium.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
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
