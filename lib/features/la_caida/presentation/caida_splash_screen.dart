import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/services/user_profile_service.dart';
import 'caida_lobby_screen.dart';
import 'widgets/profile_options_dialog.dart';

/// Pantalla de bienvenida y portada estilizada para La Caída,
/// inspirada en la captura con fondo chevron púrpura y tipografía 3D abombada.
class CaidaSplashScreen extends StatefulWidget {
  const CaidaSplashScreen({super.key});

  @override
  State<CaidaSplashScreen> createState() => _CaidaSplashScreenState();
}

class _CaidaSplashScreenState extends State<CaidaSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _proceedToLobby() async {
    final profileService = UserProfileService();
    if (profileService.isFirstTime && mounted) {
      await ProfileOptionsDialog.show(context);
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const CaidaLobbyScreen(),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _proceedToLobby,
        child: Stack(
          children: [
            // 1. Fondo de Chevrons en zigzag Púrpura / Azul Rey
            Positioned.fill(
              child: CustomPaint(
                painter: _ChevronBackgroundPainter(),
              ),
            ),

            // Botón de regresar al Compendio en la esquina superior izquierda
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Volver al compendio',
              ),
            ),

            // 2. Logotipo Central 3D con Sombras
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título 3D abombado
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Sombra 3D profunda
                      Transform.translate(
                        offset: const Offset(4, 8),
                        child: Text(
                          'CAÍDA',
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            foreground: Paint()
                              ..style = PaintingStyle.fill
                              ..color = const Color(0xFF0369A1).withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      // Texto frontal celeste brillante
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF38BDF8), Color(0xFF0284C7), Color(0xFF0369A1)],
                        ).createShader(bounds),
                        child: Text(
                          'CAÍDA',
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 6
                              ..color = const Color(0xFF0284C7),
                          ),
                        ),
                      ),
                      const Text(
                        'CAÍDA',
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: Color(0xFF38BDF8),
                        ),
                      ),

                      // Rótulo manuscrito "Criolla / Tradicional"
                      Positioned(
                        bottom: -4,
                        right: 12,
                        child: Transform.rotate(
                          angle: -math.pi / 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA855F7),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF9333EA).withValues(alpha: 0.6),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Tradicional',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Cartas en abanico decorativas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMiniCardDecor(-math.pi / 12, const Color(0xFFFDE047), '👑'),
                      _buildMiniCardDecor(0, const Color(0xFF38BDF8), '⚔️'),
                      _buildMiniCardDecor(math.pi / 12, const Color(0xFFF43F5E), '🏆'),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Botón inferior pulsante "Tocar para entrar"
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 48,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.06);
                  return Transform.scale(
                    scale: scale,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF0D9488)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF7DD3FC), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                            SizedBox(width: 8),
                            Text(
                              'TOCAR PARA ENTRAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCardDecor(double angle, Color borderColor, String emoji) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 44,
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }
}

/// CustomPainter para generar el patrón en zigzag / chevrons en tonos púrpuras
class _ChevronBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2E1065), Color(0xFF3B0764), Color(0xFF1E1B4B)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Dibujar chevrons repetitivos con bandas alternas
    final chevronHeight = 56.0;
    final halfWidth = size.width / 2;
    final totalChevrons = (size.height / (chevronHeight * 0.75)).ceil() + 3;

    final paint1 = Paint()
      ..color = const Color(0xFF4C1D95).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = const Color(0xFF581C87).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    for (int i = -1; i < totalChevrons; i++) {
      final y = i * chevronHeight * 0.8;
      final path = Path()
        ..moveTo(0, y)
        ..lineTo(halfWidth, y - chevronHeight * 0.4)
        ..lineTo(size.width, y)
        ..lineTo(size.width, y + chevronHeight * 0.5)
        ..lineTo(halfWidth, y + chevronHeight * 0.1)
        ..lineTo(0, y + chevronHeight * 0.5)
        ..close();

      canvas.drawPath(path, i % 2 == 0 ? paint1 : paint2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
