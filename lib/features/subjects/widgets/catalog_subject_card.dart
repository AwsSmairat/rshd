import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/rshd_loader.dart';
import '../data/models/subject_model.dart';

const _navy = Color(0xFF0B1F3A);

/// A course in a department list, in the same style as the home screen's
/// "continue" cards: the cover fills the card under a navy wash, with the
/// title, instructor and the enrolment action on top.
class CatalogSubjectCard extends StatelessWidget {
  const CatalogSubjectCard({
    super.key,
    required this.subject,
    required this.onTap,
    this.onRequestPurchase,
    this.isRequesting = false,
  });

  final SubjectModel subject;
  final VoidCallback onTap;
  final VoidCallback? onRequestPurchase;
  final bool isRequesting;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final instructor = subject.instructor?.name;
    final radius = BorderRadius.circular(20);
    final url = subject.resolvedCoverImageUrl;

    return SizedBox(
      height: 168,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            color: _navy,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (url != null)
                    Image(
                      image: cachedImage(url),
                      fit: BoxFit.cover,
                      // The artwork below the poster's own title.
                      alignment: const Alignment(0, 0.35),
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.centerStart,
                        end: AlignmentDirectional.centerEnd,
                        stops: [0.0, 0.6, 1.0],
                        colors: [
                          Color(0xF20B1F3A),
                          Color(0xB30B1F3A),
                          Color(0x330B1F3A),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (subject.studyYear != null)
                              _Tag(strings.studyYearLabel(subject.studyYear!)),
                            const Spacer(),
                            Icon(
                              Directionality.of(context) == TextDirection.rtl
                                  ? Icons.chevron_left_rounded
                                  : Icons.chevron_right_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          strings.t(subject.title),
                          style: AppTextStyles.bodyOf(context).copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (instructor != null && instructor.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            strings.t(instructor),
                            style: AppTextStyles.bodyOf(context).copyWith(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _Action(
                          subject: subject,
                          onRequestPurchase: onRequestPurchase,
                          isRequesting: isRequesting,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Enrolled, waiting for activation, or a button to request access.
class _Action extends StatelessWidget {
  const _Action({
    required this.subject,
    required this.onRequestPurchase,
    required this.isRequesting,
  });

  final SubjectModel subject;
  final VoidCallback? onRequestPurchase;
  final bool isRequesting;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);

    if (subject.isEnrollmentActive) {
      return _Status(
        icon: Icons.check_circle_rounded,
        label: strings.enrolledBadge,
        color: const Color(0xFF4ADE80),
      );
    }
    if (subject.isEnrollmentPending) {
      return _Status(
        icon: Icons.schedule_rounded,
        label: strings.awaitingActivation,
        color: colors.accent,
      );
    }
    if (onRequestPurchase == null) return const SizedBox.shrink();

    return SizedBox(
      height: 38,
      child: FilledButton(
        onPressed: isRequesting ? null : onRequestPurchase,
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          disabledBackgroundColor: colors.accent.withValues(alpha: 0.7),
          foregroundColor: _navy,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: isRequesting
            ? const RshdLoader(size: 12, color: _navy)
            : Text(
                strings.requestPurchase,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
