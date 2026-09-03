import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/help_center_model.dart';

class HelpSupportCard extends StatelessWidget {
  const HelpSupportCard({super.key, required this.onContact});

  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.of(context).primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.support_agent_outlined,
                  color: AppColors.of(context).primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الدعم الفني',
                      style: AppTextStyles.subtitleOf(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    Text(
                      'تواصل مع إدارة المنصة للمساعدة التقنية',
                      style: AppTextStyles.bodyOf(context).copyWith(
                        fontSize: 12,
                        color: AppColors.of(context).textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onContact,
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('بدء محادثة الدعم الفني'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.of(context).primary,
              minimumSize: const Size(double.infinity, 46),
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

class HelpTeacherContactTile extends StatelessWidget {
  const HelpTeacherContactTile({
    super.key,
    required this.teacher,
    required this.onContact,
  });

  final TeacherContactModel teacher;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.of(context).accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_outline,
              color: AppColors.of(context).darkGold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher.subjectTitle,
                  style: AppTextStyles.bodyOf(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  teacher.instructorName,
                  style: AppTextStyles.bodyOf(context).copyWith(
                    fontSize: 12,
                    color: AppColors.of(context).textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'رسالة داخل المنصة',
                  style: AppTextStyles.bodyOf(context).copyWith(
                    fontSize: 11,
                    color: AppColors.of(context).darkGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onContact,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.of(context).darkGold,
              side: BorderSide(color: AppColors.of(context).darkGold),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('تواصل', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
