import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/subject_model.dart';
import 'subject_grouping_helper.dart';
import 'subject_icon_helper.dart';

class LuxurySubjectCard extends StatelessWidget {
  const LuxurySubjectCard({
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

  Color get _accent {
    switch (SubjectGroupingHelper.resolveCategoryKey(subject)) {
      case 'medicine':
        return const Color(0xFF0F766E);
      case 'it':
        return const Color(0xFF234E70);
      case 'engineering':
        return AppColors.darkGold;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructorName = subject.instructor?.name;
    final coverUrl = subject.resolvedCoverImageUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 196,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.glassShadow.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (coverUrl != null)
                  Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _FallbackCover(accent: _accent, subject: subject);
                    },
                  )
                else
                  _FallbackCover(accent: _accent, subject: subject),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x330B1F3A),
                        Color(0x990B1F3A),
                        Color(0xE60B1F3A),
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 22,
                  child: Container(
                    width: 10,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.95),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(6),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _OverlayChip(label: subject.categoryLabel),
                          const Spacer(),
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        subject.title,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 20,
                          height: 1.2,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Color(0x66000000),
                              blurRadius: 8,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (instructorName != null &&
                          instructorName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'المدرّس: $instructorName',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (!subject.isEnrollmentActive) ...[
                        const SizedBox(height: 10),
                        if (subject.isEnrollmentPending)
                          _OverlayChip(
                            label: 'بانتظار تفعيل الإدارة',
                            emphasize: true,
                          )
                        else if (onRequestPurchase != null)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed:
                                  isRequesting ? null : onRequestPurchase,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isRequesting ? 'جاري الإرسال...' : 'طلب شراء',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({
    required this.label,
    this.emphasize = false,
  });

  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: emphasize
                ? AppColors.accent.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: emphasize ? AppColors.accent : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({
    required this.accent,
    required this.subject,
  });

  final Color accent;
  final SubjectModel subject;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent,
            AppColors.primary,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          SubjectIconHelper.iconForSubject(subject),
          color: Colors.white.withValues(alpha: 0.35),
          size: 64,
        ),
      ),
    );
  }
}
