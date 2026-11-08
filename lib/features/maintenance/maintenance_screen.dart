import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/platform/platform_settings.dart';
import '../../core/platform/platform_settings_controller.dart';
import '../../core/theme/app_text_styles.dart';

const _navyTop = Color(0xFF102849);
const _navy = Color(0xFF0B1F3A);
const _navyBottom = Color(0xFF081426);
const _gold = Color(0xFFD6B56D);
const _ivory = Color(0xFFF6F1E7);

/// Shown while the platform is under maintenance. Two gears turn to say the
/// work is under way; the screen checks every [_checkEvery] whether the
/// platform is back, and the router leaves it on its own once it is.
class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  static const _checkEvery = Duration(seconds: 30);

  Timer? _ticker;
  int _secondsLeft = _checkEvery.inSeconds;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_checking) {
        return;
      }
      if (_secondsLeft <= 1) {
        unawaited(_check());
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking) {
      return;
    }
    setState(() => _checking = true);
    try {
      await ref.read(platformSettingsProvider.notifier).refresh();
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
          _secondsLeft = _checkEvery.inSeconds;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final message = ref
        .watch(platformSettingsProvider)
        .maybeWhen(
          data: (value) => value.maintenanceMessage,
          orElse: () => PlatformSettings.fallback.maintenanceMessage,
        );
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final gearsSize = shortest >= 600 ? 240.0 : 190.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _navy,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_navyTop, _navy, _navyBottom],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/rshd_logo_no_bg.png',
                        height: 56,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(height: 28),
                      _MaintenanceGears(size: gearsSize),
                      const SizedBox(height: 32),
                      Text(
                        strings.t('نعمل على تحسين المنصة'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleOf(context).copyWith(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          strings.t(message),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyOf(context).copyWith(
                            color: _ivory.withValues(alpha: 0.78),
                            fontSize: 15,
                            height: 1.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _CheckStatus(
                        checking: _checking,
                        secondsLeft: _secondsLeft,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _checking ? null : _check,
                          icon: _checking
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _navy,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 20),
                          label: Text(strings.t('تحقق الآن')),
                          style: FilledButton.styleFrom(
                            backgroundColor: _gold,
                            foregroundColor: _navy,
                            disabledBackgroundColor: _gold.withValues(
                              alpha: 0.55,
                            ),
                            disabledForegroundColor: _navy,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: AppTextStyles.bodyOf(context).copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Checking automatically in 12 s", or "Checking…" while a check runs.
class _CheckStatus extends StatelessWidget {
  const _CheckStatus({required this.checking, required this.secondsLeft});

  final bool checking;
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final text = checking
        ? strings.t('جاري التحقق من عودة المنصة…')
        : strings.isEnglish
        ? 'Checking again in ${secondsLeft}s'
        : 'نتحقق تلقائياً خلال $secondsLeft ث';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulsingDot(),
          const SizedBox(width: 10),
          Text(
            text,
            style: AppTextStyles.captionOf(context).copyWith(
              color: _ivory.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
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
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_pulse),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle),
      ),
    );
  }
}

/// Two meshing gears turning slowly in opposite directions, on a soft glow.
/// Still when the system asks for reduced motion.
class _MaintenanceGears extends StatefulWidget {
  const _MaintenanceGears({required this.size});

  final double size;

  @override
  State<_MaintenanceGears> createState() => _MaintenanceGearsState();
}

class _MaintenanceGearsState extends State<_MaintenanceGears>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _turn.stop();
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.of(context).t('المنصة تحت الصيانة'),
      image: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _turn,
          builder: (context, _) =>
              CustomPaint(painter: _GearsPainter(turn: _turn.value)),
        ),
      ),
    );
  }
}

class _GearsPainter extends CustomPainter {
  _GearsPainter({required this.turn});

  /// 0..1 over one slow revolution of the big gear.
  final double turn;

  static const _bigTeeth = 12;
  static const _smallTeeth = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // Soft gold glow behind the gears.
    canvas.drawCircle(
      Offset(s * 0.5, s * 0.5),
      s * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors: [_gold.withValues(alpha: 0.22), _gold.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, s, s)),
    );

    final bigRadius = s * 0.27;
    final smallRadius = bigRadius * _smallTeeth / _bigTeeth;
    final bigCentre = Offset(s * 0.42, s * 0.56);
    // Placed so the teeth interlock, up and to the side of the big gear.
    final reach = bigRadius + smallRadius + s * 0.035;
    const meshAngle = -math.pi / 4;
    final smallCentre =
        bigCentre + Offset(math.cos(meshAngle), math.sin(meshAngle)) * reach;

    final bigAngle = turn * 2 * math.pi;
    // The small gear turns the other way, faster by the tooth ratio, offset
    // by half a tooth so tooth meets gap.
    final smallAngle =
        -bigAngle * _bigTeeth / _smallTeeth + math.pi / _smallTeeth;

    _drawGear(
      canvas,
      centre: bigCentre,
      radius: bigRadius,
      teeth: _bigTeeth,
      angle: bigAngle,
      fill: _gold,
      hub: _navy,
    );
    _drawGear(
      canvas,
      centre: smallCentre,
      radius: smallRadius,
      teeth: _smallTeeth,
      angle: smallAngle,
      fill: _ivory.withValues(alpha: 0.92),
      hub: _navy,
    );
  }

  void _drawGear(
    Canvas canvas, {
    required Offset centre,
    required double radius,
    required int teeth,
    required double angle,
    required Color fill,
    required Color hub,
  }) {
    final toothDepth = radius * 0.22;
    final path = Path();
    final steps = teeth * 4;
    for (var i = 0; i <= steps; i++) {
      // Each tooth: rise, top, fall, root.
      final phase = i % 4;
      final r = phase == 1 || phase == 2 ? radius + toothDepth : radius;
      final a = angle + i * 2 * math.pi / steps;
      final point = centre + Offset(math.cos(a), math.sin(a)) * r;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawCircle(centre, radius * 0.42, Paint()..color = hub);
    canvas.drawCircle(centre, radius * 0.16, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_GearsPainter oldDelegate) => oldDelegate.turn != turn;
}
