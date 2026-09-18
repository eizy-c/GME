import 'dart:async';
import 'playing_card.dart';
import 'table_state.dart';
import '../strategies/bot_play_strategy.dart';

/// Abstracción polimórfica de un jugador en la mesa de La Caída.
abstract class Player {
  final String id;
  final String name;
  final int teamId;
  final bool isBot;

  final List<PlayingCard> _hand = [];
  final List<PlayingCard> _capturedCards = [];
  int score = 0;

  Player({
    required this.id,
    required this.name,
    required this.teamId,
    required this.isBot,
  });

  List<PlayingCard> get hand => List.unmodifiable(_hand);
  List<PlayingCard> get capturedCards => List.unmodifiable(_capturedCards);
  int get capturedCount => _capturedCards.length;

  void receiveCards(List<PlayingCard> cards) => _hand.addAll(cards);

  bool removeCard(PlayingCard card) => _hand.remove(card);

  void addCapturedCards(List<PlayingCard> cards) => _capturedCards.addAll(cards);

  void addScore(int points) => score += points;

  void resetRound() {
    _hand.clear();
    _capturedCards.clear();
  }

  /// Método polimórfico: solicita la jugada al jugador (asíncrono).
  Future<PlayingCard> requestAction(TableState tableState);
}

/// Jugador humano: su acción se resuelve cuando el usuario toca la carta y confirma en la UI.
class HumanPlayer extends Player {
  Completer<PlayingCard>? _actionCompleter;

  HumanPlayer({
    required super.id,
    required super.name,
    super.teamId = 0,
  }) : super(isBot: false);

  @override
  Future<PlayingCard> requestAction(TableState tableState) {
    _actionCompleter = Completer<PlayingCard>();
    return _actionCompleter!.future;
  }

  void submitSelectedCard(PlayingCard card) {
    if (_actionCompleter != null && !_actionCompleter!.isCompleted) {
      _actionCompleter!.complete(card);
      _actionCompleter = null;
    }
  }

  bool get isWaitingForInput => _actionCompleter != null && !_actionCompleter!.isCompleted;
}

/// Jugador Bot: utiliza la heurística desacoplada `BotPlayStrategy`.
class BotPlayer extends Player {
  final BotPlayStrategy strategy;
  final Duration simulatedDelay;

  BotPlayer({
    required super.id,
    required super.name,
    super.teamId = 0,
    BotPlayStrategy? strategy,
    this.simulatedDelay = const Duration(milliseconds: 700),
  })  : strategy = strategy ?? const DefaultBotStrategy(),
        super(isBot: true);

  @override
  Future<PlayingCard> requestAction(TableState tableState) async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }
    return strategy.chooseCard(hand: _hand, tableState: tableState);
  }
}
