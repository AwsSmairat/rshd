import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Full-width action under the player.
class FloatingPlaybackLaunchBar extends StatelessWidget {
  const FloatingPlaybackLaunchBar({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.picture_in_picture_alt_rounded, size: 20),
        label: const Text('تشغيل عائم داخل التطبيق'),
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: AppTextStyles.bodyOf(
            context,
          ).copyWith(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
    );
  }
}
