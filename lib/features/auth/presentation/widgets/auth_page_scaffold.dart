import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Shared layout for the secondary auth pages (forgot password, code
/// verification, reset password).
///
/// Warm ivory ground, the RSHD mark centred, the page's title and copy, then
/// the form held in a soft raised card — the same card language as the
/// sign-in panel, so the flow reads as one family.
///
/// Deliberately absent: a back chevron (the footer link is the way back) and
/// any gold divider rule under the mark. Do not reintroduce either.
class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
  });

  final String title;
  final String subtitle;

  /// Form content, laid out stretched inside the card.
  final List<Widget> children;

  /// Optional link row under the card (e.g. "back to sign in").
  final Widget? footer;

  static const _logoAsset = 'assets/images/rshd_logo_no_bg.png';

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final isTablet = media.size.shortestSide >= 600;
    final isShort = media.size.height < 740;

    final ground = isDark ? colors.background : const Color(0xFFF7F2E9);
    final cardColor = isDark
        ? colors.cardWhite.withValues(alpha: 0.55)
        : colors.white.withValues(alpha: 0.72);

    return Scaffold(
      backgroundColor: ground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Two quiet flourishes: a soft gold bloom behind the mark and faint
          // rings low on the page. Both are far too light to compete with the
          // content; they only stop the ivory reading as a blank sheet.
          Positioned(
            top: -media.size.width * 0.34,
            left: -media.size.width * 0.18,
            right: -media.size.width * 0.18,
            height: media.size.width,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.accent.withValues(alpha: isDark ? 0.10 : 0.13),
                    colors.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -media.size.width * 0.42,
            left: -media.size.width * 0.16,
            right: -media.size.width * 0.16,
            height: media.size.width,
            child: CustomPaint(
              painter: _RingsPainter(
                color: colors.darkGold.withValues(alpha: isDark ? 0.10 : 0.15),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 56 : 24,
                    24,
                    isTablet ? 56 : 24,
                    28 + media.viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 52,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              _logoAsset,
                              height: isShort ? 92 : 112,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(
                                    'RSHD',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 3,
                                      color: colors.primary,
                                    ),
                                  ),
                            ),
                            SizedBox(height: isShort ? 20 : 26),

                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: isShort ? 25 : 28,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  height: 1.65,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textMuted,
                                ),
                              ),
                            ),
                            SizedBox(height: isShort ? 24 : 32),

                            // The form sits on its own raised surface, which
                            // gives the page a centre of gravity instead of
                            // leaving the field floating on bare ivory.
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: isDark
                                      ? colors.white.withValues(alpha: 0.10)
                                      : colors.white.withValues(alpha: 0.85),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.primary.withValues(
                                      alpha: isDark ? 0.35 : 0.07,
                                    ),
                                    blurRadius: 26,
                                    spreadRadius: -4,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  24,
                                  20,
                                  24,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: children,
                                ),
                              ),
                            ),

                            if (footer != null) ...[
                              const SizedBox(height: 20),
                              Center(child: footer!),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Three concentric rings plus a short tick, used as a quiet corner flourish.
class _RingsPainter extends CustomPainter {
  const _RingsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;

    final centre = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(centre, size.width * (0.26 + i * 0.11), paint);
    }

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: size.width * 0.48),
      -math.pi * 0.75,
      math.pi * 0.28,
      false,
      paint..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) =>
      oldDelegate.color != color;
}
