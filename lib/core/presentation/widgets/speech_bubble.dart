import 'package:flutter/material.dart';

/// Bocadillo de diálogo animado estilo cómic / videojuego tradicional.
/// Utilizado para desplegar cantos instantáneos ("¡Ronda!", "Patrulla", "¡Caída!", "¡Truco!", "Paso").
class SpeechBubble extends StatelessWidget {
  final String text;
  final bool pointsDown;
  final Color backgroundColor;
  final Color textColor;

  const SpeechBubble({
    super.key,
    required this.text,
    this.pointsDown = true,
    this.backgroundColor = Colors.white,
    this.textColor = const Color(0xFF1E293B),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 250),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.5, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          alignment: pointsDown ? Alignment.bottomCenter : Alignment.topCenter,
          child: CustomPaint(
            painter: _SpeechBubblePainter(
              color: backgroundColor,
              pointsDown: pointsDown,
            ),
            child: Container(
              padding: EdgeInsets.fromLTRB(
                14,
                pointsDown ? 8 : 14,
                14,
                pointsDown ? 14 : 8,
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpeechBubblePainter extends CustomPainter {
  final Color color;
  final bool pointsDown;

  const _SpeechBubblePainter({required this.color, required this.pointsDown});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    const radius = 10.0;
    const arrowWidth = 14.0;
    const arrowHeight = 7.0;

    final bodyRect = pointsDown
        ? Rect.fromLTWH(0, 0, size.width, size.height - arrowHeight)
        : Rect.fromLTWH(0, arrowHeight, size.width, size.height - arrowHeight);

    path.addRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(radius)));

    // Triángulo que apunta hacia el avatar
    final arrowPath = Path();
    final arrowCenterX = size.width * 0.5;

    if (pointsDown) {
      arrowPath.moveTo(arrowCenterX - (arrowWidth / 2), size.height - arrowHeight);
      arrowPath.lineTo(arrowCenterX, size.height);
      arrowPath.lineTo(arrowCenterX + (arrowWidth / 2), size.height - arrowHeight);
    } else {
      arrowPath.moveTo(arrowCenterX - (arrowWidth / 2), arrowHeight);
      arrowPath.lineTo(arrowCenterX, 0);
      arrowPath.lineTo(arrowCenterX + (arrowWidth / 2), arrowHeight);
    }
    arrowPath.close();

    path.addPath(arrowPath, Offset.zero);

    // Sombra, relleno y contorno
    canvas.drawPath(path.shift(const Offset(0, 2)), shadowPaint);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pointsDown != pointsDown;
}
