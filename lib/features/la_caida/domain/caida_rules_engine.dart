import '../../../core/models/cards/spanish_card.dart';
import '../../../core/models/cards/spanish_deck.dart';
import 'caida_models.dart';

/// Motor desacoplado y puro de reglas tradicionales para La Caída venezolana.
class CaidaRulesEngine {
  /// Secuencia canónica de valores de la baraja española de 40 cartas (sin 8 ni 9).
  static const List<int> sequence = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12];

  /// Obtiene el siguiente valor correlativo superior según la secuencia tradicional.
  /// Ejemplo: 7 -> 10, 10 -> 11, 11 -> 12, 12 -> -1.
  static int getNextInSequence(int number) {
    final idx = sequence.indexOf(number);
    if (idx == -1 || idx == sequence.length - 1) return -1;
    return sequence[idx + 1];
  }

  /// Verifica si dos valores son inmediatamente consecutivos en la secuencia tradicional.
  static bool areConsecutive(int a, int b) {
    final idxA = sequence.indexOf(a);
    final idxB = sequence.indexOf(b);
    if (idxA == -1 || idxB == -1) return false;
    return (idxA - idxB).abs() == 1;
  }

  /// Puntos otorgados por una Ronda según el valor del par.
  /// 1 al 7: +1 punto
  /// 10 (Sota): +2 puntos
  /// 11 (Caballo): +3 puntos
  /// Puntos otorgados por una Ronda según el valor del naipe:
  /// 1 al 7: +2 puntos base
  /// 10 (Sota): +3 puntos
  /// 11 (Caballo): +4 puntos
  /// 12 (Rey): +5 puntos
  static int getCardRondaPoints(int number) {
    switch (number) {
      case 10:
        return 3;
      case 11:
        return 4;
      case 12:
        return 5;
      default:
        return 2;
    }
  }

  /// Puntos otorgados por una Caída según el valor del naipe caído.
  /// 1 al 7: +1 punto
  /// 10 (Sota): +2 puntos
  /// 11 (Caballo): +3 puntos
  /// 12 (Rey): +4 puntos
  static int getCardCaidaPoints(int number) {
    switch (number) {
      case 10:
        return 2;
      case 11:
        return 3;
      case 12:
        return 4;
      default:
        return 1;
    }
  }

  /// Puntos otorgados por Mesa Limpia:
  /// +4 puntos si aún quedan cartas en mazo/manojo.
  /// +2 puntos si es la última mano con el mazo ya agotado.
  static int getLimpiaPoints({required bool isDeckEmpty}) {
    return isDeckEmpty ? 2 : 4;
  }

  // ===========================================================================
  // 1. REPARTO INICIAL Y "CANTO DE MESA"
  // ===========================================================================

  /// Ejecuta el reparto inicial de 4 cartas a la mesa evaluando el Canto de Mesa del repartidor.
  ///
  /// Reglas:
  /// - Coloca 4 cartas sin números repetidos.
  /// - El repartidor canta en dirección Ascendente (1..4) o Descendente (4..1).
  /// - Si el valor de la carta coincide con el número cantado: el repartidor suma inmediatamente
  ///   el valor exacto de esa carta (ej. cantó 3 y salió 3 = +3 pts).
  /// - Si sale un número repetido respecto a las ya presentes en mesa: se descarta, se busca
  ///   otra carta en el mazo y se le otorga +1 punto al rival / siguiente jugador.
  /// - Si tras las 4 cartas el repartidor no acertó ningún número: se otorga +1 punto al rival.
  static InitialTableDealResult dealInitialTable({
    required DealDirection direction,
    required SpanishDeck deck,
    required String dealerId,
    required String opponentId,
  }) {
    final tableCards = <SpanishCard>[];
    final discardedRepeats = <SpanishCard>[];
    final events = <String>[];
    final spokenSequence = direction.sequence;
    final matches = <bool>[];

    int dealerPoints = 0;
    int opponentPoints = 0;
    int hits = 0;

    for (int i = 0; i < 4; i++) {
      final spoken = spokenSequence[i];

      // Robar cartas asegurando que no haya números repetidos en mesa
      SpanishCard? drawn = deck.draw();
      while (drawn != null && tableCards.any((c) => c.number == drawn!.number)) {
        discardedRepeats.add(drawn);
        deck.discard(drawn);
        opponentPoints += 1;
        events.add('Número repetido (${drawn.number}) descartado de mesa: +1 pt para rivales.');
        drawn = deck.draw();
      }

      if (drawn == null) break;

      tableCards.add(drawn);

      // Verificar si acertó el canto
      if (drawn.number == spoken) {
        hits++;
        dealerPoints += drawn.number;
        matches.add(true);
        events.add('¡Canto de Mesa acertado! Cantó $spoken y salió $spoken: +$spoken pts para el repartidor.');
      } else {
        matches.add(false);
        events.add('Cantó $spoken y salió ${drawn.number}.');
      }
    }

    // Si no acertó ningún número en las 4 cartas, +1 al rival
    if (hits == 0) {
      opponentPoints += 1;
      events.add('El repartidor no acertó ningún número en mesa: +1 pt para rivales.');
    }

    return InitialTableDealResult(
      tableCards: tableCards,
      dealerPoints: dealerPoints,
      opponentPoints: opponentPoints,
      events: events,
      discardedRepeats: discardedRepeats,
      spokenSequence: spokenSequence,
      matches: matches,
    );
  }

  // ===========================================================================
  // 2. FASE DE CANTOS (AL RECIBIR LAS 3 CARTAS)
  // ===========================================================================

  /// Evalúa la mano de 3 cartas de un jugador y retorna el canto de mayor jerarquía disponible,
  /// o null si no posee ningún canto.
  ///
  /// Jerarquía oficial y puntos tradicionales:
  /// 1. Trivilín (3 cartas del mismo número): +24 puntos (Prioridad 5)
  /// 2. Vigía (2 cartas iguales + 1 consecutiva): +8 puntos (Prioridad 4)
  /// 3. Registro (As, Caballo y Rey: [1, 11, 12]): +12 puntos (Prioridad 3)
  /// 4. Patrulla (3 cartas consecutivas): +4 puntos (Prioridad 2)
  /// 5. Ronda (2 cartas del mismo número no consecutivas): +2 a +5 puntos (Prioridad 1)
  static Canto? evaluateCantos(List<SpanishCard> hand) {
    if (hand.length != 3) return null;

    final n1 = hand[0].number;
    final n2 = hand[1].number;
    final n3 = hand[2].number;

    // 1. Trivilín (3 cartas iguales): +24 pts
    if (n1 == n2 && n2 == n3) {
      return TrivilinCanto(
        cards: List.unmodifiable(hand),
        nominalNumber: n1,
      );
    }

    // 2. Vigía (2 cartas iguales + 1 consecutiva según la secuencia): +8 pts
    int? pairNum;
    int? thirdNum;

    if (n1 == n2) {
      pairNum = n1;
      thirdNum = n3;
    } else if (n2 == n3) {
      pairNum = n2;
      thirdNum = n1;
    } else if (n1 == n3) {
      pairNum = n1;
      thirdNum = n2;
    }

    if (pairNum != null && thirdNum != null && areConsecutive(pairNum, thirdNum)) {
      return VigiaCanto(
        cards: List.unmodifiable(hand),
        pairNumber: pairNum,
        consecutiveNumber: thirdNum,
      );
    }

    // 3. Registro (Exactamente As, Caballo y Rey: [1, 11, 12]): +12 pts
    final numbersSet = {n1, n2, n3};
    if (numbersSet.contains(1) && numbersSet.contains(11) && numbersSet.contains(12)) {
      return RegistroCanto(
        cards: List.unmodifiable(hand),
      );
    }

    // 4. Patrulla (3 cartas consecutivas en la secuencia tradicional): +4 pts
    final sortedIndices = [
      sequence.indexOf(n1),
      sequence.indexOf(n2),
      sequence.indexOf(n3),
    ]..sort();

    if (sortedIndices[0] != -1 &&
        sortedIndices[0] + 1 == sortedIndices[1] &&
        sortedIndices[1] + 1 == sortedIndices[2]) {
      final highestNum = sequence[sortedIndices[2]];
      return PatrullaCanto(
        cards: List.unmodifiable(hand),
        highestNumber: highestNum,
      );
    }

    // 5. Ronda (2 cartas del mismo número no consecutivas con la tercera): +2..+5 pts
    if (pairNum != null) {
      final pts = getCardRondaPoints(pairNum);
      return RondaCanto(
        cards: List.unmodifiable(hand),
        pairNumber: pairNum,
        nominalPoints: pts,
      );
    }

    return null;
  }

  /// Resuelve el conflicto de cantos entre rivales de la mesa.
  ///
  /// Regla oficial:
  /// "Si varios jugadores tienen cantos, solo cobra el bando que tenga el canto de
  /// mayor jerarquía o el valor nominal más alto."
  ///
  /// Retorna un mapa con los cantos que son válidos para cobrar (los derrotados reciben null o 0 pts).
  static Map<String, Canto?> resolveCantosConflict({
    required Map<String, Canto?> playerCantos,
    required Map<String, int> playerTeams,
    int manoIndex = 0,
    List<String> playerIdsOrder = const [],
  }) {
    final activeCantos = <String, Canto>{};
    for (final entry in playerCantos.entries) {
      if (entry.value != null) {
        activeCantos[entry.key] = entry.value!;
      }
    }

    if (activeCantos.isEmpty) {
      return playerCantos;
    }

    // Determinar el canto ganador comparando bando vs bando con compareTo polimórfico
    final winningEntry = activeCantos.entries.reduce((best, current) {
      final comparison = current.value.compareTo(best.value);
      if (comparison > 0) return current;
      if (comparison < 0) return best;

      // En empate de jerarquía y valor nominal, prevalece quien esté más cerca de la Mano
      final bestIdx = playerIdsOrder.indexOf(best.key);
      final currentIdx = playerIdsOrder.indexOf(current.key);
      if (bestIdx == -1 || currentIdx == -1) return best;

      final distBest = (bestIdx - manoIndex + playerIdsOrder.length) % playerIdsOrder.length;
      final distCurrent = (currentIdx - manoIndex + playerIdsOrder.length) % playerIdsOrder.length;

      return distCurrent < distBest ? current : best;
    });

    final winningTeamId = playerTeams[winningEntry.key] ?? 0;

    // Solo cobran los jugadores pertenecientes al bando ganador
    final resolved = <String, Canto?>{};
    for (final entry in playerCantos.entries) {
      final canto = entry.value;
      if (canto == null) {
        resolved[entry.key] = null;
        continue;
      }

      final teamId = playerTeams[entry.key] ?? 0;
      if (teamId == winningTeamId) {
        resolved[entry.key] = canto;
      } else {
        // Canto derrotado por el bando rival
        resolved[entry.key] = null;
      }
    }

    return resolved;
  }

  // ===========================================================================
  // 3. JUGADAS DE TURNO, CAÍDAS Y LEVANTAMIENTO
  // ===========================================================================

  /// Evalúa una jugada individual de un jugador sobre la mesa:
  /// - Coincidencia simple y Arrastre (Seguidilla consecutiva).
  /// - Caída sobre el naipe inmediatamente anterior.
  /// - Mesa Limpia (+4 con mazo activo / +2 última mano).
  /// - Caída y Limpia combinadas.
  static PlayEvaluationResult evaluatePlay({
    required SpanishCard playedCard,
    required List<SpanishCard> tableCards,
    SpanishCard? previousCard,
    required bool isDeckEmpty,
  }) {
    final tableCopy = List<SpanishCard>.from(tableCards);
    final captured = <SpanishCard>[];

    // 1. Verificación de Caída sobre el naipe jugado por el jugador anterior
    final isCaida = previousCard != null && previousCard.number == playedCard.number;
    final caidaPoints = isCaida ? getCardCaidaPoints(playedCard.number) : 0;

    // 2. Coincidencia y Arrastre (Seguidilla)
    final matchesOnTable = tableCopy.where((c) => c.number == playedCard.number).toList();

    if (matchesOnTable.isNotEmpty) {
      // Coincidencia exitosa: la carta jugada y las de mesa se capturan
      captured.add(playedCard);
      for (final m in matchesOnTable) {
        captured.add(m);
        tableCopy.remove(m);
      }

      // Seguidilla (Arrastre): levanta consecutivas superiores inmediatas
      int nextExpected = getNextInSequence(playedCard.number);
      while (nextExpected != -1 && tableCopy.any((c) => c.number == nextExpected)) {
        final consecutiveCards = tableCopy.where((c) => c.number == nextExpected).toList();
        for (final cc in consecutiveCards) {
          captured.add(cc);
          tableCopy.remove(cc);
        }
        nextExpected = getNextInSequence(nextExpected);
      }
    } else {
      // No hubo coincidencia: la carta jugada queda en la mesa
      tableCopy.add(playedCard);
    }

    // 3. Verificación de Mesa Limpia (solo si hubo captura y la mesa quedó sin naipes)
    final isLimpia = captured.isNotEmpty && tableCopy.isEmpty;
    final limpiaPoints = isLimpia ? getLimpiaPoints(isDeckEmpty: isDeckEmpty) : 0;

    final totalPoints = caidaPoints + limpiaPoints;

    // Construcción del mensaje descriptivo
    String breakdownMessage = '';
    if (isCaida && isLimpia) {
      breakdownMessage = '¡Caída (+$caidaPoints) y Mesa Limpia (+$limpiaPoints)!';
    } else if (isCaida) {
      breakdownMessage = '¡Caída! (+$caidaPoints pts)';
    } else if (isLimpia) {
      breakdownMessage = '¡Mesa Limpia! (+$limpiaPoints pts)';
    } else if (captured.length > 2) {
      breakdownMessage = '¡Arrastre! Levantó ${captured.length} cartas.';
    }

    return PlayEvaluationResult(
      playedCard: playedCard,
      capturedCards: captured,
      newTableCards: tableCopy,
      isCaida: isCaida,
      caidaPoints: caidaPoints,
      isLimpia: isLimpia,
      limpiaPoints: limpiaPoints,
      totalPoints: totalPoints,
      breakdownMessage: breakdownMessage,
    );
  }

  // ===========================================================================
  // 4. CIERRE DE MANO Y CONTEO POR VOLUMEN
  // ===========================================================================

  /// Resuelve el cierre de mano o fin del mazo de 40 naipes:
  /// - Cartas sobrantes en mesa se las lleva el último jugador que capturó legítimamente.
  /// - Conteo por volumen: Quien tenga más de 20 cartas físicas suma (Cartas - 20) puntos.
  /// - Meta de partida: 24 puntos.
  static HandResolutionResult resolveHandEnd({
    required List<CaidaPlayerState> players,
    required List<SpanishCard> remainingTable,
    required String? lastCapturingPlayerId,
    bool isTeams = false,
  }) {
    final events = <String>[];
    final totalCardsWon = <String, int>{};
    final updatedScores = <String, int>{};
    final volumeBonusPoints = <String, int>{};

    for (final p in players) {
      totalCardsWon[p.id] = p.initialCardsWon;
      updatedScores[p.id] = p.initialScore;
      volumeBonusPoints[p.id] = 0;
    }

    // 1. Adjudicar cartas sobrantes de mesa al último jugador que levantó
    final awardedTable = List<SpanishCard>.from(remainingTable);
    if (awardedTable.isNotEmpty && lastCapturingPlayerId != null && totalCardsWon.containsKey(lastCapturingPlayerId)) {
      totalCardsWon[lastCapturingPlayerId] = (totalCardsWon[lastCapturingPlayerId] ?? 0) + awardedTable.length;
      events.add('Las ${awardedTable.length} cartas sobrantes en mesa se las lleva el último capturador.');
    }

    // 2. Conteo físico de naipes por jugador o bando
    if (isTeams) {
      // Agrupar por bando
      final teamCards = <int, int>{};
      for (final p in players) {
        teamCards[p.teamId] = (teamCards[p.teamId] ?? 0) + (totalCardsWon[p.id] ?? 0);
      }

      for (final entry in teamCards.entries) {
        final teamId = entry.key;
        final count = entry.value;
        if (count > 20) {
          final bonus = count - 20;
          events.add('Equipo $teamId superó 20 cartas físicas ($count cartas): +$bonus pts por volumen.');
          for (final p in players.where((pl) => pl.teamId == teamId)) {
            volumeBonusPoints[p.id] = bonus;
            updatedScores[p.id] = (updatedScores[p.id] ?? 0) + bonus;
          }
        }
      }
    } else {
      // Individual: cada jugador contabiliza sus cartas
      for (final p in players) {
        final count = totalCardsWon[p.id] ?? 0;
        if (count > 20) {
          final bonus = count - 20;
          volumeBonusPoints[p.id] = bonus;
          updatedScores[p.id] = (updatedScores[p.id] ?? 0) + bonus;
          events.add('${p.name} superó 20 cartas físicas ($count cartas): +$bonus pts por volumen.');
        }
      }
    }

    // 3. Comprobar si algún jugador o equipo alcanzó los 24 puntos
    String? winnerPlayerId;
    int? winnerTeamId;

    for (final p in players) {
      final score = updatedScores[p.id] ?? 0;
      if (score >= 24) {
        winnerPlayerId = p.id;
        winnerTeamId = p.teamId;
        break;
      }
    }

    return HandResolutionResult(
      lastCapturingPlayerId: lastCapturingPlayerId,
      remainingTableAwarded: awardedTable,
      totalCardsWon: totalCardsWon,
      volumeBonusPoints: volumeBonusPoints,
      updatedScores: updatedScores,
      events: events,
      winnerPlayerId: winnerPlayerId,
      winnerTeamId: winnerTeamId,
    );
  }
}
