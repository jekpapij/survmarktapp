import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// App-bar sederhana (indigo900 + tombol back + judul) buat layar yang
/// DI-PUSH dari dalam flow lain (bukan tab root, jadi nggak butuh bottom
/// nav ataupun bell notifikasi kayak `SurvMarktAppBar`). Diekstrak jadi
/// reusable (CPMK 2) karena dipakai identik di 3 layar baru "Ubah
/// Password"/"Lupa Password" (self-designed, lihat CLAUDE.md) — pola
/// visual sama kayak `_AppBar` privat di `notifications_screen.dart`,
/// cuma dilepas dari logic "tandai semua dibaca" yang spesifik notifikasi.
class SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SimpleAppBar({super.key, required this.title, this.eyebrow});

  final String title;

  /// Update 2026-09-08: opsional — baris kecil uppercase di atas judul
  /// (mis. "EDIT PROFIL" di frame `researcher-profile-edit`, node
  /// 77:2654). Null = perilaku lama (judul 1 baris doang), backward-
  /// compatible ke 3 layar yang udah pakai widget ini duluan.
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
      color: AppColors.primary900,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eyebrow != null)
                    Text(
                      eyebrow!,
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  Text(
                    title,
                    style: AppTypography.displaySmall.copyWith(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(eyebrow != null ? 64 : 56);
}
