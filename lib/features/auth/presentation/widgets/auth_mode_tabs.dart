import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

/// Which form the unified auth screen is currently showing.
enum AuthTab { signIn, register }

/// Segmented sign-in / create-account selector with a sliding gold indicator.
///
/// Switching tabs never navigates — the parent swaps the form in place.
class AuthModeTabs extends StatelessWidget {
  const AuthModeTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AuthTab selected;
  final ValueChanged<AuthTab> onChanged;

  static const _duration = Duration(milliseconds: 300);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSignIn = selected == AuthTab.signIn;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / 2;

        return SizedBox(
          height: 56,
          child: Stack(
            children: [
              // Track.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark
                        ? colors.white.withValues(alpha: 0.06)
                        : colors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              // Sliding pill. AlignmentDirectional keeps it correct in RTL.
              AnimatedAlign(
                duration: _duration,
                curve: _curve,
                alignment: isSignIn
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    width: tabWidth - 8,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? colors.secondaryNavy
                          : colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(
                            alpha: isDark ? 0.35 : 0.08,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 44,
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            colors: [colors.accent, colors.darkGold],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: _TabLabel(
                      label: strings.t('تسجيل الدخول'),
                      isActive: isSignIn,
                      onTap: () => onChanged(AuthTab.signIn),
                    ),
                  ),
                  Expanded(
                    child: _TabLabel(
                      label: strings.t('إنشاء حساب'),
                      isActive: !isSignIn,
                      onTap: () => onChanged(AuthTab.register),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Semantics(
      button: true,
      selected: isActive,
      child: InkWell(
        onTap: isActive ? null : onTap,
        borderRadius: BorderRadius.circular(13),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: AuthModeTabs._duration,
            curve: AuthModeTabs._curve,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive ? colors.primary : colors.textMuted,
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}
