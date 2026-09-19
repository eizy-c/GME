import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gme/features/la_caida/economy/player_session.dart';
import 'package:gme/features/la_caida/economy/player_stats_model.dart';
import 'package:gme/features/la_caida/presentation/caida_lobby_screen.dart';
import 'package:gme/features/la_caida/presentation/widgets/player_profile_stats_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlayerSession.setShared(PlayerSession.createDefault(name: 'Yoangel Eizaga', avatarIndex: 2, coins: 0));
    PlayerStatsModel.setShared(PlayerStatsModel());
  });

  group('PlayerStatsModel - Lógica y Persistencia', () {
    test('Valores iniciales comienzan todos en 0 para un nuevo jugador', () {
      final stats = PlayerStatsModel();
      expect(stats.totalEarnings, 0);
      expect(stats.gamesPlayed, 0);
      expect(stats.gamesWon, 0);
      expect(stats.winRatePercentage, 0);
      expect(stats.currentStreak, 0);
      expect(stats.maxStreak, 0);
      expect(stats.soloWins, 0);
      expect(stats.teamWins, 0);
      expect(stats.caidasMade, 0);
      expect(stats.caidasReceived, 0);
      expect(stats.mesasLimpias, 0);
      expect(stats.caidasWithLimpia, 0);
      expect(stats.registros, 0);
      expect(stats.totalCardsWon, 0);
      expect(stats.rondas, 0);
      expect(stats.patrullas, 0);
      expect(stats.vigias, 0);
      expect(stats.trivilines, 0);
      expect(stats.claimedAchievementIds, isEmpty);
    });

    test('Incrementos 1 a 1 de jugadas, caídas y cantos durante partidas', () {
      final stats = PlayerStatsModel();

      // Caída 1 a 1
      stats.recordCaidaMade();
      expect(stats.caidasMade, 1);
      stats.recordCaidaMade(withLimpia: true);
      expect(stats.caidasMade, 2);
      expect(stats.caidasWithLimpia, 1);
      expect(stats.mesasLimpias, 1);

      // Caída recibida 1 a 1
      stats.recordCaidaReceived();
      expect(stats.caidasReceived, 1);

      // Mesa limpia 1 a 1
      stats.recordMesaLimpia();
      expect(stats.mesasLimpias, 2);

      // Cantos 1 a 1
      stats.recordCanto('Ronda');
      expect(stats.rondas, 1);
      stats.recordCanto('Patrulla');
      expect(stats.patrullas, 1);
      stats.recordCanto('Vigía');
      expect(stats.vigias, 1);
      stats.recordCanto('Registro');
      expect(stats.registros, 1);
      stats.recordCanto('Trivilín');
      expect(stats.trivilines, 1);

      // Fin de partida
      stats.recordGameResult(
        won: true,
        isTeams: false,
        coinsWon: 150,
        cardsWon: 24,
      );
      expect(stats.gamesPlayed, 1);
      expect(stats.gamesWon, 1);
      expect(stats.currentStreak, 1);
      expect(stats.maxStreak, 1);
      expect(stats.soloWins, 1);
      expect(stats.totalEarnings, 150);
      expect(stats.totalCardsWon, 24);
      expect(stats.winRatePercentage, 100);
    });

    test('claimAchievement marca logros y serialización JSON', () {
      final stats = PlayerStatsModel();
      expect(stats.claimAchievement('ach_limpia'), isTrue);
      expect(stats.claimAchievement('ach_limpia'), isFalse);

      final json = stats.toJson();
      final fromJson = PlayerStatsModel.fromJson(json);

      expect(fromJson.totalEarnings, stats.totalEarnings);
      expect(fromJson.claimedAchievementIds.contains('ach_limpia'), isTrue);
    });
  });

  group('PlayerProfileStatsModal - Renderizado y UI de Estadísticas', () {
    testWidgets('Renderiza estado inicial en 0 para nuevo jugador con Nivel 0 y Pichón', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PlayerProfileStatsModal.show(context),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // Banner superior
      expect(find.text('Perfil del jugador'), findsOneWidget);

      // Pestañas
      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Logros'), findsOneWidget);

      // Identidad del jugador
      expect(find.text('Yoangel Eizaga'), findsOneWidget);
      expect(find.text('🇻🇪'), findsOneWidget);
      expect(find.text('EDITAR'), findsOneWidget);
      expect(find.textContaining('Nivel 0'), findsWidgets);
      expect(find.text('0 de 100 XP'), findsOneWidget);
      expect(find.text('Título: "Pichón"'), findsOneWidget);
    });

    testWidgets('Muestra todas las secciones de Estadísticas Generales en 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayerProfileStatsModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Encabezados de sección
      expect(find.text('ESTADÍSTICAS GENERALES'), findsOneWidget);
      expect(find.text('JUGADAS Y MESA (CAÍDA)'), findsOneWidget);
      expect(find.text('CANTOS TRADICIONALES'), findsOneWidget);

      // Filas de estadísticas
      expect(find.text('Ganancias totales'), findsOneWidget);
      expect(find.text('Partidas jugadas / Ganadas'), findsOneWidget);
      expect(find.text('0 (0 ganadas)'), findsOneWidget);
      expect(find.text('Efectividad de victoria'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Racha actual / Máxima'), findsOneWidget);
      expect(find.text('0 / 0'), findsOneWidget);

      expect(find.text('Caídas cantadas (rival cazado)'), findsOneWidget);
      expect(find.text('Caídas recibidas'), findsOneWidget);
      expect(find.text('Mesas limpias'), findsOneWidget);
      expect(find.text('Rondas'), findsOneWidget);
      expect(find.text('Patrullas'), findsOneWidget);
      expect(find.text('Vigías'), findsOneWidget);
      expect(find.text('Trivilines cantados'), findsOneWidget);
    });

    testWidgets('Alternar a pestaña Logros muestra lista de logros con progreso 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayerProfileStatsModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tocar pestaña "Logros"
      await tester.tap(find.text('Logros'));
      await tester.pumpAndSettle();

      expect(find.text('Maestro del Trivilín'), findsOneWidget);
      expect(find.text('Rey de la Mesa Limpia'), findsOneWidget);
      expect(find.text('Cazador de Caídas'), findsOneWidget);
      expect(find.text('Gallo de Oro'), findsOneWidget);
      expect(find.text('Invicto en Parejas'), findsOneWidget);
      expect(find.text('Coleccionista de Ases'), findsOneWidget);

      // Volver a pestaña "Perfil"
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();

      expect(find.text('ESTADÍSTICAS GENERALES'), findsOneWidget);
    });

    testWidgets('Boton Estadística en CaidaLobbyScreen abre modal y se cierra con [X]', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaidaLobbyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tocar botón "Estadística" en el Lobby
      final statsBtn = find.text('Estadística');
      expect(statsBtn, findsOneWidget);
      await tester.tap(statsBtn);
      await tester.pumpAndSettle();

      expect(find.text('Perfil del jugador'), findsOneWidget);
      expect(find.text('ESTADÍSTICAS GENERALES'), findsOneWidget);
      expect(find.text('Título: "Pichón"'), findsOneWidget);

      // Tocar botón de cerrar [X]
      final closeIcon = find.byIcon(Icons.close_rounded);
      expect(closeIcon, findsOneWidget);
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      expect(find.text('Perfil del jugador'), findsNothing);
    });
  });
}
