import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ensures each route paints as a fully opaque surface during transitions.
///
/// With a shared [LiquidGlassBackground] behind the navigator and transparent
/// scaffolds, outgoing routes can visually bleed over incoming routes during
/// MaterialPage animations. This wrapper guarantees the route occludes routes
/// beneath it for the entire transition.
class OpaqueRouteSurface extends StatelessWidget {
  const OpaqueRouteSurface({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor ?? AppColors.of(context).background,
      child: child,
    );
  }
}
