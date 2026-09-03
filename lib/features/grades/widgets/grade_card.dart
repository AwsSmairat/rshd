import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/grade_model.dart';
import 'grade_type_badge.dart';

class GradeCard extends StatelessWidget {
  const GradeCard({super.key, required this.grade, required this.onTap});

  final GradeModel grade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradeValue = grade.gradeValue ?? 0;
    final accent = _gradeAccent(context, gradeValue);

    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      fillOpacity: 0.35,
      borderOpacity: 0.65,
      blurSigma: 16,
      tintColor: AppColors.of(context).accent,
      tintOpacity: 0.04,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        grade.displayTitle,
                        style: AppTextStyles.titleOf(context).copyWith(
                          fontSize: 17,
                          height: 1.3,
                          color: AppColors.of(context).primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accent.withValues(alpha: 0.45),
                            AppColors.of(context).darkGold,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (grade.subjectTitle != null &&
                    grade.subjectTitle!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    grade.subjectTitle!,
                    style: AppTextStyles.bodyOf(context).copyWith(
                      fontSize: 13,
                      color: AppColors.of(context).textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    GradeTypeBadge(sourceType: grade.sourceType),
                    if (grade.createdAt != null &&
                        grade.createdAt!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: AppColors.of(
                          context,
                        ).textMuted.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(grade.createdAt!),
                        style: AppTextStyles.bodyOf(context).copyWith(
                          fontSize: 12,
                          color: AppColors.of(context).textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _GradeScoreRing(value: gradeValue, accent: accent),
          const SizedBox(width: 6),
          Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: AppColors.of(context).primary.withValues(alpha: 0.55),
          ),
        ],
      ),
    );
  }

  Color _gradeAccent(BuildContext context, double value) {
    if (value >= 85) return AppColors.of(context).darkGold;
    if (value >= 70) return AppColors.of(context).accent;
    if (value >= 50) return AppColors.of(context).secondary;
    return AppColors.of(context).error.withValues(alpha: 0.85);
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat('yyyy/MM/dd', 'ar').format(parsed.toLocal());
  }
}

class _GradeScoreRing extends StatelessWidget {
  const _GradeScoreRing({required this.value, required this.accent});

  final double value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final progress = (value / 100).clamp(0.0, 1.0);

    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: AppColors.of(
                context,
              ).accent.withValues(alpha: 0.14),
              color: accent,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value % 1 == 0 ? '${value.toInt()}' : value.toStringAsFixed(1),
                style: AppTextStyles.titleOf(context).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.of(context).primary,
                  height: 1,
                ),
              ),
              Text(
                '%',
                style: AppTextStyles.bodyOf(context).copyWith(
                  fontSize: 10,
                  color: AppColors.of(context).textMuted,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
