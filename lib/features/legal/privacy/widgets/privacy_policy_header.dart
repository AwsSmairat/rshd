import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/app_layout_metrics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/responsive_content.dart';
import '../../../auth/presentation/widgets/login_header.dart';

class PrivacyPolicyHeader extends StatelessWidget {
  const PrivacyPolicyHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.lastUpdated,
  });

  final String title;
  final String subtitle;
  final String lastUpdated;

  static const _logoAsset = 'assets/images/rshd_logo.png';

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final metrics = AppLayoutMetrics.of(context);
    final canPop = context.canPop();

    return ClipPath(
      clipper: LoginHeaderWaveClipper(),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 220),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF091729),
              AppColors.primary,
              AppColors.secondaryNavy,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -16,
              top: topInset + 20,
              child: Icon(
                Icons.shield_outlined,
                size: 110,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            ResponsiveHeaderContent(
              padding: EdgeInsets.fromLTRB(
                metrics.horizontalPadding,
                topInset + 8,
                metrics.horizontalPadding,
                36,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (canPop)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Semantics(
                              label: 'رجوع',
                              button: true,
                              child: IconButton(
                                onPressed: () => context.pop(),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.privacy_tip_outlined,
                              color: AppColors.accent.withValues(alpha: 0.95),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: metrics.pageHeaderTitleFontSize,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Image.asset(
                            _logoAsset,
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.school_outlined,
                              color: AppColors.accent.withValues(alpha: 0.8),
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'آخر تحديث: $lastUpdated',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.accent.withValues(alpha: 0.95),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
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
