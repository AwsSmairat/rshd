import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/lesson_file_model.dart';

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
                ? AppColors.textMuted.withValues(alpha: 0.12)
                : AppColors.secondary.withValues(alpha: 0.12),
            child: Icon(
              locked ? Icons.lock_outline_rounded : file.fileIcon,
              color: locked ? AppColors.textMuted : AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  locked ? 'متاح بعد تفعيل المادة' : file.fileTypeLabel,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (!locked) ...[
                  const SizedBox(height: 2),
                  Text(
                    'الحجم: ${file.formattedSize}',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.secondary,
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
            color: locked ? AppColors.textMuted : AppColors.primary,
          ),
        ],
      ),
    );
  }
}
