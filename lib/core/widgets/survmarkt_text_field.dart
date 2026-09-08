import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Text field standar SurvMarkt: label (Inter semibold) di atas, input rounded
/// indigo-bordered di bawah — konsisten sama pattern card di PROMPT_SPEC.md §4.4.
class SurvMarktTextField extends StatefulWidget {
  const SurvMarktTextField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.hintText,
    this.maxLines = 1,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final String? hintText;

  /// Update 2026-09-08: buat field textarea (mis. "Deskripsi" di form
  /// `create-survey`) — default 1 (single-line, perilaku lama nggak
  /// berubah). Textarea beneran pakai `maxLines` >1 + `alignLabelWithHint`.
  final int maxLines;

  /// Opsional — buat field yang butuh recalculate tampilan lain secara live
  /// pas diketik (mis. kalkulator insentif di `create-survey`).
  final ValueChanged<String>? onChanged;

  @override
  State<SurvMarktTextField> createState() => _SurvMarktTextFieldState();
}

class _SurvMarktTextFieldState extends State<SurvMarktTextField> {
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.slate200),
    );

    // Update 2026-09-08: label/input/hint diganti dari Inter ke JetBrains Mono
    // — dicek ulang lewat get_design_context di 2 frame (login-page &
    // register-page), dua-duanya konsisten pakai JetBrains Mono buat semua
    // label/placeholder form, bukan cuma eyebrow/angka doang kayak aturan
    // lama di PROMPT_SPEC.md. Ini widget SHARED, jadi perubahan ini otomatis
    // ngefek ke semua text field di app (bukan cuma register).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.monoSmall.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          style: AppTypography.monoSmall.copyWith(fontSize: 14, color: AppColors.slate900),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTypography.monoSmall.copyWith(fontSize: 14, color: AppColors.slate400),
            alignLabelWithHint: widget.maxLines > 1,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: AppColors.slate400, size: 20)
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.slate400,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary600, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }
}
