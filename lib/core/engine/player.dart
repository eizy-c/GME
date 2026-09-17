import 'game_action.dart';
import 'game_state.dart';

/// Representación genérica de un participante en el juego.
abstract class Player {
  /// Identificador único del jugador (e.g. "player_1", "bot_vieja").
  final String id;

  /// Nombre público para visualización en la UI.
  final String name;

  /// `true` si es un humano interactuando por UI, `false` si es un bot/IA.
  final bool isHuman;

  const Player({
    required this.id,
    required this.name,
    required this.isHuman,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Player && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$runtimeType(id: $id, name: $name, isHuman: $isHuman)';
}

/// Participante humano. La UI suministra sus acciones a través del motor.
class HumanPlayer extends Player {
  const HumanPlayer({
    required super.id,
    required super.name,
  }) : super(isHuman: true);
}

/// Participante automatizado (Bot local).
///
/// Implementa [playTurn] para evaluar el [state] y emitir la mejor acción
/// según sus heurísticas deterministas o árbol de decisiones.
abstract class AIPlayer<TState extends GameState, TAction extends GameAction>
    extends Player {
  /// Tiempo de espera simulado para emular pensamiento y mejorar la experiencia del usuario.
  final Duration simulatedDelay;

  const AIPlayer({
    required super.id,
    required super.name,
    this.simulatedDelay = const Duration(milliseconds: 400),
  }) : super(isHuman: false);

  /// Evalúa el [state] actual y devuelve la acción a ejecutar.
  /// Si no puede realizar ninguna acción válida, devuelve `null`.
  Future<TAction?> playTurn(TState state);
}
