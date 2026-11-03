import 'package:flutter/material.dart';

/// When each page (route) first built a [StaggerReveal]; items only animate
/// in that opening moment, not when a list rebuilds them on scroll.
final Expando<DateTime> _pageOpenedAt = Expando<DateTime>('pageOpenedAt');

/// Fades a list item in with a small rise, staggered by [order], when its
/// page first opens. Items built later (scrolled into view, refreshed) show
/// at once, and nothing animates under reduced motion.
class StaggerReveal extends StatefulWidget {
  const StaggerReveal({super.key, required this.order, required this.child});

  final int order;
  final Widget child;

  /// Items past this position appear with the last one rather than waiting.
  static const _maxStagger = 7;
  static const _openingWindow = Duration(milliseconds: 1200);

  @override
  State<StaggerReveal> createState() => _StaggerRevealState();
}

class _StaggerRevealState extends State<StaggerReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  bool _decided = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;

    final route = ModalRoute.of(context);
    final now = DateTime.now();
    final opened = route == null ? now : (_pageOpenedAt[route] ??= now);
    final opening = now.difference(opened) < StaggerReveal._openingWindow;

    if (!opening || MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    final step = widget.order.clamp(0, StaggerReveal._maxStagger);
    Future.delayed(Duration(milliseconds: 60 * step), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}
