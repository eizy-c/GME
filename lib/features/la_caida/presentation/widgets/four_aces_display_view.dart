import 'package:flutter/material.dart';
import '../../../../core/models/cards/card_suit.dart';
import '../../../../core/models/cards/spanish_card.dart';
import '../../../../core/presentation/widgets/spanish_card_view.dart';

/// Widget visual para renderizar los 4 Ases (1 de cada palo) de la Baraja Española
/// en un abanico natural tridimensional sobre el tapete central del lobby.
class FourAcesDisplayView extends StatelessWidget {
  final double cardWidth;

  const FourAcesDisplayView({
    super.key,
    this.cardWidth = 72.0,
  });

  @override
  Widget build(BuildContext context) {
    final cardHeight = cardWidth * 1.55;

    // Los 4 Ases de la Baraja Española tradicional
    const aces = [
      SpanishCard(number: 1, suit: CardSuit.oros),
      SpanishCard(number: 1, suit: CardSuit.copas),
      SpanishCard(number: 1, suit: CardSuit.espadas),
      SpanishCard(number: 1, suit: CardSuit.bastos),
    ];

    // Configuración de abanico armónico
    final fanConfig = [
      _AceFanSlot(offset: const Offset(-48, 12), rotation: -0.25, zIndex: 1),
      _AceFanSlot(offset: const Offset(-16, 2), rotation: -0.08, zIndex: 2),
      _AceFanSlot(offset: const Offset(16, 2), rotation: 0.08, zIndex: 3),
      _AceFanSlot(offset: const Offset(48, 12), rotation: 0.25, zIndex: 4),
    ];

    return SizedBox(
      width: cardWidth * 2.8,
      height: cardHeight * 1.2,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: List.generate(4, (i) {
          final ace = aces[i];
          final config = fanConfig[i];

          return Positioned(
            left: (cardWidth * 1.4) + config.offset.dx - (cardWidth / 2),
            top: (cardHeight * 0.1) + config.offset.dy,
            child: Transform.rotate(
              angle: config.rotation,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cardWidth * 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: SpanishCardView(
                  card: ace,
                  width: cardWidth,
                  height: cardHeight,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AceFanSlot {
  final Offset offset;
  final double rotation;
  final int zIndex;

  const _AceFanSlot({
    required this.offset,
    required this.rotation,
    required this.zIndex,
  });
}
