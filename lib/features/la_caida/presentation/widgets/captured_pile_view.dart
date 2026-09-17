import 'package:flutter/material.dart';

/// Componente visual que representa el "Pozo de Cartas Recogidas" de un jugador en la mesa.
/// Permite ver el montoncito de cartas capturadas y el total acumulado rumbo a la meta de 20 cartas.
class CapturedPileView extends StatelessWidget {
  final String playerName;
  final int cardsCount;
  final Color accentColor;
  final bool isUser;

  const CapturedPileView({
    super.key,
    required this.playerName,
    required this.cardsCount,
    this.accentColor = const Color(0xFF38BDF8),
    this.isUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasCards = cardsCount > 0;
    // Si tiene más de 20 cartas, resalta en dorado (bonificación de volumen)
    final isBonusZone = cardsCount > 20;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBonusZone
              ? const Color(0xFFFDE047)
              : hasCards
                  ? accentColor.withValues(alpha: 0.6)
                  : Colors.white12,
          width: isBonusZone ? 1.4 : 1,
        ),
        boxShadow: isBonusZone
            ? [
                BoxShadow(
                  color: const Color(0xFFEAB308).withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono representativo de cartas apiladas
          Stack(
            children: [
              Container(
                width: 14,
                height: 18,
                decoration: BoxDecoration(
                  color: hasCards ? const Color(0xFF991B1B) : Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.white38, width: 0.5),
                ),
              ),
              if (hasCards)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Container(
                    width: 14,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB91C1C),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: const Color(0xFFFDE047), width: 0.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$cardsCount',
                style: TextStyle(
                  color: isBonusZone
                      ? const Color(0xFFFDE047)
                      : (hasCards ? Colors.white : Colors.white60),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                isBonusZone ? '+${cardsCount - 20} pts' : 'recogidas',
                style: TextStyle(
                  color: isBonusZone ? const Color(0xFFFDE047) : Colors.white54,
                  fontSize: 8,
                  fontWeight: isBonusZone ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
