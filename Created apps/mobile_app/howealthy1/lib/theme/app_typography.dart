import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Howealthy Design System — Typography Tokens
/// All text styles use Google Fonts Poppins for a premium fintech feel.
/// Every screen must reference these tokens instead of inline TextStyles.
class AppTypography {
  AppTypography._();

  // ─── DISPLAY ──────────────────────────────────────────────
  /// Hero numbers — net worth, total balance (36pt bold)
  static TextStyle displayLarge({bool isDark = true}) => GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        height: 1.2,
        letterSpacing: -0.5,
      );

  /// Section hero titles (28pt bold)
  static TextStyle displayMedium({bool isDark = true}) => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        height: 1.3,
        letterSpacing: -0.3,
      );

  // ─── HEADLINE ─────────────────────────────────────────────
  /// Card titles, page headers (22pt semi-bold)
  static TextStyle headlineLarge({bool isDark = true}) => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        height: 1.3,
      );

  /// Sub-headings (18pt semi-bold)
  static TextStyle headlineMedium({bool isDark = true}) => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        height: 1.4,
      );

  /// Small headings, tab labels (16pt medium)
  static TextStyle headlineSmall({bool isDark = true}) => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        height: 1.4,
      );

  // ─── BODY ─────────────────────────────────────────────────
  /// Primary body text (16pt regular)
  static TextStyle bodyLarge({bool isDark = true}) => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        height: 1.5,
      );

  /// Standard body text (14pt regular)
  static TextStyle bodyMedium({bool isDark = true}) => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color:
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        height: 1.5,
      );

  /// Small body copy, dates (12pt regular)
  static TextStyle bodySmall({bool isDark = true}) => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color:
            isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
        height: 1.4,
      );

  // ─── LABEL ────────────────────────────────────────────────
  /// Button text (16pt semi-bold)
  static TextStyle labelLarge({bool isDark = true}) => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        height: 1.2,
      );

  /// Chip labels, small buttons (13pt medium)
  static TextStyle labelMedium({bool isDark = true}) => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color:
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        height: 1.2,
      );

  /// Captions, timestamps (11pt regular)
  static TextStyle labelSmall({bool isDark = true}) => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color:
            isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
        height: 1.2,
      );

  // ─── ACCENT STYLES ────────────────────────────────────────
  /// Teal-accented value display (for monetary amounts)
  static TextStyle amountLarge({bool isPositive = true}) => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: isPositive ? AppColors.income : AppColors.expense,
        height: 1.2,
      );

  static TextStyle amountMedium({bool isPositive = true}) =>
      GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isPositive ? AppColors.income : AppColors.expense,
        height: 1.2,
      );

  /// Gold accent text — for premium labels
  static TextStyle goldAccent({double size = 14}) => GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryGold,
        letterSpacing: 1.1,
        height: 1.2,
      );

  /// Teal accent text — for CTAs and highlights
  static TextStyle tealAccent({double size = 14}) => GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryTealAccent,
        height: 1.2,
      );

  /// Full Poppins TextTheme for ThemeData integration
  static TextTheme textTheme({bool isDark = true}) => TextTheme(
        displayLarge: displayLarge(isDark: isDark),
        displayMedium: displayMedium(isDark: isDark),
        headlineLarge: headlineLarge(isDark: isDark),
        headlineMedium: headlineMedium(isDark: isDark),
        headlineSmall: headlineSmall(isDark: isDark),
        bodyLarge: bodyLarge(isDark: isDark),
        bodyMedium: bodyMedium(isDark: isDark),
        bodySmall: bodySmall(isDark: isDark),
        labelLarge: labelLarge(isDark: isDark),
        labelMedium: labelMedium(isDark: isDark),
        labelSmall: labelSmall(isDark: isDark),
      );
}
