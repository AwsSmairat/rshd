import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({
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

  @override
  Widget build(BuildContext context) {
    final resolvedRadius = borderRadius.resolve(Directionality.of(context));

    Widget surface = ClipRRect(
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

    if (onTap != null) {
      surface = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: resolvedRadius,
          splashColor: (highlightColor ?? AppColors.of(context).accent)
              .withValues(alpha: 0.12),
          highlightColor: (highlightColor ?? AppColors.of(context).accent)
              .withValues(alpha: 0.06),
          child: surface,
        ),
      );
    }

    if (margin != null) {
      surface = Padding(padding: margin!, child: surface);
    }

    return surface;
  }
}
