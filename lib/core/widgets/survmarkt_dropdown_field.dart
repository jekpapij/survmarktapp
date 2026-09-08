import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Dropdown standar SurvMarkt: label (+ tanda `*` opsional) di atas, input
/// rounded bordered di bawah, popup putih. Diekstrak (CPMK 2) dari
/// `_DropdownField` privat yang tadinya cuma dipakai di
/// `create_survey_screen.dart` — dipakai ulang lagi di
/// `researcher_profile_edit_screen.dart` (field "Peran"), jadi ditaruh di
/// `core/widgets/` biar konsisten & nggak duplikat implementasi.
///
/// `dropdownColor: Colors.white` + style eksplisit per item WAJIB ada — ini
/// FIX buat bug yang pernah kejadian (popup dropdown nongol gelap ngikutin
/// Theme ambient kalau nggak di-pin manual, lihat CLAUDE.md "Bugfix
/// dropdown gelap"). Pola sama kayak `RoleSelectField`.
class SurvMarktDropdownField extends StatelessWidget {
  const SurvMarktDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hintText,
    this.validator,
    this.isRequired = false,
  });

  final String label;

  /// Null = belum ada yang dipilih (nampilin `hintText`). Dipakai di form
  /// `researcher-profile-edit` yang field-nya emang belum ke-prefill.
  final String? value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.monoSmall.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate900),
            ),
            if (isRequired) ...[
              const SizedBox(width: 2),
              const Text('*', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: value,
              // Fix dropdown gelap — lihat catatan di atas class.
              dropdownColor: Colors.white,
              isExpanded: true,
              hint: hintText != null
                  ? Text(hintText!, style: AppTypography.monoSmall.copyWith(fontSize: 14, color: AppColors.slate400))
                  : null,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.slate400, size: 20),
              style: AppTypography.monoSmall.copyWith(fontSize: 14, color: AppColors.slate900),
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
              validator: validator,
              items: [
                for (final option in options)
                  DropdownMenuItem(
                    value: option,
                    child: Text(
                      option,
                      style: AppTypography.monoSmall.copyWith(fontSize: 14, color: AppColors.slate900),
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
