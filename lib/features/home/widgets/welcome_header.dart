import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/app_layout_metrics.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../auth/presentation/widgets/login_header.dart';
import 'notification_badge_button.dart';

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({
    super.key,
    required this.studentName,
    required this.unreadCount,
  });

  final String studentName;
  final int unreadCount;

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
              left: -24,
              top: topInset + 20,
              child: Icon(
                Icons.school_outlined,
                size: 120,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            Positioned(
              right: 12,
              top: topInset + 28,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.15),
                  ),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  size: 28,
                  color: AppColors.accent.withValues(alpha: 0.3),
                ),
              ),
            ),
            ResponsiveHeaderContent(
              padding: EdgeInsets.fromLTRB(
                metrics.horizontalPadding,
                topInset + 16,
                metrics.horizontalPadding,
                40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: AppTextStyles.title.copyWith(
                              fontSize: metrics.headerTitleFontSize,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                            children: [
                              const TextSpan(
                                text: 'مرحباً، ',
                                style: TextStyle(color: AppColors.accent),
                              ),
                              TextSpan(
                                text: studentName,
                                style: const TextStyle(color: AppColors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _HeaderIconButton(
                        icon: Icons.person_outline,
                        tooltip: 'الملف الشخصي',
                        onTap: () => context.push(AppRoutes.profile),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: NotificationBadgeButton(
                          unreadCount: unreadCount,
                          iconColor: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تابع تعلمك اليوم من منصة RSHD',
                    style: AppTextStyles.body.copyWith(
                      fontSize: metrics.isTablet ? 15 : 14,
                      color: AppColors.white.withValues(alpha: 0.82),
                    ),
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.18),
        ),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.white, size: 22),
      ),
    );
  }
}
