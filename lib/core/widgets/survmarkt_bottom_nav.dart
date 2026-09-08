import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Satu item bottom nav — dipakai bareng [SurvMarktBottomNav].
class SurvMarktNavItem {
  const SurvMarktNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Bottom nav generik & reusable — jumlah/isi tab beda-beda per role (lihat
/// CLAUDE.md §"Bottom nav per role"): Researcher 4 tab, Respondent 4 tab beda
/// isi, Admin 4 tab beda lagi. Widget ini nggak tau apa-apa soal role, cuma
/// nerima list item + index aktif — jadi 1 komponen ini dipakein ulang di
/// ketiga role, bukan bikin widget nav terpisah per role (rubrik CPMK 2:
/// "pemisahan widget secara modular").
class SurvMarktBottomNav extends StatelessWidget {
  const SurvMarktBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<SurvMarktNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 73,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.primary100)),
        boxShadow: [
          BoxShadow(color: Color(0x140F172A), blurRadius: 8, offset: Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _NavTab(
                item: items[i],
                isActive: i == currentIndex,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({required this.item, required this.isActive, required this.onTap});

  final SurvMarktNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.indigoAccent : AppColors.slate400;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary50 : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, size: 20, color: color),
          ),
          const SizedBox(height: 4),
          // Update 2026-09-08: fix overflow — label sebelumnya bisa wrap ke
          // 2 baris kalau kepanjangan buat lebar 1 tab (kejadian di
          // "Create Survey", screenshot user: "BOTTOM OVERFLOWED BY 12
          // PIXELS"), soalnya Container height di atas fixed 73 tapi Column
          // isinya jadi lebih tinggi dari itu. Dibikin defense-in-depth di
          // level widget shared ini (maxLines 1 + ellipsis) SEKALIGUS
          // dibenerin sumber datanya (lihat researcher_dashboard_screen.dart
          // — label diganti ke "Buat Survei" biar muat 1 baris & konsisten
          // Indonesia kayak label lain), karena widget ini bakal dipakai
          // ulang buat respondent/admin yang label-nya belum tentu sependek
          // ini juga.
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.monoSmall.copyWith(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
