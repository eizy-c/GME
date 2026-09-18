import 'dart:async';
import 'package:flutter/foundation.dart';

import '../domain/models/playing_card.dart';
import '../domain/models/deck.dart';
import '../domain/models/player.dart';
import '../domain/models/table_state.dart';
import '../domain/models/canto.dart';
import 'match_phase.dart';

/// Resultado de una jugada evaluada.
class EvaluatedMove {
  final PlayingCard playedCard;
  final List<PlayingCard> capturedCards;
  final TableState newTableState;
  final bool isCaida;
  final int caidaPoints;
  final bool isLimpia;
  final int limpiaPoints;
  final int totalPoints;
  final String summary;

  const EvaluatedMove({
    required this.playedCard,
    required this.capturedCards,
    required this.newTableState,
    required this.isCaida,
    required this.caidaPoints,
    required this.isLimpia,
    required this.limpiaPoints,
    required this.totalPoints,
    required this.summary,
  });

  bool get hasCapture => capturedCards.isNotEmpty;
}

/// Controlador Reactivo de Máquina de Estados para La Caída.
///
/// Implementa turnos limpios, soporte polimórfico de HumanPlayer y BotPlayer,
/// y cancelación garantizada de timers al destruirse (`dispose`).
class GameMatchController extends ChangeNotifier {
  static const List<int> sequence = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12];

  final List<Player> _players = [];
  final Deck _deck = Deck();
  TableState _tableState = const TableState();
  MatchPhase _phase = MatchPhase.idle;

  int _currentTurnIndex = 0;
  int _dealerIndex = 0;
  int _manoIndex = 0;
  int _roundNumber = 1;
  bool _isTeams = false;
  String _statusBanner = 'Listo para jugar';
  Player? _winner;

  final List<Timer> _activeTimers = [];

  // Getters públicos
  List<Player> get players => List.unmodifiable(_players);
  TableState get tableState => _tableState;
  MatchPhase get phase => _phase;
  int get currentTurnIndex => _currentTurnIndex;
  int get dealerIndex => _dealerIndex;
  int get manoIndex => _manoIndex;
  int get roundNumber => _roundNumber;
  bool get isTeams => _isTeams;
  Player get activePlayer => _players[_currentTurnIndex];
  Player get dealerPlayer => _players[_dealerIndex];
  Player? get winner => _winner;
  int get remainingDeckCount => _deck.remainingCount;
  String get statusBanner => _statusBanner;

  @override
  void dispose() {
    _cancelAllTimers();
    super.dispose();
  }

  void _registerTimer(Duration duration, VoidCallback callback) {
    late Timer timer;
    timer = Timer(duration, () {
      _activeTimers.remove(timer);
      callback();
    });
    _activeTimers.add(timer);
  }

  void _cancelAllTimers() {
    for (final t in _activeTimers) {
      t.cancel();
    }
    _activeTimers.clear();
  }

  /// Inicia una nueva partida con la cantidad de jugadores indicada.
  void startMatch({
    required String humanName,
    required int totalPlayers,
    required bool isTeams,
  }) {
    _cancelAllTimers();
    _players.clear();
    _deck.reset();
    _deck.shuffle();
    _tableState = const TableState();
    _roundNumber = 1;
    _isTeams = isTeams;
    _winner = null;

    // 1. Instanciar jugador humano
    _players.add(HumanPlayer(id: 'p0', name: humanName, teamId: 0));

    // 2. Instanciar bots
    for (int i = 1; i < totalPlayers; i++) {
      _players.add(BotPlayer(
        id: 'p$i',
        name: 'Bot ${String.fromCharCode(64 + i)}',
        teamId: isTeams ? (i % 2) : i,
      ));
    }

    _dealerIndex = 0;
    _manoIndex = (_dealerIndex + 1) % _players.length;
    _currentTurnIndex = _manoIndex;

    _setPhase(MatchPhase.tableDeal);
    _executeTableDeal();
  }

  void _setPhase(MatchPhase newPhase) {
    _phase = newPhase;
    notifyListeners();
  }

  /// Reparto inicial de 4 cartas a la mesa con canto 1-4 ascendente.
  void _executeTableDeal() {
    _statusBanner = 'Repartiendo mesa inicial...';
    notifyListeners();

    _registerTimer(const Duration(milliseconds: 700), () {
      final tableCards = <PlayingCard>[];
      final spoken = [1, 2, 3, 4];
      int dealerPoints = 0;
      int opponentPoints = 0;
      int hits = 0;

      for (int i = 0; i < 4; i++) {
        final target = spoken[i];
        PlayingCard? card = _deck.draw();

        // Descarte de cartas repetidas (+1 pt al rival)
        while (card != null && tableCards.any((c) => c.value == card!.value)) {
          _deck.discard(card);
          opponentPoints += 1;
          card = _deck.draw();
        }

        if (card == null) break;
        tableCards.add(card);

        if (card.value == target) {
          hits++;
          dealerPoints += card.value;
        }
      }

      if (hits == 0) opponentPoints += 1;

      dealerPlayer.addScore(dealerPoints);
      _players[_manoIndex].addScore(opponentPoints);

      _tableState = _tableState.copyWith(activeCards: () => tableCards);
      _statusBanner = dealerPoints > 0
          ? '¡Canto de Mesa acertado! (+$dealerPoints pts)'
          : 'Mesa servida';

      _setPhase(MatchPhase.dealingHands);
      _dealHandsToPlayers();
    });
  }

  /// Reparte 3 cartas a cada jugador.
  void _dealHandsToPlayers() {
    _registerTimer(const Duration(milliseconds: 600), () {
      for (final p in _players) {
        final cards = _deck.drawMultiple(3);
        p.receiveCards(cards);
      }

      _setPhase(MatchPhase.cantosResolution);
      _resolveCantosPhase();
    });
  }

  /// Resuelve la fase de cantos aplicando "Matando Cantos".
  void _resolveCantosPhase() {
    final cantosFound = <String, Canto>{};
    for (final p in _players) {
      final canto = _evaluateHandCanto(p.hand);
      if (canto != null) cantosFound[p.id] = canto;
    }

    if (cantosFound.isNotEmpty) {
      // Regla "Matando Cantos": solo cobra el bando con el canto superior
      final winningEntry = cantosFound.entries.reduce((best, curr) {
        final comp = curr.value.compareTo(best.value);
        if (comp > 0) return curr;
        if (comp < 0) return best;
        // Desempate por cercanía a la Mano
        final bestDist = (_players.indexWhere((p) => p.id == best.key) - _manoIndex + _players.length) % _players.length;
        final currDist = (_players.indexWhere((p) => p.id == curr.key) - _manoIndex + _players.length) % _players.length;
        return currDist < bestDist ? curr : best;
      });

      final winnerPlayer = _players.firstWhere((p) => p.id == winningEntry.key);
      winnerPlayer.addScore(winningEntry.value.points);
      _statusBanner = '${winnerPlayer.name} canta ${winningEntry.value.name} (+${winningEntry.value.points} pts)';

      // Trivilín (+24) gana la partida de inmediato
      if (winningEntry.value is TrivilinCanto || winnerPlayer.score >= 24) {
        _winner = winnerPlayer;
        _statusBanner = '¡${winnerPlayer.name} canta TRIVILÍN y gana la partida!';
        _setPhase(MatchPhase.matchEnd);
        return;
      }
    }

    _registerTimer(const Duration(milliseconds: 1000), () {
      _setPhase(MatchPhase.playerTurn);
      _promptCurrentTurn();
    });
  }

  /// Solicita la jugada al jugador activo de forma polimórfica.
  Future<void> _promptCurrentTurn() async {
    final player = activePlayer;
    _statusBanner = 'Turno de ${player.name}';
    notifyListeners();

    final cardToPlay = await player.requestAction(_tableState);
    _handlePlayerMove(player, cardToPlay);
  }

  /// Acción ejecutada cuando el usuario confirma una carta desde la UI.
  void playHumanCard(PlayingCard card) {
    if (activePlayer is HumanPlayer && _phase == MatchPhase.playerTurn) {
      (activePlayer as HumanPlayer).submitSelectedCard(card);
    }
  }

  /// Procesa la jugada del jugador en la mesa.
  void _handlePlayerMove(Player player, PlayingCard card) {
    player.removeCard(card);
    _setPhase(MatchPhase.evaluatingMove);

    final moveResult = _evaluatePlayMove(
      card: card,
      currentTable: _tableState,
      isDeckEmpty: _deck.isEmpty,
      playerId: player.id,
    );

    _tableState = moveResult.newTableState;
    if (moveResult.hasCapture) {
      player.addCapturedCards(moveResult.capturedCards);
    }
    player.addScore(moveResult.totalPoints);

    if (moveResult.summary.isNotEmpty) {
      _statusBanner = '${player.name}: ${moveResult.summary}';
    }
    notifyListeners();

    _registerTimer(const Duration(milliseconds: 900), () {
      _checkPostMoveState();
    });
  }

  void _checkPostMoveState() {
    // 1. Victoria por alcanzar 24 puntos
    final gameWinner = _players.where((p) => p.score >= 24).firstOrNull;
    if (gameWinner != null) {
      _winner = gameWinner;
      _statusBanner = '¡${gameWinner.name} ha ganado con ${gameWinner.score} pts!';
      _setPhase(MatchPhase.matchEnd);
      return;
    }

    // 2. Comprobar si la mano de 3 cartas concluyó
    final allEmpty = _players.every((p) => p.hand.isEmpty);
    if (allEmpty) {
      if (_deck.isNotEmpty) {
        // La Mano se mantiene fija durante todo el manojo
        _currentTurnIndex = _manoIndex;
        _roundNumber++;
        _setPhase(MatchPhase.dealingHands);
        _dealHandsToPlayers();
      } else {
        _resolveVolumeFinalCount();
      }
      return;
    }

    // 3. Siguiente turno correlativo
    _currentTurnIndex = (_currentTurnIndex + 1) % _players.length;
    _setPhase(MatchPhase.playerTurn);
    _promptCurrentTurn();
  }

  /// Resolución de conteo final por volumen de cartas físicas.
  void _resolveVolumeFinalCount() {
    // Adjudicar sobrante en mesa al último capturador
    if (_tableState.lastCapturingPlayerId != null && _tableState.activeCards.isNotEmpty) {
      final lastCapturer = _players.firstWhere((p) => p.id == _tableState.lastCapturingPlayerId);
      lastCapturer.addCapturedCards(_tableState.activeCards);
    }

    final totalPlayers = _players.length;
    final dealerId = dealerPlayer.id;

    if (_isTeams) {
      // Parejas: umbral 20
      final teamCards = <int, int>{0: 0, 1: 0};
      for (final p in _players) {
        teamCards[p.teamId] = (teamCards[p.teamId] ?? 0) + p.capturedCount;
      }
      for (final entry in teamCards.entries) {
        if (entry.value > 20) {
          final bonus = entry.value - 20;
          for (final p in _players.where((pl) => pl.teamId == entry.key)) {
            p.addScore(bonus);
          }
        }
      }
    } else {
      // Individual: 20 (1v1), 13 y 14 repartidor (3 jugadores), 10 (4 jugadores)
      for (final p in _players) {
        int threshold = 20;
        if (totalPlayers == 3) {
          threshold = (p.id == dealerId) ? 14 : 13;
        } else if (totalPlayers >= 4) {
          threshold = 10;
        } else {
          threshold = 20;
        }

        if (p.capturedCount > threshold) {
          final bonus = p.capturedCount - threshold;
          p.addScore(bonus);
        }
      }
    }

    // Definir ganador final
    _players.sort((a, b) => b.score.compareTo(a.score));
    _winner = _players.first;
    _statusBanner = 'Partida finalizada. Ganador: ${_winner!.name} (${_winner!.score} pts)';
    _setPhase(MatchPhase.matchEnd);
  }

  // --- MÉTODOS AUXILIARES DE REGLAS DE NEGOCIO ---

  static int _getNextInSequence(int value) {
    final idx = sequence.indexOf(value);
    if (idx == -1 || idx == sequence.length - 1) return -1;
    return sequence[idx + 1];
  }

  static bool _areConsecutive(int a, int b) {
    final idxA = sequence.indexOf(a);
    final idxB = sequence.indexOf(b);
    if (idxA == -1 || idxB == -1) return false;
    return (idxA - idxB).abs() == 1;
  }

  static Canto? _evaluateHandCanto(List<PlayingCard> hand) {
    if (hand.length != 3) return null;
    final v1 = hand[0].value, v2 = hand[1].value, v3 = hand[2].value;

    // Trivilín (3 iguales: +24 pts, gana la partida)
    if (v1 == v2 && v2 == v3) {
      return TrivilinCanto(cards: hand, value: v1);
    }

    // Vigía (Par + 1 que le sigue o le atrasa: +7 pts)
    int? pairVal, thirdVal;
    if (v1 == v2) { pairVal = v1; thirdVal = v3; }
    else if (v2 == v3) { pairVal = v2; thirdVal = v1; }
    else if (v1 == v3) { pairVal = v1; thirdVal = v2; }

    if (pairVal != null && thirdVal != null && _areConsecutive(pairVal, thirdVal)) {
      return VigiaCanto(cards: hand, pairValue: pairVal, adjacentValue: thirdVal);
    }

    // Registro (1, 11, 12 exactos: +8 pts)
    final set = {v1, v2, v3};
    if (set.contains(1) && set.contains(11) && set.contains(12)) {
      return RegistroCanto(cards: hand);
    }

    // Patrulla (3 en escalera: +6 pts)
    final indices = [sequence.indexOf(v1), sequence.indexOf(v2), sequence.indexOf(v3)]..sort();
    if (indices[0] != -1 && indices[0] + 1 == indices[1] && indices[1] + 1 == indices[2]) {
      return PatrullaCanto(cards: hand, highestValue: sequence[indices[2]]);
    }

    // Ronda (Par igual: +1 a +4 pts)
    if (pairVal != null) {
      return RondaCanto(cards: hand, pairValue: pairVal);
    }

    return null;
  }

  static EvaluatedMove _evaluatePlayMove({
    required PlayingCard card,
    required TableState currentTable,
    required bool isDeckEmpty,
    required String playerId,
  }) {
    final tableList = List<PlayingCard>.from(currentTable.activeCards);
    final captured = <PlayingCard>[];

    // 1. Caída sobre la carta previa
    final isCaida = currentTable.lastPlayedCard != null &&
        currentTable.lastPlayedCard!.value == card.value;
    final caidaPts = isCaida ? card.caidaPoints : 0;

    // 2. Coincidencia y Arrastre
    final matches = tableList.where((c) => c.value == card.value).toList();
    if (matches.isNotEmpty) {
      captured.add(card);
      for (final m in matches) {
        captured.add(m);
        tableList.remove(m);
      }

      int nextVal = _getNextInSequence(card.value);
      while (nextVal != -1 && tableList.any((c) => c.value == nextVal)) {
        final chain = tableList.where((c) => c.value == nextVal).toList();
        for (final item in chain) {
          captured.add(item);
          tableList.remove(item);
        }
        nextVal = _getNextInSequence(nextVal);
      }
    } else {
      tableList.add(card);
    }

    // 3. Mesa Limpia: +4 con mazo activo, 0 en mazo vacío
    final isLimpia = captured.isNotEmpty && tableList.isEmpty;
    final limpiaPts = isLimpia ? (isDeckEmpty ? 0 : 4) : 0;
    final totalPts = caidaPts + limpiaPts;

    final updatedTable = currentTable.copyWith(
      activeCards: () => tableList,
      lastPlayedCard: () => card,
      lastCapturingPlayerId: () => captured.isNotEmpty ? playerId : currentTable.lastCapturingPlayerId,
    );

    String summary = '';
    if (isCaida && isLimpia && limpiaPts > 0) {
      summary = '¡Caída (+$caidaPts) y Limpia (+$limpiaPts)!';
    } else if (isCaida) {
      summary = '¡Caída! (+$caidaPts pts)';
    } else if (isLimpia && limpiaPts > 0) {
      summary = '¡Mesa Limpia! (+$limpiaPts pts)';
    } else if (captured.length > 2) {
      summary = '¡Arrastre! (${captured.length} cartas)';
    }

    return EvaluatedMove(
      playedCard: card,
      capturedCards: captured,
      newTableState: updatedTable,
      isCaida: isCaida,
      caidaPoints: caidaPts,
      isLimpia: isLimpia,
      limpiaPoints: limpiaPts,
      totalPoints: totalPts,
      summary: summary,
    );
  }
}
