import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gme/core/presentation/widgets/game_result_dialog.dart';
import 'package:gme/core/presentation/widgets/game_table_header.dart';
import 'package:gme/core/presentation/widgets/match_setup_dialog.dart';
import 'package:gme/core/presentation/widgets/speech_bubble.dart';
import 'package:gme/core/presentation/widgets/table_player_badge.dart';
import 'package:gme/core/presentation/widgets/wood_table_background.dart';
import 'package:gme/features/domino/presentation/domino_screen.dart';
import 'package:gme/features/la_caida/presentation/caida_screen.dart';

void main() {
  group('Componentes Visuales de Mesa de Juego Tradicional', () {
    testWidgets('WoodTableBackground renderiza fondo y elemento hijo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WoodTableBackground(
              child: Center(child: Text('Mesa de Prueba')),
            ),
          ),
        ),
      );

      expect(find.text('Mesa de Prueba'), findsOneWidget);
    });

    testWidgets('GameTableHeader renderiza título, trofeos y ping', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: GameTableHeader(
              title: 'La Caída',
              trophies: 7500,
              pingMs: 60,
              showPing: true,
              onBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('La Caída'), findsOneWidget);
      expect(find.text('7.5k'), findsOneWidget);
      expect(find.text('60ms'), findsOneWidget);
    });

    testWidgets('GameTableHeader oculta ping en modo bot (showPing: false)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: GameTableHeader(
              title: 'La Caída',
              trophies: 7500,
              showPing: false,
              onBack: () {},
            ),
          ),
        ),
      );

      expect(find.text('La Caída'), findsOneWidget);
      expect(find.text('60ms'), findsNothing);
    });

    testWidgets('TablePlayerBadge renderiza avatar, nombre y bocadillo de canto', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TablePlayerBadge(
              name: 'Player 1',
              scoreOrCards: 16,
              isBot: false,
              isCurrentTurn: true,
              calloutMessage: 'Patrulla',
            ),
          ),
        ),
      );

      expect(find.text('Player 1'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text('Patrulla'), findsOneWidget);
      expect(find.byType(SpeechBubble), findsOneWidget);
    });

    testWidgets('MatchSetupDialog permite seleccionar 1, 2, 3 o 4 jugadores', (tester) async {
      MatchSetupConfig? selectedConfig;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedConfig = await MatchSetupDialog.show(
                    context,
                    gameTitle: 'La Caída',
                    initialPlayerCount: 3,
                  );
                },
                child: const Text('Abrir Setup'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Setup'));
      await tester.pumpAndSettle();

      expect(find.text('CONFIGURAR SALA'), findsOneWidget);
      expect(find.text('La Caída'), findsOneWidget);
      expect(find.text('1 Jug.'), findsOneWidget);
      expect(find.text('2 Jug.'), findsOneWidget);
      expect(find.text('3 Jug.'), findsOneWidget);
      expect(find.text('4 Jug.'), findsOneWidget);

      // Seleccionar 4 jugadores
      await tester.tap(find.text('4 Jug.'));
      await tester.pumpAndSettle();

      // Iniciar
      await tester.tap(find.text('¡INICIAR MESA DE JUEGO!'));
      await tester.pumpAndSettle();

      expect(selectedConfig, isNotNull);
      expect(selectedConfig!.playerCount, equals(4));
    });

    testWidgets('GameResultDialog renderiza modal de victoria con podio', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameResultDialog(
              userWon: true,
              subtitle: 'Partida concluida',
              entries: const [
                GameResultEntry(name: 'Tú', scoreChange: 2000, isWinner: true, isUser: true),
                GameResultEntry(name: 'Player 1', scoreChange: -1000, isWinner: false, isUser: false),
              ],
              onRematch: () {},
              onBackToMenu: () {},
            ),
          ),
        ),
      );

      expect(find.text('¡HAS GANADO!'), findsOneWidget);
      expect(find.text('Tú'), findsOneWidget);
      expect(find.text('Player 1'), findsOneWidget);
      expect(find.text('+2000'), findsOneWidget);
      expect(find.text('-1000'), findsOneWidget);
      expect(find.text('Lobby'), findsOneWidget);
      expect(find.text('Revancha'), findsOneWidget);
      expect(find.text('Atrás'), findsNothing);
    });
  });

  group('Mesa de Juegos con 1 a 4 Jugadores', () {
    testWidgets('La Caída muestra menú previo de configuración antes de iniciar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaidaScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('LA CAÍDA TRADICIONAL'), findsOneWidget);
      expect(find.text('¿Deseas comenzar a jugar?'), findsOneWidget);
      expect(find.text('Contra Bot'), findsOneWidget);
      expect(find.text('Multijugador'), findsOneWidget);
      expect(find.text('1 Bot'), findsOneWidget);
      expect(find.text('2 Bots'), findsOneWidget);
      expect(find.text('3 Bots'), findsOneWidget);
      expect(find.text('¡COMENZAR A JUGAR!'), findsOneWidget);

      // Iniciar partida pulsando el botón
      await tester.ensureVisible(find.text('¡COMENZAR A JUGAR!'));
      await tester.tap(find.text('¡COMENZAR A JUGAR!'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tú'), findsOneWidget);
      expect(find.text('Player 1'), findsOneWidget);
    });

    testWidgets('La Caída carga con 3 jugadores como en Captura 1', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaidaScreen(initialPlayers: 3, autoStart: true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('La Caída Tradicional'), findsOneWidget);
      expect(find.text('3 Jug.'), findsOneWidget);
      expect(find.text('Tú'), findsOneWidget);
      expect(find.text('Player 1'), findsOneWidget);
      expect(find.text('Player 2'), findsOneWidget);
    });


    testWidgets('Dominó carga con 4 jugadores en cruz', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DominoScreen(initialPlayers: 4),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Dominó Tradicional (Doble 6)'), findsOneWidget);
      expect(find.text('4 Jug.'), findsOneWidget);
      expect(find.text('Tú'), findsOneWidget);
    });
  });
}
