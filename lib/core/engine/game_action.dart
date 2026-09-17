/// Clase base abstracta e inmutable para cualquier acción o movimiento
/// ejecutado por un jugador (humano o bot).
abstract class GameAction {
  /// Identificador único del jugador que originó la acción.
  final String playerId;

  /// Momento temporal en el que se emitió la acción.
  final DateTime timestamp;

  GameAction({
    required this.playerId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => '$runtimeType(playerId: $playerId, timestamp: $timestamp)';
}
