import 'package:flutter/material.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../auth/presentation/widgets/login_header.dart';

class StudentSettingsHeader extends StatelessWidget {
  const StudentSettingsHeader({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.onBack,
  });

  final String name;
  final String? avatarUrl;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final metrics = AppLayoutMetrics.of(context);

    return ClipPath(
      clipper: LoginHeaderWaveClipper(),
      child: Container(
        width: double.infinity,
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
                tooltip: 'رجوع',
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.white,
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
                    'إعدادات الطالب',
                    style: AppTextStyles.subtitle.copyWith(
                      fontSize: metrics.pageHeaderTitleFontSize,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _Avatar(url: avatarUrl),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTextStyles.title.copyWith(
                                fontSize: metrics.isTablet ? 24 : 22,
                                color: AppColors.white,
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
                                color: AppColors.darkGold.withValues(
                                  alpha: 0.9,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.school_outlined,
                                    size: 14,
                                    color: AppColors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'طالب',
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
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
                        AppColors.accent.withValues(alpha: 0.1),
                        AppColors.accent,
                        AppColors.accent.withValues(alpha: 0.1),
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
  const _Avatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent, width: 2),
        color: AppColors.primary.withValues(alpha: 0.35),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url!.isNotEmpty
          ? Image.network(url!, fit: BoxFit.cover)
          : const Icon(Icons.person_outline, color: AppColors.accent, size: 36),
    );
  }
}
