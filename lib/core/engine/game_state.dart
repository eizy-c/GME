import 'game_phase.dart';
import 'player.dart';

/// Estado inmutable base para cualquier juego en el compendio.
abstract class GameState {
  /// Fase actual del ciclo de vida del juego.
  final GamePhase phase;

  /// ID del jugador que posee el turno activo.
  final String currentTurnPlayerId;

  /// Lista de participantes registrados en la partida.
  final List<Player> players;

  /// ID del jugador ganador (si existe y la partida concluyó).
  final String? winnerId;

  /// Indica si la partida concluyó en empate o tranca.
  final bool isDraw;

  /// Contador incremental de turnos efectuados.
  final int turnNumber;

  /// Mensaje descriptivo o informativo del estado actual (opcional).
  final String? statusMessage;

  const GameState({
    required this.phase,
    required this.currentTurnPlayerId,
    required this.players,
    this.winnerId,
    this.isDraw = false,
    this.turnNumber = 1,
    this.statusMessage,
  });

  /// Indica si la partida ha finalizado.
  bool get isGameOver => phase == GamePhase.gameOver;

  /// Obtiene la instancia del jugador activo.
  Player? get currentPlayer {
    try {
      return players.firstWhere((p) => p.id == currentTurnPlayerId);
    } catch (_) {
      return null;
    }
  }

  /// Obtiene la instancia del jugador ganador (si lo hay).
  Player? get winnerPlayer {
    if (winnerId == null) return null;
    try {
      return players.firstWhere((p) => p.id == winnerId);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() =>
      '$runtimeType(phase: $phase, turnPlayer: $currentTurnPlayerId, winner: $winnerId, isDraw: $isDraw)';
}
