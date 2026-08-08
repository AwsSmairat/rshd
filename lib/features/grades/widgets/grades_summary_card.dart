import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../presentation/grades_controller.dart';

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
      tintColor: AppColors.accent,
      tintOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppColors.primary.withValues(alpha: 0.92),
                  AppColors.secondaryNavy.withValues(alpha: 0.88),
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
                        color: AppColors.accent.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: AppColors.accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'ملخص الدرجات',
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  average != null ? '${average.toStringAsFixed(1)}%' : '—',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'المتوسط العام',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: AppColors.white.withValues(alpha: 0.72),
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
                    label: 'عدد الدرجات',
                    value: '${state.count}',
                  ),
                ),
                Container(
                  width: 1,
                  height: 44,
                  color: AppColors.accent.withValues(alpha: 0.22),
                ),
                Expanded(
                  child: _SummaryStatTile(
                    icon: Icons.trending_up_rounded,
                    label: 'الأعلى',
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
        Icon(icon, size: 18, color: AppColors.darkGold),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.title.copyWith(
            fontSize: 20,
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
