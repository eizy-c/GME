import 'package:flutter/material.dart';

/// Dirección del conector o cola del bocadillo de diálogo hacia el avatar.
enum BubbleArrowDirection { down, up, left, right }

/// Bocadillo de diálogo / pensamiento animado estilo cómic / videojuego tradicional.
/// Utilizado para desplegar cantos instantáneos ("¡Ronda!", "Patrulla", "¡Caída!", "¡Truco!", "Paso")
/// y mensajes de chat futuros que emergen directamente del avatar.
class SpeechBubble extends StatelessWidget {
  final String text;
  final BubbleArrowDirection arrowDirection;
  final Color backgroundColor;
  final Color textColor;
  final double maxWidth;

  const SpeechBubble({
    super.key,
    required this.text,
    bool pointsDown = true,
    BubbleArrowDirection? direction,
    this.backgroundColor = Colors.white,
    this.textColor = const Color(0xFF1E293B),
    this.maxWidth = 155,
  }) : arrowDirection = direction ?? (pointsDown ? BubbleArrowDirection.down : BubbleArrowDirection.up);

  const SpeechBubble.directional({
    super.key,
    required this.text,
    required this.arrowDirection,
    this.backgroundColor = Colors.white,
    this.textColor = const Color(0xFF1E293B),
    this.maxWidth = 155,
  });

  @override
  Widget build(BuildContext context) {
    Alignment transformAlignment;
    switch (arrowDirection) {
      case BubbleArrowDirection.down:
        transformAlignment = Alignment.bottomCenter;
        break;
      case BubbleArrowDirection.up:
        transformAlignment = Alignment.topCenter;
        break;
      case BubbleArrowDirection.left:
        transformAlignment = Alignment.centerLeft;
        break;
      case BubbleArrowDirection.right:
        transformAlignment = Alignment.centerRight;
        break;
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.4, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          alignment: transformAlignment,
          child: CustomPaint(
            painter: _SpeechBubblePainter(
              color: backgroundColor,
              direction: arrowDirection,
            ),
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: EdgeInsets.fromLTRB(
                arrowDirection == BubbleArrowDirection.left ? 14 : 10,
                arrowDirection == BubbleArrowDirection.up ? 12 : 6,
                arrowDirection == BubbleArrowDirection.right ? 14 : 10,
                arrowDirection == BubbleArrowDirection.down ? 12 : 6,
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
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
  final BubbleArrowDirection direction;

  const _SpeechBubblePainter({required this.color, required this.direction});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    const radius = 10.0;
    const arrowWidth = 12.0;
    const arrowHeight = 7.0;

    Rect bodyRect;
    switch (direction) {
      case BubbleArrowDirection.down:
        bodyRect = Rect.fromLTWH(0, 0, size.width, size.height - arrowHeight);
        break;
      case BubbleArrowDirection.up:
        bodyRect = Rect.fromLTWH(0, arrowHeight, size.width, size.height - arrowHeight);
        break;
      case BubbleArrowDirection.left:
        bodyRect = Rect.fromLTWH(arrowHeight, 0, size.width - arrowHeight, size.height);
        break;
      case BubbleArrowDirection.right:
        bodyRect = Rect.fromLTWH(0, 0, size.width - arrowHeight, size.height);
        break;
    }

    path.addRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(radius)));

    // Flecha / Conector apuntando al avatar
    final arrowPath = Path();
    switch (direction) {
      case BubbleArrowDirection.down:
        final cx = size.width * 0.5;
        arrowPath.moveTo(cx - (arrowWidth / 2), size.height - arrowHeight);
        arrowPath.lineTo(cx, size.height);
        arrowPath.lineTo(cx + (arrowWidth / 2), size.height - arrowHeight);
        break;
      case BubbleArrowDirection.up:
        final cx = size.width * 0.5;
        arrowPath.moveTo(cx - (arrowWidth / 2), arrowHeight);
        arrowPath.lineTo(cx, 0);
        arrowPath.lineTo(cx + (arrowWidth / 2), arrowHeight);
        break;
      case BubbleArrowDirection.left:
        final cy = size.height * 0.5;
        arrowPath.moveTo(arrowHeight, cy - (arrowWidth / 2));
        arrowPath.lineTo(0, cy);
        arrowPath.lineTo(arrowHeight, cy + (arrowWidth / 2));
        break;
      case BubbleArrowDirection.right:
        final cy = size.height * 0.5;
        arrowPath.moveTo(size.width - arrowHeight, cy - (arrowWidth / 2));
        arrowPath.lineTo(size.width, cy);
        arrowPath.lineTo(size.width - arrowHeight, cy + (arrowWidth / 2));
        break;
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
      oldDelegate.color != color || oldDelegate.direction != direction;
}
