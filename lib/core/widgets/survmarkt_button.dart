import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// Primary/amber/outline/destructive button — PROMPT_SPEC.md §4.5.
enum SurvMarktButtonVariant { primary, amber, outline, destructive }

class SurvMarktButton extends StatelessWidget {
  const SurvMarktButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SurvMarktButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final SurvMarktButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isDisabled ? null : onPressed,
        style: _buttonStyle,
        child: isLoading ? _buildLoadingIndicator() : _buildLabel(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final color = variant == SurvMarktButtonVariant.amber || variant == SurvMarktButtonVariant.outline
        ? AppColors.primary900
        : Colors.white;
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }

  Widget _buildLabel() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: _textStyle.color),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(label, style: _textStyle),
      ],
    );
  }

  TextStyle get _textStyle {
    switch (variant) {
      case SurvMarktButtonVariant.amber:
        return AppTypography.buttonText.copyWith(color: AppColors.primary900);
      case SurvMarktButtonVariant.outline:
        return AppTypography.buttonText.copyWith(color: AppColors.primary600);
      case SurvMarktButtonVariant.primary:
      case SurvMarktButtonVariant.destructive:
        return AppTypography.buttonText;
    }
  }

  ButtonStyle get _buttonStyle {
    final radius = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));
    switch (variant) {
      case SurvMarktButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary600,
          disabledBackgroundColor: AppColors.primary600.withValues(alpha: 0.5),
          shape: radius,
          elevation: 0,
        );
      case SurvMarktButtonVariant.amber:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber500,
          disabledBackgroundColor: AppColors.amber500.withValues(alpha: 0.5),
          shape: radius,
          elevation: 0,
        );
      case SurvMarktButtonVariant.outline:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.primary600),
          shape: radius,
          elevation: 0,
        );
      case SurvMarktButtonVariant.destructive:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger,
          disabledBackgroundColor: AppColors.danger.withValues(alpha: 0.5),
          shape: radius,
          elevation: 0,
        );
    }
  }
}
