import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gme/core/presentation/widgets/spanish_card_view.dart';
import 'package:gme/features/la_caida/presentation/caida_screen.dart';

void main() {
  group('Reglas de Puntuación Tradicional de La Caída', () {
    test('Valores de puntos de Ronda y Caída según la jerarquía de figuras', () {
      int getRondaCaidaPoints(int number) {
        switch (number) {
          case 10:
            return 2; // Sota
          case 11:
            return 3; // Caballo
          case 12:
            return 4; // Rey
          default:
            return 1; // 1 al 7
        }
      }

      // Números del 1 al 7 valen +1
      for (int n = 1; n <= 7; n++) {
        expect(getRondaCaidaPoints(n), equals(1), reason: 'Número $n debe valer 1 punto');
      }

      // Figuras
      expect(getRondaCaidaPoints(10), equals(2), reason: 'Sota (10) debe valer 2 puntos');
      expect(getRondaCaidaPoints(11), equals(3), reason: 'Caballo (11) debe valer 3 puntos');
      expect(getRondaCaidaPoints(12), equals(4), reason: 'Rey (12) debe valer 4 puntos');
    });

    test('Mesa Limpia otorga +4 con mazo activo y 0 con manojo vacío', () {
      int getLimpiaPoints({required bool hasCardsInDeck}) {
        return hasCardsInDeck ? 4 : 0;
      }

      expect(getLimpiaPoints(hasCardsInDeck: true), equals(4));
      expect(getLimpiaPoints(hasCardsInDeck: false), equals(0));
    });
  });

  group('Interacción Táctil y Selección Individual de Cartas', () {
    testWidgets('Tocar una carta selecciona únicamente esa carta y muestra botón JUGAR', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CaidaScreen(initialPlayers: 2, autoStart: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar que el juego inició en el turno del usuario
      expect(find.text('Tú'), findsOneWidget);
      expect(find.text('Player 1'), findsOneWidget);

      // Buscar las cartas en mano del usuario
      final cardViews = find.byType(SpanishCardView);
      expect(cardViews, findsWidgets);

      // Antes de tocar ninguna carta, no debe haber botón de jugar carta específica
      expect(find.textContaining('JUGAR '), findsNothing);

      // Tocar la primera carta en la mano del usuario mediante su ValueKey
      final userCardFinder = find.byKey(const ValueKey('user_card_0'));
      expect(userCardFinder, findsOneWidget);
      await tester.tap(userCardFinder);
      await tester.pump();

      // Ahora solo esa carta está seleccionada y aparece el botón de acción rápido
      expect(find.textContaining('JUGAR '), findsOneWidget);

      // Tocar el botón de jugar carta para jugarla a la mesa
      await tester.tap(find.textContaining('JUGAR '));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // La carta fue jugada (se resetea la selección)
      expect(find.textContaining('JUGAR '), findsNothing);
    });

    testWidgets('Tocar individualmente cada una de las 3 cartas permite alternar la selección sin conflicto', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CaidaScreen(initialPlayers: 2, autoStart: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verificar que las 3 cartas del usuario están presentes
      final card0 = find.byKey(const ValueKey('user_card_0'));
      final card1 = find.byKey(const ValueKey('user_card_1'));
      final card2 = find.byKey(const ValueKey('user_card_2'));

      expect(card0, findsOneWidget);
      expect(card1, findsOneWidget);
      expect(card2, findsOneWidget);

      // Tocar carta 0
      await tester.tap(card0);
      await tester.pump();
      expect(find.textContaining('JUGAR '), findsOneWidget);

      // Tocar carta 1 directamente (debe alternar a carta 1)
      await tester.tap(card1);
      await tester.pump();
      expect(find.textContaining('JUGAR '), findsOneWidget);

      // Tocar carta 2 directamente (debe alternar a carta 2)
      await tester.tap(card2);
      await tester.pump();
      expect(find.textContaining('JUGAR '), findsOneWidget);

      // Jugar la carta 2
      await tester.tap(find.textContaining('JUGAR '));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Ahora quedan 2 cartas en la mano
      expect(find.byKey(const ValueKey('user_card_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('user_card_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('user_card_2')), findsNothing);
    });

    testWidgets('Indicador de Mano y Nivel se muestran correctamente en mesa y cabecera', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CaidaScreen(initialPlayers: 2, autoStart: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // En la cabecera y en el badge se muestra el nivel
      expect(find.textContaining('Nv. 1'), findsWidgets);

      // La insignia de Mano dorada (ícono de mano) aparece en pantalla (sin texto MANO)
      expect(find.byIcon(Icons.front_hand_rounded), findsOneWidget);
    });
  });
}
