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
    this.isRequired = false,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final String? hintText;

  /// Update 2026-09-08: tanda `*` merah di sebelah label — buat field
  /// wajib diisi di frame `researcher-profile-edit` (get_design_context
  /// node 77:2654), Figma-nya beneran nunjukin asterisk merah eksplisit
  /// (beda dari `create-survey` yang nggak ada tanda ini sama sekali).
  final bool isRequired;

  /// Update 2026-09-08: field non-editable (mis. "Email" di
  /// `researcher-profile-edit` — sengaja nggak bisa diubah dari sini).
  /// Beda dari `TextFormField.enabled: false` (yang bikin teksnya keabuan
  /// otomatis dari Material) — di sini teksnya tetep warna normal, cuma
  /// background-nya abu-abu (`slate100`) & nggak bisa diketik, nyamain
  /// persis visual Figma.
  final bool readOnly;

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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: AppTypography.monoSmall.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: 2),
              const Text('*', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          readOnly: widget.readOnly,
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
            fillColor: widget.readOnly ? AppColors.slate100 : Colors.white,
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
