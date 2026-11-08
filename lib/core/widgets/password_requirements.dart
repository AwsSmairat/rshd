import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../security/password_policy.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The password rules as a live checklist under a new-password field: each
/// line ticks green as soon as the typed password meets it.
class PasswordRequirementsChecklist extends StatelessWidget {
  const PasswordRequirementsChecklist({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);
    const met = Color(0xFF16A34A);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: colors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.isEnglish
                ? 'Your password needs'
                : 'كلمة المرور يجب أن تحتوي على',
            style: AppTextStyles.captionOf(
              context,
            ).copyWith(fontWeight: FontWeight.w700, color: colors.text),
          ),
          const SizedBox(height: 8),
          for (final rule in PasswordPolicy.requirements)
            _RequirementLine(
              label: rule.label(strings),
              met: rule.isMetBy(password),
              metColor: met,
            ),
        ],
      ),
    );
  }
}

class _RequirementLine extends StatelessWidget {
  const _RequirementLine({
    required this.label,
    required this.met,
    required this.metColor,
  });

  final String label;
  final bool met;
  final Color metColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = met ? metColor : colors.textMuted;

    return Semantics(
      label:
          '$label، ${met ? AppStrings.of(context).t('متحقق') : AppStrings.of(context).t('غير متحقق')}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                met
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                key: ValueKey(met),
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppTextStyles.captionOf(context).copyWith(
                  color: met ? metColor : colors.textMuted,
                  fontWeight: met ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
