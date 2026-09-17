import 'dart:math';

import 'card_suit.dart';
import 'spanish_card.dart';

/// Mazo de Baraja Española tradicional de 40 naipes.
///
/// Gestiona la generación completa de las 40 cartas, barajado determinista o aleatorio,
/// corte de mazo, extracción y reparto equitativo a jugadores.
class SpanishDeck {
  /// Lista canónica de los 10 valores tradicionales por palo (sin 8 ni 9).
  static const List<int> standardNumbers = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12];

  final List<SpanishCard> _cards = [];
  final List<SpanishCard> _discardPile = [];

  SpanishDeck() {
    reset();
  }

  /// Crea un mazo aplicando una función transformadora de jerarquías/puntos.
  SpanishDeck.custom({SpanishCard Function(SpanishCard)? ruleMapper}) {
    reset(ruleMapper: ruleMapper);
  }

  /// Crea un mazo a partir de una lista específica de cartas (útil para pruebas y escenarios controlados).
  SpanishDeck.fromCards(List<SpanishCard> cards) {
    _cards.clear();
    _discardPile.clear();
    _cards.addAll(cards);
  }

  /// Reinicia el mazo con las 40 cartas completas y vacía el descarte.
  void reset({SpanishCard Function(SpanishCard)? ruleMapper}) {
    _cards.clear();
    _discardPile.clear();

    for (final suit in CardSuit.values) {
      for (final number in standardNumbers) {
        var card = SpanishCard(number: number, suit: suit);
        if (ruleMapper != null) {
          card = ruleMapper(card);
        }
        _cards.add(card);
      }
    }
  }

  /// Cantidad de cartas restantes en el mazo para robar.
  int get remainingCount => _cards.length;

  /// Cantidad de cartas en la pila de descarte.
  int get discardCount => _discardPile.length;

  /// Indica si el mazo se ha agotado.
  bool get isEmpty => _cards.isEmpty;

  /// Retorna una vista inmutable de las cartas actuales en el mazo.
  List<SpanishCard> get remainingCards => List.unmodifiable(_cards);

  /// Retorna una vista inmutable de las cartas descartadas.
  List<SpanishCard> get discardedCards => List.unmodifiable(_discardPile);

  /// Baraja las cartas restantes utilizando el algoritmo Fisher-Yates.
  /// Acepta un [random] para permitir barajado determinista en pruebas unitarias.
  void shuffle([Random? random]) {
    _cards.shuffle(random ?? Random());
  }

  /// Corta el mazo tradicionalmente por un índice dado o por la mitad.
  void cut([int? cutIndex]) {
    if (_cards.length <= 1) return;
    final index = cutIndex ?? (_cards.length ~/ 2);
    if (index <= 0 || index >= _cards.length) return;

    final topPortion = _cards.sublist(0, index);
    final bottomPortion = _cards.sublist(index);
    _cards
      ..clear()
      ..addAll(bottomPortion)
      ..addAll(topPortion);
  }

  /// Roba la primera carta disponible del tope del mazo.
  SpanishCard? draw() {
    if (_cards.isEmpty) return null;
    return _cards.removeAt(0);
  }

  /// Roba un número [count] determinado de cartas del mazo.
  List<SpanishCard> deal(int count) {
    final dealt = <SpanishCard>[];
    for (var i = 0; i < count; i++) {
      final card = draw();
      if (card == null) break;
      dealt.add(card);
    }
    return dealt;
  }

  /// Reparte [cardsPerPlayer] cartas a cada jugador en orden rotativo (estilo tradicional de mesa).
  Map<String, List<SpanishCard>> dealToPlayers(
    List<String> playerIds,
    int cardsPerPlayer,
  ) {
    final hands = <String, List<SpanishCard>>{
      for (final id in playerIds) id: <SpanishCard>[],
    };

    for (var round = 0; round < cardsPerPlayer; round++) {
      for (final playerId in playerIds) {
        final card = draw();
        if (card != null) {
          hands[playerId]!.add(card);
        }
      }
    }

    return hands;
  }

  /// Añade una carta a la pila de descarte.
  void discard(SpanishCard card) {
    _discardPile.add(card);
  }

  /// Recicla las cartas del descarte de vuelta al mazo y las baraja.
  void recycleDiscarded([Random? random]) {
    _cards.addAll(_discardPile);
    _discardPile.clear();
    shuffle(random);
  }
}
