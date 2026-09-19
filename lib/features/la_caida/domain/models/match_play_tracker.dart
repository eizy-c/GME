import '../../../../core/models/cards/spanish_card.dart';

/// Seguimiento y auditoría en tiempo real de jugadas, caídas, limpias y cantos en la partida activa.
/// Desacopla las variables sueltas de conteo dentro del State de CaidaScreen.
class MatchPlayTracker {
  int userCaidas = 0;
  int userLimpias = 0;
  int userCantos = 0;

  SpanishCard? lastPlayedCard;
  int? lastPlayedPlayerIndex;
  int? lastCapturingPlayerIndex;

  /// Registra el lanzamiento de una carta por un jugador o bot
  void recordPlay({
    required SpanishCard card,
    required int playerIndex,
  }) {
    lastPlayedCard = card;
    lastPlayedPlayerIndex = playerIndex;
  }

  /// Registra una captura de mesa
  void recordCapture({
    required int playerIndex,
    bool isCaida = false,
    bool isLimpia = false,
    bool isUser = false,
  }) {
    lastCapturingPlayerIndex = playerIndex;
    if (isUser) {
      if (isCaida) userCaidas++;
      if (isLimpia) userLimpias++;
    }
  }

  /// Registra un canto válido (Ronda, Patrulla, Vigía, Registro)
  void recordCanto({required bool isUser}) {
    if (isUser) {
      userCantos++;
    }
  }

  /// Reinicia el rastreador para una nueva partida
  void reset() {
    userCaidas = 0;
    userLimpias = 0;
    userCantos = 0;
    lastPlayedCard = null;
    lastPlayedPlayerIndex = null;
    lastCapturingPlayerIndex = null;
  }
}
