import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import 'quiz_icon_helper.dart';

class QuizzesEmptyState extends StatelessWidget {
  const QuizzesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      fillOpacity: 0.38,
      borderOpacity: 0.7,
      blurSigma: 16,
      tintColor: AppColors.accent,
      tintOpacity: 0.06,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              QuizIconHelper.sectionIcon,
              color: AppColors.darkGold,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد اختبارات حالياً',
            style: AppTextStyles.subtitle.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر الاختبارات هنا عند إضافتها من المدرّس',
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class QuizzesLoadingSkeleton extends StatelessWidget {
  const QuizzesLoadingSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 16),
          child: LiquidGlassSurface(
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(18),
            fillOpacity: 0.32,
            borderOpacity: 0.58,
            blurSigma: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SkeletonBox(width: double.infinity, height: 18),
                      const SizedBox(height: 10),
                      _SkeletonBox(width: 130, height: 14),
                      const SizedBox(height: 8),
                      _SkeletonBox(width: 150, height: 12),
                      const SizedBox(height: 10),
                      _SkeletonBox(width: double.infinity, height: 28, radius: 999),
                      const SizedBox(height: 10),
                      _SkeletonBox(width: 88, height: 24, radius: 20),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _SkeletonBox(width: 72, height: 96, radius: 16),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class QuizzesErrorState extends StatelessWidget {
  const QuizzesErrorState({
    super.key,
    required this.onRetry,
    this.message = 'تعذر تحميل الاختبارات',
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(24),
      fillOpacity: 0.32,
      borderOpacity: 0.58,
      blurSigma: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('إعادة المحاولة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.accent.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
