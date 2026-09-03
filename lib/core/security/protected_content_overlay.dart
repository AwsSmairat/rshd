import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Full-screen shield shown during capture or App Switcher privacy.
class ProtectedContentOverlay extends StatelessWidget {
  const ProtectedContentOverlay({super.key, this.showScreenshotNotice = false});

  final bool showScreenshotNotice;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: AppColors.of(context).primary,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.of(
                        context,
                      ).white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.of(
                          context,
                        ).accent.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: AppColors.of(context).accent,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'المحتوى محمي',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleOf(context).copyWith(
                      color: AppColors.of(context).white,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    showScreenshotNotice
                        ? 'تم التقاط لقطة شاشة. المحتوى التعليمي محمي ولا يجوز مشاركته.'
                        : 'أوقف تسجيل أو مشاركة الشاشة لعرض المحتوى.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyOf(context).copyWith(
                      color: AppColors.of(
                        context,
                      ).white.withValues(alpha: 0.82),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
