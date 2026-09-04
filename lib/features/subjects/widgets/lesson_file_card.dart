import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/lesson_file_model.dart';
import '../../../core/l10n/app_strings.dart';

class LessonFileCard extends StatelessWidget {
  const LessonFileCard({super.key, required this.file, required this.onTap});

  final LessonFileModel file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = file.isLocked;

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: locked
                ? AppColors.of(context).textMuted.withValues(alpha: 0.12)
                : AppColors.of(context).secondary.withValues(alpha: 0.12),
            child: Icon(
              locked ? Icons.lock_outline_rounded : file.fileIcon,
              color: locked
                  ? AppColors.of(context).textMuted
                  : AppColors.of(context).secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.of(context).t(file.title),
                  style: AppTextStyles.bodyOf(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(AppStrings.of(context).t(locked ? 'متاح بعد تفعيل المادة' : file.fileTypeLabel),
                  style: AppTextStyles.bodyOf(context).copyWith(
                    color: AppColors.of(context).textMuted,
                    fontSize: 12,
                  ),
                ),
                if (!locked) ...[
                  const SizedBox(height: 2),
                  Text(AppStrings.of(context).t('الحجم: ${file.formattedSize}'),
                    style: AppTextStyles.bodyOf(context).copyWith(
                      color: AppColors.of(context).secondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            locked ? Icons.lock_outline_rounded : Icons.arrow_back_ios_new,
            size: 16,
            color: locked
                ? AppColors.of(context).textMuted
                : AppColors.of(context).primary,
          ),
        ],
      ),
    );
  }
}
