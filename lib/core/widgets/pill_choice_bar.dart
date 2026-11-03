import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// One option in a [PillChoiceBar]; [badge] shows a small count beside the
/// label (e.g. unread notifications).
class PillChoice<T> {
  const PillChoice(this.value, this.label, {this.badge});

  final T value;
  final String label;
  final int? badge;
}

/// A horizontal row of pill-shaped choices, edge to edge with the page
/// margin as its padding. Used for the study-year and notification filters.
class PillChoiceBar<T> extends StatelessWidget {
  const PillChoiceBar({
    super.key,
    required this.choices,
    required this.selected,
    required this.onChanged,
    this.padding = EdgeInsets.zero,
  });

  final List<PillChoice<T>> choices;
  final T selected;
  final ValueChanged<T> onChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        padding: padding,
        itemCount: choices.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final choice = choices[i];
          return PillChip(
            label: choice.label,
            badge: choice.badge,
            selected: choice.value == selected,
            onTap: () {
              if (choice.value == selected) return;
              HapticFeedback.selectionClick();
              onChanged(choice.value);
            },
          );
        },
      ),
    );
  }
}

class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? colors.accent : colors.primary;
    final onFill = isDark ? const Color(0xFF0B1F3A) : Colors.white;
    final count = badge ?? 0;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? fill : colors.cardWhite,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? fill
                  : colors.primary.withValues(alpha: isDark ? 0.25 : 0.10),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: fill.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? onFill : colors.text,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0B1F3A),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
