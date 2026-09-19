import 'dart:ui';
import '../../../../core/models/cards/spanish_card.dart';
import '../../../../core/models/cards/spanish_deck.dart';

/// Representa una carta individual boca abajo candidata en el sorteo de Mano.
class ManoCardCandidate {
  final int id;
  final SpanishCard card;
  final double topOffset;
  final double leftOffset;
  final double rotation;
  int? chosenByPlayerIndex;
  bool isRevealed;
  bool isWinner;

  ManoCardCandidate({
    required this.id,
    required this.card,
    required this.topOffset,
    required this.leftOffset,
    required this.rotation,
    this.chosenByPlayerIndex,
    this.isRevealed = false,
    this.isWinner = false,
  });

  bool get isAvailable => chosenByPlayerIndex == null;
}

/// Objeto de Dominio que encapsula el ritual del sorteo de Mano ("¡ELIGE UNA CARTA!").
class ManoDrawSession {
  final List<ManoCardCandidate> candidates;
  String? announcement;
  int? winnerIndex;
  bool isActive;

  ManoDrawSession({
    List<ManoCardCandidate>? candidates,
    this.announcement,
    this.winnerIndex,
    this.isActive = false,
  }) : candidates = candidates ?? [];

  /// Posiciones fijas naturales en el tapete de madera para el abanico del sorteo.
  static const List<Offset> candidatePositions = [
    Offset(-70, -70),
    Offset(15, -75),
    Offset(85, -70),
    Offset(-35, -20),
    Offset(55, -15),
    Offset(-75, 30),
    Offset(5, 35),
    Offset(75, 35),
    Offset(-40, 80),
    Offset(45, 75),
  ];

  static const List<double> candidateRotations = [
    -0.06,
    0.04,
    -0.05,
    0.08,
    -0.04,
    0.05,
    -0.07,
    0.06,
    -0.03,
    0.05,
  ];

  /// Inicializa una nueva sesión de sorteo barajando un mazo y repartiendo 10 cartas candidatas
  factory ManoDrawSession.startNew({
    String initialAnnouncement = 'Sorteo de Mano: Toca una carta para ver quién sale',
  }) {
    final tempDeck = SpanishDeck()..shuffle();
    final list = <ManoCardCandidate>[];

    for (int i = 0; i < 10; i++) {
      final card = tempDeck.draw()!;
      list.add(ManoCardCandidate(
        id: i,
        card: card,
        topOffset: candidatePositions[i].dy,
        leftOffset: candidatePositions[i].dx,
        rotation: candidateRotations[i],
      ));
    }

    return ManoDrawSession(
      candidates: list,
      announcement: initialAnnouncement,
      isActive: true,
    );
  }

  /// Lista de cartas que aún no han sido seleccionadas
  List<ManoCardCandidate> get unchosenCandidates =>
      candidates.where((c) => c.isAvailable).toList();

  /// Asigna una carta a un jugador específico y la revela
  void pickCard(ManoCardCandidate candidate, int playerIndex) {
    candidate.chosenByPlayerIndex = playerIndex;
    candidate.isRevealed = true;
  }

  /// Determina el ganador comparando las cartas elegidas por cada jugador
  ManoCardCandidate? determineWinner() {
    final chosen = candidates.where((c) => c.chosenByPlayerIndex != null).toList();
    if (chosen.isEmpty) return null;

    chosen.sort((a, b) => b.card.number.compareTo(a.card.number));
    final winner = chosen.first;
    winner.isWinner = true;
    winnerIndex = winner.chosenByPlayerIndex;
    return winner;
  }

  void reset() {
    candidates.clear();
    announcement = null;
    winnerIndex = null;
    isActive = false;
  }
}
