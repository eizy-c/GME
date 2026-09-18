import 'package:flutter/material.dart';
import '../../../features/la_caida/presentation/widgets/avatar_view.dart';
import 'speech_bubble.dart';

enum PlayerPositionOnTable { bottom, top, left, right }

/// Badge visual unificado para representar a cualquier jugador o bot en la mesa.
/// Traduce el diseño técnico del boceto:
/// - Barra de tiempo curva en la esquina superior izquierda.
/// - Corona dorada flotante de "Mano" en la esquina superior derecha.
/// - Cápsulas gemelas de Puntos (★) y Cartas recogidas (🎴) en el borde inferior del avatar.
/// - Placa horizontal redondeada con el nombre del jugador.
/// - Mini-cartas boca abajo para rivales.
class TablePlayerBadge extends StatelessWidget {
  final String name;
  final int? scoreOrCards;
  final int? score;
  final int? cardsWon;
  final bool isBot;
  final bool isCurrentTurn;
  final double turnProgress; // 0.0 a 1.0 para la barra de tiempo
  final PlayerPositionOnTable position;
  final String? calloutMessage;
  final int cardsInHandCount;
  final Color avatarColor;
  final bool isMano;
  final int? avatarId;
  final VoidCallback? onTap;

  const TablePlayerBadge({
    super.key,
    required this.name,
    this.scoreOrCards,
    this.score,
    this.cardsWon,
    this.isBot = true,
    this.isCurrentTurn = false,
    this.turnProgress = 1.0,
    this.position = PlayerPositionOnTable.top,
    this.calloutMessage,
    this.cardsInHandCount = 3,
    this.avatarColor = const Color(0xFF6366F1),
    this.isMano = false,
    this.avatarId,
    this.onTap,
  }) : assert(scoreOrCards != null || score != null, 'Debe especificarse score o scoreOrCards');

  @override
  Widget build(BuildContext context) {
    const avatarSize = 56.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Contenedor del Avatar con decoraciones flotantes
              SizedBox(
                width: avatarSize,
                height: avatarSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // 1. Barra de tiempo curva en la esquina superior izquierda
                    if (isCurrentTurn)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CurvedCornerTimerPainter(
                            progress: turnProgress,
                            isCurrentTurn: isCurrentTurn,
                          ),
                        ),
                      ),

                    // 2. Cuadro del Avatar con squircle y borde suave
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B4B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrentTurn
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF818CF8).withValues(alpha: 0.5),
                          width: isCurrentTurn ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          if (isCurrentTurn)
                            BoxShadow(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.45),
                              blurRadius: 10,
                              spreadRadius: 1.5,
                            )
                          else
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: avatarId != null
                            ? AvatarView(
                                avatarId: avatarId!,
                                size: avatarSize,
                                showBorder: false,
                              )
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    color: avatarColor.withValues(alpha: 0.35),
                                  ),
                                  Icon(
                                    isBot ? Icons.smart_toy_rounded : Icons.person_rounded,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                      ),
                    ),

                    // 3. Corona dorada flotante de "MANO" en la esquina superior derecha
                    if (isMano)
                      Positioned(
                        top: -8,
                        right: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFDE047), Color(0xFFEAB308)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEAB308).withValues(alpha: 0.65),
                                blurRadius: 6,
                                spreadRadius: 1,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '👑',
                                style: TextStyle(fontSize: 9.5, height: 1.0),
                              ),
                              SizedBox(width: 2.5),
                              Text(
                                'MANO',
                                style: TextStyle(
                                  color: Color(0xFF713F12),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 4. Cápsulas gemelas: Puntos (★) y Cartas recogidas (🎴) en el borde inferior
                    Positioned(
                      bottom: -9,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPointsPill(),
                          if (cardsWon != null) ...[
                            const SizedBox(width: 3),
                            _buildCardsWonPill(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Separación para librar las cápsulas que sobresalen hacia abajo
              const SizedBox(height: 12),

              // 5. Placa horizontal del Nombre del Jugador
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrentTurn
                        ? const Color(0xFF22C55E).withValues(alpha: 0.8)
                        : Colors.white24,
                    width: isCurrentTurn ? 1.2 : 0.8,
                  ),
                  boxShadow: [
                    if (isCurrentTurn)
                      BoxShadow(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    else
                      const BoxShadow(
                        color: Colors.black38,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isBot) ...[
                      const Icon(Icons.smart_toy_rounded, size: 10, color: Color(0xFF2DD4BF)),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrentTurn ? const Color(0xFF86EFAC) : Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // 6. Mini-cartas en mano para rivales
              if (position != PlayerPositionOnTable.bottom && cardsInHandCount > 0) ...[
                const SizedBox(height: 3),
                _buildMiniFacedownCards(),
              ],
            ],
          ),
        ),

        // Bocadillo flotante de cantos
        if (calloutMessage != null && calloutMessage!.isNotEmpty)
          Positioned(
            top: position == PlayerPositionOnTable.top ? 85 : -52,
            child: SpeechBubble(
              text: calloutMessage!,
              pointsDown: position != PlayerPositionOnTable.top,
            ),
          ),
      ],
    );
  }

  /// Cápsula izquierda: Puntos (★)
  Widget _buildPointsPill() {
    final displayValue = score ?? scoreOrCards ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 10.5, color: Color(0xFFFDE047)),
          const SizedBox(width: 2),
          Text(
            '$displayValue',
            style: const TextStyle(
              color: Color(0xFFFDE047),
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  /// Cápsula derecha: Cartas recogidas (🎴)
  Widget _buildCardsWonPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.style_rounded, size: 9.5, color: Color(0xFF38BDF8)),
          const SizedBox(width: 2),
          Text(
            '$cardsWon',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFacedownCards() {
    final count = cardsInHandCount.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        return Transform.translate(
          offset: Offset(index * -4.0, 0),
          child: Container(
            width: 14,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.white70, width: 0.8),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 2),
              ],
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 14,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFBBF24), width: 0.5),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Painter para la barra de tiempo en L / curva en la esquina superior izquierda del avatar
class _CurvedCornerTimerPainter extends CustomPainter {
  final double progress;
  final bool isCurrentTurn;

  _CurvedCornerTimerPainter({
    required this.progress,
    required this.isCurrentTurn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isCurrentTurn) return;

    const strokeWidth = 3.8;
    const padding = 2.5;
    const cornerRadius = 16.0;

    // Ruta en L curvada que abraza la esquina superior izquierda del avatar:
    // Empieza a 65% de altura en el lateral izquierdo, sube por la esquina redondeada
    // y termina a 65% de ancho en el borde superior.
    final path = Path();
    final startY = size.height * 0.65;
    final endX = size.width * 0.65;

    path.moveTo(-padding, startY);
    path.lineTo(-padding, cornerRadius);
    path.arcToPoint(
      const Offset(cornerRadius, -padding),
      radius: const Radius.circular(cornerRadius + padding),
      clockwise: true,
    );
    path.lineTo(endX, -padding);

    // 1. Trazado sutil de fondo
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, trackPaint);

    // 2. Trazo de progreso activo
    final clampedProgress = progress.clamp(0.0, 1.0);
    if (clampedProgress <= 0.001) return;

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final extractLength = metric.length * clampedProgress;
    final progressPath = metric.extractPath(0, extractLength);

    final isWarning = clampedProgress <= 0.25;
    final activeColor = isWarning
        ? const Color(0xFFEF4444)
        : const Color(0xFF22C55E);

    // Resplandor exterior
    final glowPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    canvas.drawPath(progressPath, glowPaint);

    // Trazo principal nítido
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(progressPath, activePaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedCornerTimerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isCurrentTurn != isCurrentTurn;
  }
}
