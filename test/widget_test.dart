import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gme/core/models/cards/card_suit.dart';
import 'package:gme/core/models/cards/spanish_card.dart';
import 'package:gme/core/presentation/widgets/debug_console_modal.dart';
import 'package:gme/core/presentation/widgets/debug_inspector_overlay.dart';
import 'package:gme/core/presentation/widgets/game_rules_dialog.dart';
import 'package:gme/core/presentation/widgets/spanish_card_view.dart';
import 'package:gme/core/services/debug_logger.dart';
import 'package:gme/core/stats/stats_repository.dart';
import 'package:gme/main.dart';

void main() {
  setUp(() {
    DebugLogger.initialize();
  });

  testWidgets('Carga inicial directa en CaidaSplashScreen y renderizado del botón de bugs', (WidgetTester tester) async {
    final statsRepo = InMemoryStatsRepository();
    await tester.pumpWidget(CaidaGoApp(statsRepository: statsRepo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Comprobar título del juego en pantalla de bienvenida
    expect(find.text('CAIDAGO'), findsWidgets);
    expect(find.text('Tradicional'), findsOneWidget);
    expect(find.text('TOCAR PARA ENTRAR'), findsOneWidget);

    // Verificar que el overlay de depuración está presente con su icono de bug
    expect(find.byType(DebugInspectorOverlay), findsOneWidget);
    expect(find.byIcon(Icons.bug_report_rounded), findsOneWidget);
  });

  testWidgets('Apertura de la consola de diagnóstico de bugs al tocar el botón flotante', (WidgetTester tester) async {
    final statsRepo = InMemoryStatsRepository();
    await tester.pumpWidget(CaidaGoApp(statsRepository: statsRepo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tocar el botón flotante de bugs
    await tester.tap(find.byIcon(Icons.bug_report_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verificar que abre el modal de diagnóstico
    expect(find.byType(DebugConsoleModal), findsOneWidget);
    expect(find.text('CONSOLA DE BUGS Y REGISTROS'), findsOneWidget);
    expect(find.text('Copiar Logs'), findsOneWidget);
    expect(find.text('Simular Error'), findsOneWidget);
  });

  testWidgets('Apertura del diálogo de reglas de La Caída', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => GameRulesDialog.show(context, 'la_caida'),
              child: const Text('Ver Reglas'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ver Reglas'));
    await tester.pumpAndSettle();

    // Comprobar que se abre la ventana modal con las secciones de reglas de La Caída
    expect(find.text('CaidaGO'), findsOneWidget);
    expect(find.text('Objetivo del Juego'), findsOneWidget);
    expect(find.text('Preparación y Reparto'), findsOneWidget);
    expect(find.text('¡Entendido, vamos a jugar!'), findsOneWidget);

    // Desplazar la lista del diálogo para ver el resto de secciones
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('¿Cómo se Juega? (Paso a Paso)'), findsOneWidget);
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
                SpanishCardView(card: SpanishCard(number: 10, suit: CardSuit.oros), width: 72),
                SpanishCardView(card: SpanishCard(number: 11, suit: CardSuit.oros), width: 72),
                SpanishCardView(card: SpanishCard(number: 12, suit: CardSuit.oros), width: 72),
                SpanishCardView(card: SpanishCard(number: 10, suit: CardSuit.copas), width: 72),
                SpanishCardView(card: SpanishCard(number: 11, suit: CardSuit.copas), width: 72),
                SpanishCardView(card: SpanishCard(number: 12, suit: CardSuit.copas), width: 72),
                SpanishCardView(card: SpanishCard(number: 10, suit: CardSuit.espadas), width: 72),
                SpanishCardView(card: SpanishCard(number: 11, suit: CardSuit.espadas), width: 72),
                SpanishCardView(card: SpanishCard(number: 12, suit: CardSuit.espadas), width: 72),
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
