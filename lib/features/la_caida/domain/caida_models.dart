import '../../../core/models/cards/spanish_card.dart';

/// Dirección del Canto de Mesa que elige el repartidor.
enum DealDirection {
  ascending, // 1 -> 2 -> 3 -> 4
  descending, // 4 -> 3 -> 2 -> 1
}

extension DealDirectionExtension on DealDirection {
  String get label => this == DealDirection.ascending
      ? 'Ascendente (1 → 2 → 3 → 4)'
      : 'Descendente (4 → 3 → 2 → 1)';

  List<int> get sequence => this == DealDirection.ascending
      ? const [1, 2, 3, 4]
      : const [4, 3, 2, 1];
}

/// Tipos de cantos tradicionales venezolanos en La Caída.
enum CantoType {
  ronda, // 2 cartas del mismo número
  patrulla, // 3 cartas consecutivas
  registro, // Exactamente As, Caballo y Rey: [1, 11, 12]
  vigia, // 2 cartas iguales + 1 consecutiva
  trivilin, // 3 cartas del mismo número
}

/// Representación inmutable de un Canto evaluado en la mano de un jugador.
class Canto {
  final CantoType type;
  final int points;
  final int priority; // 5 (Trivilín) > 4 (Vigía) > 3 (Registro) > 2 (Patrulla) > 1 (Ronda)
  final int tieBreakerValue;
  final String name;
  final String description;
  final List<SpanishCard> cards;

  const Canto({
    required this.type,
    required this.points,
    required this.priority,
    required this.tieBreakerValue,
    required this.name,
    required this.description,
    required this.cards,
  });

  @override
  String toString() => '$name (+$points pts)';
}

/// Resultado puro del reparto inicial y el "Canto de Mesa".
class InitialTableDealResult {
  final List<SpanishCard> tableCards;
  final int dealerPoints;
  final int opponentPoints;
  final List<String> events;
  final List<SpanishCard> discardedRepeats;
  final List<int> spokenSequence;
  final List<bool> matches;

  const InitialTableDealResult({
    required this.tableCards,
    required this.dealerPoints,
    required this.opponentPoints,
    required this.events,
    required this.discardedRepeats,
    required this.spokenSequence,
    required this.matches,
  });

  bool get hadMatches => matches.any((m) => m);
}

/// Resultado puro de una jugada de turno (captura, seguidilla, caída y limpia).
class PlayEvaluationResult {
  final SpanishCard playedCard;
  final List<SpanishCard> capturedCards;
  final List<SpanishCard> newTableCards;
  final bool isCaida;
  final int caidaPoints;
  final bool isLimpia;
  final int limpiaPoints;
  final int totalPoints;
  final String breakdownMessage;

  const PlayEvaluationResult({
    required this.playedCard,
    required this.capturedCards,
    required this.newTableCards,
    required this.isCaida,
    required this.caidaPoints,
    required this.isLimpia,
    required this.limpiaPoints,
    required this.totalPoints,
    required this.breakdownMessage,
  });

  bool get didCapture => capturedCards.isNotEmpty;
}

/// Estado simplificado de un jugador para cálculos puros de fin de mano.
class CaidaPlayerState {
  final String id;
  final String name;
  final int teamId;
  final int initialScore;
  final int initialCardsWon;

  const CaidaPlayerState({
    required this.id,
    required this.name,
    required this.teamId,
    required this.initialScore,
    required this.initialCardsWon,
  });
}

/// Resultado del cierre de una mano o fin de mazo de 40 naipes.
class HandResolutionResult {
  final String? lastCapturingPlayerId;
  final List<SpanishCard> remainingTableAwarded;
  final Map<String, int> totalCardsWon;
  final Map<String, int> volumeBonusPoints;
  final Map<String, int> updatedScores;
  final List<String> events;
  final String? winnerPlayerId;
  final int? winnerTeamId;

  const HandResolutionResult({
    required this.lastCapturingPlayerId,
    required this.remainingTableAwarded,
    required this.totalCardsWon,
    required this.volumeBonusPoints,
    required this.updatedScores,
    required this.events,
    this.winnerPlayerId,
    this.winnerTeamId,
  });

  bool get hasWinner => winnerPlayerId != null || winnerTeamId != null;
}
