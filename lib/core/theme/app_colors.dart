import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.secondary,
    required this.secondaryNavy,
    required this.accent,
    required this.darkGold,
    required this.background,
    required this.cardWhite,
    required this.glassToolbar,
    required this.glassShadow,
    required this.text,
    required this.textMuted,
    required this.error,
    required this.white,
    required this.backgroundGradient,
  });

  final Color primary;
  final Color secondary;
  final Color secondaryNavy;
  final Color accent;
  final Color darkGold;
  final Color background;
  final Color cardWhite;
  final Color glassToolbar;
  final Color glassShadow;
  final Color text;
  final Color textMuted;
  final Color error;
  final Color white;
  final List<Color> backgroundGradient;

  static const light = AppColors(
    primary: Color(0xFF0B1F3A),
    secondary: Color(0xFF234E70),
    secondaryNavy: Color(0xFF102A4C),
    accent: Color(0xFFD6B56D),
    darkGold: Color(0xFFB88A32),
    background: Color(0xFFF6F1E7),
    cardWhite: Color(0xFFFFFDF8),
    glassToolbar: Color(0xBFFFFFFF),
    glassShadow: Color(0xFF0B1F3A),
    text: Color(0xFF111827),
    textMuted: Color(0xFF6B7280),
    error: Color(0xFFB42318),
    white: Color(0xFFFFFFFF),
    backgroundGradient: [
      Color(0xFFF6F1E7),
      Color(0xFFEDE4D4),
      Color(0xFFE8EEF6),
    ],
  );

  static const dark = AppColors(
    primary: Color(0xFFD6B56D),
    secondary: Color(0xFFE4C98A),
    secondaryNavy: Color(0xFF1A3358),
    accent: Color(0xFFD6B56D),
    darkGold: Color(0xFFE4C98A),
    background: Color(0xFF07111F),
    cardWhite: Color(0xFF102A4C),
    glassToolbar: Color(0xE6102A4C),
    glassShadow: Color(0xFF000000),
    text: Color(0xFFF6F1E7),
    textMuted: Color(0xFFB7C0CC),
    error: Color(0xFFF97066),
    white: Color(0xFFFFFFFF),
    backgroundGradient: [
      Color(0xFF07111F),
      Color(0xFF0B1F3A),
      Color(0xFF102A4C),
    ],
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ?? light;
  }

  @override
  AppColors copyWith({
    Color? primary,
    Color? secondary,
    Color? secondaryNavy,
    Color? accent,
    Color? darkGold,
    Color? background,
    Color? cardWhite,
    Color? glassToolbar,
    Color? glassShadow,
    Color? text,
    Color? textMuted,
    Color? error,
    Color? white,
    List<Color>? backgroundGradient,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      secondaryNavy: secondaryNavy ?? this.secondaryNavy,
      accent: accent ?? this.accent,
      darkGold: darkGold ?? this.darkGold,
      background: background ?? this.background,
      cardWhite: cardWhite ?? this.cardWhite,
      glassToolbar: glassToolbar ?? this.glassToolbar,
      glassShadow: glassShadow ?? this.glassShadow,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      error: error ?? this.error,
      white: white ?? this.white,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryNavy: Color.lerp(secondaryNavy, other.secondaryNavy, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      darkGold: Color.lerp(darkGold, other.darkGold, t)!,
      background: Color.lerp(background, other.background, t)!,
      cardWhite: Color.lerp(cardWhite, other.cardWhite, t)!,
      glassToolbar: Color.lerp(glassToolbar, other.glassToolbar, t)!,
      glassShadow: Color.lerp(glassShadow, other.glassShadow, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      error: Color.lerp(error, other.error, t)!,
      white: Color.lerp(white, other.white, t)!,
      backgroundGradient: [
        for (var i = 0; i < backgroundGradient.length; i++)
          Color.lerp(backgroundGradient[i], other.backgroundGradient[i], t)!,
      ],
    );
  }
}
