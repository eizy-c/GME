import '../../../core/engine/game_action.dart';
import '../../../core/engine/game_phase.dart';
import '../../../core/engine/game_state.dart';
import '../../../core/engine/player.dart';
import '../../../core/models/board/grid_board.dart';

/// Símbolos posibles en las casillas de La Vieja (Tres en Raya).
enum ViejaSymbol {
  none(''),
  x('X'),
  o('O');

  final String label;
  const ViejaSymbol(this.label);

  /// Devuelve el símbolo contrario para el contrincante.
  ViejaSymbol get opponent {
    if (this == ViejaSymbol.x) return ViejaSymbol.o;
    if (this == ViejaSymbol.o) return ViejaSymbol.x;
    return ViejaSymbol.none;
  }
}

/// Representa la línea de 3 casillas ganadora detectada en el tablero.
class ViejaWinningLine {
  final List<(int row, int col)> cells;
  final String description;

  const ViejaWinningLine({
    required this.cells,
    required this.description,
  });

  @override
  String toString() => '$description: $cells';
}

/// Acción efectuada por un jugador al marcar una casilla en el tablero.
class ViejaAction extends GameAction {
  final int row;
  final int col;

  ViejaAction({
    required super.playerId,
    required this.row,
    required this.col,
    super.timestamp,
  });

  @override
  String toString() => 'ViejaAction(playerId: $playerId, pos: ($row, $col))';
}

/// Estado inmutable específico del juego La Vieja.
class ViejaState extends GameState {
  /// Tablero matricial 3x3 de símbolos.
  final GridBoard<ViejaSymbol> board;

  /// Mapeo de ID de jugador a su símbolo asignado ('X' u 'O').
  final Map<String, ViejaSymbol> playerSymbols;

  /// Línea ganadora de 3 casillas (si la partida fue ganada).
  final ViejaWinningLine? winningLine;

  const ViejaState({
    required super.phase,
    required super.currentTurnPlayerId,
    required super.players,
    required this.board,
    required this.playerSymbols,
    this.winningLine,
    super.winnerId,
    super.isDraw = false,
    super.turnNumber = 1,
    super.statusMessage,
  });

  /// Obtiene el símbolo correspondiente al jugador en turno.
  ViejaSymbol get currentTurnSymbol =>
      playerSymbols[currentTurnPlayerId] ?? ViejaSymbol.none;

  /// Crea una copia inmutable del estado actual con campos modificados.
  ViejaState copyWith({
    GamePhase? phase,
    String? currentTurnPlayerId,
    List<Player>? players,
    GridBoard<ViejaSymbol>? board,
    Map<String, ViejaSymbol>? playerSymbols,
    ViejaWinningLine? winningLine,
    String? winnerId,
    bool? isDraw,
    int? turnNumber,
    String? statusMessage,
  }) {
    return ViejaState(
      phase: phase ?? this.phase,
      currentTurnPlayerId: currentTurnPlayerId ?? this.currentTurnPlayerId,
      players: players ?? this.players,
      board: board ?? this.board.clone(),
      playerSymbols: playerSymbols ?? Map.unmodifiable(this.playerSymbols),
      winningLine: winningLine ?? this.winningLine,
      winnerId: winnerId ?? this.winnerId,
      isDraw: isDraw ?? this.isDraw,
      turnNumber: turnNumber ?? this.turnNumber,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
