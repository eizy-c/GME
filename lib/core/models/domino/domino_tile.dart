/// Representación inmutable de una Ficha de Dominó tradicional (Doble 6).
class DominoTile {
  /// Valor del extremo izquierdo (0 al 6).
  final int left;

  /// Valor del extremo derecho (0 al 6).
  final int right;

  const DominoTile(this.left, this.right)
      : assert(left >= 0 && left <= 6, 'El valor left debe estar entre 0 y 6. Valor: $left'),
        assert(right >= 0 && right <= 6, 'El valor right debe estar entre 0 y 6. Valor: $right');

  /// Indica si la ficha es una cochina / doble (ej. [6|6], [0|0]).
  bool get isDouble => left == right;

  /// Total de puntos (pintas) que contiene la ficha.
  int get totalPips => left + right;

  /// Verifica si alguno de los dos extremos de la ficha coincide con un [value].
  bool canConnectWith(int value) => left == value || right == value;

  /// Invierte la orientación de la ficha para acomodarse a la cabeza o cola del tablero.
  DominoTile flip() => DominoTile(right, left);

  /// Comprueba si esta ficha es equivalente a otra, sin importar su orientación.
  bool matches(DominoTile other) =>
      (left == other.left && right == other.right) ||
      (left == other.right && right == other.left);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DominoTile && matches(other));

  @override
  int get hashCode => left < right ? Object.hash(left, right) : Object.hash(right, left);

  @override
  String toString() => '[$left|$right]';
}
