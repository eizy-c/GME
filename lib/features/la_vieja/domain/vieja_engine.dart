import '../../../core/engine/base_game_engine.dart';
import '../../../core/engine/game_phase.dart';
import '../../../core/engine/player.dart';
import '../../../core/models/board/grid_board.dart';
import '../../../core/stats/game_stats.dart';
import '../../../core/stats/stats_repository.dart';
import 'vieja_models.dart';

/// Motor desacoplado del juego La Vieja (Tic-Tac-Toe / Tres en Raya).
class ViejaEngine extends BaseGameEngine<ViejaState, ViejaAction> {
  final Player player1;
  final Player player2;
  final StatsRepository? statsRepository;

  ViejaEngine({
    required this.player1,
    required this.player2,
    this.statsRepository,
    super.autoPlayAI = true,
  });

  @override
  Future<void> initializeGame() async {
    final board = GridBoard<ViejaSymbol>(
      rows: 3,
      cols: 3,
      emptyValue: ViejaSymbol.none,
    );

    final symbols = {
      player1.id: ViejaSymbol.x,
      player2.id: ViejaSymbol.o,
    };

    final initialState = ViejaState(
      phase: GamePhase.playing,
      currentTurnPlayerId: player1.id,
      players: [player1, player2],
      board: board,
      playerSymbols: symbols,
      turnNumber: 1,
      statusMessage: 'Turno de ${player1.name} (X)',
    );

    emitState(initialState);
  }

  @override
  bool isValidAction(ViejaAction action) {
    if (state.isGameOver || state.phase != GamePhase.playing) {
      return false;
    }
    if (action.playerId != state.currentTurnPlayerId) {
      return false;
    }
    if (!state.board.isValidCoordinate(action.row, action.col)) {
      return false;
    }
    return state.board.isEmpty(action.row, action.col);
  }

  @override
  Future<bool> processAction(ViejaAction action) async {
    if (!isValidAction(action)) {
      return false;
    }

    final symbol = state.playerSymbols[action.playerId]!;
    final newBoard = state.board.clone();
    newBoard.set(action.row, action.col, symbol);

    final winningLine = _detectWinningLine(newBoard, symbol);

    if (winningLine != null) {
      // Fin por victoria
      final winner = state.players.firstWhere((p) => p.id == action.playerId);
      final nextState = state.copyWith(
        phase: GamePhase.gameOver,
        board: newBoard,
        winnerId: action.playerId,
        winningLine: winningLine,
        isDraw: false,
        statusMessage: '¡Victoria de ${winner.name}!',
      );
      await _recordGameResult(winnerId: action.playerId, isDraw: false);
      emitState(nextState);
      return true;
    }

    if (newBoard.isFull) {
      // Fin por empate
      final nextState = state.copyWith(
        phase: GamePhase.gameOver,
        board: newBoard,
        isDraw: true,
        statusMessage: '¡Partida empatada!',
      );
      await _recordGameResult(winnerId: null, isDraw: true);
      emitState(nextState);
      return true;
    }

    // Continuar juego, cambiar de turno
    final nextPlayer =
        state.currentTurnPlayerId == player1.id ? player2 : player1;
    final nextSymbol = state.playerSymbols[nextPlayer.id]!;

    final nextState = state.copyWith(
      board: newBoard,
      currentTurnPlayerId: nextPlayer.id,
      turnNumber: state.turnNumber + 1,
      statusMessage: 'Turno de ${nextPlayer.name} (${nextSymbol.label})',
    );

    emitState(nextState);
    return true;
  }

  @override
  Future<void> restartGame() async {
    await initializeGame();
  }

  /// Verifica si existe una línea de 3 casillas idénticas del [symbol].
  ViejaWinningLine? _detectWinningLine(
    GridBoard<ViejaSymbol> board,
    ViejaSymbol symbol,
  ) {
    // 1. Filas
    for (var r = 0; r < 3; r++) {
      if (board.getRow(r).every((s) => s == symbol)) {
        return ViejaWinningLine(
          cells: [(r, 0), (r, 1), (r, 2)],
          description: 'Fila ${r + 1}',
        );
      }
    }

    // 2. Columnas
    for (var c = 0; c < 3; c++) {
      if (board.getColumn(c).every((s) => s == symbol)) {
        return ViejaWinningLine(
          cells: [(0, c), (1, c), (2, c)],
          description: 'Columna ${c + 1}',
        );
      }
    }

    // 3. Diagonal principal
    if (board.getMainDiagonal().every((s) => s == symbol)) {
      return const ViejaWinningLine(
        cells: [(0, 0), (1, 1), (2, 2)],
        description: 'Diagonal Principal',
      );
    }

    // 4. Diagonal secundaria
    if (board.getAntiDiagonal().every((s) => s == symbol)) {
      return const ViejaWinningLine(
        cells: [(0, 2), (1, 1), (2, 0)],
        description: 'Diagonal Secundaria',
      );
    }

    return null;
  }

  /// Registra el resultado en el repositorio de estadísticas offline si existe.
  Future<void> _recordGameResult({
    required String? winnerId,
    required bool isDraw,
  }) async {
    if (statsRepository == null) return;

    final currentStats = await statsRepository!.getStats(GameType.laVieja);
    GameStats updatedStats;

    if (isDraw) {
      updatedStats = currentStats.recordDraw();
    } else {
      final isPlayer1Winner = winnerId == player1.id;
      final humanWon =
          (isPlayer1Winner && player1.isHuman) || (!isPlayer1Winner && player2.isHuman);
      final botWon =
          (isPlayer1Winner && !player1.isHuman) || (!isPlayer1Winner && !player2.isHuman);

      if (humanWon && !botWon) {
        updatedStats = currentStats.recordWin();
      } else if (botWon && !humanWon) {
        updatedStats = currentStats.recordLoss();
      } else {
        // Humano vs Humano: contabilizar victoria
        updatedStats = currentStats.recordWin();
      }
    }

    await statsRepository!.saveStats(updatedStats);
  }
}
