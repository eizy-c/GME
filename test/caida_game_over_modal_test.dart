import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gme/features/la_caida/economy/player_session.dart';
import 'package:gme/features/la_caida/presentation/widgets/caida_game_over_modal.dart';

void main() {
  setUp(() {
    PlayerSession.setShared(PlayerSession.createDefault(coins: 0, tickets: 10));
  });

  group('CaidaGameOverModal Tests', () {
    testWidgets('Modal de Victoria renderiza banner, marcador, cofre obtenido, XP y botones', (tester) async {
      bool rematchPressed = false;
      bool lobbyPressed = false;

      const summary = CaidaMatchSummary(
        userWon: true,
        userTeamScore: 24,
        opponentTeamScore: 16,
        userTeamCardsWon: 22,
        opponentTeamCardsWon: 18,
        caidasCount: 2,
        limpiasCount: 1,
        cantosCount: 1,
        coinsWon: 150,
        xpWon: 720,
        chestAwarded: true,
        chestSlotIndex: 0,
        didLevelUp: true,
        initialLevel: 0,
        finalLevel: 1,
        isTeams: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CaidaGameOverModal.show(
                  context,
                  summary: summary,
                  onRematch: () => rematchPressed = true,
                  onBackToMenu: () => lobbyPressed = true,
                ),
                child: const Text('OPEN MODAL'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Abrir modal
      await tester.tap(find.text('OPEN MODAL'));
      await tester.pumpAndSettle();

      // Verificar elementos de victoria
      expect(find.text('¡VICTORIA!'), findsOneWidget);
      expect(find.text('Tu Equipo'), findsOneWidget);
      expect(find.text('Rivales'), findsOneWidget);
      expect(find.text('24 pts'), findsOneWidget);
      expect(find.text('16 pts'), findsOneWidget);

      // Verificar cofre obtenido
      expect(find.text('¡NUEVO COFRE OBTENIDO!'), findsOneWidget);
      expect(find.textContaining('Desbloqueando en ranura 1'), findsOneWidget);

      // Verificar monedas y XP
      expect(find.text('+150 🪙'), findsOneWidget);
      expect(find.text('+720 XP'), findsOneWidget);

      // Verificar subida de nivel
      expect(find.textContaining('¡SUBISTE A NIVEL 1!'), findsOneWidget);

      // Verificar estadísticas clave
      expect(find.text('Caídas'), findsOneWidget);
      expect(find.text('Limpias'), findsOneWidget);
      expect(find.text('Cantos'), findsOneWidget);
      expect(find.text('Cartas'), findsOneWidget);

      // Tocar botón Revancha
      await tester.ensureVisible(find.text('REVANCHA'));
      await tester.tap(find.text('REVANCHA'));
      await tester.pumpAndSettle();
      expect(rematchPressed, isTrue);
    });

    testWidgets('Modal de Derrota renderiza banner de derrota y aviso de bóveda de cofres', (tester) async {
      bool lobbyPressed = false;

      const summary = CaidaMatchSummary(
        userWon: false,
        userTeamScore: 14,
        opponentTeamScore: 24,
        userTeamCardsWon: 16,
        opponentTeamCardsWon: 24,
        caidasCount: 0,
        limpiasCount: 0,
        cantosCount: 0,
        coinsWon: 0,
        xpWon: 180,
        chestAwarded: false,
        didLevelUp: false,
        initialLevel: 0,
        finalLevel: 0,
        isTeams: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CaidaGameOverModal.show(
                  context,
                  summary: summary,
                  onRematch: () {},
                  onBackToMenu: () => lobbyPressed = true,
                ),
                child: const Text('OPEN MODAL'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('OPEN MODAL'));
      await tester.pumpAndSettle();

      expect(find.text('¡DERROTA!'), findsOneWidget);
      expect(find.text('Tú'), findsOneWidget);
      expect(find.text('Rival'), findsOneWidget);
      expect(find.text('+0 🪙'), findsOneWidget);
      expect(find.text('+180 XP'), findsOneWidget);

      // Tocar botón Lobby
      await tester.ensureVisible(find.text('LOBBY'));
      await tester.tap(find.text('LOBBY'));
      await tester.pumpAndSettle();
      expect(lobbyPressed, isTrue);
    });
  });
}
