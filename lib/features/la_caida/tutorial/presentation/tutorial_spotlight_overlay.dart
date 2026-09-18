import 'package:flutter/material.dart';

/// Capa oscura bloqueante con foco iluminado ("Spotlight") y tarjeta explicativa flotante.
class TutorialSpotlightOverlay extends StatefulWidget {
  final Rect? spotlightTarget;
  final String title;
  final String instruction;
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onSkip;

  const TutorialSpotlightOverlay({
    super.key,
    this.spotlightTarget,
    required this.title,
    required this.instruction,
    required this.currentStep,
    required this.totalSteps,
    this.onSkip,
  });

  @override
  State<TutorialSpotlightOverlay> createState() => _TutorialSpotlightOverlayState();
}

class _TutorialSpotlightOverlayState extends State<TutorialSpotlightOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final target = widget.spotlightTarget;

    // Determinar si la tarjeta explicativa va arriba o abajo según la posición del objetivo
    final bool putCardAtTop = target != null && target.top > screenSize.height * 0.45;

    return Stack(
      children: [
        // 1. Capa oscura con recorte transparente sobre el objetivo
        if (target != null)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: CustomPaint(
                painter: _SpotlightPainter(
                  targetRect: target,
                  borderRadius: 14.0,
                ),
              ),
            ),
          )
        else
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.75),
            ),
          ),

        // 2. Anillo dorado pulsante alrededor del objetivo
        if (target != null)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (ctx, child) {
              final scale = _pulseAnimation.value;
              final expandedRect = Rect.fromCenter(
                center: target.center,
                width: target.width * scale + 8,
                height: target.height * scale + 8,
              );

              return Positioned(
                left: expandedRect.left,
                top: expandedRect.top,
                width: expandedRect.width,
                height: expandedRect.height,
                child: IgnorePointer(
                  ignoring: true,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFDE047),
                        width: 2.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

        // 3. Tarjeta flotante pedagógica estilo pizarra (#1E293B) con bordes dorados
        Positioned(
          left: 20,
          right: 20,
          top: putCardAtTop ? MediaQuery.of(context).padding.top + 50 : null,
          bottom: putCardAtTop ? null : 40,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFF59E0B),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila superior: Plaqueta de paso y botón omitir
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'LECCIÓN ${widget.currentStep} DE ${widget.totalSteps}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (widget.onSkip != null)
                      GestureDetector(
                        onTap: widget.onSkip,
                        child: const Row(
                          children: [
                            Text(
                              'Saltar',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.close_rounded, color: Colors.white60, size: 16),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Título de la etapa
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Color(0xFFFDE047),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Instrucción detallada
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 8),
                      child: Icon(Icons.touch_app_rounded, color: Color(0xFF38BDF8), size: 18),
                    ),
                    Expanded(
                      child: Text(
                        widget.instruction,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// CustomPainter que recorta un rectángulo transparente sobre una pantalla oscurecida.
class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final double borderRadius;

  _SpotlightPainter({
    required this.targetRect,
    this.borderRadius = 14.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());

    // Capa oscura de fondo (75% opacidad)
    canvas.drawColor(Colors.black.withValues(alpha: 0.75), BlendMode.srcOver);

    // Recorte transparente
    final holePaint = Paint()..blendMode = BlendMode.clear;
    final rrect = RRect.fromRectAndRadius(
      targetRect.inflate(6.0),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(rrect, holePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect || oldDelegate.borderRadius != borderRadius;
  }
}
