import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LiquidGlassBackground extends StatelessWidget {
  const LiquidGlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors.backgroundGradient,
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -90,
          right: -70,
          child: _GlassBlob(
            size: 280,
            color: colors.accent.withValues(alpha: 0.26),
          ),
        ),
        Positioned(
          top: MediaQuery.sizeOf(context).height * 0.28,
          left: -50,
          child: _GlassBlob(
            size: 210,
            color: colors.secondary.withValues(alpha: 0.16),
          ),
        ),
        Positioned(
          bottom: 80,
          right: 20,
          child: _GlassBlob(
            size: 190,
            color: colors.primary.withValues(alpha: 0.1),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -30,
          child: _GlassBlob(
            size: 240,
            color: colors.darkGold.withValues(alpha: 0.14),
          ),
        ),
        child,
      ],
    );
  }
}

class _GlassBlob extends StatelessWidget {
  const _GlassBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
