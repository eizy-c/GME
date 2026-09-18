import 'dart:math';
import 'playing_card.dart';

/// Mazo de 40 cartas de la baraja española tradicional (sin 8 ni 9).
class Deck {
  final List<PlayingCard> _cards = [];
  final List<PlayingCard> _discards = [];

  Deck() {
    reset();
  }

  int get remainingCount => _cards.length;
  bool get isEmpty => _cards.isEmpty;
  bool get isNotEmpty => _cards.isNotEmpty;

  void reset() {
    _cards.clear();
    _discards.clear();
    for (final suit in CardSuit.values) {
      for (int v = 1; v <= 7; v++) {
        _cards.add(PlayingCard(suit: suit, value: v));
      }
      for (int v = 10; v <= 12; v++) {
        _cards.add(PlayingCard(suit: suit, value: v));
      }
    }
  }

  void shuffle([Random? random]) {
    _cards.shuffle(random ?? Random());
  }

  PlayingCard? draw() {
    if (_cards.isEmpty) return null;
    return _cards.removeLast();
  }

  List<PlayingCard> drawMultiple(int count) {
    final drawn = <PlayingCard>[];
    for (int i = 0; i < count; i++) {
      final card = draw();
      if (card != null) drawn.add(card);
    }
    return drawn;
  }

  void discard(PlayingCard card) {
    _discards.add(card);
  }
}
