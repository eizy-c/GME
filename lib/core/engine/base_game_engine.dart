import 'dart:async';

import 'game_action.dart';
import 'game_phase.dart';
import 'game_state.dart';
import 'player.dart';

/// Motor de juego base agnóstico de interfaz gráfica.
///
/// Todas las variantes de juegos (La Vieja, Truco, Caída, Dominó, Cinquillo)
/// heredan de esta clase para gestionar su ciclo de vida, turnos, validación de reglas
/// y coordinación con bots/jugadores humanos.
abstract class BaseGameEngine<TState extends GameState, TAction extends GameAction> {
  final StreamController<TState> _stateController = StreamController<TState>.broadcast();
  late TState _state;
  bool _isDisposed = false;
  bool _isProcessingAI = false;

  /// Controla si el motor ejecuta automáticamente los turnos de los bots locales.
  final bool autoPlayAI;

  BaseGameEngine({this.autoPlayAI = true});

  /// Estado actual reactivo e inmutable del juego.
  TState get state => _state;

  /// Stream reactivo para suscribir la UI o inspectores a cambios de estado.
  Stream<TState> get stateStream => _stateController.stream;

  /// Indica si el motor ha sido cerrado.
  bool get isDisposed => _isDisposed;

  /// Inicializa la partida, baraja o configura el tablero y coloca la fase inicial.
  Future<void> initializeGame();

  /// Valida si una acción propuesta por un jugador es legal en el estado actual.
  bool isValidAction(TAction action);

  /// Ejecuta una acción válida en el motor y transiciona de estado.
  /// Devuelve `true` si la acción fue procesada exitosamente, `false` si fue inválida o rechazada.
  Future<bool> processAction(TAction action);

  /// Reinicia la partida con los mismos o nuevos participantes.
  Future<void> restartGame();

  /// Actualiza y emite el nuevo estado a todos los oyentes.
  void emitState(TState newState) {
    if (_isDisposed) return;
    _state = newState;
    _stateController.add(_state);

    if (autoPlayAI && !_state.isGameOver && _state.phase == GamePhase.playing) {
      _checkAndTriggerAITurn();
    }
  }

  /// Verifica si el jugador en turno es un [AIPlayer] y dispara su movimiento.
  Future<void> _checkAndTriggerAITurn() async {
    if (_isProcessingAI || _isDisposed) return;

    final currentPlayer = _state.currentPlayer;
    if (currentPlayer is AIPlayer<TState, TAction>) {
      _isProcessingAI = true;
      try {
        if (currentPlayer.simulatedDelay > Duration.zero) {
          await Future.delayed(currentPlayer.simulatedDelay);
        }
        if (_isDisposed || _state.isGameOver) return;

        final action = await currentPlayer.playTurn(_state);
        if (action != null && !_isDisposed) {
          await processAction(action);
        }
      } finally {
        _isProcessingAI = false;
      }
    }
  }

  /// Libera recursos y cierra los streams.
  void dispose() {
    _isDisposed = true;
    _stateController.close();
  }
}
