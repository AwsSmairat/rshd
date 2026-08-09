import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class QuizIconPanel extends StatelessWidget {
  const QuizIconPanel({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondaryNavy],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Icon(icon, color: AppColors.accent, size: 26),
            ),
          ),
        ),
        Positioned(
          top: -2,
          left: 8,
          child: Container(
            width: 10,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkGold.withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
