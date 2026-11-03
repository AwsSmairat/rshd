import 'dart:math' as math;

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
              const SizedBox(width: 52),
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
              _BellButton(
                unreadCount: unreadCount,
                tooltip: strings.notifications,
                onTap: () => context.push(AppRoutes.notifications),
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

/// Notifications button in the logo's colours: a navy tile with a fine gold
/// edge and a gold bell. New notifications show as a gold count badge, and
/// the bell gives a short ring whenever the count goes up.
class _BellButton extends StatefulWidget {
  const _BellButton({
    required this.unreadCount,
    required this.tooltip,
    required this.onTap,
  });

  final int unreadCount;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_BellButton> createState() => _BellButtonState();
}

class _BellButtonState extends State<_BellButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.unreadCount > 0) _ringSoon();
  }

  @override
  void didUpdateWidget(covariant _BellButton old) {
    super.didUpdateWidget(old);
    if (widget.unreadCount > old.unreadCount) _ringSoon();
  }

  void _ringSoon() {
    // After the page has settled, so the ring is noticed.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
      _ring.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  /// A damped swing: a few back-and-forth turns that fade out.
  double _angle(double t) => math.sin(t * math.pi * 6) * (1 - t) * 0.32;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final count = widget.unreadCount;
    const navy = Color(0xFF0B1F3A);
    final radius = BorderRadius.circular(16);

    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        label: count > 0 ? '${widget.tooltip}: $count' : widget.tooltip,
        excludeSemantics: true,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background, edge and shadow live on a plain box; the ripple
              // sits inside, clipped to the same rounded shape.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A3A66), navy],
                  ),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: navy.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  type: MaterialType.transparency,
                  borderRadius: radius,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.onTap,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _ring,
                        builder: (context, child) => Transform.rotate(
                          angle: _angle(_ring.value),
                          // Swing from the top, like a real bell.
                          alignment: const Alignment(0, -0.6),
                          child: child,
                        ),
                        child: Icon(
                          count > 0
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_rounded,
                          color: colors.accent,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (count > 0)
                PositionedDirectional(
                  top: -4,
                  end: -2,
                  child: IgnorePointer(
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: colors.background, width: 2),
                      ),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          fontSize: 10.5,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: navy,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
