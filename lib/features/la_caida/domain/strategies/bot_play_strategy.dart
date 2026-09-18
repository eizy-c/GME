import '../models/playing_card.dart';
import '../models/table_state.dart';

/// Interfaz desacoplada para la heurística de IA de los bots.
abstract class BotPlayStrategy {
  PlayingCard chooseCard({
    required List<PlayingCard> hand,
    required TableState tableState,
  });
}

/// Estrategia clásica por capas: Caída > Arrastre/Captura > Descarte seguro.
class DefaultBotStrategy implements BotPlayStrategy {
  const DefaultBotStrategy();

  static const List<int> sequence = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12];

  @override
  PlayingCard chooseCard({
    required List<PlayingCard> hand,
    required TableState tableState,
  }) {
    assert(hand.isNotEmpty, 'La mano del bot no puede estar vacía');
    if (hand.length == 1) return hand.first;

    // 1. PRIORIDAD MÁXIMA: Realizar ¡Caída! sobre la carta inmediatamente previa
    if (tableState.lastPlayedCard != null) {
      final caidaCandidate = hand.where(
        (c) => c.value == tableState.lastPlayedCard!.value,
      ).firstOrNull;
      if (caidaCandidate != null) return caidaCandidate;
    }

    // 2. SEGUNDA PRIORIDAD: Captura que maximice el arrastre de cartas
    PlayingCard? bestCaptureCard;
    int maxCapturedCount = 0;

    for (final card in hand) {
      final matches = tableState.activeCards.where((c) => c.value == card.value).toList();
      if (matches.isNotEmpty) {
        int captured = 1 + matches.length;
        // Simular arrastre hacia arriba
        int nextExpected = _getNextInSequence(card.value);
        while (nextExpected != -1 && tableState.activeCards.any((c) => c.value == nextExpected)) {
          final count = tableState.activeCards.where((c) => c.value == nextExpected).length;
          captured += count;
          nextExpected = _getNextInSequence(nextExpected);
        }

        if (captured > maxCapturedCount) {
          maxCapturedCount = captured;
          bestCaptureCard = card;
        }
      }
    }

    if (bestCaptureCard != null) return bestCaptureCard;

    // 3. TERCERA PRIORIDAD: Descarte seguro (priorizar cartas bajas que no dejen arrastre)
    final sortedBySafeness = List<PlayingCard>.from(hand)
      ..sort((a, b) {
        // Evita descartar figuras (10, 11, 12) si hay cartas bajas disponibles
        final aIsFig = a.isFigure ? 1 : 0;
        final bIsFig = b.isFigure ? 1 : 0;
        if (aIsFig != bIsFig) return aIsFig.compareTo(bIsFig);
        return a.value.compareTo(b.value);
      });

    return sortedBySafeness.first;
  }

  int _getNextInSequence(int value) {
    final idx = sequence.indexOf(value);
    if (idx == -1 || idx == sequence.length - 1) return -1;
    return sequence[idx + 1];
  }
}
