import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../data/terms_and_conditions_model.dart';

class TermsSection extends StatelessWidget {
  const TermsSection({super.key, required this.section});

  final TermsSectionData section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...section.paragraphs.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              p,
              style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.65),
            ),
          ),
        ),
        if (section.bulletPoints.isNotEmpty)
          ...section.bulletPoints.map(_bullet),
        if (section.subsections.isNotEmpty)
          ...section.subsections.map(_subsection),
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
              style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subsection(TermsSubsection subsection) {
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

class TermsSectionTile extends StatelessWidget {
  const TermsSectionTile({
    super.key,
    required this.section,
    required this.isExpanded,
    required this.onToggle,
    this.trailing,
  });

  final TermsSectionData section;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            if (expanded != isExpanded) onToggle();
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
            ),
          ),
          trailing:
              trailing ??
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
              ),
          children: [TermsSection(section: section)],
        ),
      ),
    );
  }
}

class TermsAccordion extends StatelessWidget {
  const TermsAccordion({
    super.key,
    required this.sections,
    required this.expandedIds,
    required this.onToggle,
    this.extraForSection,
  });

  final List<TermsSectionData> sections;
  final Set<String> expandedIds;
  final ValueChanged<String> onToggle;
  final Widget? Function(TermsSectionData section)? extraForSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final section in sections) ...[
          TermsSectionTile(
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
