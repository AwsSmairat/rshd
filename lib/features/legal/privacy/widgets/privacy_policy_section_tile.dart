import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../data/privacy_policy_model.dart';
import 'privacy_policy_section.dart';

class PrivacyPolicySectionTile extends StatelessWidget {
  const PrivacyPolicySectionTile({
    super.key,
    required this.section,
    required this.isExpanded,
    required this.onToggle,
    this.trailing,
  });

  final PrivacyPolicySectionData section;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      expanded: isExpanded,
      label: section.title,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isExpanded
                ? AppColors.darkGold.withValues(alpha: 0.35)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: ValueKey('${section.id}-$isExpanded'),
            initiallyExpanded: isExpanded,
            onExpansionChanged: (expanded) {
              if (expanded != isExpanded) {
                onToggle();
              }
            },
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(section.icon, color: AppColors.darkGold, size: 18),
            ),
            title: Text(
              section.title,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            trailing: trailing ??
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                ),
            children: [
              PrivacyPolicySection(section: section),
            ],
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicyAccordion extends StatelessWidget {
  const PrivacyPolicyAccordion({
    super.key,
    required this.sections,
    required this.expandedIds,
    required this.onToggle,
    this.extraForSection,
  });

  final List<PrivacyPolicySectionData> sections;
  final Set<String> expandedIds;
  final ValueChanged<String> onToggle;
  final Widget? Function(PrivacyPolicySectionData section)? extraForSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final section in sections) ...[
          PrivacyPolicySectionTile(
            section: section,
            isExpanded: expandedIds.contains(section.id),
            onToggle: () => onToggle(section.id),
          ),
          if (extraForSection != null)
            extraForSection!(section) ?? const SizedBox.shrink(),
        ],
      ],
    );
  }
}
