import 'package:flutter/material.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../auth/presentation/widgets/login_header.dart';
import 'student_avatar_image.dart';

class StudentSettingsHeader extends StatelessWidget {
  const StudentSettingsHeader({
    super.key,
    required this.name,
    this.localAvatarPath,
    required this.onBack,
  });

  final String name;
  final String? localAvatarPath;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final metrics = AppLayoutMetrics.of(context);

    return ClipPath(
      clipper: LoginHeaderWaveClipper(),
      child: Container(
        width: double.infinity,
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
              left: -20,
              top: topInset + 24,
              child: Icon(
                Icons.circle_outlined,
                size: 120,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Positioned(
              right: -10,
              top: topInset + 40,
              child: Icon(
                Icons.person_outline,
                size: 100,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            Positioned(
              top: topInset + 4,
              left: 4,
              child: IconButton(
                tooltip: AppStrings.of(context).back,
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.of(context).white,
                  size: 18,
                ),
              ),
            ),
            ResponsiveHeaderContent(
              padding: EdgeInsets.fromLTRB(
                metrics.horizontalPadding,
                topInset + 8,
                metrics.horizontalPadding,
                44,
              ),
              child: Column(
                children: [
                  Text(
                    AppStrings.of(
                      context,
                    ).t(AppStrings.of(context).studentSettings),
                    style: AppTextStyles.subtitleOf(context).copyWith(
                      fontSize: metrics.pageHeaderTitleFontSize,
                      fontWeight: FontWeight.w700,
                      color: AppColors.of(context).white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _Avatar(localPath: localAvatarPath),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.of(context).t(name),
                              style: AppTextStyles.titleOf(context).copyWith(
                                fontSize: metrics.isTablet ? 24 : 22,
                                color: AppColors.of(context).white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.of(
                                  context,
                                ).darkGold.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 14,
                                    color: AppColors.of(context).white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppStrings.of(
                                      context,
                                    ).t(AppStrings.of(context).studentRole),
                                    style: AppTextStyles.bodyOf(context)
                                        .copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.of(context).white,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        'assets/images/rshd_logo_no_bg.png',
                        width: metrics.isTablet ? 56 : 48,
                        height: metrics.isTablet ? 56 : 48,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Center(
                child: Container(
                  width: 120,
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.of(context).accent.withValues(alpha: 0.1),
                        AppColors.of(context).accent,
                        AppColors.of(context).accent.withValues(alpha: 0.1),
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

class _Avatar extends StatelessWidget {
  const _Avatar({this.localPath});

  final String? localPath;

  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(
      Icons.person_outline,
      color: AppColors.of(context).accent,
      size: 36,
    );

    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.of(context).accent, width: 2),
        color: AppColors.of(context).primary.withValues(alpha: 0.35),
      ),
      clipBehavior: Clip.antiAlias,
      child: StudentAvatarImage(
        size: 78,
        localPath: localPath,
        placeholder: placeholder,
      ),
    );
  }
}
