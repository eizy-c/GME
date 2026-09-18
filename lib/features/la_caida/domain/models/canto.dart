import 'playing_card.dart';

/// Tipos de cantos tradicionales venezolanos en La Caída.
enum CantoType {
  ronda,     // 2 cartas del mismo número (+1 a +4 pts)
  patrulla,  // 3 cartas consecutivas (+6 pts)
  registro,  // As, Caballo y Rey exactos: [1, 11, 12] (+8 pts)
  vigia,     // 2 cartas iguales + 1 consecutiva que le sigue o le atrasa (+7 pts)
  trivilin,  // 3 cartas del mismo número (+24 pts, gana de inmediato)
}

/// Jerarquía sellada (sealed class) POO en Dart 3 para los Cantos de La Caída.
sealed class Canto implements Comparable<Canto> {
  final List<PlayingCard> cards;

  const Canto({required this.cards});

  CantoType get type;
  String get name;
  int get points;
  int get priority;
  int get tieBreakerValue;
  String get description;

  @override
  int compareTo(Canto other) {
    if (priority != other.priority) {
      return priority.compareTo(other.priority);
    }
    return tieBreakerValue.compareTo(other.tieBreakerValue);
  }

  @override
  String toString() => '$name (+$points pts)';
}

/// Trivilín: Tres cartas del mismo número en mano (+24 pts, partida inmediata).
class TrivilinCanto extends Canto {
  final int value;

  const TrivilinCanto({required super.cards, required this.value});

  @override
  CantoType get type => CantoType.trivilin;

  @override
  String get name => '¡Trivilín!';

  @override
  int get points => 24;

  @override
  int get priority => 5;

  @override
  int get tieBreakerValue => value;

  @override
  String get description => 'Tres cartas del número $value';
}

/// Vigía: Par de cartas iguales + una consecutiva que le sigue o le atrasa (+7 pts).
class VigiaCanto extends Canto {
  final int pairValue;
  final int adjacentValue;

  const VigiaCanto({
    required super.cards,
    required this.pairValue,
    required this.adjacentValue,
  });

  @override
  CantoType get type => CantoType.vigia;

  @override
  String get name => '¡Vigía!';

  @override
  int get points => 7;

  @override
  int get priority => 4;

  @override
  int get tieBreakerValue => pairValue * 100 + adjacentValue;

  @override
  String get description => 'Par de $pairValue con $adjacentValue (adyacente)';
}

/// Registro: Exactamente As, Caballo y Rey [1, 11, 12] (+8 pts).
class RegistroCanto extends Canto {
  const RegistroCanto({required super.cards});

  @override
  CantoType get type => CantoType.registro;

  @override
  String get name => '¡Registro!';

  @override
  int get points => 8;

  @override
  int get priority => 3;

  @override
  int get tieBreakerValue => 12;

  @override
  String get description => 'As, Caballo y Rey [1, 11, 12]';
}

/// Patrulla: Tres cartas consecutivas en escalera (+6 pts).
class PatrullaCanto extends Canto {
  final int highestValue;

  const PatrullaCanto({required super.cards, required this.highestValue});

  @override
  CantoType get type => CantoType.patrulla;

  @override
  String get name => '¡Patrulla!';

  @override
  int get points => 6;

  @override
  int get priority => 2;

  @override
  int get tieBreakerValue => highestValue;

  @override
  String get description => 'Tres cartas en escalera hasta el $highestValue';
}

/// Ronda: Dos cartas del mismo número en mano (+1 a +4 pts según figura).
class RondaCanto extends Canto {
  final int pairValue;

  const RondaCanto({required super.cards, required this.pairValue});

  @override
  CantoType get type => CantoType.ronda;

  @override
  String get name => '¡Ronda!';

  @override
  int get points {
    switch (pairValue) {
      case 10: return 2;
      case 11: return 3;
      case 12: return 4;
      default: return 1;
    }
  }

  @override
  int get priority => 1;

  @override
  int get tieBreakerValue => pairValue;

  @override
  String get description => 'Par de $pairValue (+$points pts)';
}
