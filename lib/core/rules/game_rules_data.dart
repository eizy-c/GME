/// Modelo estructurado para explicar las reglas, dinámicas y consejos de cada juego.
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

/// Repositorio estático con las reglas oficiales y tradicionales de los juegos del compendio.
class GameRulesData {
  static const Map<String, GameRules> allRules = {
    'domino': GameRules(
      id: 'domino',
      title: 'Dominó Tradicional (Doble 6)',
      subtitle: 'Estrategia de conexión y conteo de pintas',
      playersCount: '2 a 4 Jugadores (Individual o por Parejas)',
      objective:
          'Quedarse sin fichas en la mano ("Dominar") o tener la menor cantidad de puntos acumulados si la partida se cierra ("Tranque").',
      setup: [
        'Se utiliza el conjunto completo de 28 fichas (desde el [0|0] hasta el [6|6]).',
        'Se colocan las fichas bocarriba o se revuelven boca abajo en la mesa.',
        'Cada jugador recibe 7 fichas. En partidas de 2 jugadores, las 14 fichas sobrantes forman el pozo (boneyard).',
      ],
      steps: [
        'Abre la primera ronda el jugador que posea el [6|6] (Doble Seis / "La Cochina"). En rondas sucesivas, sale quien ganó la anterior.',
        'En tu turno, debes colocar una ficha cuyos puntos coincidan con uno de los dos extremos abiertos de la cadena en la mesa.',
        'Si no tienes ninguna ficha jugable: debes robar del pozo hasta encontrar una válida (o pasar si se juega sin pozo).',
      ],
      specialRules: [
        'Dominó: Gana la mano el primer jugador que juegue todas sus fichas.',
        'Tranque / Cierre: Ocurre cuando ningún jugador puede poner ficha. En este caso, cada jugador suma los puntos de sus fichas restantes; gana quien tenga menos puntos.',
        'En caso de empate en el tranque, gana quien tenga la mano (jugó primero).',
      ],
      proTips: [
        'Observa qué números castigan o pasan tus rivales para bloquearlos con esos extremos.',
        'Deshazte temprano de las fichas pesadas (dobles altos como el [6|6] y [5|5]) para no quedar con muchos puntos en un tranque.',
      ],
    ),
    'la_caida': GameRules(
      id: 'la_caida',
      title: 'La Caída Tradicional',
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
        '¡Caída!: Si juegas exactamente la misma carta que el rival anterior acaba de tirar a la mesa, cantas "¡Caída!" y sumas puntos extra.',
        '¡Limpia!: Si al capturar dejas la mesa completamente vacía sin ninguna carta, sumas puntos por mesa limpia.',
        '¡Ronda!: Si al recibir tus 3 cartas tienes un par del mismo número en mano, cantas "¡Ronda!" antes de jugar.',
      ],
      proTips: [
        'Memoriza las cartas que tu rival ha tirado para anticipar qué valores no podrá caerte.',
        'Si puedes limpiar la mesa, obligarás al rival a tirar una carta huérfana en la mesa que podrás caerle fácilmente.',
      ],
    ),
  };

  static GameRules getRules(String id) {
    return allRules[id] ?? allRules['domino']!;
  }
}
