import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

/// Identifies which provider a social button represents.
///
/// Kept separate from the widget so wiring real authentication later is a
/// matter of handling this value in [SocialSignInButtons.onProviderPressed] —
/// no visual changes required.
enum SocialAuthProvider { google, apple }

/// Google + Apple sign-in row.
///
/// The buttons are fully interactive but intentionally **not** wired to any
/// authentication SDK yet; [onProviderPressed] currently surfaces a
/// "coming soon" notice.
class SocialSignInButtons extends StatelessWidget {
  const SocialSignInButtons({super.key, required this.onProviderPressed});

  final ValueChanged<SocialAuthProvider> onProviderPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            label: strings.continueWithGoogle,
            icon: const _GoogleMark(size: 20),
            onTap: () => onProviderPressed(SocialAuthProvider.google),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            label: strings.continueWithApple,
            icon: Icon(
              Icons.apple,
              size: 24,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.of(context).white
                  : Colors.black,
            ),
            onTap: () => onProviderPressed(SocialAuthProvider.apple),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatefulWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? colors.white.withValues(alpha: 0.06)
                  : colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? colors.white.withValues(alpha: 0.10)
                    : colors.primary.withValues(alpha: 0.07),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.icon,
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Google's four-colour "G", drawn so no network or binary asset is needed.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);
  static const _blue = Color(0xFF4285F4);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.22;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Four arcs, clockwise from the upper right, mirroring the brand mark.
    canvas.drawArc(rect, -0.52, -1.05, false, paint..color = _red);
    canvas.drawArc(rect, -1.57, -1.57, false, paint..color = _yellow);
    canvas.drawArc(rect, 3.14, -1.22, false, paint..color = _green);
    canvas.drawArc(rect, 0.70, -1.22, false, paint..color = _blue);

    // The horizontal bar of the G.
    final barHeight = stroke * 0.92;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.52,
        (size.height - barHeight) / 2,
        size.width * 0.46,
        barHeight,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleMarkPainter oldDelegate) => false;
}
