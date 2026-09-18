import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gme/core/models/cards/card_suit.dart';
import 'package:gme/core/models/cards/spanish_card.dart';
import 'package:gme/features/la_caida/economy/player_session.dart';
import 'package:gme/features/la_caida/tutorial/tutorial_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TutorialEngine - Tour de Novatos (Fase 3)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PlayerSession.setShared(PlayerSession.createDefault(coins: 0, hasCompletedTutorial: false));
    });

    test('Catálogo oficial contiene exactamente 8 etapas consecutivas', () {
      final engine = TutorialEngine();
      expect(engine.totalSteps, 8);
      expect(engine.currentStepIndex, 0);
      expect(engine.isCompleted, false);
    });

    test('Etapa 1: Caída Básica - Fuerza jugar 6 de Espadas y rechaza otras cartas', () {
      final engine = TutorialEngine();
      expect(engine.currentStep.stepNumber, 1);

      // Intentar jugar carta no autorizada
      const wrongCard = SpanishCard(number: 10, suit: CardSuit.bastos);
      expect(engine.canPlayCard(wrongCard), false);
      expect(engine.playUserCard(wrongCard), false);

      // Jugar carta correcta (6 de Espadas)
      const correctCard = SpanishCard(number: 6, suit: CardSuit.espadas);
      expect(engine.canPlayCard(correctCard), true);
      final played = engine.playUserCard(correctCard);
      expect(played, true);
      expect(engine.userScore, 1);
      expect(engine.showingFeedbackModal, true);
      expect(engine.tableCards.isEmpty, true);
    });

    test('Etapa 2: Arrastre y Seguidilla - Levanta mesa con 6 de Copas', () {
      final engine = TutorialEngine();
      engine.advanceToNextStep(); // Paso 2
      expect(engine.currentStep.stepNumber, 2);

      const correctCard = SpanishCard(number: 6, suit: CardSuit.copas);
      expect(engine.playUserCard(correctCard), true);
      expect(engine.userScore, 1);
      expect(engine.tableCards.isEmpty, true);
    });

    test('Etapa 3: Mesa Limpia y Volumen - Suma +4 puntos de Limpia', () {
      final engine = TutorialEngine();
      engine.advanceToNextStep();
      engine.advanceToNextStep(); // Paso 3
      expect(engine.currentStep.stepNumber, 3);

      const correctCard = SpanishCard(number: 11, suit: CardSuit.espadas);
      expect(engine.playUserCard(correctCard), true);
      expect(engine.userScore, 4);
    });

    test('Etapas 4 a 7: Cantos Tradicionales (Ronda, Patrulla, Vigía, Registro)', () {
      final engine = TutorialEngine();

      // Paso 4: Ronda de Reyes (+4)
      for (int i = 0; i < 3; i++) {
        engine.advanceToNextStep();
      }
      expect(engine.currentStep.stepNumber, 4);
      expect(engine.callUserCanto('VIGÍA'), false);
      expect(engine.callUserCanto('RONDA DE REYES'), true);
      expect(engine.userScore, 4);

      // Paso 5: Patrulla (+6)
      engine.advanceToNextStep();
      expect(engine.currentStep.stepNumber, 5);
      expect(engine.callUserCanto('PATRULLA'), true);
      expect(engine.userScore, 10);

      // Paso 6: Vigía (+7)
      engine.advanceToNextStep();
      expect(engine.currentStep.stepNumber, 6);
      expect(engine.callUserCanto('VIGÍA'), true);
      expect(engine.userScore, 17);

      // Paso 7: Registro (+8)
      engine.advanceToNextStep();
      expect(engine.currentStep.stepNumber, 7);
      expect(engine.callUserCanto('REGISTRO'), true);
      expect(engine.userScore, 25);
    });

    test('Etapa 8: Clímax de Trivilín - Victoria fulminante, +1000 monedas y hasCompletedTutorial', () {
      final engine = TutorialEngine();
      final session = PlayerSession.shared;
      expect(session.coins, 0);
      expect(session.hasCompletedTutorial, false);

      // Avanzar hasta la etapa 8
      for (int i = 0; i < 7; i++) {
        engine.advanceToNextStep();
      }
      expect(engine.currentStep.stepNumber, 8);
      expect(engine.currentStep.isTrivilinFinale, true);

      // Cantar Trivilín
      final success = engine.callUserCanto('¡TRIVILÍN!');
      expect(success, true);
      expect(engine.isCompleted, true);

      // Validar impacto económico de graduación
      expect(session.coins, 1000);
      expect(session.hasCompletedTutorial, true);
    });
  });
}
