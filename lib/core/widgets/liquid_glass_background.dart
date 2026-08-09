import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LiquidGlassBackground extends StatelessWidget {
  const LiquidGlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF6F1E7), Color(0xFFEDE4D4), Color(0xFFE8EEF6)],
              stops: [0.0, 0.42, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -90,
          right: -70,
          child: _GlassBlob(
            size: 280,
            color: AppColors.accent.withValues(alpha: 0.26),
          ),
        ),
        Positioned(
          top: MediaQuery.sizeOf(context).height * 0.28,
          left: -50,
          child: _GlassBlob(
            size: 210,
            color: AppColors.secondary.withValues(alpha: 0.16),
          ),
        ),
        Positioned(
          bottom: 80,
          right: 20,
          child: _GlassBlob(
            size: 190,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -30,
          child: _GlassBlob(
            size: 240,
            color: AppColors.darkGold.withValues(alpha: 0.14),
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
