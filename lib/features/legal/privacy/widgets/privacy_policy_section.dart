import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../data/privacy_policy_model.dart';

class PrivacyPolicySection extends StatelessWidget {
  const PrivacyPolicySection({super.key, required this.section});

  final PrivacyPolicySectionData section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...section.paragraphs.map(
          (paragraph) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              paragraph,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                height: 1.65,
                color: AppColors.text,
              ),
            ),
          ),
        ),
        if (section.bulletPoints.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...section.bulletPoints.map(_bullet),
        ],
        if (section.subsections.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...section.subsections.map(_subsection),
        ],
      ],
    );
  }

  Widget _bullet(String item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.darkGold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                height: 1.6,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subsection(PrivacyPolicySubsection subsection) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            subsection.title,
            style: AppTextStyles.subtitle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          ...subsection.items.map(_bullet),
        ],
      ),
    );
  }
}
