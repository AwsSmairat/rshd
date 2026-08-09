import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/liquid_glass_surface.dart';
import '../data/models/subject_model.dart';
import 'subject_icon_helper.dart';

class SubjectCoverPalette {
  SubjectCoverPalette._();

  static (Color start, Color end) gradientFor(SubjectModel subject) {
    switch (subject.category) {
      case 'medicine':
        return (const Color(0xFF7F1D1D), const Color(0xFF991B1B));
      case 'engineering':
        return (const Color(0xFF92400E), AppColors.darkGold);
      case 'it':
        return (const Color(0xFF1E3A8A), AppColors.primary);
      default:
        return (AppColors.secondaryNavy, AppColors.primary);
    }
  }
}

class SubjectDetailsHero extends StatelessWidget {
  const SubjectDetailsHero({super.key, required this.subject});

  final SubjectModel subject;

  @override
  Widget build(BuildContext context) {
    final (gradientStart, gradientEnd) = SubjectCoverPalette.gradientFor(
      subject,
    );
    final coverUrl = subject.resolvedCoverImageUrl;
    final topInset = MediaQuery.paddingOf(context).top;

    return SliverAppBar(
      expandedHeight: 248,
      pinned: true,
      stretch: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: Text(
        subject.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (coverUrl != null)
              Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _GradientCover(start: gradientStart, end: gradientEnd),
              )
            else
              _GradientCover(start: gradientStart, end: gradientEnd),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.62),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
            Positioned(
              top: topInset + 56,
              right: 20,
              child: _HeroBadge(label: subject.categoryLabel),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Icon(
                      SubjectIconHelper.iconForSubject(subject),
                      color: AppColors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          subject.title,
                          style: AppTextStyles.title.copyWith(
                            color: AppColors.white,
                            fontSize: 24,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subject.instructor?.name != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            subject.instructor!.name,
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubjectDetailsMetaCard extends StatelessWidget {
  const SubjectDetailsMetaCard({
    super.key,
    required this.subject,
    required this.lessonsCount,
    this.isRequesting = false,
    this.isCancelling = false,
    this.onRequestPurchase,
    this.onCancelPurchase,
  });

  final SubjectModel subject;
  final int lessonsCount;
  final bool isRequesting;
  final bool isCancelling;
  final VoidCallback? onRequestPurchase;
  final VoidCallback? onCancelPurchase;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(18),
      fillOpacity: 0.3,
      borderOpacity: 0.58,
      tintColor: AppColors.primary,
      tintOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: Icons.category_outlined,
                label: subject.categoryLabel,
              ),
              if (subject.price != null)
                _MetaChip(
                  icon: Icons.payments_outlined,
                  label: '${subject.price} د.أ',
                ),
              if (lessonsCount > 0)
                _MetaChip(
                  icon: Icons.view_module_outlined,
                  label: '$lessonsCount ${lessonsCount == 1 ? 'جزء' : 'أجزاء'}',
                ),
              if (subject.isEnrollmentActive)
                const _MetaChip(
                  icon: Icons.verified_outlined,
                  label: 'مفعّلة',
                  highlighted: true,
                )
              else if (subject.isEnrollmentPending)
                const _MetaChip(
                  icon: Icons.hourglass_top_rounded,
                  label: 'بانتظار التفعيل',
                  highlighted: true,
                ),
            ],
          ),
          if (subject.description != null &&
              subject.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              subject.description!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.text,
                height: 1.55,
              ),
            ),
          ],
          if (subject.isEnrollmentActive &&
              subject.progressPercent != null) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  'التقدم',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${subject.progressPercent!.round()}%',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: (subject.progressPercent! / 100).clamp(0, 1),
                backgroundColor: AppColors.accent.withValues(alpha: 0.18),
                color: AppColors.accent,
              ),
            ),
          ],
          if (!subject.isEnrollmentActive) ...[
            const SizedBox(height: 18),
            if (subject.isEnrollmentPending)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.darkGold,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'طلب الشراء قيد المراجعة. يمكنك مشاهدة الفيديوهات المجانية حتى يتم تفعيل المادة.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: (isCancelling || isRequesting)
                        ? null
                        : onCancelPurchase,
                    icon: isCancelling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close_rounded, size: 18),
                    label: Text(
                      isCancelling ? 'جاري الإلغاء...' : 'إلغاء طلب الشراء',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.45),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              )
            else
              _PurchaseButton(
                isRequesting: isRequesting,
                onPressed: onRequestPurchase,
              ),
            if (!subject.isEnrollmentPending) ...[
              const SizedBox(height: 10),
              Text(
                'معاينة المحتوى — الفيديوهات المجانية متاحة للمشاهدة',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class SubjectDetailsSectionHeader extends StatelessWidget {
  const SubjectDetailsSectionHeader({
    super.key,
    required this.title,
    this.count,
  });

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.accent, AppColors.darkGold],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: AppTextStyles.title.copyWith(fontSize: 20)),
        if (count != null && count! > 0) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _GradientCover extends StatelessWidget {
  const _GradientCover({required this.start, required this.end});

  final Color start;
  final Color end;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [start, end],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.accent.withValues(alpha: 0.22)
            : AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted
              ? AppColors.accent.withValues(alpha: 0.45)
              : AppColors.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: highlighted ? AppColors.darkGold : AppColors.secondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: highlighted ? AppColors.primary : AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseButton extends StatelessWidget {
  const _PurchaseButton({required this.isRequesting, this.onPressed});

  final bool isRequesting;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isRequesting ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isRequesting
                  ? [
                      AppColors.accent.withValues(alpha: 0.6),
                      AppColors.darkGold.withValues(alpha: 0.6),
                    ]
                  : const [AppColors.accent, AppColors.darkGold],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkGold.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: isRequesting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'طلب شراء المادة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
