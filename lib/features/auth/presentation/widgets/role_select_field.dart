import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/user_entity.dart';

/// Dropdown "Daftar Sebagai" — frame `dropdown-pilihan-role-register` di
/// Figma. Isinya cuma Peneliti/Responden (Admin dibuat manual, bukan lewat
/// register-page — lihat CLAUDE.md "Keputusan produk penting").
class RoleSelectField extends StatelessWidget {
  const RoleSelectField({super.key, required this.value, required this.onChanged});

  final UserRole? value;
  final ValueChanged<UserRole> onChanged;

  static const _options = [UserRole.peneliti, UserRole.responden];

  @override
  Widget build(BuildContext context) {
    // Update 2026-09-08: disamain persis frame Figma `register-page`
    // (get_design_context, node 27:40, section `role`) — border-2 bukan
    // border-1, radius 8 bukan 12, label & item pakai JetBrains Mono
    // (bukan Inter), hint "Pilih" persis kayak di Figma.
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: const BorderSide(color: AppColors.slate200, width: 2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar Sebagai',
          style: AppTypography.monoSmall.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<UserRole>(
          initialValue: value,
          dropdownColor: Colors.white,
          hint: Text('Pilih', style: AppTypography.monoSmall.copyWith(fontSize: 14, color: AppColors.slate400)),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.slate400),
          items: _options
              .map(
                (role) => DropdownMenuItem(
                  value: role,
                  child: Text(
                    role.label,
                    style: AppTypography.monoSmall.copyWith(fontSize: 16, color: AppColors.slate900),
                  ),
                ),
              )
              .toList(),
          onChanged: (role) {
            if (role != null) onChanged(role);
          },
          validator: (role) => role == null ? 'Pilih salah satu peran' : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.primary600, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }
}
