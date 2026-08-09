import 'package:flutter/material.dart';

import '../../../../core/layout/auth_layout_metrics.dart';
import '../../../../core/theme/app_colors.dart';

class LoginHeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 28)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height - 6,
        size.width * 0.5,
        size.height - 22,
      )
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height - 38,
        0,
        size.height - 18,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  static const _logoAsset = 'assets/images/rshd_logo.png';

  @override
  Widget build(BuildContext context) {
    final metrics = AuthLayoutMetrics.of(context);

    return ClipPath(
      clipper: LoginHeaderWaveClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF091729), AppColors.primary, AppColors.secondary],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -24,
              top: metrics.headerTopPadding,
              child: Icon(
                Icons.medical_services_outlined,
                size: metrics.headerIconSize,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Positioned(
              right: metrics.isLargeTablet ? 24 : 8,
              top: metrics.headerTopPadding + (metrics.isTablet ? 12 : 16),
              child: Container(
                width: metrics.headerBadgeSize,
                height: metrics.headerBadgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  size: metrics.isLargeTablet ? 38 : 32,
                  color: AppColors.accent.withValues(alpha: 0.35),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                metrics.headerTopPadding,
                24,
                metrics.headerBottomPadding,
              ),
              child: Center(
                child: Image.asset(
                  _logoAsset,
                  height: metrics.headerLogoHeight,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.medical_services_outlined,
                      size: metrics.headerLogoHeight * 0.6,
                      color: AppColors.accent.withValues(alpha: 0.8),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
