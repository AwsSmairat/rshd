import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

/// The app's loading indicator: the letters R S H D lit one after another in
/// a wave, rising slightly as the light passes. Used everywhere instead of
/// the Material spinner, from full-page loads down to buttons.
class RshdLoader extends StatefulWidget {
  const RshdLoader({super.key, this.size = 30, this.color, this.baseColor});

  /// Letter height. 30 for a page, about 13 inside a button.
  final double size;

  /// Colour of the lit letter; the brand gold by default.
  final Color? color;

  /// Colour of the resting letters; a faint version of [color] by default.
  final Color? baseColor;

  @override
  State<RshdLoader> createState() => _RshdLoaderState();
}

class _RshdLoaderState extends State<RshdLoader>
    with SingleTickerProviderStateMixin {
  static const _letters = ['R', 'S', 'H', 'D'];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 0..1 brightness of letter [index] at animation value [t]: a smooth bump
  /// that travels across the word once per cycle.
  static double _glow(double t, int index) {
    const span = 0.42;
    final phase = (t - index * 0.16) % 1.0;
    if (phase > span) return 0;
    return math.sin(math.pi * phase / span);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final lit = widget.color ?? colors.accent;
    final rest = widget.baseColor ?? lit.withValues(alpha: 0.28);
    final still = MediaQuery.disableAnimationsOf(context);
    final style = TextStyle(
      fontSize: widget.size,
      height: 1,
      fontWeight: FontWeight.w900,
      letterSpacing: widget.size * 0.04,
      fontFamily: DefaultTextStyle.of(context).style.fontFamily,
    );

    return Semantics(
      label: AppStrings.of(context).t('جاري التحميل'),
      liveRegion: true,
      child: ExcludeSemantics(
        // Latin letters read left to right in every locale.
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            // Room for the letters to rise without being clipped.
            padding: EdgeInsets.only(top: widget.size * 0.2),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _letters.length; i++)
                    _letter(
                      i,
                      still ? 0.6 : _glow(_controller.value, i),
                      lit,
                      rest,
                      style,
                      still,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _letter(
    int i,
    double glow,
    Color lit,
    Color rest,
    TextStyle style,
    bool still,
  ) {
    return Transform.translate(
      offset: Offset(0, still ? 0 : -glow * widget.size * 0.18),
      child: Transform.scale(
        scale: 1 + glow * 0.08,
        child: Text(
          _letters[i],
          style: style.copyWith(color: Color.lerp(rest, lit, glow)),
        ),
      ),
    );
  }
}
