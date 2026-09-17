import 'package:flutter/material.dart';

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

/// Clase base abstracta sellada para el modelado orientado a objetos (POO)
/// de los Cantos en La Caída.
///
/// Permite polimorfismo puro, comparación natural (`compareTo`) y
/// pattern matching exhaustivo en Dart 3 (`switch (canto)`).
sealed class Canto implements Comparable<Canto> {
  final List<SpanishCard> cards;

  const Canto({required this.cards});

  /// Tipo enumerado del canto para serialización o categorización rápida.
  CantoType get type;

  /// Nombre tradicional del canto (ej: "¡Trivilín!", "¡Registro!").
  String get name;

  /// Puntos que otorga el canto según las reglas oficiales tradicionales.
  int get points;

  /// Jerarquía de prioridad para resolución de conflictos:
  /// Trivilín (5) > Vigía (4) > Registro (3) > Patrulla (2) > Ronda (1)
  int get priority;

  /// Valor nominal para desempatar entre cantos de la misma jerarquía.
  int get tieBreakerValue;

  /// Descripción legible para la UI e historial de partidas.
  String get description;

  /// Color distintivo para badges, banners y resaltados en la interfaz.
  Color get accentColor;

  /// Ícono representativo para la UI.
  IconData get icon;

  @override
  int compareTo(Canto other) {
    if (priority != other.priority) {
      return priority.compareTo(other.priority);
    }
    return tieBreakerValue.compareTo(other.tieBreakerValue);
  }

  @override
  String toString() => '$name (+$points pts)';
}

/// Trivilín: Tres cartas del mismo número en mano.
/// Otorga +24 puntos (la partida completa en la tradición de 24 puntos).
class TrivilinCanto extends Canto {
  final int nominalNumber;

  const TrivilinCanto({
    required super.cards,
    required this.nominalNumber,
  });

  @override
  CantoType get type => CantoType.trivilin;

  @override
  String get name => '¡Trivilín!';

  @override
  int get points => 24;

  @override
  int get priority => 5;

  @override
  int get tieBreakerValue => nominalNumber;

  @override
  String get description => 'Tres cartas del número $nominalNumber';

  @override
  Color get accentColor => const Color(0xFFF59E0B); // Ámbar dorado

  @override
  IconData get icon => Icons.auto_awesome_rounded;
}

/// Vigía: Dos cartas iguales + una consecutiva según la secuencia tradicional.
/// Otorga +8 puntos.
class VigiaCanto extends Canto {
  final int pairNumber;
  final int consecutiveNumber;

  const VigiaCanto({
    required super.cards,
    required this.pairNumber,
    required this.consecutiveNumber,
  });

  @override
  CantoType get type => CantoType.vigia;

  @override
  String get name => '¡Vigía!';

  @override
  int get points => 8;

  @override
  int get priority => 4;

  @override
  int get tieBreakerValue => pairNumber * 100 + consecutiveNumber;

  @override
  String get description => 'Par de $pairNumber y consecutiva $consecutiveNumber';

  @override
  Color get accentColor => const Color(0xFFA855F7); // Púrpura

  @override
  IconData get icon => Icons.visibility_rounded;
}

/// Registro: Exactamente As, Caballo y Rey [1, 11, 12].
/// Otorga +12 puntos (media partida).
class RegistroCanto extends Canto {
  const RegistroCanto({required super.cards});

  @override
  CantoType get type => CantoType.registro;

  @override
  String get name => '¡Registro!';

  @override
  int get points => 12;

  @override
  int get priority => 3;

  @override
  int get tieBreakerValue => 12;

  @override
  String get description => 'As, Caballo y Rey [1, 11, 12]';

  @override
  Color get accentColor => const Color(0xFFEC4899); // Rosa fucsia

  @override
  IconData get icon => Icons.military_tech_rounded;
}

/// Patrulla: Tres cartas consecutivas en la secuencia tradicional (ej: 4, 5, 6 o 6, 7, 10).
/// Otorga +4 puntos.
class PatrullaCanto extends Canto {
  final int highestNumber;

  const PatrullaCanto({
    required super.cards,
    required this.highestNumber,
  });

  @override
  CantoType get type => CantoType.patrulla;

  @override
  String get name => '¡Patrulla!';

  @override
  int get points => 4;

  @override
  int get priority => 2;

  @override
  int get tieBreakerValue => highestNumber;

  @override
  String get description => 'Tres cartas en escalera hasta el $highestNumber';

  @override
  Color get accentColor => const Color(0xFF06B6D4); // Cian

  @override
  IconData get icon => Icons.shield_rounded;
}

/// Ronda: Dos cartas del mismo número en mano.
/// Otorga +2 puntos base para números del 1 al 7, y puntos incrementales según figura:
/// - 1 al 7: +2 pts
/// - Sota (10): +3 pts
/// - Caballo (11): +4 pts
/// - Rey (12): +5 pts
class RondaCanto extends Canto {
  final int pairNumber;
  final int nominalPoints;

  const RondaCanto({
    required super.cards,
    required this.pairNumber,
    required this.nominalPoints,
  });

  @override
  CantoType get type => CantoType.ronda;

  @override
  String get name => '¡Ronda!';

  @override
  int get points => nominalPoints;

  @override
  int get priority => 1;

  @override
  int get tieBreakerValue => pairNumber;

  @override
  String get description => 'Par de $pairNumber (+$points pts)';

  @override
  Color get accentColor => const Color(0xFF10B981); // Esmeralda

  @override
  IconData get icon => Icons.style_rounded;
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
