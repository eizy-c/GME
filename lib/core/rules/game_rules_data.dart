/// Modelo estructurado para explicar las reglas, dinámicas y consejos del juego.
class GameRules {
  final String id;
  final String title;
  final String subtitle;
  final String playersCount;
  final String objective;
  final List<String> setup;
  final List<String> steps;
  final List<String> specialRules;
  final List<String> proTips;

  const GameRules({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.playersCount,
    required this.objective,
    required this.setup,
    required this.steps,
    required this.specialRules,
    required this.proTips,
  });
}

/// Repositorio estático con las reglas oficiales y tradicionales de La Caída.
class GameRulesData {
  static const Map<String, GameRules> allRules = {
    'la_caida': GameRules(
      id: 'la_caida',
      title: 'CaidaGO',
      subtitle: 'Juego tradicional de naipes con cantos y capturas',
      playersCount: '2 a 4 Jugadores',
      objective:
          'Alcanzar 24 puntos capturando cartas de la mesa y cantando jugadas especiales (Caída, Limpia y Ronda).',
      setup: [
        'Baraja española tradicional de 40 cartas.',
        'Se colocan 4 cartas abiertas sobre el tapete central.',
        'Se reparten 3 cartas a cada jugador. Al acabarse, se reparten 3 más sucesivamente hasta agotar el mazo.',
      ],
      steps: [
        'En tu turno, juegas una carta de tu mano a la mesa.',
        'Si tu carta tiene el mismo número que alguna de la mesa, la capturas junto con las consecutivas ascendentes.',
        'Si no coincide con ninguna, la carta se queda en la mesa disponible para el rival.',
      ],
      specialRules: [
        '¡Cantos Tradicionales!: Al recibir 3 cartas puedes cantar: Trivilín (+24 pts, gana la partida de inmediato), Registro (+8 pts, As, Caballo y Rey [1, 11, 12]), Vigía (+7 pts, par + carta que le sigue o le atrasa), Patrulla (+6 pts, 3 en escalera) o Ronda (+1 pt cartas 1-7, +2 Sota, +3 Caballo, +4 Rey). En conflicto solo cobra el bando con el canto superior.',
        '¡Canto de Mesa!: Al abrir la partida, el repartidor canta de 1 a 4 (ascendente o descendente); aciertos suman puntos, repetidas o sin aciertos dan +1 pt al rival.',
        '¡Caída!: Si juegas el mismo número de la carta que acaba de tirar el jugador anterior, cantas ¡Caída! (+1 pt cartas 1-7, +2 Sota, +3 Caballo, +4 Rey).',
        '¡Mesa Limpia!: Si levantas todas las cartas de la mesa con cartas en el manojo sumas +4 pts. Si no hay más cartas en el manojo no vale mesa limpia (0 pts).',
        'Bono por Volumen: Al agotarse el mazo, se cuenta hasta 20 (2 jugadores/equipos), 13 y 14 repartidor (3 jugadores) o 10 (4 jugadores); el excedente son puntos directos.',
      ],
      proTips: [
        'Memoriza las cartas que tu rival ha tirado para anticipar qué valores no podrá caerte.',
        'Si puedes limpiar la mesa, obligarás al rival a tirar una carta huérfana en la mesa que podrás caerle fácilmente.',
      ],
    ),
  };

  static GameRules getRules([String id = 'la_caida']) {
    return allRules[id] ?? allRules['la_caida']!;
  }
}
