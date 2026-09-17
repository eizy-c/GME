import 'package:flutter/material.dart';
import 'speech_bubble.dart';

enum PlayerPositionOnTable { bottom, top, left, right }

/// Badge visual para representar a cualquier jugador o bot en la mesa.
/// Incluye avatar ilustrado, barra de tiempo de turno, conteo de cartas/puntos,
/// indicador de bot y bocadillo de diálogo de cantos.
class TablePlayerBadge extends StatelessWidget {
  final String name;
  final int scoreOrCards;
  final bool isBot;
  final bool isCurrentTurn;
  final double turnProgress; // 0.0 a 1.0 para la barra de tiempo verde
  final PlayerPositionOnTable position;
  final String? calloutMessage;
  final int cardsInHandCount;
  final Color avatarColor;
  final bool isMano;
  final VoidCallback? onTap;

  const TablePlayerBadge({
    super.key,
    required this.name,
    required this.scoreOrCards,
    this.isBot = true,
    this.isCurrentTurn = false,
    this.turnProgress = 1.0,
    this.position = PlayerPositionOnTable.top,
    this.calloutMessage,
    this.cardsInHandCount = 3,
    this.avatarColor = const Color(0xFF6366F1),
    this.isMano = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra de tiempo de turno animada (verde brillante) si es su turno
              if (isCurrentTurn) ...[
                _buildTurnTimerBar(),
                const SizedBox(height: 4),
              ],

              // Contenedor principal del Avatar y sus etiquetas
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Cuadro del Avatar con borde brillante si está en turno
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B4B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrentTurn
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF818CF8).withValues(alpha: 0.6),
                        width: isCurrentTurn ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        if (isCurrentTurn)
                          BoxShadow(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        else
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            color: avatarColor.withValues(alpha: 0.35),
                          ),
                          Icon(
                            isBot ? Icons.smart_toy_rounded : Icons.person_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Insignia dorada de Mano (jugador con prioridad en la mano/ronda)
                  if (isMano)
                    Positioned(
                      top: -7,
                      left: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFDE047), Color(0xFFEAB308)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEAB308).withValues(alpha: 0.7),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pan_tool_alt_rounded, size: 9, color: Color(0xFF713F12)),
                            SizedBox(width: 2),
                            Text(
                              'MANO',
                              style: TextStyle(
                                color: Color(0xFF713F12),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Indicador de Bot (+🤖 verde menta) en la esquina superior derecha
                  if (isBot)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 2),
                          ],
                        ),
                        child: const Icon(Icons.smart_toy_rounded, size: 10, color: Colors.white),
                      ),
                    ),

                  // Chip de cartas/puntos (cajita oscura con borde)
                  Positioned(
                    bottom: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCurrentTurn ? const Color(0xFF22C55E) : Colors.white54,
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 3),
                        ],
                      ),
                      child: Text(
                        '$scoreOrCards',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              // Nombre del jugador
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrentTurn ? const Color(0xFF86EFAC) : Colors.white,
                    fontSize: 11,
                    fontWeight: isCurrentTurn ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),

              // Representación de cartas en mano para rivales
              if (position != PlayerPositionOnTable.bottom && cardsInHandCount > 0) ...[
                const SizedBox(height: 3),
                _buildMiniFacedownCards(),
              ],
            ],
          ),
        ),

        // Bocadillo de canto ("Patrulla", "Ronda", "¡Caída!", "Truco")
        if (calloutMessage != null && calloutMessage!.isNotEmpty)
          Positioned(
            top: position == PlayerPositionOnTable.top ? 64 : -45,
            child: SpeechBubble(
              text: calloutMessage!,
              pointsDown: position != PlayerPositionOnTable.top,
            ),
          ),
      ],
    );
  }

  Widget _buildTurnTimerBar() {
    return Container(
      width: 50,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: turnProgress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E),
            borderRadius: BorderRadius.circular(3),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF22C55E),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniFacedownCards() {
    // Si la posición es izquierda o derecha, se pueden mostrar de lado
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
