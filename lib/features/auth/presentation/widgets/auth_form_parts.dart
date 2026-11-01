import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

/// Inline banner for the server-side error message of the active form.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 19, color: colors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: colors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Informational banner (e.g. self-registration disabled by the platform).
class AuthNoticeBanner extends StatelessWidget {
  const AuthNoticeBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 19, color: colors.darkGold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: colors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hairline rule with a centred label, used above the social providers.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final lineColor = colors.textMuted.withValues(alpha: 0.22);

    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: colors.textMuted,
            ),
          ),
        ),
        Expanded(child: Divider(color: lineColor, height: 1)),
      ],
    );
  }
}

/// Eye toggle shared by every password field on the auth screen.
class AuthVisibilityToggle extends StatelessWidget {
  const AuthVisibilityToggle({
    super.key,
    required this.obscured,
    required this.onToggle,
  });

  final bool obscured;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return IconButton(
      tooltip: obscured ? strings.showPassword : strings.hidePassword,
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 21,
        color: AppColors.of(context).textMuted,
      ),
      onPressed: onToggle,
    );
  }
}

/// Shows which address the code was sent to.
class AuthEmailChip extends StatelessWidget {
  const AuthEmailChip({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? colors.white.withValues(alpha: 0.06)
            : colors.accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline_rounded, size: 19, color: colors.darkGold),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              email,
              // The address is data, not prose: keep it LTR even in Arabic.
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Countdown that turns into a "resend code" action once it reaches zero.
class AuthResendRow extends StatelessWidget {
  const AuthResendRow({
    super.key,
    required this.secondsRemaining,
    required this.isResending,
    required this.onResend,
  });

  final int secondsRemaining;
  final bool isResending;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final strings = AppStrings.of(context);
    final waiting = secondsRemaining > 0;

    if (waiting) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 16,
            color: colors.textMuted.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 8),
          Text(
            strings.resendIn(secondsRemaining),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
        ],
      );
    }

    return TextButton(
      onPressed: isResending ? null : onResend,
      style: TextButton.styleFrom(
        foregroundColor: colors.darkGold,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      child: Text(
        isResending ? strings.sending : strings.resendCode,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Themed "coming soon" notice for the not-yet-wired social providers.
void showComingSoonNotice(BuildContext context) {
  final strings = AppStrings.of(context);
  final colors = AppColors.of(context);

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.primary,
        elevation: 6,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(Icons.schedule_rounded, size: 20, color: colors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings.comingSoonNotice,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
