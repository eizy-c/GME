/// Palos tradicionales de la Baraja Española.
enum CardSuit {
  espadas('Espadas', 'ESP'),
  bastos('Bastos', 'BAS'),
  copas('Copas', 'COP'),
  oros('Oros', 'ORO');

  final String displayName;
  final String code;
  const CardSuit(this.displayName, this.code);
}

/// Representación inmutable de un naipe tradicional español (1-7, 10-12).
///
/// Implementa reglas oficiales de puntuación:
/// - Rondas y Caídas: 1 al 7 (+1 pt), 10 (+2 pts), 11 (+3 pts), 12 (+4 pts).
class PlayingCard implements Comparable<PlayingCard> {
  final CardSuit suit;
  final int value; // 1..7, 10..12

  const PlayingCard({required this.suit, required this.value})
      : assert(
          (value >= 1 && value <= 7) || (value >= 10 && value <= 12),
          'Valor inválido para baraja española de 40 cartas: $value',
        );

  /// Puntos otorgados si forma una Ronda en mano.
  int get rondaPoints {
    switch (value) {
      case 10:
        return 2; // Sota
      case 11:
        return 3; // Caballo
      case 12:
        return 4; // Rey
      default:
        return 1; // 1 al 7
    }
  }

  /// Puntos otorgados al realizar una Caída sobre este naipe.
  int get caidaPoints {
    switch (value) {
      case 10:
        return 2; // Sota
      case 11:
        return 3; // Caballo
      case 12:
        return 4; // Rey
      default:
        return 1; // 1 al 7
    }
  }

  bool get isFigure => value >= 10;

  String get label {
    switch (value) {
      case 1:
        return 'As';
      case 10:
        return 'Sota';
      case 11:
        return 'Caballo';
      case 12:
        return 'Rey';
      default:
        return '$value';
    }
  }

  String get shortName => '${suit.code}-$value';

  @override
  int compareTo(PlayingCard other) {
    if (value != other.value) return value.compareTo(other.value);
    return suit.index.compareTo(other.suit.index);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingCard &&
          runtimeType == other.runtimeType &&
          suit == other.suit &&
          value == other.value;

  @override
  int get hashCode => Object.hash(suit, value);

  @override
  String toString() => '$label de ${suit.displayName}';
}
