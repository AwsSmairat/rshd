import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/widgets/login_header.dart';
import '../../../core/widgets/responsive_content.dart';
import 'quiz_icon_helper.dart';

class QuizzesHeader extends StatelessWidget {
  const QuizzesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final canPop = context.canPop();
    final metrics = AppLayoutMetrics.of(context);

    return ClipPath(
      clipper: LoginHeaderWaveClipper(),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 168),
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
              left: -24,
              top: topInset + 18,
              child: Icon(
                QuizIconHelper.sectionIcon,
                size: 110,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            Positioned(
              right: -10,
              top: topInset + 42,
              child: Container(
                width: 120,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.accent.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 48,
              child: Container(
                width: 80,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            ResponsiveHeaderContent(
              padding: EdgeInsets.fromLTRB(
                metrics.horizontalPadding,
                topInset + 8,
                metrics.horizontalPadding,
                40,
              ),
              child: SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'الاختبارات',
                      style: TextStyle(
                        fontSize: metrics.pageHeaderTitleFontSize,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    if (canPop)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _BackButton(onTap: () => context.pop()),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Center(
                child: Container(
                  width: 110,
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.12),
                        AppColors.accent,
                        AppColors.accent.withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.22),
            ),
          ),
          child: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}
