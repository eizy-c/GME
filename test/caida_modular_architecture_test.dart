import 'package:flutter_test/flutter_test.dart';
import 'package:gme/features/la_caida/domain/models/playing_card.dart';
import 'package:gme/features/la_caida/domain/models/deck.dart';
import 'package:gme/features/la_caida/domain/models/player.dart';
import 'package:gme/features/la_caida/domain/models/table_state.dart';
import 'package:gme/features/la_caida/domain/models/canto.dart';
import 'package:gme/features/la_caida/domain/strategies/bot_play_strategy.dart';
import 'package:gme/features/la_caida/controllers/match_phase.dart';
import 'package:gme/features/la_caida/controllers/game_match_controller.dart';
import 'package:gme/features/la_caida/economy/economy_service.dart';
import 'package:gme/features/la_caida/economy/user_progress.dart';

void main() {
  group('Arquitectura Modular - Modelos de Dominio POO', () {
    test('PlayingCard inmutable y puntos oficiales unificados (+1..+4)', () {
      const c4 = PlayingCard(suit: CardSuit.oros, value: 4);
      const c10 = PlayingCard(suit: CardSuit.copas, value: 10);
      const c11 = PlayingCard(suit: CardSuit.espadas, value: 11);
      const c12 = PlayingCard(suit: CardSuit.bastos, value: 12);

      // 1 al 7: +1
      expect(c4.rondaPoints, equals(1));
      expect(c4.caidaPoints, equals(1));

      // Sota 10: +2
      expect(c10.rondaPoints, equals(2));
      expect(c10.caidaPoints, equals(2));

      // Caballo 11: +3
      expect(c11.rondaPoints, equals(3));
      expect(c11.caidaPoints, equals(3));

      // Rey 12: +4
      expect(c12.rondaPoints, equals(4));
      expect(c12.caidaPoints, equals(4));
    });

    test('Deck de 40 cartas únicas y extracción', () {
      final deck = Deck();
      expect(deck.remainingCount, equals(40));

      final drawn = deck.drawMultiple(3);
      expect(drawn.length, equals(3));
      expect(deck.remainingCount, equals(37));

      deck.shuffle();
      final set = <PlayingCard>{...drawn};
      while (deck.isNotEmpty) {
        set.add(deck.draw()!);
      }
      expect(set.length, equals(40), reason: 'Las 40 cartas son únicas');
    });

    test('BotPlayStrategy prioriza Caída sobre carta previa', () {
      const strategy = DefaultBotStrategy();
      final hand = [
        const PlayingCard(suit: CardSuit.oros, value: 3),
        const PlayingCard(suit: CardSuit.copas, value: 11), // Caída
        const PlayingCard(suit: CardSuit.espadas, value: 7),
      ];
      const tableState = TableState(
        activeCards: [
          PlayingCard(suit: CardSuit.bastos, value: 11),
        ],
        lastPlayedCard: PlayingCard(suit: CardSuit.bastos, value: 11),
      );

      final chosen = strategy.chooseCard(hand: hand, tableState: tableState);
      expect(chosen.value, equals(11), reason: 'Debe priorizar la Caída de Caballo');
    });

    test('Jerarquía de Cantos: Trivilín (24), Registro (8), Vigía (7), Patrulla (6)', () {
      const trivilin = TrivilinCanto(cards: [], value: 7);
      const registro = RegistroCanto(cards: []);
      const vigia = VigiaCanto(cards: [], pairValue: 4, adjacentValue: 5);
      const patrulla = PatrullaCanto(cards: [], highestValue: 6);
      const ronda = RondaCanto(cards: [], pairValue: 12);

      expect(trivilin.points, equals(24));
      expect(registro.points, equals(8));
      expect(vigia.points, equals(7));
      expect(patrulla.points, equals(6));
      expect(ronda.points, equals(4));

      // Comparaciones de jerarquía
      expect(trivilin.compareTo(vigia), greaterThan(0));
      expect(vigia.compareTo(registro), greaterThan(0));
      expect(registro.compareTo(patrulla), greaterThan(0));
      expect(patrulla.compareTo(ronda), greaterThan(0));
    });
  });

  group('Arquitectura Modular - GameMatchController', () {
    test('startMatch inicializa fases y jugadores sin timers huérfanos', () async {
      final controller = GameMatchController();
      controller.startMatch(humanName: 'Tester', totalPlayers: 2, isTeams: false);

      expect(controller.players.length, equals(2));
      expect(controller.players[0], isA<HumanPlayer>());
      expect(controller.players[1], isA<BotPlayer>());
      // La Mano juega primero (índice 1 en 2 jugadores)
      expect(controller.activePlayer, equals(controller.players[controller.manoIndex]));
      expect(controller.phase, equals(MatchPhase.tableDeal));

      controller.dispose(); // Limpieza garantizada
    });
  });

  group('Arquitectura Modular - Economía y Progresión', () {
    test('UserProgress calcula progresión exponencial correctamente', () {
      const prog0 = UserProgress(totalXp: 0);
      expect(prog0.currentLevel, equals(0));

      const prog1 = UserProgress(totalXp: 100);
      expect(prog1.currentLevel, equals(1));

      // Nivel 2 requiere 100 * (2^1.5) = 282 XP
      const prog2 = UserProgress(totalXp: 300);
      expect(prog2.currentLevel, equals(2));

      expect(prog2.levelProgressPercentage, inInclusiveRange(0.0, 1.0));
    });

    test('EconomyService gestiona saldo de monedas, tickets y diamantes', () {
      final economy = EconomyService()..resetToDefault();
      expect(economy.coins, equals(6000));
      expect(economy.tickets, equals(10));
      expect(economy.diamonds, equals(50));

      final paid = economy.payEntryFee(costCoins: 500, costTickets: 1);
      expect(paid, isTrue);
      expect(economy.coins, equals(5500));
      expect(economy.tickets, equals(9));

      economy.awardVictory(rewardCoins: 1000, rewardDiamonds: 10);
      expect(economy.coins, equals(6500));
      expect(economy.diamonds, equals(60));
    });
  });
}
