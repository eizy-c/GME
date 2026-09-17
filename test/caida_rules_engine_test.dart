import 'package:flutter_test/flutter_test.dart';
import 'package:gme/core/models/cards/card_suit.dart';
import 'package:gme/core/models/cards/spanish_card.dart';
import 'package:gme/core/models/cards/spanish_deck.dart';
import 'package:gme/features/la_caida/domain/caida_models.dart';
import 'package:gme/features/la_caida/domain/caida_rules_engine.dart';

void main() {
  group('CaidaRulesEngine - Secuencia y Puntuación Base', () {
    test('Secuencia canónica española (sin 8 ni 9) y getNextInSequence', () {
      expect(CaidaRulesEngine.sequence, equals([1, 2, 3, 4, 5, 6, 7, 10, 11, 12]));
      expect(CaidaRulesEngine.getNextInSequence(1), equals(2));
      expect(CaidaRulesEngine.getNextInSequence(6), equals(7));
      expect(CaidaRulesEngine.getNextInSequence(7), equals(10), reason: 'Después de 7 sigue Sota (10)');
      expect(CaidaRulesEngine.getNextInSequence(10), equals(11));
      expect(CaidaRulesEngine.getNextInSequence(11), equals(12));
      expect(CaidaRulesEngine.getNextInSequence(12), equals(-1));
    });

    test('areConsecutive respeta el salto de 7 a 10', () {
      expect(CaidaRulesEngine.areConsecutive(5, 6), isTrue);
      expect(CaidaRulesEngine.areConsecutive(7, 10), isTrue, reason: '7 y 10 son correlativos');
      expect(CaidaRulesEngine.areConsecutive(10, 11), isTrue);
      expect(CaidaRulesEngine.areConsecutive(7, 8), isFalse);
      expect(CaidaRulesEngine.areConsecutive(6, 10), isFalse);
    });

    test('Puntuación de Ronda y Caída por figura', () {
      expect(CaidaRulesEngine.getCardCaidaPoints(4), equals(1));
      expect(CaidaRulesEngine.getCardCaidaPoints(7), equals(1));
      expect(CaidaRulesEngine.getCardCaidaPoints(10), equals(2));
      expect(CaidaRulesEngine.getCardCaidaPoints(11), equals(3));
      expect(CaidaRulesEngine.getCardCaidaPoints(12), equals(4));
    });
  });

  group('CaidaRulesEngine - 1. Reparto Inicial y Canto de Mesa', () {
    test('Reparto inicial con 4 cartas sin números repetidos', () {
      final deck = SpanishDeck()..shuffle();
      final result = CaidaRulesEngine.dealInitialTable(
        direction: DealDirection.ascending,
        deck: deck,
        dealerId: 'user',
        opponentId: 'player_1',
      );

      expect(result.tableCards.length, equals(4));
      final numbers = result.tableCards.map((c) => c.number).toSet();
      expect(numbers.length, equals(4), reason: 'No deben existir números repetidos en mesa');
    });

    test('Acierto de canto de mesa suma el valor exacto de la carta cantada', () {
      final customCards = [
        const SpanishCard(number: 1, suit: CardSuit.oros),
        const SpanishCard(number: 5, suit: CardSuit.copas),
        const SpanishCard(number: 3, suit: CardSuit.espadas),
        const SpanishCard(number: 4, suit: CardSuit.bastos),
      ];

      final mockDeck = SpanishDeck.fromCards(customCards);

      // Cantando ascendente: 1 (acierta 1: +1), 2 (sale 5: no), 3 (acierta 3: +3), 4 (acierta 4: +4)
      final result = CaidaRulesEngine.dealInitialTable(
        direction: DealDirection.ascending,
        deck: mockDeck,
        dealerId: 'dealer',
        opponentId: 'rival',
      );

      expect(result.tableCards.length, equals(4));
      expect(result.matches[0], isTrue); // Cantó 1 y salió 1 -> +1
      expect(result.matches[1], isFalse); // Cantó 2 y salió 5
      expect(result.matches[2], isTrue); // Cantó 3 y salió 3 -> +3
      expect(result.matches[3], isTrue); // Cantó 4 y salió 4 -> +4
      expect(result.dealerPoints, equals(1 + 3 + 4));
    });

    test('Si el repartidor no acierta ningún número, rival suma +1 punto', () {
      // Cartas 5, 6, 7, 10 nunca coinciden con [1, 2, 3, 4]
      final noHits = [
        const SpanishCard(number: 5, suit: CardSuit.oros),
        const SpanishCard(number: 6, suit: CardSuit.copas),
        const SpanishCard(number: 7, suit: CardSuit.espadas),
        const SpanishCard(number: 10, suit: CardSuit.bastos),
      ];

      final mockDeck = SpanishDeck.fromCards(noHits);

      final result = CaidaRulesEngine.dealInitialTable(
        direction: DealDirection.ascending,
        deck: mockDeck,
        dealerId: 'dealer',
        opponentId: 'rival',
      );

      expect(result.dealerPoints, equals(0));
      expect(result.opponentPoints, equals(1));
    });
  });

  group('CaidaRulesEngine - 2. Evaluación de Cantos', () {
    test('Trivilín (3 del mismo número) otorga 5 puntos y prioridad 5', () {
      final hand = [
        const SpanishCard(number: 7, suit: CardSuit.oros),
        const SpanishCard(number: 7, suit: CardSuit.copas),
        const SpanishCard(number: 7, suit: CardSuit.espadas),
      ];
      final canto = CaidaRulesEngine.evaluateCantos(hand);
      expect(canto, isNotNull);
      expect(canto!.type, equals(CantoType.trivilin));
      expect(canto.points, equals(5));
      expect(canto.priority, equals(5));
    });

    test('Vigía (2 iguales + 1 consecutiva) otorga 3 puntos y prioridad 4', () {
      // Caso 1: [5, 5, 6]
      final hand1 = [
        const SpanishCard(number: 5, suit: CardSuit.oros),
        const SpanishCard(number: 5, suit: CardSuit.copas),
        const SpanishCard(number: 6, suit: CardSuit.espadas),
      ];
      final c1 = CaidaRulesEngine.evaluateCantos(hand1);
      expect(c1, isNotNull);
      expect(c1!.type, equals(CantoType.vigia));
      expect(c1.points, equals(3));
      expect(c1.priority, equals(4));

      // Caso 2: [7, 7, 10] (7 y 10 son correlativos)
      final hand2 = [
        const SpanishCard(number: 7, suit: CardSuit.oros),
        const SpanishCard(number: 10, suit: CardSuit.copas),
        const SpanishCard(number: 7, suit: CardSuit.espadas),
      ];
      final c2 = CaidaRulesEngine.evaluateCantos(hand2);
      expect(c2, isNotNull);
      expect(c2!.type, equals(CantoType.vigia));
      expect(c2.points, equals(3));
    });

    test('Registro (As, Caballo y Rey [1, 11, 12]) otorga 3 puntos y prioridad 3', () {
      final hand = [
        const SpanishCard(number: 11, suit: CardSuit.bastos),
        const SpanishCard(number: 1, suit: CardSuit.oros),
        const SpanishCard(number: 12, suit: CardSuit.espadas),
      ];
      final canto = CaidaRulesEngine.evaluateCantos(hand);
      expect(canto, isNotNull);
      expect(canto!.type, equals(CantoType.registro));
      expect(canto.points, equals(3));
      expect(canto.priority, equals(3));
    });

    test('Patrulla (3 cartas consecutivas) otorga 2 puntos y prioridad 2', () {
      // Caso 1: [3, 4, 5]
      final hand1 = [
        const SpanishCard(number: 4, suit: CardSuit.oros),
        const SpanishCard(number: 3, suit: CardSuit.copas),
        const SpanishCard(number: 5, suit: CardSuit.espadas),
      ];
      final c1 = CaidaRulesEngine.evaluateCantos(hand1);
      expect(c1, isNotNull);
      expect(c1!.type, equals(CantoType.patrulla));
      expect(c1.points, equals(2));
      expect(c1.priority, equals(2));

      // Caso 2: [7, 10, 11]
      final hand2 = [
        const SpanishCard(number: 7, suit: CardSuit.bastos),
        const SpanishCard(number: 10, suit: CardSuit.copas),
        const SpanishCard(number: 11, suit: CardSuit.espadas),
      ];
      final c2 = CaidaRulesEngine.evaluateCantos(hand2);
      expect(c2, isNotNull);
      expect(c2!.type, equals(CantoType.patrulla));
    });

    test('Ronda (2 iguales no consecutivas con la 3ra) otorga 1..4 puntos', () {
      // Par de 4 con 10 (no consecutivas)
      final hand1 = [
        const SpanishCard(number: 4, suit: CardSuit.oros),
        const SpanishCard(number: 10, suit: CardSuit.copas),
        const SpanishCard(number: 4, suit: CardSuit.espadas),
      ];
      final c1 = CaidaRulesEngine.evaluateCantos(hand1);
      expect(c1, isNotNull);
      expect(c1!.type, equals(CantoType.ronda));
      expect(c1.points, equals(1));
      expect(c1.priority, equals(1));

      // Par de Rey (12) con 3
      final hand2 = [
        const SpanishCard(number: 12, suit: CardSuit.oros),
        const SpanishCard(number: 3, suit: CardSuit.copas),
        const SpanishCard(number: 12, suit: CardSuit.espadas),
      ];
      final c2 = CaidaRulesEngine.evaluateCantos(hand2);
      expect(c2, isNotNull);
      expect(c2!.type, equals(CantoType.ronda));
      expect(c2.points, equals(4), reason: 'Ronda de Rey vale 4 puntos');
    });

    test('Sin cantos retorna null', () {
      final hand = [
        const SpanishCard(number: 1, suit: CardSuit.oros),
        const SpanishCard(number: 4, suit: CardSuit.copas),
        const SpanishCard(number: 10, suit: CardSuit.espadas),
      ];
      expect(CaidaRulesEngine.evaluateCantos(hand), isNull);
    });

    test('Resolución de conflicto: Solo cobra el bando con el canto superior', () {
      final cantos = {
        'player_1': const Canto(
          type: CantoType.ronda,
          points: 4,
          priority: 1,
          tieBreakerValue: 12,
          name: 'Ronda de Rey',
          description: '',
          cards: [],
        ),
        'player_2': const Canto(
          type: CantoType.vigia,
          points: 3,
          priority: 4,
          tieBreakerValue: 506,
          name: 'Vigía',
          description: '',
          cards: [],
        ),
      };

      final teams = {'player_1': 1, 'player_2': 2};

      final resolved = CaidaRulesEngine.resolveCantosConflict(
        playerCantos: cantos,
        playerTeams: teams,
      );

      expect(resolved['player_1'], isNull, reason: 'Ronda pierde contra Vigía');
      expect(resolved['player_2'], isNotNull);
      expect(resolved['player_2']!.points, equals(3));
    });
  });

  group('CaidaRulesEngine - 3. Jugadas de Turno, Caídas y Arrastre', () {
    test('Coincidencia simple y Arrastre en seguidilla (1..7, 10..12)', () {
      // Mesa: [4, 5, 6, 11]
      final table = [
        const SpanishCard(number: 4, suit: CardSuit.oros),
        const SpanishCard(number: 5, suit: CardSuit.copas),
        const SpanishCard(number: 6, suit: CardSuit.espadas),
        const SpanishCard(number: 11, suit: CardSuit.bastos),
      ];

      final play = const SpanishCard(number: 4, suit: CardSuit.copas);

      final result = CaidaRulesEngine.evaluatePlay(
        playedCard: play,
        tableCards: table,
        previousCard: null,
        isDeckEmpty: false,
      );

      // Debe levantar: la jugada (4) + el 4 de mesa + el 5 de mesa + el 6 de mesa = 4 cartas
      expect(result.capturedCards.length, equals(4));
      expect(result.capturedCards.map((c) => c.number), containsAll([4, 5, 6]));
      // Queda el 11 en mesa
      expect(result.newTableCards.length, equals(1));
      expect(result.newTableCards.first.number, equals(11));
      expect(result.isLimpia, isFalse);
    });

    test('Arrastre cruzando de 7 a 10', () {
      // Mesa: [7, 10, 11]
      final table = [
        const SpanishCard(number: 7, suit: CardSuit.oros),
        const SpanishCard(number: 10, suit: CardSuit.copas),
        const SpanishCard(number: 11, suit: CardSuit.espadas),
      ];

      final play = const SpanishCard(number: 7, suit: CardSuit.copas);

      final result = CaidaRulesEngine.evaluatePlay(
        playedCard: play,
        tableCards: table,
        previousCard: null,
        isDeckEmpty: false,
      );

      // Levanta todas las cartas y deja mesa limpia
      expect(result.capturedCards.length, equals(4));
      expect(result.newTableCards, isEmpty);
      expect(result.isLimpia, isTrue);
      expect(result.limpiaPoints, equals(4));
    });

    test('Caída otorga puntos según figura (+1..+4)', () {
      final prev = const SpanishCard(number: 11, suit: CardSuit.oros); // Caballo
      final current = const SpanishCard(number: 11, suit: CardSuit.copas);

      final result = CaidaRulesEngine.evaluatePlay(
        playedCard: current,
        tableCards: [prev],
        previousCard: prev,
        isDeckEmpty: false,
      );

      expect(result.isCaida, isTrue);
      expect(result.caidaPoints, equals(3), reason: 'Caída de Caballo vale 3 puntos');
      expect(result.isLimpia, isTrue);
      expect(result.limpiaPoints, equals(4));
      expect(result.totalPoints, equals(7), reason: 'Caída de Caballo (3) + Mesa Limpia (4) = 7 pts');
    });
  });

  group('CaidaRulesEngine - 4. Conteo por Volumen y Cierre', () {
    test('Cartas sobrantes se adjudican al último capturador y bono > 20 cartas', () {
      final players = [
        const CaidaPlayerState(id: 'user', name: 'Tú', teamId: 0, initialScore: 10, initialCardsWon: 22),
        const CaidaPlayerState(id: 'p1', name: 'Player 1', teamId: 1, initialScore: 8, initialCardsWon: 16),
      ];

      final remaining = [
        const SpanishCard(number: 2, suit: CardSuit.oros),
        const SpanishCard(number: 3, suit: CardSuit.copas),
      ];

      final res = CaidaRulesEngine.resolveHandEnd(
        players: players,
        remainingTable: remaining,
        lastCapturingPlayerId: 'user',
        isTeams: false,
      );

      // 'user' tenía 22 + 2 sobrantes = 24 cartas
      expect(res.totalCardsWon['user'], equals(24));
      // Bono volumen: 24 - 20 = +4 puntos
      expect(res.volumeBonusPoints['user'], equals(4));
      expect(res.updatedScores['user'], equals(14));
    });
  });
}
