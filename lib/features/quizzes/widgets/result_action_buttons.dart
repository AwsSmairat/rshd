import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class QuizActionButton extends StatelessWidget {
  const QuizActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.play_arrow_rounded,
    this.isPrimary = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondaryNavy],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.accent, size: 22),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.cardWhite.withValues(alpha: 0.85),
          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.65)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.darkGold, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultActionButtons extends StatelessWidget {
  const ResultActionButtons({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryIcon = Icons.description_outlined,
    this.tertiaryLabel,
    this.onTertiary,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final IconData secondaryIcon;
  final String? tertiaryLabel;
  final VoidCallback? onTertiary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuizActionButton(label: primaryLabel, onPressed: onPrimary),
        if (secondaryLabel != null && onSecondary != null) ...[
          const SizedBox(height: 12),
          QuizActionButton(
            label: secondaryLabel!,
            onPressed: onSecondary,
            icon: secondaryIcon,
            isPrimary: false,
          ),
        ],
        if (tertiaryLabel != null && onTertiary != null) ...[
          const SizedBox(height: 12),
          QuizActionButton(
            label: tertiaryLabel!,
            onPressed: onTertiary,
            icon: Icons.home_outlined,
            isPrimary: false,
          ),
        ],
      ],
    );
  }
}
