import '../../../../core/models/cards/card_suit.dart';
import '../../../../core/models/cards/spanish_card.dart';

/// Tipo de acción requerida en cada etapa del tutorial guiado.
enum TutorialActionType {
  /// El usuario debe seleccionar y arrojar una carta específica a la mesa.
  playCard,

  /// El usuario debe pulsar el botón de canto correspondiente.
  callCanto,
}

/// Representa una etapa pedagógica secuencial dentro del tour guiado de novatos.
class TutorialStep {
  final int stepNumber;
  final String title;
  final String instruction;
  final TutorialActionType actionType;
  final List<SpanishCard> playerCards;
  final SpanishCard? botCard;
  final String? botCallout;
  final List<SpanishCard> initialTableCards;
  final SpanishCard? targetCard;
  final String? targetCantoName;
  final String feedbackTitle;
  final String feedbackDetail;
  final int pointsAwarded;
  final bool isTrivilinFinale;

  const TutorialStep({
    required this.stepNumber,
    required this.title,
    required this.instruction,
    required this.actionType,
    required this.playerCards,
    this.botCard,
    this.botCallout,
    this.initialTableCards = const [],
    this.targetCard,
    this.targetCantoName,
    required this.feedbackTitle,
    required this.feedbackDetail,
    required this.pointsAwarded,
    this.isTrivilinFinale = false,
  });

  /// Lista oficial y secuencial de las 8 etapas pedagógicas de La Caída.
  static List<TutorialStep> get officialSteps => [
        // ETAPA 1: CAÍDA BÁSICA (Mecánica Principal)
        const TutorialStep(
          stepNumber: 1,
          title: 'Etapa 1: Caída Básica',
          instruction:
              'El rival acaba de jugar un 6 de Copas. Toca tu 6 de Espadas para hacer "Caída" sobre su carta.',
          actionType: TutorialActionType.playCard,
          playerCards: [
            SpanishCard(number: 6, suit: CardSuit.espadas),
            SpanishCard(number: 10, suit: CardSuit.bastos),
            SpanishCard(number: 1, suit: CardSuit.oros),
          ],
          botCard: SpanishCard(number: 6, suit: CardSuit.copas),
          initialTableCards: [
            SpanishCard(number: 6, suit: CardSuit.copas),
          ],
          targetCard: SpanishCard(number: 6, suit: CardSuit.espadas),
          feedbackTitle: '¡CAÍDA! (+1 PT)',
          feedbackDetail:
              '¡Excelente! Si juegas una carta del mismo número que acaba de lanzar el rival anterior, haces Caída y sumas los puntos de esa carta (1 al 7 = +1 pt, Sota 10 = +2 pts, Caballo 11 = +3 pts, Rey 12 = +4 pts).',
          pointsAwarded: 1,
        ),

        // ETAPA 2: ARRASTRE Y SEGUIDILLA (Levantar mesa)
        const TutorialStep(
          stepNumber: 2,
          title: 'Etapa 2: Arrastre y Seguidilla',
          instruction:
              'En mesa hay 6, 7 y 10. Juega tu 6 de Copas para levantar el 6 y arrastrar en seguidilla consecutiva el 7 y el 10.',
          actionType: TutorialActionType.playCard,
          playerCards: [
            SpanishCard(number: 6, suit: CardSuit.copas),
            SpanishCard(number: 2, suit: CardSuit.espadas),
            SpanishCard(number: 11, suit: CardSuit.oros),
          ],
          botCard: SpanishCard(number: 6, suit: CardSuit.espadas),
          initialTableCards: [
            SpanishCard(number: 6, suit: CardSuit.espadas),
            SpanishCard(number: 7, suit: CardSuit.oros),
            SpanishCard(number: 10, suit: CardSuit.bastos),
          ],
          targetCard: SpanishCard(number: 6, suit: CardSuit.copas),
          feedbackTitle: '¡ARRASTRE Y SEGUIDILLA!',
          feedbackDetail:
              '¡Fantástico! Al coincidir tu 6 con el de la mesa, también levantas las cartas consecutivas inmediatas superiores (7 y 10). ¡Recuerda que en la baraja de 40 cartas del 7 se salta a la Sota 10!',
          pointsAwarded: 1,
        ),

        // ETAPA 3: MESA LIMPIA Y CONTEO DE VOLUMEN
        const TutorialStep(
          stepNumber: 3,
          title: 'Etapa 3: Mesa Limpia y Volumen',
          instruction:
              'Queda un solo Caballo (11) en mesa. Tira tu Caballo de Espadas para capturarlo y dejar la mesa completamente vacía.',
          actionType: TutorialActionType.playCard,
          playerCards: [
            SpanishCard(number: 11, suit: CardSuit.espadas),
          ],
          initialTableCards: [
            SpanishCard(number: 11, suit: CardSuit.bastos),
          ],
          targetCard: SpanishCard(number: 11, suit: CardSuit.espadas),
          feedbackTitle: '¡MESA LIMPIA (+4 PT)!',
          feedbackDetail:
              '¡Dejaste el tapete limpio! Sumas +4 puntos de Mesa Limpia (+2 pts si el mazo ya está vacío). Además, quien acumule más de 20 cartas físicas en su pozo sumará puntos de volumen (1 punto por cada carta sobrante).',
          pointsAwarded: 4,
        ),

        // ETAPA 4: LA RONDA Y "MATAR CANTOS"
        const TutorialStep(
          stepNumber: 4,
          title: 'Etapa 4: La Ronda y "Matar Cantos"',
          instruction:
              'Tienes una pareja de Reyes (12) y el rival cantó "Ronda de 5". Toca el botón para cantar tu "RONDA DE REYES".',
          actionType: TutorialActionType.callCanto,
          playerCards: [
            SpanishCard(number: 12, suit: CardSuit.copas),
            SpanishCard(number: 12, suit: CardSuit.espadas),
            SpanishCard(number: 4, suit: CardSuit.oros),
          ],
          botCallout: '¡Ronda de 5! (+1 pt)',
          targetCantoName: 'RONDA DE REYES',
          feedbackTitle: '¡RONDA MATADA (+4 PT)!',
          feedbackDetail:
              '¡Regla "Matando Cantos"! Dos cartas iguales forman una Ronda. Al ser Reyes (12), anulan completamente la Ronda inferior del rival y cobran +4 puntos. (1-7 = +1 pt, 10 = +2 pts, 11 = +3 pts, 12 = +4 pts).',
          pointsAwarded: 4,
        ),

        // ETAPA 5: PATRULLA (Escalera Consecutiva)
        const TutorialStep(
          stepNumber: 5,
          title: 'Etapa 5: Patrulla Tradicional',
          instruction:
              'Recibiste 4 de Copas, 5 de Oros y 6 de Espadas (3 consecutivas). Activa el botón de canto "PATRULLA".',
          actionType: TutorialActionType.callCanto,
          playerCards: [
            SpanishCard(number: 4, suit: CardSuit.copas),
            SpanishCard(number: 5, suit: CardSuit.oros),
            SpanishCard(number: 6, suit: CardSuit.espadas),
          ],
          targetCantoName: 'PATRULLA',
          feedbackTitle: '¡PATRULLA (+6 PT)!',
          feedbackDetail:
              '¡Gran jugada! 3 cartas en secuencia consecutiva forman la Patrulla tradicional venezolana, sumando 6 puntos directos para tu marcador.',
          pointsAwarded: 6,
        ),

        // ETAPA 6: VIGÍA (Pareja con Adyacente)
        const TutorialStep(
          stepNumber: 6,
          title: 'Etapa 6: El Canto de Vigía',
          instruction:
              'Tienes un par de 7 acompañado de un 6 (adyacente inmediato). Activa el botón de canto "VIGÍA".',
          actionType: TutorialActionType.callCanto,
          playerCards: [
            SpanishCard(number: 7, suit: CardSuit.oros),
            SpanishCard(number: 7, suit: CardSuit.bastos),
            SpanishCard(number: 6, suit: CardSuit.copas),
          ],
          targetCantoName: 'VIGÍA',
          feedbackTitle: '¡VIGÍA (+7 PT)!',
          feedbackDetail:
              '¡Poderoso! Dos cartas del mismo número con una correlativa inmediata forman el Vigía (ej: 7-7-6 o Sota-Sota-Caballo), otorgando 7 puntos directos.',
          pointsAwarded: 7,
        ),

        // ETAPA 7: REGISTRO (1, 11 Y 12)
        const TutorialStep(
          stepNumber: 7,
          title: 'Etapa 7: Canto de Registro',
          instruction:
              '¡Mano de gala! Tienes exactamente As (1), Caballo (11) y Rey (12). Activa el botón de canto "REGISTRO".',
          actionType: TutorialActionType.callCanto,
          playerCards: [
            SpanishCard(number: 1, suit: CardSuit.espadas),
            SpanishCard(number: 11, suit: CardSuit.copas),
            SpanishCard(number: 12, suit: CardSuit.oros),
          ],
          targetCantoName: 'REGISTRO',
          feedbackTitle: '¡REGISTRO (+8 PT)!',
          feedbackDetail:
              '¡El Registro! Reunir en la misma mano al As (1), Caballo (11) y Rey (12) otorga 8 puntos directos. Es el segundo canto más alto antes del Trivilín.',
          pointsAwarded: 8,
        ),

        // ETAPA 8: CLÍMAX Y CIERRE CON TRIVILÍN (Victoria Automática)
        const TutorialStep(
          stepNumber: 8,
          title: 'Etapa 8: ¡Trivilín y Victoria!',
          instruction:
              '¡Mano legendaria de tres cartas idénticas! Toca el botón parpadeante de "¡TRIVILÍN!" para terminar la partida de inmediato.',
          actionType: TutorialActionType.callCanto,
          playerCards: [
            SpanishCard(number: 11, suit: CardSuit.oros),
            SpanishCard(number: 11, suit: CardSuit.copas),
            SpanishCard(number: 11, suit: CardSuit.bastos),
          ],
          targetCantoName: '¡TRIVILÍN!',
          feedbackTitle: '¡TRIVILÍN! ¡VICTORIA ABSOLUTA!',
          feedbackDetail:
              '¡TRES CARTAS DEL MISMO NÚMERO SON TRIVILÍN! Otorga 24 puntos inmediatos y gana la partida por knock-out instantáneo.',
          pointsAwarded: 24,
          isTrivilinFinale: true,
        ),
      ];
}
