import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

/// Placeholder for content that is still loading, drawn in the shape of the
/// page that is coming so nothing jumps when it arrives.
///
/// Every [SkeletonBox] below one [Skeleton] breathes in step, and stays
/// still when the system asks for reduced motion. Screen readers hear a
/// single "loading" instead of the empty shapes.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.child});

  final Widget child;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse
        ..stop()
        ..value = 0.5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.of(context).t('جاري التحميل'),
      liveRegion: true,
      excludeSemantics: true,
      child: _SkeletonPulse(
        notifier: _pulse,
        child: IgnorePointer(child: widget.child),
      ),
    );
  }
}

class _SkeletonPulse extends InheritedNotifier<AnimationController> {
  const _SkeletonPulse({required super.notifier, required super.child});

  static double? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SkeletonPulse>()
        ?.notifier
        ?.value;
  }
}

/// One grey shape: a line of text, an image, an avatar.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 8,
  });

  /// A round shape, for avatars and icon tiles.
  const SkeletonBox.circle({super.key, required double size})
    : width = size,
      height = size,
      radius = 999;

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final t = Curves.easeInOut.transform(_SkeletonPulse.of(context) ?? 0.5);
    // `text` is navy in light mode and ivory in dark, so the shapes read on
    // both backgrounds.
    final color = Color.lerp(
      colors.text.withValues(alpha: 0.06),
      colors.text.withValues(alpha: 0.12),
      t,
    );
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A card surface like the app's real cards, to hold skeleton shapes.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 20,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      height: height,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.cardWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.primary.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

/// The common list row: a leading tile and two lines of text.
class SkeletonListRow extends StatelessWidget {
  const SkeletonListRow({
    super.key,
    this.leadingSize = 44,
    this.leadingRadius = 14,
    this.titleWidth = 180,
    this.subtitleWidth = 120,
  });

  final double leadingSize;
  final double leadingRadius;
  final double titleWidth;
  final double subtitleWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SkeletonBox(
          width: leadingSize,
          height: leadingSize,
          radius: leadingRadius,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: titleWidth, height: 14),
              const SizedBox(height: 8),
              SkeletonBox(width: subtitleWidth, height: 11),
            ],
          ),
        ),
      ],
    );
  }
}
