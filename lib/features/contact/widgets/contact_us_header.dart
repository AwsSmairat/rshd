import 'package:flutter/material.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../auth/presentation/widgets/login_header.dart';
import '../../../core/l10n/app_strings.dart';

class ContactUsHeader extends StatelessWidget {
  const ContactUsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final metrics = AppLayoutMetrics.of(context);
    final canPop = Navigator.canPop(context);

    return ClipPath(
      clipper: LoginHeaderWaveClipper(),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF091729),
              AppColors.of(context).primary,
              AppColors.of(context).secondaryNavy,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -16,
              top: topInset + 20,
              child: Icon(
                Icons.circle_outlined,
                size: 110,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Positioned(
              right: -8,
              top: topInset + 36,
              child: Icon(
                Icons.support_agent_outlined,
                size: 96,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.outerHorizontalInset,
                topInset + 12,
                metrics.outerHorizontalInset,
                28,
              ),
              child: ResponsiveContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (canPop)
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            tooltip: AppStrings.of(context).t('رجوع'),
                          )
                        else
                          const SizedBox(width: 48),
                        Expanded(
                          child: Text(AppStrings.of(context).t('تواصل معنا'),
                            style: AppTextStyles.titleOf(
                              context,
                            ).copyWith(color: Colors.white, fontSize: 22),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(AppStrings.of(context).t('نحن هنا لمساعدتك — اختر وسيلة التواصل المناسبة'),
                      style: AppTextStyles.bodyOf(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
