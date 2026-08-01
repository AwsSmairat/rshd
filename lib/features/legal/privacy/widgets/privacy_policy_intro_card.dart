import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PrivacyPolicyIntroCard extends StatelessWidget {
  const PrivacyPolicyIntroCard({
    super.key,
    required this.introText,
  });

  final String introText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            introText,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              height: 1.65,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.darkGold.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.darkGold,
                  size: 22,
                  semanticLabel: 'تنبيه',
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'باستخدامك للمنصة، فإنك تقر بأنك اطلعت على هذه السياسة '
                    'ووافقت عليها وفق الآليات المعتمدة في التطبيق.',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
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
