import 'package:flutter/material.dart';

class GoogleLogoIcon extends StatelessWidget {
  const GoogleLogoIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final greenPaint = Paint()..color = const Color(0xFF34A853);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.8,
      4.6,
      true,
      bluePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.2,
      1.4,
      true,
      greenPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.4,
      1.2,
      true,
      yellowPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      4.4,
      1.4,
      true,
      redPaint,
    );

    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.62, innerPaint);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - radius * 0.14,
        radius * 0.95,
        radius * 0.28,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFFE5E7EB).withValues(alpha: 0.7),
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4285F4),
                    ),
                  )
                : Row(
                    mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: enabled
                              ? const Color(0xFF1F2937)
                              : const Color(0xFF9CA3AF),
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: compact ? 8 : 10),
                      Opacity(
                        opacity: enabled ? 1 : 0.45,
                        child: GoogleLogoIcon(size: compact ? 18 : 20),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
