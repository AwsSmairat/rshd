import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/rshd_loader.dart';

/// Lifecycle of the primary auth action.
enum AuthButtonState {
  idle,

  /// Request in flight.
  loading,

  /// Accepted: the pill turns green and the arrow travels its length.
  success,

  /// Rejected: the pill turns red and shakes, then returns to [idle].
  failure,
}

/// Which palette the pill wears.
enum AuthButtonVariant {
  /// Navy pill with a gold arrow puck — the sign-in / register action.
  navy,

  /// Gold pill with a translucent puck — secondary auth pages.
  gold,
}

/// Navy pill action button with a gold circular arrow affordance.
///
/// The arrow follows the reading direction, so it rests at the trailing edge
/// and points left in RTL, right in LTR. On [AuthButtonState.success] it
/// travels across to the opposite edge while the pill goes green; on
/// [AuthButtonState.failure] the pill goes red and shakes in place.
class AuthPrimaryButton extends StatefulWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.state = AuthButtonState.idle,
    this.variant = AuthButtonVariant.navy,
  });

  final AuthButtonVariant variant;

  final String label;

  /// Null disables the button (e.g. self-registration turned off).
  final VoidCallback? onPressed;

  final AuthButtonState state;

  @override
  State<AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<AuthPrimaryButton>
    with SingleTickerProviderStateMixin {
  static const _successGreen = Color(0xFF17865A);
  static const _settle = Duration(milliseconds: 420);

  late final AnimationController _shakeController;
  late final Animation<double> _shake;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    // Damped oscillation: four decreasing swings back to rest.
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -11.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -11.0, end: 9.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 9.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 3.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.linear));
  }

  @override
  void didUpdateWidget(AuthPrimaryButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == AuthButtonState.failure &&
        oldWidget.state != AuthButtonState.failure) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final isDisabled = widget.onPressed == null;
    final isSuccess = widget.state == AuthButtonState.success;
    final isFailure = widget.state == AuthButtonState.failure;
    final isLoading = widget.state == AuthButtonState.loading;
    final isInert = isDisabled || isLoading || isSuccess;

    final isGold = widget.variant == AuthButtonVariant.gold;

    // In dark mode `primary` is the gold tone, so the navy pill is sourced
    // from `secondaryNavy` to keep the button reading as navy in both themes.
    final restColor = isGold
        ? colors.darkGold
        : (isDark ? colors.secondaryNavy : colors.primary);
    final pillColor = isSuccess
        ? _successGreen
        : isFailure
        ? colors.error
        : restColor;

    // Only the resting gold pill carries a gradient; success and failure are
    // flat so the state reads unambiguously.
    final pillGradient = isGold && !isSuccess && !isFailure
        ? LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: [colors.darkGold, colors.accent],
          )
        : null;

    return Semantics(
      button: true,
      enabled: !isInert,
      label: widget.label,
      child: AnimatedBuilder(
        animation: _shake,
        builder: (context, child) =>
            Transform.translate(offset: Offset(_shake.value, 0), child: child),
        child: Opacity(
          opacity: isDisabled ? 0.45 : 1,
          child: GestureDetector(
            onTapDown: isInert ? null : (_) => setState(() => _pressed = true),
            onTapUp: isInert ? null : (_) => setState(() => _pressed = false),
            onTapCancel: isInert
                ? null
                : () => setState(() => _pressed = false),
            onTap: isInert ? null : widget.onPressed,
            child: AnimatedScale(
              scale: _pressed ? 0.98 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: _settle,
                curve: Curves.easeOut,
                height: 60,
                decoration: BoxDecoration(
                  color: pillGradient == null ? pillColor : null,
                  gradient: pillGradient,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: pillColor.withValues(
                        alpha: _pressed ? 0.18 : 0.28,
                      ),
                      blurRadius: _pressed ? 10 : 18,
                      offset: Offset(0, _pressed ? 3 : 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: AnimatedOpacity(
                          // The travelling arrow would cross the label, so the
                          // label steps aside for the success run.
                          opacity: isSuccess ? 0 : 1,
                          duration: const Duration(milliseconds: 180),
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedAlign(
                      // Directional, so "travels the length of the button"
                      // means right-to-left in Arabic and the reverse in
                      // English without any extra branching.
                      alignment: isSuccess
                          ? AlignmentDirectional.centerStart
                          : AlignmentDirectional.centerEnd,
                      duration: _settle,
                      curve: Curves.easeInOutCubic,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _Puck(
                          isLoading: isLoading,
                          isSuccess: isSuccess,
                          isRtl: isRtl,
                          isDark: isDark,
                          isGold: isGold,
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

class _Puck extends StatelessWidget {
  const _Puck({
    required this.isLoading,
    required this.isSuccess,
    required this.isRtl,
    required this.isDark,
    this.isGold = false,
  });

  final bool isLoading;
  final bool isSuccess;
  final bool isRtl;
  final bool isDark;
  final bool isGold;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    // On a gold pill the puck is a lighter well in the same metal, so the
    // arrow stays legible without a second accent colour.
    final glyphColor = isGold
        ? colors.white
        : (isDark ? const Color(0xFF0B1F3A) : colors.primary);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isGold ? colors.white.withValues(alpha: 0.22) : null,
        gradient: isGold
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.accent, colors.darkGold],
              ),
      ),
      child: Center(
        child: isLoading
            ? RshdLoader(size: 12.4)
            : Icon(
                isSuccess
                    ? Icons.check_rounded
                    : isRtl
                    ? Icons.arrow_back_rounded
                    : Icons.arrow_forward_rounded,
                size: 22,
                color: glyphColor,
              ),
      ),
    );
  }
}
