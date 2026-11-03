import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Empty list message: a layered emblem with the department's icon, a clear
/// title, one line of guidance, and an optional way out. Sized to its
/// content (no stretched panel).
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.subtitle = '',
    this.icon = Icons.auto_stories_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? colors.accent : colors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 148,
            height: 148,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _Ring(size: 148, color: ink.withValues(alpha: 0.04)),
                _Ring(size: 116, color: ink.withValues(alpha: 0.06)),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF16345C), Color(0xFF0B1F3A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B1F3A).withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: colors.accent, size: 36),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            AppStrings.of(context).t(message),
            style: AppTextStyles.titleOf(context).copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: colors.text,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                AppStrings.of(context).t(subtitle),
                style: AppTextStyles.bodyOf(
                  context,
                ).copyWith(fontSize: 14, height: 1.6, color: colors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: ink,
                side: BorderSide(color: ink.withValues(alpha: 0.25)),
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
