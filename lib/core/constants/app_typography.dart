import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Display — Lora
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Lora',
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.primary900,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Lora',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.primary900,
  );
  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'Lora',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.primary900,
  );
  static const TextStyle displayItalic = TextStyle(
    fontFamily: 'Lora',
    fontSize: 22,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    color: AppColors.primary900,
  );

  // Body — Inter
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.slate900,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.slate600,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.slate400,
  );
  static const TextStyle labelSemibold = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.slate900,
  );
  static const TextStyle buttonText = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: Colors.white,
  );

  // Eyebrow — JetBrains Mono
  static const TextStyle eyebrow = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: AppColors.primary600,
  );
  static const TextStyle eyebrowMuted = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: AppColors.slate400,
  );
  static const TextStyle monoSmall = TextStyle(
  fontFamily: 'JetBrainsMono',
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: AppColors.slate600,
  );
  static const TextStyle monoNumber = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.primary900,
  );
}