import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../presentation/grades_controller.dart';
import '../../../core/l10n/app_strings.dart';

class GradesSummaryCard extends StatelessWidget {
  const GradesSummaryCard({super.key, required this.state});

  final GradesListState state;

  @override
  Widget build(BuildContext context) {
    final average = state.averageGrade;
    final highest = state.highestGrade;

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(24),
      padding: EdgeInsets.zero,
      fillOpacity: 0.38,
      borderOpacity: 0.62,
      blurSigma: 16,
      tintColor: AppColors.of(context).accent,
      tintOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppColors.of(context).primary.withValues(alpha: 0.92),
                  AppColors.of(context).secondaryNavy.withValues(alpha: 0.88),
                ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.of(
                          context,
                        ).accent.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.of(
                            context,
                          ).accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        Icons.insights_rounded,
                        color: AppColors.of(context).accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(AppStrings.of(context).t('ملخص الدرجات'),
                      style: AppTextStyles.subtitleOf(context).copyWith(
                        color: AppColors.of(context).white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(AppStrings.of(context).t(average != null ? '${average.toStringAsFixed(1)}%' : '—'),
                  style: AppTextStyles.titleOf(context).copyWith(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: AppColors.of(context).white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(AppStrings.of(context).t('المتوسط العام'),
                  style: AppTextStyles.bodyOf(context).copyWith(
                    fontSize: 13,
                    color: AppColors.of(context).white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryStatTile(
                    icon: Icons.list_alt_rounded,
                    label: AppStrings.of(context).t('عدد الدرجات'),
                    value: '${state.count}',
                  ),
                ),
                Container(
                  width: 1,
                  height: 44,
                  color: AppColors.of(context).accent.withValues(alpha: 0.22),
                ),
                Expanded(
                  child: _SummaryStatTile(
                    icon: Icons.trending_up_rounded,
                    label: AppStrings.of(context).t('الأعلى'),
                    value: highest != null
                        ? '${highest.toStringAsFixed(1)}%'
                        : '—',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStatTile extends StatelessWidget {
  const _SummaryStatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.of(context).darkGold),
        const SizedBox(height: 6),
        Text(AppStrings.of(context).t(value),
          style: AppTextStyles.titleOf(context).copyWith(
            fontSize: 20,
            color: AppColors.of(context).primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(AppStrings.of(context).t(label),
          style: AppTextStyles.bodyOf(
            context,
          ).copyWith(fontSize: 12, color: AppColors.of(context).textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
