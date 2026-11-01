import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Full-bleed photographic backdrop for the auth screen.
///
/// The plate covers the whole screen and is left essentially untouched — the
/// flag, the citadel columns and the arch stay fully legible — because the
/// floating glass panel, not a wash, is what separates the form from the
/// photo. Only a light top-to-bottom scrim is applied, enough to seat the
/// logo and the welcome copy.
///
/// It stays mounted while the auth tabs switch, so the photo never reloads.
class HeroBackdrop extends StatelessWidget {
  const HeroBackdrop({super.key, required this.bandHeight});

  /// Height of the photographic band at the top of the screen.
  ///
  /// The plate is close to square, so stretching it over a 19.5:9 phone with
  /// `cover` would crop away most of its width — including the flag and the
  /// citadel columns. Confining it to a band keeps the crop shallow and the
  /// whole scene readable; the glass panel then floats over its lower edge.
  final double bandHeight;

  static const heroAsset = 'assets/images/login_hero.jpg';

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ground = isDark ? colors.background : const Color(0xFFF7F2E9);
    final depth = isDark ? colors.secondaryNavy : const Color(0xFFEFE7DA);

    // Where the photo ends, as a fraction of the screen. The page gradient
    // holds the exact colour the photo fades into down to this line and only
    // starts deepening below it; if it began at the top of the screen it
    // would already have shifted by the time the photo ends, leaving a
    // visible seam between the two.
    final screenHeight = MediaQuery.sizeOf(context).height;
    final seam = screenHeight <= 0
        ? 0.5
        : (bandHeight / screenHeight).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ground, ground, depth],
              stops: [0.0, seam, 1.0],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: bandHeight,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  heroAsset,
                  fit: BoxFit.cover,
                  // Biased toward the window so the arch, the columns and the
                  // flag all stay inside the shallow horizontal crop.
                  alignment: const Alignment(0.34, -0.1),
                  errorBuilder: (context, error, stackTrace) =>
                      _BackdropFallback(isDark: isDark),
                ),
                if (isDark)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.background.withValues(alpha: 0.4),
                    ),
                  ),
                // Settles the band into the ground so its lower edge is a
                // dissolve, not a cut, behind the floating panel.
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: bandHeight * 0.40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          ground.withValues(alpha: 0.0),
                          ground.withValues(alpha: 0.55),
                          ground.withValues(alpha: 0.96),
                          ground,
                        ],
                        stops: const [0.0, 0.34, 0.72, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Keeps the screen presentable if the photographic plate is ever absent.
class _BackdropFallback extends StatelessWidget {
  const _BackdropFallback({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [colors.background, colors.secondaryNavy, colors.primary]
              : const [Color(0xFFFBF7EF), Color(0xFFF2E6D2), Color(0xFFD9E4F0)],
        ),
      ),
    );
  }
}

/// Logo + welcome copy sitting on the backdrop above the floating panel.
/// Logo + welcome copy on the photo band.
///
/// Deliberately static: only the floating auth panel animates, so the brand
/// mark and the headline stay put while the forms transition.
class HeroWelcomeCopy extends StatelessWidget {
  const HeroWelcomeCopy({
    super.key,
    required this.bandHeight,
    this.compact = false,
  });

  /// Matches [HeroBackdrop.bandHeight] so the copy lands inside the photo.
  final double bandHeight;

  /// Trims the block when vertical space is tight (small phones, long forms).
  final bool compact;

  static const _logoAsset = 'assets/images/rshd_logo_no_bg.png';

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final logoHeight = compact ? 64.0 : 88.0;

    return SizedBox(
      height: bandHeight,
      // Full width, so the leading edge is the screen's right margin in
      // Arabic rather than the centred block's own edge.
      width: double.infinity,
      child: Padding(
        // The panel rides ~26pt over the band, so the copy keeps a matching
        // bottom inset to stay clear of it.
        padding: EdgeInsetsDirectional.fromSTEB(22, compact ? 4 : 10, 24, 22),
        child: Column(
          // Just the mark, centred. The greeting lives inside the floating
          // panel so it can change with the selected tab.
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Image.asset(
              _logoAsset,
              height: logoHeight,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) => Text(
                'RSHD',
                style: TextStyle(
                  fontSize: logoHeight * 0.4,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
