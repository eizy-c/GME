import 'playing_card.dart';

/// Estado inmutable de las cartas en la mesa y eventos de arrastre.
class TableState {
  final List<PlayingCard> activeCards;
  final PlayingCard? lastPlayedCard;
  final String? lastCapturingPlayerId;

  const TableState({
    this.activeCards = const [],
    this.lastPlayedCard,
    this.lastCapturingPlayerId,
  });

  TableState copyWith({
    List<PlayingCard> Function()? activeCards,
    PlayingCard? Function()? lastPlayedCard,
    String? Function()? lastCapturingPlayerId,
  }) {
    return TableState(
      activeCards: activeCards != null ? activeCards() : this.activeCards,
      lastPlayedCard: lastPlayedCard != null ? lastPlayedCard() : this.lastPlayedCard,
      lastCapturingPlayerId: lastCapturingPlayerId != null ? lastCapturingPlayerId() : this.lastCapturingPlayerId,
    );
  }
}
