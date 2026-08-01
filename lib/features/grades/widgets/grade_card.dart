import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/grade_model.dart';
import 'grade_type_badge.dart';

class GradeCard extends StatelessWidget {
  const GradeCard({
    super.key,
    required this.grade,
    required this.onTap,
  });

  final GradeModel grade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GradeTypeBadge(sourceType: grade.sourceType),
                    const SizedBox(height: 10),
                    Text(
                      grade.displayTitle,
                      style: AppTextStyles.title.copyWith(fontSize: 17),
                    ),
                    if (grade.subjectTitle != null &&
                        grade.subjectTitle!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        grade.subjectTitle!,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (grade.createdAt != null &&
                        grade.createdAt!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(grade.createdAt!),
                        style: AppTextStyles.body.copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    '${grade.grade}%',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 22,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.arrow_back_ios_new, size: 16),
                ],
              ),
            ],
          ),
    );
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat('yyyy/MM/dd', 'ar').format(parsed.toLocal());
  }
}
