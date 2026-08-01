import 'package:flutter/material.dart';

import '../layout/app_layout_metrics.dart';

/// Centers page content and applies responsive horizontal padding.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final metrics = AppLayoutMetrics.of(context);
    final resolvedPadding = padding ??
        EdgeInsets.symmetric(horizontal: metrics.outerHorizontalInset);

    return Padding(
      padding: resolvedPadding,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: metrics.contentMaxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Wraps a [sliver] with responsive horizontal insets and max width.
class ResponsiveSliverContent extends StatelessWidget {
  const ResponsiveSliverContent({
    super.key,
    required this.sliver,
    this.padding,
  });

  final Widget sliver;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final metrics = AppLayoutMetrics.of(context);
    final resolvedPadding =
        padding ?? metrics.pagePadding(top: 8, bottom: 32);

    return SliverPadding(
      padding: resolvedPadding,
      sliver: SliverConstrainedCrossAxis(
        maxExtent: metrics.contentMaxWidth,
        sliver: sliver,
      ),
    );
  }
}

/// Keeps decorative headers full width while constraining their inner content.
class ResponsiveHeaderContent extends StatelessWidget {
  const ResponsiveHeaderContent({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final metrics = AppLayoutMetrics.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: metrics.contentMaxWidth),
        child: Padding(
          padding: padding ??
              EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
          child: child,
        ),
      ),
    );
  }
}
