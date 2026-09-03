import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class QuizStatItem extends StatelessWidget {
  const QuizStatItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.of(context).accent.withValues(alpha: 0.14),
            ),
            child: Icon(icon, size: 18, color: AppColors.of(context).darkGold),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTextStyles.bodyOf(
              context,
            ).copyWith(fontSize: 12, color: AppColors.of(context).textMuted),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyOf(context).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.of(context).primary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
