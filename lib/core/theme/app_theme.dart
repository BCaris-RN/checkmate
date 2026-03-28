import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/design_tokens.g.dart';

class AppTheme {
  static ThemeData light() {
    GoogleFonts.config.allowRuntimeFetching = false;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
      surface: AppColors.surface,
    );

    TextStyle textStyle({
      required String family,
      required double size,
      required Color color,
      FontWeight weight = FontWeight.w400,
      double? height,
      double letterSpacing = 0,
    }) {
      return GoogleFonts.getFont(
        family,
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: TextTheme(
        displayLarge: textStyle(
          family: AppFonts.displayFamily,
          size: AppTypography.displayXL,
          color: AppColors.textPrimary,
          height: AppTypography.displayLineHeight,
        ),
        displayMedium: textStyle(
          family: AppFonts.displayFamily,
          size: AppTypography.displayMD,
          color: AppColors.textPrimary,
          height: AppTypography.displayLineHeight,
        ),
        bodyLarge: textStyle(
          family: AppFonts.bodyFamily,
          size: AppTypography.bodyMD,
          color: AppColors.textPrimary,
          height: AppTypography.bodyLineHeight,
        ),
        bodyMedium: textStyle(
          family: AppFonts.bodyFamily,
          size: AppTypography.bodyMD,
          color: AppColors.textMuted,
          height: AppTypography.bodyLineHeight,
        ),
        labelLarge: textStyle(
          family: AppFonts.bodyFamily,
          size: AppTypography.labelMD,
          color: AppColors.textMuted,
          weight: FontWeight.w600,
          height: AppTypography.labelLineHeight,
          letterSpacing: 0.08,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.textPrimary.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
          borderSide: BorderSide(
            color: AppColors.textPrimary.withValues(alpha: 0.10),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
          borderSide: BorderSide(
            color: AppColors.textPrimary.withValues(alpha: 0.10),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
          borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.85)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.grid4,
          vertical: AppSpacing.grid4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.surface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.grid4,
            vertical: AppSpacing.grid4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.small),
          ),
          textStyle: textStyle(
            family: AppFonts.bodyFamily,
            size: AppTypography.bodyMD,
            color: AppColors.surface,
            weight: FontWeight.w600,
            height: AppTypography.bodyLineHeight,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.14)),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.grid4,
            vertical: AppSpacing.grid4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.small),
          ),
          textStyle: textStyle(
            family: AppFonts.bodyFamily,
            size: AppTypography.bodyMD,
            color: AppColors.textPrimary,
            weight: FontWeight.w600,
            height: AppTypography.bodyLineHeight,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.textPrimary.withValues(alpha: 0.12),
        thickness: 1,
        space: AppSpacing.grid8,
      ),
    );
  }
}
