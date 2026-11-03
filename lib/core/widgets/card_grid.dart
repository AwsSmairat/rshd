import 'package:flutter/material.dart';

import '../layout/app_layout_metrics.dart';

/// Lays cards out one per row on phones and in rows of
/// [AppLayoutMetrics.cardColumns] on wide screens, each row as tall as its
/// tallest card.
class CardGrid extends StatelessWidget {
  const CardGrid({
    super.key,
    required this.children,
    this.spacing = 12,
    this.columns,
  });

  final List<Widget> children;
  final double spacing;

  /// Overrides the screen-based column count.
  final int? columns;

  @override
  Widget build(BuildContext context) {
    final count = columns ?? AppLayoutMetrics.of(context).cardColumns;
    if (count <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      );
    }

    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += count) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var c = 0; c < count; c++) ...[
                if (c > 0) SizedBox(width: spacing),
                Expanded(
                  child: start + c < children.length
                      ? children[start + c]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}
