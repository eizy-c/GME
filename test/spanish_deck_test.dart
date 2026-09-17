import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gme/core/models/cards/card_suit.dart';
import 'package:gme/core/models/cards/spanish_card.dart';
import 'package:gme/core/models/cards/spanish_deck.dart';

void main() {
  group('SpanishDeck & SpanishCard Tests', () {
    test('El mazo estándar contiene exactamente 40 cartas únicas', () {
      final deck = SpanishDeck();
      expect(deck.remainingCount, equals(40));

      final cardsSet = <String>{};
      for (final card in deck.remainingCards) {
        cardsSet.add(card.shortCode);
      }
      expect(cardsSet.length, equals(40));
    });

    test('No contiene cartas 8 ni 9 en ningún palo', () {
      final deck = SpanishDeck();
      for (final card in deck.remainingCards) {
        expect(card.number, isNot(isIn([8, 9])));
        expect(
          (card.number >= 1 && card.number <= 7) ||
              (card.number >= 10 && card.number <= 12),
          isTrue,
        );
      }
    });

    test('Contiene exactamente 10 cartas de cada uno de los 4 palos', () {
      final deck = SpanishDeck();
      for (final suit in CardSuit.values) {
        final suitCards =
            deck.remainingCards.where((c) => c.suit == suit).toList();
        expect(suitCards.length, equals(10));
      }
    });

    test('Identifica correctamente figuras (Sota 10, Caballo 11, Rey 12)', () {
      const sota = SpanishCard(number: 10, suit: CardSuit.espadas);
      const caballo = SpanishCard(number: 11, suit: CardSuit.copas);
      const rey = SpanishCard(number: 12, suit: CardSuit.oros);
      const as = SpanishCard(number: 1, suit: CardSuit.bastos);

      expect(sota.isFigure, isTrue);
      expect(sota.rankName, equals('Sota'));
      expect(caballo.isFigure, isTrue);
      expect(caballo.rankName, equals('Caballo'));
      expect(rey.isFigure, isTrue);
      expect(rey.rankName, equals('Rey'));
      expect(as.isFigure, isFalse);
      expect(as.rankName, equals('As'));
    });

    test('Barajado aleatorio altera el orden conservando las 40 cartas', () {
      final deck = SpanishDeck();
      final initialCodes = deck.remainingCards.map((c) => c.shortCode).toList();

      deck.shuffle(Random(42));
      final shuffledCodes =
          deck.remainingCards.map((c) => c.shortCode).toList();

      expect(deck.remainingCount, equals(40));
      expect(shuffledCodes, isNot(equals(initialCodes)));
      expect(shuffledCodes.toSet(), equals(initialCodes.toSet()));
    });

    test('Corte de mazo traslada las porciones correctamente', () {
      final deck = SpanishDeck();
      final originalTop = deck.remainingCards.first;
      final middleCard = deck.remainingCards[20];
      final cardBeforeCut = deck.remainingCards[19];

      deck.cut(20);
      // La porción inferior ahora está arriba
      expect(deck.remainingCards.first, equals(middleCard));
      // La porción superior ahora está abajo, con cardBeforeCut al final
      expect(deck.remainingCards.last, equals(cardBeforeCut));
      expect(deck.remainingCards[20], equals(originalTop));
      expect(deck.remainingCount, equals(40));
    });

    test('Reparto a jugadores para La Caída o Truco (3 cartas a cada uno)', () {
      final deck = SpanishDeck();
      deck.shuffle(Random(123));

      final players = ['jugador_1', 'jugador_2'];
      final hands = deck.dealToPlayers(players, 3);

      expect(hands['jugador_1']!.length, equals(3));
      expect(hands['jugador_2']!.length, equals(3));
      expect(deck.remainingCount, equals(34));

      // Las cartas repartidas no se repiten entre manos
      final allDealtCards = [...hands['jugador_1']!, ...hands['jugador_2']!];
      expect(allDealtCards.toSet().length, equals(6));
    });

    test('Personalización de jerarquía para juegos (withRules)', () {
      const asDeEspadas = SpanishCard(number: 1, suit: CardSuit.espadas);
      final trucoAs = asDeEspadas.withRules(hierarchy: 14);

      expect(asDeEspadas.hierarchyValue, equals(0));
      expect(trucoAs.hierarchyValue, equals(14));
      expect(trucoAs.compareTo(asDeEspadas), greaterThan(0));
    });
  });
}
