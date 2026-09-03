import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle title([AppColors colors = AppColors.light]) =>
      TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.text);

  static TextStyle subtitle([AppColors colors = AppColors.light]) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: colors.textMuted,
  );

  static TextStyle body([AppColors colors = AppColors.light]) =>
      TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: colors.text);

  static TextStyle caption([AppColors colors = AppColors.light]) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: colors.textMuted,
  );

  static TextStyle button([AppColors colors = AppColors.light]) =>
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.white);

  static TextStyle error([AppColors colors = AppColors.light]) =>
      TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.error);

  static TextStyle titleOf(BuildContext context) =>
      title(AppColors.of(context));

  static TextStyle subtitleOf(BuildContext context) =>
      subtitle(AppColors.of(context));

  static TextStyle bodyOf(BuildContext context) => body(AppColors.of(context));

  static TextStyle captionOf(BuildContext context) =>
      caption(AppColors.of(context));

  static TextStyle buttonOf(BuildContext context) =>
      button(AppColors.of(context));

  static TextStyle errorOf(BuildContext context) =>
      error(AppColors.of(context));
}
