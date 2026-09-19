import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gme/core/models/cards/card_suit.dart';
import 'package:gme/core/models/cards/spanish_card.dart';
import 'package:gme/core/presentation/widgets/domino_tile_view.dart';
import 'package:gme/core/presentation/widgets/spanish_card_view.dart';
import 'package:gme/core/stats/stats_repository.dart';
import 'package:gme/main.dart';

void main() {
  testWidgets('Carga inicial del compendio con Dominó y La Caída', (WidgetTester tester) async {
    final statsRepo = InMemoryStatsRepository();
    await tester.pumpWidget(CompendioJuegosApp(statsRepository: statsRepo));

    // Comprobar título del compendio y badge offline
    expect(find.text('Compendio de Juegos'), findsOneWidget);
    expect(find.text('100% OFFLINE'), findsOneWidget);
    expect(find.text('Dominó (Doble 6)'), findsOneWidget);
    expect(find.text('CaidaGO'), findsOneWidget);
  });

  testWidgets('Apertura del diálogo de reglas "¿Cómo jugar?"', (WidgetTester tester) async {
    final statsRepo = InMemoryStatsRepository();
    await tester.pumpWidget(CompendioJuegosApp(statsRepository: statsRepo));

    // Debe haber botones de "¿Cómo jugar?" en las tarjetas de juego
    final rulesButtons = find.text('¿Cómo jugar?');
    expect(rulesButtons, findsWidgets);

    // Tocar el primer botón de "¿Cómo jugar?"
    await tester.tap(rulesButtons.first);
    await tester.pumpAndSettle();

    // Comprobar que se abre la ventana modal con las secciones de reglas
    expect(find.text('Objetivo del Juego'), findsOneWidget);
    expect(find.text('Preparación y Reparto'), findsOneWidget);
    expect(find.text('¡Entendido, vamos a jugar!'), findsOneWidget);

    // Desplazar la lista del diálogo para ver el resto de secciones
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('¿Cómo se Juega? (Paso a Paso)'), findsOneWidget);
  });

  testWidgets('Navegación y carga interactiva de Dominó (Doble 6)', (WidgetTester tester) async {
    final statsRepo = InMemoryStatsRepository();
    await tester.pumpWidget(CompendioJuegosApp(statsRepository: statsRepo));

    // Filtrar por Dominó (Mesa)
    await tester.tap(find.text('Dominó (Mesa)'));
    await tester.pumpAndSettle();

    // Tocar tarjeta de Dominó
    await tester.tap(find.text('Dominó (Doble 6)'));
    await tester.pumpAndSettle();

    // Verificar que cargó la pantalla de Dominó
    expect(find.text('Dominó Tradicional (Doble 6)'), findsOneWidget);
    expect(find.textContaining('Tú'), findsOneWidget);
    expect(find.byType(DominoTileView), findsWidgets);
  });

  testWidgets('SpanishCardView renderiza figuras en tamaño compacto sin desbordamiento (overflow)', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterErrorDetails? errorDetails;
    FlutterError.onError = (details) {
      errorDetails = details;
    };

    // Renderizamos las figuras 10, 11, 12 de cada palo a width 72 y width 46
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Casos que antes producían overflow en el showcase
                SpanishCardView(card: SpanishCard(number: 10, suit: CardSuit.oros), width: 72),
                SpanishCardView(card: SpanishCard(number: 11, suit: CardSuit.oros), width: 72),
                SpanishCardView(card: SpanishCard(number: 12, suit: CardSuit.oros), width: 72),
                SpanishCardView(card: SpanishCard(number: 10, suit: CardSuit.copas), width: 72),
                SpanishCardView(card: SpanishCard(number: 11, suit: CardSuit.copas), width: 72),
                SpanishCardView(card: SpanishCard(number: 12, suit: CardSuit.copas), width: 72),
                SpanishCardView(card: SpanishCard(number: 10, suit: CardSuit.espadas), width: 72),
                SpanishCardView(card: SpanishCard(number: 11, suit: CardSuit.espadas), width: 72),
                SpanishCardView(card: SpanishCard(number: 12, suit: CardSuit.espadas), width: 72),
                // Tamaño ultra-compacto como en Cinquillo
                SpanishCardView(card: SpanishCard(number: 12, suit: CardSuit.oros), width: 46),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    FlutterError.onError = originalOnError;
    expect(errorDetails, isNull, reason: 'No debe existir ningún error de desbordamiento en SpanishCardView');
  });
}
