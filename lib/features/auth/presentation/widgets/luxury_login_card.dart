import 'package:flutter/material.dart';

import '../../../../core/layout/auth_layout_metrics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/liquid_glass_surface.dart';
import '../../../../core/l10n/app_strings.dart';

class LuxuryLoginCard extends StatelessWidget {
  const LuxuryLoginCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final metrics = AuthLayoutMetrics.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: metrics.cardHorizontalPadding),
      child: Transform.translate(
        offset: Offset(0, metrics.isTablet ? 10 : 6),
        child: LiquidGlassSurface(
          borderRadius: BorderRadius.circular(metrics.isTablet ? 28 : 24),
          padding: EdgeInsets.zero,
          fillOpacity: 0.3,
          borderOpacity: 0.58,
          tintColor: AppColors.of(context).accent,
          tintOpacity: 0.06,
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: metrics.isTablet ? 12 : 10),
                width: metrics.isTablet ? 56 : 48,
                height: metrics.isTablet ? 5 : 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.of(context).accent,
                      AppColors.of(context).darkGold,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.cardInnerPadding,
                  metrics.isTablet ? 20 : 16,
                  metrics.cardInnerPadding,
                  metrics.cardVerticalPadding,
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginCardTitle extends StatelessWidget {
  const LoginCardTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = AuthLayoutMetrics.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Diamond(size: metrics.isTablet ? 8 : 7),
            SizedBox(width: metrics.isTablet ? 12 : 10),
            Text(AppStrings.of(context).t('تسجيل الدخول'),
              style: TextStyle(
                fontSize: metrics.titleFontSize,
                fontWeight: FontWeight.w800,
                color: AppColors.of(context).primary,
              ),
            ),
            SizedBox(width: metrics.isTablet ? 12 : 10),
            _Diamond(size: metrics.isTablet ? 8 : 7),
          ],
        ),
        SizedBox(height: metrics.isTablet ? 10 : 8),
        Text(AppStrings.of(context).t('أهلاً بك في منصة RSHD التعليمية'),
          style: TextStyle(
            fontSize: metrics.subtitleFontSize,
            color: AppColors.of(context).textMuted.withValues(alpha: 0.95),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Diamond extends StatelessWidget {
  const _Diamond({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785398,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.of(context).accent.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = AuthLayoutMetrics.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        metrics.cardInnerPadding,
        metrics.isLargeTablet ? 36 : 28,
        metrics.cardInnerPadding,
        metrics.bottomSpacing,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: AppColors.of(context).accent.withValues(alpha: 0.35),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Transform.rotate(
                  angle: 0.785398,
                  child: Container(
                    width: 6,
                    height: 6,
                    color: AppColors.of(context).accent.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: AppColors.of(context).accent.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(AppStrings.of(context).t('RSHD LEARNING PLATFORM'),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).secondary.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
