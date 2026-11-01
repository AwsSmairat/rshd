import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Light header: the RSHD mark in the middle, notifications on the end
/// side, then the greeting.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.studentName,
    required this.unreadCount,
  });

  final String studentName;
  final int unreadCount;

  static const _logoAsset = 'assets/images/rshd_logo_no_bg.png';

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 64,
          child: Row(
            children: [
              // Balances the bell so the logo stays centred; the account is
              // a tab of its own in the bar.
              const SizedBox(width: 48),
              Expanded(
                child: Center(
                  child: Image.asset(
                    _logoAsset,
                    height: 54,
                    fit: BoxFit.contain,
                    semanticLabel: 'RSHD',
                  ),
                ),
              ),
              _RoundButton(
                tooltip: strings.notifications,
                onTap: () => context.push(AppRoutes.notifications),
                child: Badge(
                  isLabelVisible: unreadCount > 0,
                  backgroundColor: colors.accent,
                  textColor: const Color(0xFF0B1F3A),
                  label: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${strings.greetingHello} '),
              TextSpan(
                text: studentName,
                style: TextStyle(color: colors.darkGold),
              ),
            ],
          ),
          style: AppTextStyles.subtitleOf(context).copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: colors.text,
            height: 1.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          strings.continueLearningToday,
          style: AppTextStyles.bodyOf(
            context,
          ).copyWith(fontSize: 14, color: colors.textMuted),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.cardWhite,
        shape: CircleBorder(
          side: BorderSide(color: colors.primary.withValues(alpha: 0.06)),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B1F3A).withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
