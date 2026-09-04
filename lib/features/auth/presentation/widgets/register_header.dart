import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'login_header.dart';
import '../../../../core/l10n/app_strings.dart';

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key});

  static const _logoAsset = 'assets/images/rshd_logo_no_bg.png';

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

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
              AppColors.of(context).secondary,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -24,
              top: topInset + 16,
              child: Icon(
                Icons.school_outlined,
                size: 110,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Positioned(
              right: 8,
              top: topInset + 16,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.of(context).accent.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  size: 32,
                  color: AppColors.of(context).accent.withValues(alpha: 0.35),
                ),
              ),
            ),
            Positioned(
              top: topInset + 4,
              left: 4,
              child: IconButton(
                tooltip: AppStrings.of(context).t('رجوع'),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.login);
                  }
                },
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.of(context).accent,
                  size: 20,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, topInset + 24, 24, 36),
              child: Center(
                child: Image.asset(
                  _logoAsset,
                  height: 96,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.school_outlined,
                      size: 56,
                      color: AppColors.of(
                        context,
                      ).accent.withValues(alpha: 0.85),
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
