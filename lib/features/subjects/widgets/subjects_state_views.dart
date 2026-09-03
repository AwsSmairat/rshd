import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';

class SubjectsEmptyState extends StatelessWidget {
  const SubjectsEmptyState({
    super.key,
    this.message = 'لا توجد مواد مفعلة حالياً',
    this.subtitle = 'سيتم عرض المواد هنا بعد تفعيلها من الإدارة',
  });

  final String message;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      fillOpacity: 0.32,
      borderOpacity: 0.55,
      tintColor: AppColors.of(context).accent,
      tintOpacity: 0.06,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.of(context).accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book_outlined,
              color: AppColors.of(context).darkGold,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.subtitleOf(context).copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.of(context).primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
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

class SubjectsLoadingSkeleton extends StatelessWidget {
  const SubjectsLoadingSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 16),
          child: LiquidGlassSurface(
            borderRadius: BorderRadius.circular(22),
            padding: const EdgeInsets.all(18),
            fillOpacity: 0.28,
            borderOpacity: 0.5,
            child: SizedBox(
              height: 120,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(width: 56, height: 22),
                        const SizedBox(height: 12),
                        _SkeletonBox(width: double.infinity, height: 18),
                        const SizedBox(height: 8),
                        _SkeletonBox(width: 140, height: 14),
                        const SizedBox(height: 8),
                        _SkeletonBox(width: 190, height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _SkeletonBox(width: 58, height: 58, radius: 999),
                ],
              ),
            ),
          ),
        );
      }),
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

class SubjectsErrorState extends StatelessWidget {
  const SubjectsErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(24),
      fillOpacity: 0.3,
      borderOpacity: 0.52,
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.of(context).error,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            message,
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
            label: const Text('إعادة المحاولة'),
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
