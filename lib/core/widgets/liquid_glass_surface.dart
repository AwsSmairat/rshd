import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The app's card surface.
///
/// By default a solid modern card — page-surface colour, a hairline edge and
/// a soft shadow — which is the look of the redesigned screens and costs no
/// blur. Pass [frosted] for real frosted glass over imagery (the floating
/// login card).
class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({
    this.frosted = false,
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.blurSigma = 22,
    this.fillOpacity = 0.24,
    this.borderOpacity = 0.5,
    this.tintColor,
    this.tintOpacity = 0.08,
    this.onTap,
    this.highlightColor,
  });

  final Widget child;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double blurSigma;
  final double fillOpacity;
  final double borderOpacity;
  final Color? tintColor;
  final double tintOpacity;
  final VoidCallback? onTap;
  final Color? highlightColor;

  /// Blurred translucent glass instead of the solid card.
  final bool frosted;

  @override
  Widget build(BuildContext context) {
    final resolvedRadius = borderRadius.resolve(Directionality.of(context));

    Widget surface = frosted
        ? _frosted(context, resolvedRadius)
        : _card(context, resolvedRadius);

    if (onTap != null) {
      surface = Material(
        color: Colors.transparent,
        borderRadius: resolvedRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: (highlightColor ?? AppColors.of(context).accent)
              .withValues(alpha: 0.12),
          highlightColor: (highlightColor ?? AppColors.of(context).accent)
              .withValues(alpha: 0.06),
          child: surface,
        ),
      );
      // Keep the shadow outside the ripple's clip.
      if (!frosted) {
        surface = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: resolvedRadius,
            boxShadow: _shadow(context),
          ),
          child: surface,
        );
      }
    }

    if (margin != null) {
      surface = Padding(padding: margin!, child: surface);
    }

    return surface;
  }

  List<BoxShadow> _shadow(BuildContext context) => [
    BoxShadow(
      color: const Color(0xFF0B1F3A).withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.05,
      ),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  Widget _card(BuildContext context, BorderRadius radius) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = tintColor;
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        // BoxDecoration takes a colour or a gradient, not both.
        color: tint == null ? colors.cardWhite : null,
        // A trace of the caller's tint so tinted cards keep their hint of
        // colour on the solid surface.
        gradient: tint == null
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.cardWhite,
                  Color.alphaBlend(
                    tint.withValues(alpha: (tintOpacity * 0.6).clamp(0, 0.06)),
                    colors.cardWhite,
                  ),
                ],
              ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : colors.primary.withValues(alpha: 0.06),
        ),
        boxShadow: onTap == null ? _shadow(context) : null,
      ),
      child: child,
    );
  }

  Widget _frosted(BuildContext context, BorderRadius resolvedRadius) {
    return ClipRRect(
      borderRadius: resolvedRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: resolvedRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 1.15,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: fillOpacity + 0.1),
                (tintColor ?? Colors.white).withValues(
                  alpha: fillOpacity + tintOpacity,
                ),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.of(
                  context,
                ).glassShadow.withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
