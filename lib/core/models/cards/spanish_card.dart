import 'card_suit.dart';

/// Representación inmutable de un naipe de la Baraja Española.
///
/// Soporta valores de 1 a 7 y figuras (10: Sota, 11: Caballo, 12: Rey).
/// La jerarquía [hierarchyValue] y el puntaje [points] son configurables
/// según las reglas del juego específico (Truco, Caída, Cinquillo).
class SpanishCard implements Comparable<SpanishCard> {
  /// Número nominal del naipe (1 al 7, 10 al 12).
  final int number;

  /// Palo al que pertenece la carta (Oros, Copas, Espadas, Bastos).
  final CardSuit suit;

  /// Valor de jerarquía para comparación de poder en mesa/mano.
  /// Mayor valor = mayor poder.
  final int hierarchyValue;

  /// Puntuación que aporta la carta al contabilizar (ej. en Caída).
  final int points;

  const SpanishCard({
    required this.number,
    required this.suit,
    this.hierarchyValue = 0,
    this.points = 0,
  }) : assert(
          (number >= 1 && number <= 7) || (number >= 10 && number <= 12),
          'Un naipe de la baraja española de 40 cartas debe ser 1..7 o 10..12. Valor dado: $number',
        );

  /// Nombre tradicional del número (As, Sota, Caballo, Rey o el número).
  String get rankName {
    switch (number) {
      case 1:
        return 'As';
      case 10:
        return 'Sota';
      case 11:
        return 'Caballo';
      case 12:
        return 'Rey';
      default:
        return '$number';
    }
  }

  /// Nombre completo de la carta (ej. "As de Oros", "Caballo de Espadas").
  String get displayName => '$rankName de ${suit.label}';

  /// Identificador corto (ej. "1O", "7E", "10C", "12B").
  String get shortCode => '$number${suit.label[0]}';

  /// Indica si la carta es una figura (Sota, Caballo, Rey).
  bool get isFigure => number >= 10 && number <= 12;

  /// Crea una copia de la carta ajustando su jerarquía y/o puntaje para un juego dado.
  SpanishCard withRules({int? hierarchy, int? points}) {
    return SpanishCard(
      number: number,
      suit: suit,
      hierarchyValue: hierarchy ?? hierarchyValue,
      points: points ?? this.points,
    );
  }

  @override
  int compareTo(SpanishCard other) {
    return hierarchyValue.compareTo(other.hierarchyValue);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpanishCard &&
          other.number == number &&
          other.suit == suit);

  @override
  int get hashCode => Object.hash(number, suit);

  @override
  String toString() => '$displayName ($shortCode)';
}
