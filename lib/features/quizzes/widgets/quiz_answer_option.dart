import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// One answer of a multiple-choice question: a letter badge, the answer in
/// its own reading direction, and a clear selected state.
class QuizAnswerOption extends StatelessWidget {
  const QuizAnswerOption({
    super.key,
    required this.letter,
    required this.answerText,
    required this.isSelected,
    required this.onTap,
  });

  final String letter;
  final String answerText;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedFill = isDark
        ? colors.accent.withValues(alpha: 0.16)
        : colors.primary.withValues(alpha: 0.06);
    final selectedEdge = isDark ? colors.accent : colors.primary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$letter. $answerText',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? selectedFill : colors.cardWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? selectedEdge
                : colors.primary.withValues(alpha: isDark ? 0.22 : 0.09),
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: isSelected || isDark
              ? null
              : [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 16, 12),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? selectedEdge
                            : colors.primary.withValues(
                                alpha: isDark ? 0.18 : 0.06,
                              ),
                      ),
                      child: Text(
                        letter,
                        style: AppTextStyles.bodyOf(context).copyWith(
                          fontSize: 14,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? (isDark ? colors.primary : colors.white)
                              : (isDark ? colors.text : colors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        answerText,
                        style: AppTextStyles.bodyOf(context).copyWith(
                          fontSize: 16,
                          height: 1.45,
                          color: colors.text,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      scale: isSelected ? 1 : 0.6,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: isSelected ? 1 : 0,
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 22,
                          color: selectedEdge,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
