import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Kartu statistik kecil (label uppercase + angka besar) — persis contoh
/// widget reusable "MetricCard" yang disebut rubrik CPMK 2 (`SPESIFIKASI_
/// PROYEK_PENILAIAN.pdf`, "Reusability Widget"). Dipakai di stat-grid
/// `researcher-dashboard`, tapi ditaruh di `core/widgets/` karena bentuknya
/// generik — bakal dipakein ulang di dashboard admin & wallet nanti (semua
/// butuh nampilin nominal/angka ringkas).
class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary100),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(color: Color(0x0A4F46E5), blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.monoSmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: AppColors.slate600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.monoNumber.copyWith(fontSize: 24, color: AppColors.primary900),
          ),
        ],
      ),
    );
  }
}
