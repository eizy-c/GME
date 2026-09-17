import 'package:flutter/material.dart';

/// Componente visual que representa el mazo de cartas físicas sobre la mesa.
/// Muestra un efecto apilado tridimensional en capas y el contador numérico
/// dinámico de cartas restantes para ver en tiempo real cómo se va agotando.
class DeckStackView extends StatelessWidget {
  final int remainingCards;
  final VoidCallback? onTap;

  const DeckStackView({
    super.key,
    required this.remainingCards,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCards = remainingCards > 0;
    // La altura del apilado es proporcional a las cartas restantes (hasta 4 capas)
    final stackLayers = hasCards ? (remainingCards / 10).ceil().clamp(1, 4) : 0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 58,
            height: 82,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!hasCards)
                  // Huella o silueta del mazo vacío sobre el tapete
                  Container(
                    width: 52,
                    height: 74,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white24,
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.layers_clear_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ),
                  )
                else
                  // Capas apiladas tridimensionales
                  ...List.generate(stackLayers, (index) {
                    final offset = (stackLayers - 1 - index) * 2.2;
                    return Positioned(
                      top: offset,
                      left: offset * 0.8,
                      child: _buildCardBack(isTop: index == stackLayers - 1),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Píldora con el contador de cartas en el mazo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: hasCards ? const Color(0xFF0F172A).withValues(alpha: 0.88) : Colors.black54,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasCards ? const Color(0xFF38BDF8).withValues(alpha: 0.7) : Colors.white24,
                width: 1,
              ),
              boxShadow: hasCards
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.style_rounded,
                  size: 10,
                  color: hasCards ? const Color(0xFF38BDF8) : Colors.white54,
                ),
                const SizedBox(width: 4),
                Text(
                  hasCards ? '$remainingCards' : 'Agotado',
                  style: TextStyle(
                    color: hasCards ? Colors.white : Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack({required bool isTop}) {
    return Container(
      width: 52,
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xFF881337), // Rojo carmesí tradicional de reverso
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTop ? const Color(0xFFFDE047) : const Color(0xFF4C0519),
          width: isTop ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 44,
          height: 66,
          decoration: BoxDecoration(
            color: const Color(0xFF9F1239),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFB7185).withValues(alpha: 0.5), width: 0.8),
          ),
          child: Center(
            child: Icon(
              Icons.all_inclusive_rounded,
              size: 16,
              color: const Color(0xFFFDE047).withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}
