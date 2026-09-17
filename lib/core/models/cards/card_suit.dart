/// Palos tradicionales de la Baraja Española de 40 cartas.
enum CardSuit {
  oros('Oros', '🟡'),
  copas('Copas', '🍷'),
  espadas('Espadas', '⚔️'),
  bastos('Bastos', '🪵');

  final String label;
  final String icon;

  const CardSuit(this.label, this.icon);

  @override
  String toString() => label;
}
