import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/opaque_route_surface.dart';

/// Builds an opaque [MaterialPage] with a stable [GoRouterState.pageKey].
Page<void> buildAppRoutePage({
  required GoRouterState state,
  required Widget child,
  Color? backgroundColor,
}) {
  return MaterialPage<void>(
    key: state.pageKey,
    name: state.name,
    arguments: state.extra,
    child: OpaqueRouteSurface(backgroundColor: backgroundColor, child: child),
  );
}
