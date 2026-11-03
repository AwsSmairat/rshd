import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// The app's typeface, bundled under assets/fonts/tajawal.
const appFontFamily = 'Tajawal';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppColors.light, Brightness.light);

  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: isDark ? const Color(0xFF0B1F3A) : colors.white,
      secondary: colors.secondary,
      onSecondary: isDark ? const Color(0xFF0B1F3A) : colors.white,
      surface: colors.cardWhite,
      onSurface: colors.text,
      error: colors.error,
      onError: colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      // Tajawal for Arabic and Latin text across the app.
      fontFamily: appFontFamily,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: colors.background,
      dividerColor: isDark ? const Color(0x33F6F1E7) : const Color(0xFFE5E7EB),
      extensions: [colors],
      // Plain bars on the page colour, matching the light page headers.
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: appFontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: colors.text,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.cardWhite,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.cardWhite,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.darkGold,
        textColor: colors.text,
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      // Soft filled fields: a gentle surface and a faint edge at rest, a
      // warm gold edge while typing — easy on the eye, clear when active.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colors.white.withValues(alpha: 0.06)
            : colors.cardWhite,
        hoverColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? colors.white.withValues(alpha: 0.10)
                : colors.primary.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.darkGold, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.error.withValues(alpha: 0.7)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.error, width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.04)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        labelStyle: AppTextStyles.body(
          colors,
        ).copyWith(color: colors.textMuted, fontWeight: FontWeight.w600),
        floatingLabelStyle: AppTextStyles.body(
          colors,
        ).copyWith(color: colors.darkGold, fontWeight: FontWeight.w700),
        hintStyle: AppTextStyles.body(
          colors,
        ).copyWith(color: colors.textMuted.withValues(alpha: 0.7)),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? colors.darkGold
              : colors.textMuted,
        ),
        suffixIconColor: colors.textMuted,
        errorStyle: TextStyle(color: colors.error, fontSize: 12, height: 1.3),
      ),
      // Primary buttons: tall, rounded, navy (gold in dark mode), with a
      // calm disabled state instead of grey-on-grey.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? colors.accent : colors.primary,
          foregroundColor: isDark ? const Color(0xFF0B1F3A) : colors.white,
          disabledBackgroundColor: (isDark ? colors.accent : colors.primary)
              .withValues(alpha: 0.35),
          disabledForegroundColor:
              (isDark ? const Color(0xFF0B1F3A) : colors.white).withValues(
                alpha: 0.85,
              ),
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.button(
            colors,
          ).copyWith(fontSize: 15.5, fontWeight: FontWeight.w800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.button(
            colors,
          ).copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? colors.accent : colors.primary,
          minimumSize: const Size(0, 50),
          side: BorderSide(
            color: (isDark ? colors.accent : colors.primary).withValues(
              alpha: 0.22,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.button(
            colors,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.secondary,
          textStyle: AppTextStyles.body(
            colors,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
