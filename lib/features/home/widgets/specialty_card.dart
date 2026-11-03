import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_text_styles.dart';

/// The three academic departments, each with its own colours, motif and
/// tap animation.
enum Specialty { medicine, it, engineering }

class _SpecialtyStyle {
  const _SpecialtyStyle({
    required this.gradient,
    required this.accent,
    required this.icon,
  });

  final List<Color> gradient;
  final Color accent;
  final IconData icon;

  static _SpecialtyStyle of(Specialty s) => switch (s) {
    Specialty.medicine => const _SpecialtyStyle(
      gradient: [Color(0xFF8E1F33), Color(0xFF4A0E1D)],
      accent: Color(0xFFFFB4BE),
      icon: Icons.favorite_rounded,
    ),
    Specialty.it => const _SpecialtyStyle(
      gradient: [Color(0xFF15406E), Color(0xFF0B1F3A)],
      accent: Color(0xFF7DE3F4),
      icon: Icons.code_rounded,
    ),
    Specialty.engineering => const _SpecialtyStyle(
      gradient: [Color(0xFF8A6526), Color(0xFF3F2C0D)],
      accent: Color(0xFFF6D58E),
      icon: Icons.settings_rounded,
    ),
  };
}

/// A department card whose artwork says what the department is: a heartbeat
/// line for medicine, lines of code for IT, a blueprint with gears for
/// engineering. Tapping plays that motif — the pulse traces and the heart
/// beats, the code types itself out, the gears turn — then opens the
/// department.
class SpecialtyCard extends StatefulWidget {
  const SpecialtyCard({
    super.key,
    required this.specialty,
    required this.title,
    required this.subtitle,
    required this.countLabel,
    required this.onOpen,
  });

  final Specialty specialty;
  final String title;
  final String subtitle;
  final String countLabel;
  final VoidCallback onOpen;

  @override
  State<SpecialtyCard> createState() => _SpecialtyCardState();
}

class _SpecialtyCardState extends State<SpecialtyCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _play = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  bool _pressed = false;
  bool _opening = false;

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_opening) return;
    HapticFeedback.lightImpact();
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onOpen();
      return;
    }
    _opening = true;
    // Open the department once the motif reaches its peak; the rest plays
    // out under the page transition, so the tap never feels held up.
    _play.forward(from: 0).whenComplete(() {
      if (mounted) _play.value = 0;
    });
    await Future<void>.delayed(const Duration(milliseconds: 420));
    _opening = false;
    if (mounted) widget.onOpen();
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final style = _SpecialtyStyle.of(widget.specialty);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final radius = BorderRadius.circular(24);

    return Semantics(
      button: true,
      label: '${widget.title}، ${widget.countLabel}',
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: style.gradient.last.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: style.gradient,
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _play,
                  builder: (context, _) {
                    final t = _play.value;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: switch (widget.specialty) {
                            Specialty.medicine => _PulsePainter(
                              t,
                              style.accent,
                              isRtl,
                            ),
                            Specialty.it => _CodePainter(
                              t,
                              style.accent,
                              isRtl,
                            ),
                            Specialty.engineering => _GearsPainter(
                              t,
                              style.accent,
                              isRtl,
                            ),
                          },
                        ),
                        // Keeps the title readable over the artwork.
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.45, 1.0],
                              colors: [Color(0x00000000), Color(0x66000000)],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _Content(widget: widget, style: style, t: t),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.widget, required this.style, required this.t});

  final SpecialtyCard widget;
  final _SpecialtyStyle style;
  final double t;

  /// Icon emphasis while the motif plays: two heartbeats for medicine, a
  /// single pop for the others.
  double get _iconScale {
    if (widget.specialty == Specialty.medicine) {
      double beat(double at) {
        final d = (t - at).abs();
        return d > 0.1 ? 0 : math.cos(d / 0.1 * math.pi / 2);
      }

      return 1 + 0.22 * math.max(beat(0.2), beat(0.48));
    }
    return 1 + 0.14 * math.sin(math.pi * t.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final iconTurns = widget.specialty == Specialty.engineering ? t * 0.5 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Transform.scale(
                scale: _iconScale,
                child: Transform.rotate(
                  angle: iconTurns * 2 * math.pi,
                  child: Icon(style.icon, color: style.accent, size: 22),
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.countLabel,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          widget.title,
          style: AppTextStyles.titleOf(context).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
          // Long names ("تكنولوجيا المعلومات") wrap rather than truncate.
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          widget.subtitle,
          style: AppTextStyles.bodyOf(context).copyWith(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.75),
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Draws in start-to-end coordinates; mirrors the canvas in RTL so motion
/// flows toward the reading direction.
abstract class _MotifPainter extends CustomPainter {
  _MotifPainter(this.t, this.accent, this.rtl);

  final double t;
  final Color accent;
  final bool rtl;

  void paintMotif(Canvas canvas, Size size);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (rtl) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    paintMotif(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MotifPainter old) =>
      old.t != t || old.accent != accent || old.rtl != rtl;
}

/// Medicine: an ECG trace across the card, lit along its length on tap.
class _PulsePainter extends _MotifPainter {
  _PulsePainter(super.t, super.accent, super.rtl);

  Path _ecg(Size size) {
    final y = size.height * 0.46;
    final w = size.width;
    final path = Path()..moveTo(0, y);
    // Two heartbeats: P wave, QRS spike, T wave.
    for (final start in [w * 0.08, w * 0.54]) {
      final u = w * 0.38;
      path
        ..lineTo(start, y)
        ..quadraticBezierTo(start + u * 0.08, y - 8, start + u * 0.16, y)
        ..lineTo(start + u * 0.26, y)
        ..lineTo(start + u * 0.32, y + 9)
        ..lineTo(start + u * 0.40, y - 38)
        ..lineTo(start + u * 0.48, y + 16)
        ..lineTo(start + u * 0.54, y)
        ..lineTo(start + u * 0.66, y)
        ..quadraticBezierTo(start + u * 0.78, y - 14, start + u * 0.9, y);
    }
    path.lineTo(w, y);
    return path;
  }

  @override
  void paintMotif(Canvas canvas, Size size) {
    final path = _ecg(size);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.18),
    );
    if (t <= 0) return;

    final metric = path.computeMetrics().first;
    final head = metric.length * Curves.easeInOut.transform(t);
    final lit = metric.extractPath(
      math.max(0, head - metric.length * 0.45),
      head,
    );
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round
      ..color = accent.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..color = accent;
    canvas
      ..drawPath(lit, glow)
      ..drawPath(lit, line);
    final tip = metric.getTangentForOffset(head)?.position;
    if (tip != null) {
      canvas.drawCircle(tip, 3.5, Paint()..color = Colors.white);
    }
  }
}

/// IT: indented lines of code that type themselves out on tap, with a
/// blinking cursor on the line being written.
class _CodePainter extends _MotifPainter {
  _CodePainter(super.t, super.accent, super.rtl);

  static const _widths = [0.42, 0.30, 0.55, 0.38, 0.48, 0.24];
  static const _indent = [0, 1, 2, 2, 1, 0];

  @override
  void paintMotif(Canvas canvas, Size size) {
    final left = size.width * 0.1;
    // Kept above a two-line title.
    final top = size.height * 0.29;
    const gap = 10.0;
    const h = 5.0;
    final rest = Paint()..color = Colors.white.withValues(alpha: 0.13);
    final ink = Paint()..color = accent.withValues(alpha: 0.9);

    for (var i = 0; i < _widths.length; i++) {
      final x = left + _indent[i] * 12.0;
      final y = top + i * gap;
      final full = size.width * _widths[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, full, h),
          const Radius.circular(3),
        ),
        rest,
      );
      if (t <= 0) continue;
      final p = ((t * 1.35 - i * 0.14) / 0.3).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final w = full * p;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          const Radius.circular(3),
        ),
        ink,
      );
      // Cursor sits at the end of the line being typed, blinking.
      if (p < 1 && (t * 14).floor().isEven) {
        canvas.drawRect(
          Rect.fromLTWH(x + w + 3, y - 3, 2, h + 6),
          Paint()..color = Colors.white,
        );
      }
    }
  }
}

/// Engineering: a faint blueprint grid with two meshing gears that turn
/// against each other on tap.
class _GearsPainter extends _MotifPainter {
  _GearsPainter(super.t, super.accent, super.rtl);

  Path _gear(Offset c, double r, int teeth, double angle) {
    final path = Path();
    final inner = r * 0.78;
    final step = 2 * math.pi / teeth;
    for (var i = 0; i < teeth; i++) {
      final a = angle + i * step;
      final pts = [
        (inner, a),
        (r, a + step * 0.15),
        (r, a + step * 0.45),
        (inner, a + step * 0.6),
      ];
      for (var j = 0; j < pts.length; j++) {
        final (rad, ang) = pts[j];
        final p = c + Offset(math.cos(ang) * rad, math.sin(ang) * rad);
        if (i == 0 && j == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
    }
    path
      ..close()
      ..addOval(Rect.fromCircle(center: c, radius: r * 0.3));
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  void paintMotif(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final turn = Curves.easeInOutCubic.transform(t) * math.pi * 0.75;
    final big = Offset(size.width * 0.70, size.height * 0.40);
    const bigR = 40.0;
    const smallR = 22.0;
    final small = big + const Offset(-bigR - smallR + 6, 30);
    final active = t > 0;
    final fill = Paint()
      ..color = (active ? accent : Colors.white).withValues(
        alpha: active ? 0.55 : 0.16,
      );
    canvas
      ..drawPath(_gear(big, bigR, 12, turn), fill)
      // The smaller gear turns the other way, faster, as if meshed.
      ..drawPath(_gear(small, smallR, 8, -turn * bigR / smallR + 0.2), fill);
  }
}
