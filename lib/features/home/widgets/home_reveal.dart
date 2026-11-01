import 'package:flutter/material.dart';

/// Fades a home section in with a small rise, staggered by [order], the first
/// time the page appears. Skipped when the system asks for reduced motion.
class HomeReveal extends StatefulWidget {
  const HomeReveal({super.key, required this.order, required this.child});

  final int order;
  final Widget child;

  @override
  State<HomeReveal> createState() => _HomeRevealState();
}

class _HomeRevealState extends State<HomeReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.status != AnimationStatus.dismissed) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    Future.delayed(Duration(milliseconds: 50 * widget.order), () {
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
          offset: Offset(0, 14 * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}
