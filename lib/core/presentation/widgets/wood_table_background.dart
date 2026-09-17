import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Fondo de mesa fotorrealista con listones de madera oscura y vetas tradicionales.
/// Diseñado para ambientar mesas de juegos de naipes y dominó clásicos.
class WoodTableBackground extends StatelessWidget {
  final Widget? child;
  final Color baseColor;

  const WoodTableBackground({
    super.key,
    this.child,
    this.baseColor = const Color(0xFF261910), // Marrón madera oscura profundo
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Pintura procedural de listones verticales con vetas y sombras
        CustomPaint(
          painter: _WoodPlanksPainter(baseColor: baseColor),
        ),
        // Viñeta perimetral de iluminación cálida en el centro y sombra en los bordes
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0.70),
              ],
              stops: const [0.35, 0.75, 1.0],
            ),
          ),
        ),
        ?child,
      ],
    );
  }
}

class _WoodPlanksPainter extends CustomPainter {
  final Color baseColor;

  const _WoodPlanksPainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo base
    final bgPaint = Paint()..color = baseColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Número de listones verticales (típicamente 5-6 en pantalla vertical)
    const plankCount = 5;
    final plankWidth = size.width / plankCount;

    final plankLineDark = Paint()
      ..color = const Color(0xFF100A06)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final plankLineLight = Paint()
      ..color = const Color(0xFF3D271B).withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final grainPaint = Paint()
      ..color = const Color(0xFF332015).withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < plankCount; i++) {
      final x = i * plankWidth;

      // Variación sutil de color entre listones contiguos
      if (i % 2 == 1) {
        final tintPaint = Paint()
          ..color = const Color(0xFF1A110B).withValues(alpha: 0.25);
        canvas.drawRect(Rect.fromLTWH(x, 0, plankWidth, size.height), tintPaint);
      }

      // Dibujar vetas orgánicas sutiles a lo largo de cada tabla
      final random = math.Random(i * 997);
      for (double y = 0; y < size.height; y += 45) {
        final path = Path();
        final startX = x + random.nextDouble() * (plankWidth * 0.4);
        final endX = x + plankWidth * 0.5 + random.nextDouble() * (plankWidth * 0.4);
        final midY = y + 25 + (random.nextDouble() * 20 - 10);
        path.moveTo(startX, y);
        path.quadraticBezierTo(startX + 15, midY, endX, y + 50);
        canvas.drawPath(path, grainPaint);
      }

      // Líneas divisorias entre listones
      if (i > 0) {
        canvas.drawLine(Offset(x - 1, 0), Offset(x - 1, size.height), plankLineDark);
        canvas.drawLine(Offset(x + 1, 0), Offset(x + 1, size.height), plankLineLight);

        // Clavos o muescas sutiles en los extremos superior e inferior
        _drawNail(canvas, Offset(x, 25));
        _drawNail(canvas, Offset(x, size.height - 25));
        _drawNail(canvas, Offset(x, size.height * 0.5));
      }
    }
  }

  void _drawNail(Canvas canvas, Offset pos) {
    final nailDark = Paint()..color = const Color(0xFF0D0805);
    final nailLight = Paint()..color = const Color(0xFF4A3425).withValues(alpha: 0.5);
    canvas.drawCircle(pos, 2.8, nailDark);
    canvas.drawCircle(Offset(pos.dx + 0.6, pos.dy - 0.6), 1.2, nailLight);
  }

  @override
  bool shouldRepaint(covariant _WoodPlanksPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor;
}
