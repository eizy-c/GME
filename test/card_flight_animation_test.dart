import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gme/core/models/cards/card_suit.dart';
import 'package:gme/core/models/cards/spanish_card.dart';
import 'package:gme/core/presentation/widgets/spanish_card_view.dart';
import 'package:gme/features/la_caida/domain/models/spatial_card_state.dart';
import 'package:gme/features/la_caida/presentation/widgets/card_flight_overlay.dart';

void main() {
  group('SpatialCardAnchor & CardFlightTrajectory Tests', () {
    const testCard = SpanishCard(number: 1, suit: CardSuit.oros);

    test('SpatialCardAnchor calcula anclas fijas de mazo y estaciones de jugadores', () {
      // Ancla de mazo
      expect(SpatialCardAnchor.deckAnchor.offset.dx, -140);
      expect(SpatialCardAnchor.deckAnchor.offset.dy, -180);

      // Ancla del usuario (Asiento 0)
      final userAnchor = SpatialCardAnchor.playerStationAnchor(playerIndex: 0, totalPlayers: 2);
      expect(userAnchor.offset.dy, 240);

      // Ancla de rival en 2 jugadores (Asiento 1)
      final rivalAnchor2P = SpatialCardAnchor.playerStationAnchor(playerIndex: 1, totalPlayers: 2);
      expect(rivalAnchor2P.offset.dy, -220);

      // Anclas en 4 jugadores (Cruz)
      final rival1 = SpatialCardAnchor.playerStationAnchor(playerIndex: 1, totalPlayers: 4);
      final teammate = SpatialCardAnchor.playerStationAnchor(playerIndex: 2, totalPlayers: 4);
      final rival3 = SpatialCardAnchor.playerStationAnchor(playerIndex: 3, totalPlayers: 4);

      expect(rival1.offset.dx, -145);
      expect(teammate.offset.dy, -220);
      expect(rival3.offset.dx, 145);
    });

    test('SpatialCardAnchor userHandSlotAnchor distribuye posiciones y rotaciones de abanico', () {
      final slot0 = SpatialCardAnchor.userHandSlotAnchor(cardIndex: 0, totalCardsInHand: 3);
      final slot1 = SpatialCardAnchor.userHandSlotAnchor(cardIndex: 1, totalCardsInHand: 3);
      final slot2 = SpatialCardAnchor.userHandSlotAnchor(cardIndex: 2, totalCardsInHand: 3);

      expect(slot0.offset.dx, lessThan(slot1.offset.dx));
      expect(slot1.offset.dx, lessThan(slot2.offset.dx));
      expect(slot0.rotation, lessThan(0.0));
      expect(slot1.rotation, 0.0);
      expect(slot2.rotation, greaterThan(0.0));
    });

    test('CardFlightTrajectory positionAt genera trayectoria con arco 3D y escala en cenit', () {
      final trajectory = CardFlightTrajectory(
        id: 'test_flight_1',
        card: testCard,
        startAnchor: const SpatialCardAnchor(offset: Offset(0, 200), rotation: 0.0),
        targetAnchor: const SpatialCardAnchor(offset: Offset(0, 0), rotation: 0.1),
        duration: const Duration(milliseconds: 300),
      );

      // Inicio (t = 0)
      final posStart = trajectory.positionAt(0.0);
      expect(posStart.dy, closeTo(200.0, 1.0));

      // Cenit (t = 0.5): La coordenada Y debe tener arco de elevación
      final posMid = trajectory.positionAt(0.5);
      expect(posMid.dy, lessThan(100.0)); // Más elevado por el arco 3D

      // Fin (t = 1.0)
      final posEnd = trajectory.positionAt(1.0);
      expect(posEnd.dy, closeTo(0.0, 1.0));

      // Escala visual en el punto medio
      expect(trajectory.scaleAt(0.5), greaterThan(1.0));
    });

    testWidgets('CardFlightOverlay renderiza naipe en vuelo y notifica onAllCompleted', (tester) async {
      bool completed = false;

      final trajectory = CardFlightTrajectory(
        id: 'flight_test',
        card: testCard,
        startAnchor: const SpatialCardAnchor(offset: Offset(0, 100)),
        targetAnchor: const SpatialCardAnchor(offset: Offset(0, -100)),
        duration: const Duration(milliseconds: 200),
        isCaidaImpact: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CardFlightOverlay(
                activeTrajectories: [trajectory],
                onAllCompleted: () {
                  completed = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CardFlightOverlay), findsOneWidget);

      // Avanzar la animación de vuelo
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 150));

      expect(completed, isTrue);
    });

    test('SpanishCardView.getCardAssetPath mapea cartas y figuras con precisión 1:1', () {
      // 1 de Bastos
      expect(
        SpanishCardView.getCardAssetPath(const SpanishCard(number: 1, suit: CardSuit.bastos)),
        'assets/cards/BASTON/B-1-CARD.png',
      );
      // 10 Sota de Espadas
      expect(
        SpanishCardView.getCardAssetPath(const SpanishCard(number: 10, suit: CardSuit.espadas)),
        'assets/cards/ESPADAS/E-S-CARD.png',
      );
      // 11 Caballo de Copas
      expect(
        SpanishCardView.getCardAssetPath(const SpanishCard(number: 11, suit: CardSuit.copas)),
        'assets/cards/COPAS/C-C-CARD.png',
      );
      // 12 Rey de Oros
      expect(
        SpanishCardView.getCardAssetPath(const SpanishCard(number: 12, suit: CardSuit.oros)),
        'assets/cards/OROS/O-R-CARD.png',
      );
      // Reverso
      expect(SpanishCardView.backAssetPath, 'assets/cards/REV-CARD.png');
    });
  });
}
