import 'package:flutter/material.dart';

/// Palos tradicionales de la Baraja Española de 40 cartas.
enum CardSuit {
  oros('Oros', Icons.monetization_on_rounded),
  copas('Copas', Icons.wine_bar_rounded),
  espadas('Espadas', Icons.shield_rounded),
  bastos('Bastos', Icons.park_rounded);

  final String label;
  final IconData icon;

  const CardSuit(this.label, this.icon);

  @override
  String toString() => label;
}
