import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../../../core/l10n/app_strings.dart';

class AssignmentsEmptyState extends StatelessWidget {
  const AssignmentsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      fillOpacity: 0.35,
      borderOpacity: 0.65,
      blurSigma: 16,
      tintColor: AppColors.of(context).accent,
      tintOpacity: 0.06,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.of(context).accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              color: AppColors.of(context).darkGold,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.of(context).t('لا توجد واجبات حالياً'),
            style: AppTextStyles.subtitleOf(context).copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.of(context).primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(AppStrings.of(context).t('ستظهر الواجبات هنا عند إضافتها من المدرّس'),
            style: AppTextStyles.bodyOf(context).copyWith(
              fontSize: 13,
              height: 1.5,
              color: AppColors.of(context).textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AssignmentsLoadingSkeleton extends StatelessWidget {
  const AssignmentsLoadingSkeleton({super.key, this.count = 3});

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
            fillOpacity: 0.3,
            borderOpacity: 0.55,
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
                      _SkeletonBox(width: 120, height: 14),
                      const SizedBox(height: 10),
                      _SkeletonBox(width: 170, height: 12),
                      const SizedBox(height: 12),
                      _SkeletonBox(width: 96, height: 24, radius: 20),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _SkeletonBox(width: 72, height: 88, radius: 16),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class AssignmentsErrorState extends StatelessWidget {
  const AssignmentsErrorState({
    super.key,
    required this.onRetry,
    this.message = 'تعذر تحميل الواجبات',
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
          Icon(
            Icons.error_outline,
            color: AppColors.of(context).error,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(AppStrings.of(context).t(message),
            style: AppTextStyles.bodyOf(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(AppStrings.of(context).t('إعادة المحاولة')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.of(context).primary,
              side: BorderSide(
                color: AppColors.of(context).accent.withValues(alpha: 0.6),
              ),
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
        color: AppColors.of(context).accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
