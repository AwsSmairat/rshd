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
              style: AppTextStyles.bodyOf(
                context,
              ).copyWith(fontSize: 14, height: 1.65),
            ),
          ),
        ),
        if (section.bulletPoints.isNotEmpty)
          ...section.bulletPoints.map((item) => _bullet(context, item)),
        if (section.subsections.isNotEmpty)
          ...section.subsections.map((item) => _subsection(context, item)),
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
            child: Text(
              item,
              style: AppTextStyles.bodyOf(
                context,
              ).copyWith(fontSize: 14, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subsection(BuildContext context, TermsSubsection subsection) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            subsection.title,
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
        color: AppColors.of(context).cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded
              ? AppColors.of(context).darkGold.withValues(alpha: 0.35)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.of(context).primary.withValues(alpha: 0.04),
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
              color: AppColors.of(context).background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              section.icon,
              color: AppColors.of(context).darkGold,
              size: 18,
            ),
          ),
          title: Text(
            section.title,
            style: AppTextStyles.bodyOf(
              context,
            ).copyWith(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          trailing:
              trailing ??
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.of(context).textMuted,
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
