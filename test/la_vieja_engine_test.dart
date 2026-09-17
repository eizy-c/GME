import 'package:flutter_test/flutter_test.dart';
import 'package:gme/core/engine/game_phase.dart';
import 'package:gme/core/engine/player.dart';
import 'package:gme/core/models/board/grid_board.dart';
import 'package:gme/core/stats/game_stats.dart';
import 'package:gme/core/stats/stats_repository.dart';
import 'package:gme/features/la_vieja/domain/vieja_ai_player.dart';
import 'package:gme/features/la_vieja/domain/vieja_engine.dart';
import 'package:gme/features/la_vieja/domain/vieja_models.dart';

void main() {
  group('La Vieja (Tic-Tac-Toe) Engine Tests', () {
    late HumanPlayer player1;
    late HumanPlayer player2;
    late InMemoryStatsRepository statsRepo;
    late ViejaEngine engine;

    setUp(() async {
      player1 = const HumanPlayer(id: 'p1', name: 'Jugador 1');
      player2 = const HumanPlayer(id: 'p2', name: 'Jugador 2');
      statsRepo = InMemoryStatsRepository();
      engine = ViejaEngine(
        player1: player1,
        player2: player2,
        statsRepository: statsRepo,
        autoPlayAI: false,
      );
      await engine.initializeGame();
    });

    tearDown(() {
      engine.dispose();
    });

    test('Inicializa en fase playing con turno de player1 y tablero vacío', () {
      expect(engine.state.phase, equals(GamePhase.playing));
      expect(engine.state.currentTurnPlayerId, equals(player1.id));
      expect(engine.state.turnNumber, equals(1));
      expect(engine.state.board.availablePositions.length, equals(9));
      expect(engine.state.isGameOver, isFalse);
    });

    test('Victoria de Jugador 1 en Fila 1', () async {
      // p1: (0,0) -> p2: (1,0) -> p1: (0,1) -> p2: (1,1) -> p1: (0,2) [GANA]
      expect(await engine.processAction(ViejaAction(playerId: 'p1', row: 0, col: 0)), isTrue);
      expect(await engine.processAction(ViejaAction(playerId: 'p2', row: 1, col: 0)), isTrue);
      expect(await engine.processAction(ViejaAction(playerId: 'p1', row: 0, col: 1)), isTrue);
      expect(await engine.processAction(ViejaAction(playerId: 'p2', row: 1, col: 1)), isTrue);
      expect(await engine.processAction(ViejaAction(playerId: 'p1', row: 0, col: 2)), isTrue);

      expect(engine.state.phase, equals(GamePhase.gameOver));
      expect(engine.state.winnerId, equals('p1'));
      expect(engine.state.isDraw, isFalse);
      expect(engine.state.winningLine?.description, equals('Fila 1'));

      final stats = await statsRepo.getStats(GameType.laVieja);
      expect(stats.wins, equals(1));
      expect(stats.losses, equals(0));
    });

    test('Victoria en diagonal secundaria', () async {
      // p1: (0,2), p2: (0,0), p1: (1,1), p2: (0,1), p1: (2,0) [GANA DIAGONAL]
      await engine.processAction(ViejaAction(playerId: 'p1', row: 0, col: 2));
      await engine.processAction(ViejaAction(playerId: 'p2', row: 0, col: 0));
      await engine.processAction(ViejaAction(playerId: 'p1', row: 1, col: 1));
      await engine.processAction(ViejaAction(playerId: 'p2', row: 0, col: 1));
      await engine.processAction(ViejaAction(playerId: 'p1', row: 2, col: 0));

      expect(engine.state.phase, equals(GamePhase.gameOver));
      expect(engine.state.winnerId, equals('p1'));
      expect(engine.state.winningLine?.description, equals('Diagonal Secundaria'));
    });

    test('Detección correcta de empate cuando el tablero se llena', () async {
      // Tablero:
      // X | O | X
      // X | O | O
      // O | X | X
      final moves = [
        (0, 0, 'p1'), (0, 1, 'p2'), (0, 2, 'p1'),
        (1, 1, 'p2'), (1, 0, 'p1'), (1, 2, 'p2'),
        (2, 1, 'p1'), (2, 0, 'p2'), (2, 2, 'p1'),
      ];

      for (final move in moves) {
        final ok = await engine.processAction(ViejaAction(playerId: move.$3, row: move.$1, col: move.$2));
        expect(ok, isTrue);
      }

      expect(engine.state.phase, equals(GamePhase.gameOver));
      expect(engine.state.isDraw, isTrue);
      expect(engine.state.winnerId, isNull);

      final stats = await statsRepo.getStats(GameType.laVieja);
      expect(stats.draws, equals(1));
    });

    test('Rechaza acciones inválidas (fuera de turno, casilla ocupada, límites)', () async {
      // Intento de mover fuera de turno (p2 cuando le toca a p1)
      final outOfTurn = ViejaAction(playerId: 'p2', row: 0, col: 0);
      expect(engine.isValidAction(outOfTurn), isFalse);
      expect(await engine.processAction(outOfTurn), isFalse);

      // Mover a una casilla válida
      await engine.processAction(ViejaAction(playerId: 'p1', row: 0, col: 0));

      // Intento de mover sobre casilla ya ocupada
      final cellTaken = ViejaAction(playerId: 'p2', row: 0, col: 0);
      expect(engine.isValidAction(cellTaken), isFalse);
      expect(await engine.processAction(cellTaken), isFalse);

      // Intento de mover fuera del rango de la cuadrícula
      final outOfBounds = ViejaAction(playerId: 'p2', row: 3, col: 3);
      expect(engine.isValidAction(outOfBounds), isFalse);
      expect(await engine.processAction(outOfBounds), isFalse);
    });
  });

  group('ViejaAIPlayer Heuristic Bot Tests', () {
    const bot = ViejaAIPlayer(
      id: 'bot_id',
      name: 'Bot Sabio',
      simulatedDelay: Duration.zero,
    );
    const human = HumanPlayer(id: 'human_id', name: 'Humano');

    test('Heurística 1: El bot toma la victoria inmediata cuando la tiene disponible', () async {
      final board = GridBoard<ViejaSymbol>(rows: 3, cols: 3, emptyValue: ViejaSymbol.none);
      // El bot es 'O'. Fila 0: [O | O | vacío]
      board.set(0, 0, ViejaSymbol.o);
      board.set(0, 1, ViejaSymbol.o);
      board.set(1, 0, ViejaSymbol.x);
      board.set(1, 1, ViejaSymbol.x);

      final state = ViejaState(
        phase: GamePhase.playing,
        currentTurnPlayerId: 'bot_id',
        players: [human, bot],
        board: board,
        playerSymbols: {'human_id': ViejaSymbol.x, 'bot_id': ViejaSymbol.o},
      );

      final action = await bot.playTurn(state);
      expect(action, isNotNull);
      // Debe elegir la casilla (0, 2) para ganar
      expect(action!.row, equals(0));
      expect(action.col, equals(2));
    });

    test('Heurística 2: El bot bloquea defensivamente la victoria inmediata del rival', () async {
      final board = GridBoard<ViejaSymbol>(rows: 3, cols: 3, emptyValue: ViejaSymbol.none);
      // El rival 'X' tiene columna 0: (0,0) y (1,0) con (2,0) libre
      board.set(0, 0, ViejaSymbol.x);
      board.set(1, 0, ViejaSymbol.x);
      board.set(2, 2, ViejaSymbol.o);

      final state = ViejaState(
        phase: GamePhase.playing,
        currentTurnPlayerId: 'bot_id',
        players: [human, bot],
        board: board,
        playerSymbols: {'human_id': ViejaSymbol.x, 'bot_id': ViejaSymbol.o},
      );

      final action = await bot.playTurn(state);
      expect(action, isNotNull);
      // Debe bloquear la casilla (2, 0)
      expect(action!.row, equals(2));
      expect(action.col, equals(0));
    });

    test('Heurística 3: El bot toma el centro (1, 1) si está disponible', () async {
      final board = GridBoard<ViejaSymbol>(rows: 3, cols: 3, emptyValue: ViejaSymbol.none);
      board.set(0, 0, ViejaSymbol.x); // Humano jugó esquina

      final state = ViejaState(
        phase: GamePhase.playing,
        currentTurnPlayerId: 'bot_id',
        players: [human, bot],
        board: board,
        playerSymbols: {'human_id': ViejaSymbol.x, 'bot_id': ViejaSymbol.o},
      );

      final action = await bot.playTurn(state);
      expect(action, isNotNull);
      expect(action!.row, equals(1));
      expect(action.col, equals(1));
    });

    test('Juego autónomo completo: Humano vs Bot en ViejaEngine', () async {
      final statsRepo = InMemoryStatsRepository();
      final engine = ViejaEngine(
        player1: human,
        player2: bot,
        statsRepository: statsRepo,
        autoPlayAI: true,
      );

      await engine.initializeGame();

      // Turno 1 humano: juega en esquina (0, 0)
      await engine.processAction(ViejaAction(playerId: 'human_id', row: 0, col: 0));

      // El bot con autoPlayAI responde automáticamente tomando el centro (1, 1)
      expect(engine.state.board.get(1, 1), equals(ViejaSymbol.o));
      expect(engine.state.currentTurnPlayerId, equals('human_id'));

      engine.dispose();
    });
  });
}
