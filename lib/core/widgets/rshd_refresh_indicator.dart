import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'rshd_loader.dart';

/// Pull-to-refresh with the RSHD mark instead of the Material spinner.
///
/// A small capsule slides down from the top as the page is pulled; its
/// letters light up one by one with the pull, all four once a release will
/// refresh (with a light haptic tick), then run the loading wave until
/// [onRefresh] completes. It floats over the page, so it behaves the same with
/// iOS bouncing and Android clamping scroll physics.
///
/// Takes the same arguments as [RefreshIndicator] so screens can switch over
/// without other changes; [color], [backgroundColor] and [displacement] are
/// accepted for that reason and the brand colours are used instead.
class RshdRefreshIndicator extends StatelessWidget {
  const RshdRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.edgeOffset = 0,
    this.color,
    this.backgroundColor,
    this.displacement,
    this.notificationPredicate = defaultScrollNotificationPredicate,
  });

  final RefreshCallback onRefresh;
  final Widget child;
  final double edgeOffset;
  final Color? color;
  final Color? backgroundColor;
  final double? displacement;
  final ScrollNotificationPredicate notificationPredicate;

  /// Pull distance that arms the refresh.
  static const _armDistance = 90.0;

  /// How far below the top edge the capsule rests while refreshing.
  static const _restOffset = 14.0;

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      offsetToArmed: _armDistance,
      notificationPredicate: notificationPredicate,
      onStateChanged: (change) {
        if (change.didChange(to: IndicatorState.armed)) {
          HapticFeedback.lightImpact();
        }
      },
      builder: (context, child, controller) {
        final top =
            (edgeOffset > 0 ? edgeOffset : MediaQuery.paddingOf(context).top) +
            _restOffset;
        return Stack(
          children: [
            child,
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final value = controller.value.clamp(0.0, 1.5);
                if (value == 0 && controller.isIdle) {
                  return const SizedBox.shrink();
                }
                final shown = value.clamp(0.0, 1.0);
                return Positioned(
                  top: top - 56 * (1 - shown),
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Opacity(
                        opacity: shown,
                        child: Transform.scale(
                          scale: 0.86 + 0.14 * shown + (value > 1 ? 0.04 : 0),
                          child: _Capsule(
                            progress: shown,
                            busy:
                                controller.isLoading ||
                                controller.isSettling ||
                                controller.isComplete,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      child: child,
    );
  }
}

class _Capsule extends StatelessWidget {
  const _Capsule({required this.progress, required this.busy});

  /// 0..1 pull progress; lights the letters one by one.
  final double progress;

  /// Refresh running: show the loading wave.
  final bool busy;

  static const _letterSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rest = (isDark ? colors.white : colors.primary).withValues(
      alpha: 0.2,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 11),
      decoration: BoxDecoration(
        color: colors.cardWhite,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1F3A).withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: busy
            ? RshdLoader(
                key: const ValueKey('busy'),
                size: _letterSize,
                baseColor: rest,
              )
            : _PullLetters(
                key: const ValueKey('pull'),
                progress: progress,
                lit: colors.accent,
                rest: rest,
                size: _letterSize,
              ),
      ),
    );
  }
}

/// The letters filling in with the pull: each one lights over its quarter of
/// the distance, so all four are gold exactly when the refresh is armed.
class _PullLetters extends StatelessWidget {
  const _PullLetters({
    super.key,
    required this.progress,
    required this.lit,
    required this.rest,
    required this.size,
  });

  final double progress;
  final Color lit;
  final Color rest;
  final double size;

  static const _letters = ['R', 'S', 'H', 'D'];

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: size,
      height: 1,
      fontWeight: FontWeight.w900,
      letterSpacing: size * 0.04,
      fontFamily: DefaultTextStyle.of(context).style.fontFamily,
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        // Matches RshdLoader's headroom so the swap does not jump.
        padding: EdgeInsets.only(top: size * 0.2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _letters.length; i++)
              Builder(
                builder: (context) {
                  final t = (progress * _letters.length - i).clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: Offset(0, (1 - t) * size * 0.12),
                    child: Text(
                      _letters[i],
                      style: style.copyWith(color: Color.lerp(rest, lit, t)),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
