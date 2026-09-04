import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../data/privacy_policy_model.dart';
import '../../../../core/l10n/app_strings.dart';

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
            child: Text(AppStrings.of(context).t(paragraph),
              style: AppTextStyles.bodyOf(context).copyWith(
                fontSize: 14,
                height: 1.65,
                color: AppColors.of(context).text,
              ),
            ),
          ),
        ),
        if (section.bulletPoints.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...section.bulletPoints.map((item) => _bullet(context, item)),
        ],
        if (section.subsections.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...section.subsections.map((item) => _subsection(context, item)),
        ],
      ],
    );
  }

  Widget _bullet(BuildContext context, String item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.of(context).darkGold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(AppStrings.of(context).t(item),
              style: AppTextStyles.bodyOf(context).copyWith(
                fontSize: 14,
                height: 1.6,
                color: AppColors.of(context).text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subsection(BuildContext context, PrivacyPolicySubsection subsection) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.of(context).t(subsection.title),
            style: AppTextStyles.subtitleOf(context).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.of(context).primary,
            ),
          ),
          const SizedBox(height: 6),
          ...subsection.items.map((item) => _bullet(context, item)),
        ],
      ),
    );
  }
}
