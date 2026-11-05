import 'package:flutter/material.dart';

import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/app_empty_state.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../../../core/l10n/app_strings.dart';

class QuizzesEmptyState extends StatelessWidget {
  const QuizzesEmptyState({super.key});

  @override
  Widget build(BuildContext context) => const AppEmptyState(
    icon: Icons.quiz_outlined,
    message: 'لا توجد اختبارات حالياً',
    subtitle: 'ستظهر الاختبارات هنا عند إضافتها من المدرّس',
  );
}

class QuizzesLoadingSkeleton extends StatelessWidget {
  const QuizzesLoadingSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) => Skeleton(child: _shapes(context));

  Widget _shapes(BuildContext context) {
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
                      SkeletonBox(width: double.infinity, height: 18),
                      const SizedBox(height: 10),
                      SkeletonBox(width: 130, height: 14),
                      const SizedBox(height: 8),
                      SkeletonBox(width: 150, height: 12),
                      const SizedBox(height: 10),
                      SkeletonBox(
                        width: double.infinity,
                        height: 28,
                        radius: 999,
                      ),
                      const SizedBox(height: 10),
                      SkeletonBox(width: 88, height: 24, radius: 20),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SkeletonBox(width: 72, height: 96, radius: 16),
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
          Icon(
            Icons.error_outline,
            color: AppColors.of(context).error,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.of(context).t(message),
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
