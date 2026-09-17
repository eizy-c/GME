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
    'la_vieja': GameRules(
      id: 'la_vieja',
      title: 'La Vieja (Tres en Raya)',
      subtitle: 'Duelo clásico de alineación en tablero 3x3',
      playersCount: '2 Jugadores (o contra Bot)',
      objective:
          'Ser el primer jugador en alinear 3 de sus símbolos consecutivamente en línea recta (horizontal, vertical o diagonal).',
      setup: [
        'Tablero cuadrado con una cuadrícula de 3x3 casillas vacías (9 casillas en total).',
        'El Jugador 1 juega con la ficha "X" y realiza el primer movimiento.',
        'El Jugador 2 (o Bot) juega con la ficha "O".',
      ],
      steps: [
        'Los jugadores se alternan turnos colocando una sola ficha en cualquier casilla libre.',
        'Una casilla ocupada no puede ser modificada ni reemplazada durante la partida.',
        'El turno pasa automáticamente al adversario tras colocar la ficha.',
      ],
      specialRules: [
        'Si un jugador completa una línea de 3 casillas idénticas, gana la partida de inmediato.',
        'Si las 9 casillas quedan llenas y nadie alineó 3 fichas, se declara "Empate" o "Juego Trancado".',
      ],
      proTips: [
        'Ocupar la casilla central (1, 1) otorga la mayor cantidad de opciones de victoria (4 posibles líneas).',
        'Las 4 esquinas son la segunda mejor opción estratégica para forzar ataques dobles ("bifurcaciones").',
      ],
    ),
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
    'truco': GameRules(
      id: 'truco',
      title: 'Truco Venezolano',
      subtitle: 'El rey de los juegos de cartas, farol y envite',
      playersCount: '2 o 4 Jugadores',
      objective:
          'Llegar a 24 puntos ganando bazas en las manos y cantando con éxito el Envido, la Flor y el Truco.',
      setup: [
        'Baraja española de 40 cartas.',
        'Se reparten 3 cartas a cada jugador y se voltea una carta sobre el mazo llamada "La Vira".',
      ],
      steps: [
        'Cada mano consta de 3 rondas de bazas. Cada jugador tira una carta; la carta de mayor jerarquía gana la baza.',
        'Gana la mano quien gane 2 de las 3 bazas.',
        'Antes o durante el juego de naipes, los jugadores pueden cantar envites o subir las apuestas.',
      ],
      specialRules: [
        'El Perico y la Perica: Las dos cartas más poderosas del juego. El Caballo del palo de la Vira es el "Perico" (1ª carta del juego); la Sota del palo de la Vira es la "Perica" (2ª carta).',
        'Flor: Tener 3 cartas del mismo palo (o 2 cartas del mismo palo + Perico/Perica). Se canta antes de jugar carta.',
        'El Truco: Apuesta sobre quién gana las bazas de cartas. Se puede subir a "¡Retruco!" y luego a "¡Vale Cuatro!".',
      ],
      proTips: [
        'El farol es el alma del Truco: canta con seguridad para hacer huir a rivales con mejores cartas.',
        'Guardar el Perico o una carta alta para la 2ª o 3ª baza asegura la mano decisiva.',
      ],
    ),
    'cinquillo': GameRules(
      id: 'cinquillo',
      title: 'Cinquillo',
      subtitle: 'Colocación en escalera y estrategia de bloqueo',
      playersCount: '3 a 4 Jugadores',
      objective:
          'Ser el primer jugador en deshacerse de todas las cartas de la mano colocándolas en las cuatro escaleras de la mesa.',
      setup: [
        'Baraja española de 40 cartas repartidas equitativamente entre los participantes.',
        'El centro de la mesa se reserva para las 4 columnas de palos: Oros, Copas, Espadas y Bastos.',
      ],
      steps: [
        'Empieza quien posea el 5 de Oros colocándolo en el centro de la mesa.',
        'En los turnos siguientes, cada jugador solo puede colocar cartas que continúen una escalera existente (hacia arriba 6, 7, 10, 11, 12 o hacia abajo 4, 3, 2, 1) o bien abrir un nuevo palo con su 5.',
        'Si un jugador no tiene ninguna carta que pueda colocar legalmente, está obligado a presionar "Pasar".',
      ],
      specialRules: [
        'No se puede jugar ninguna carta de un palo hasta que el 5 de ese palo haya sido colocado en mesa.',
        'Si un jugador tiene al menos una jugada legal disponible, NO puede pasar su turno voluntariamente.',
        'El primer jugador que coloque su última carta en la mesa gana la partida.',
      ],
      proTips: [
        'Si tienes el 5 de un palo pero pocas cartas de ese palo, retén el 5 lo máximo posible para evitar que los rivales bajen sus cartas.',
        'Intenta colocar cartas de los extremos en los palos donde tengas muchas cartas para desbloquearte tu propia mano.',
      ],
    ),
    'baraja_espanola': GameRules(
      id: 'baraja_espanola',
      title: 'Baraja Española (40 Naipes)',
      subtitle: 'Estructura, palos y simbología tradicional',
      playersCount: 'Simulador / 1 a 4 Jugadores',
      objective:
          'Comprender la jerarquía, figuras y mecánica de reparto tradicional con algoritmo de barajado Fisher-Yates.',
      setup: [
        'Consta exactamente de 40 naipes divididos en 4 palos tradicionales de 10 cartas cada uno: Oros, Copas, Espadas y Bastos.',
        'No contiene los números 8 ni 9 en la baraja de 40.',
      ],
      steps: [
        'Cartas numéricas: 1 (As), 2, 3, 4, 5, 6 y 7.',
        'Figuras tradicionales: 10 (Sota), 11 (Caballo / Caballero) y 12 (Rey).',
        'Cada juego tradicional (Truco, Caída, Mus, Brisca, Tute) redefine la jerarquía de las cartas según sus propias reglas.',
      ],
      specialRules: [
        'El corte del mazo es la acción tradicional de separar el mazo en dos porciones antes del reparto para garantizar aleatoriedad.',
      ],
      proTips: [
        'En la mayoría de juegos de naipes españoles, los Ases y las figuras (Sota, Caballo y Rey) tienen el mayor peso o puntaje.',
      ],
    ),
  };

  static GameRules getRules(String id) {
    return allRules[id] ?? allRules['la_vieja']!;
  }
}
