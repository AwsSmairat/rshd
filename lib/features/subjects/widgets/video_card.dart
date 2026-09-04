import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/video_model.dart';
import '../../../core/l10n/app_strings.dart';

class VideoCard extends StatelessWidget {
  const VideoCard({super.key, required this.video, required this.onTap});

  final VideoModel video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = video.isLocked;

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
                : AppColors.of(context).primary.withValues(alpha: 0.12),
            child: Icon(
              locked ? Icons.lock_outline_rounded : Icons.play_arrow_rounded,
              color: locked
                  ? AppColors.of(context).textMuted
                  : AppColors.of(context).primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.of(context).t(video.title),
                  style: AppTextStyles.bodyOf(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(AppStrings.of(context).t('المدة: ${video.formattedDuration}'),
                  style: AppTextStyles.bodyOf(context).copyWith(
                    color: AppColors.of(context).textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (video.isFree)
                      _Badge(
                        label: AppStrings.of(context).t('مجاني'),
                        color: AppColors.of(context).secondary,
                      ),
                    if (locked)
                      _Badge(
                        label: AppStrings.of(context).t('مقفل'),
                        color: AppColors.of(context).textMuted,
                      )
                    else
                      _Badge(
                        label: AppStrings.of(context).t(video.statusLabel),
                        color: AppColors.of(context).secondary,
                      ),
                  ],
                ),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(AppStrings.of(context).t(label),
        style: AppTextStyles.bodyOf(
          context,
        ).copyWith(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
