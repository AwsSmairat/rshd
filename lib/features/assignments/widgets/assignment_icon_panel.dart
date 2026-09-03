import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AssignmentIconPanel extends StatelessWidget {
  const AssignmentIconPanel({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.of(context).primary,
                AppColors.of(context).secondaryNavy,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.of(context).primary.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Icon(icon, color: AppColors.of(context).accent, size: 24),
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
              color: AppColors.of(context).accent.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.of(context).darkGold.withValues(alpha: 0.35),
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
