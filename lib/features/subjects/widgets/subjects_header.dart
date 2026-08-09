import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/widgets/login_header.dart';
import '../../../core/widgets/responsive_content.dart';

class SubjectsHeader extends StatelessWidget {
  const SubjectsHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.backgroundIcon = Icons.menu_book_outlined,
  });

  final String title;
  final bool showBackButton;
  final IconData backgroundIcon;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final canPop = showBackButton && context.canPop();
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
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -20,
              top: topInset + 24,
              child: Icon(
                backgroundIcon,
                size: 96,
                color: Colors.white.withValues(alpha: 0.04),
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
                      title,
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
            border: Border.all(color: AppColors.white.withValues(alpha: 0.22)),
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
