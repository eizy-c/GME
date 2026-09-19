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
    PlayerSession.setShared(PlayerSession.createDefault(name: 'Yoangel Eizaga', avatarIndex: 2));
    PlayerStatsModel.setShared(PlayerStatsModel());
  });

  group('PlayerStatsModel - Lógica y Persistencia', () {
    test('Valores iniciales reflejan el progreso oficial', () {
      final stats = PlayerStatsModel();
      expect(stats.totalEarnings, 9400);
      expect(stats.gamesPlayed, 5);
      expect(stats.gamesWon, 3);
      expect(stats.winRatePercentage, 60);
      expect(stats.currentStreak, 2);
      expect(stats.maxStreak, 2);
      expect(stats.soloWins, 1);
      expect(stats.teamWins, 2);
      expect(stats.caidasMade, 42);
      expect(stats.caidasReceived, 18);
      expect(stats.mesasLimpias, 14);
      expect(stats.caidasWithLimpia, 4);
      expect(stats.registros, 35);
      expect(stats.totalCardsWon, 1280);
      expect(stats.rondas, 28);
      expect(stats.patrullas, 12);
      expect(stats.vigias, 9);
      expect(stats.trivilines, 3);
    });

    test('recordGameResult actualiza rachas, victorias y métricas de mesa', () {
      final stats = PlayerStatsModel(
        gamesPlayed: 5,
        gamesWon: 3,
        currentStreak: 2,
        maxStreak: 2,
      );

      // Victoria en modo individual
      stats.recordGameResult(
        won: true,
        isTeams: false,
        coinsWon: 200,
        cardsWon: 24,
        caidas: 3,
        limpias: 1,
      );

      expect(stats.gamesPlayed, 6);
      expect(stats.gamesWon, 4);
      expect(stats.currentStreak, 3);
      expect(stats.maxStreak, 3);
      expect(stats.soloWins, 2);
      expect(stats.totalEarnings, 9600);
      expect(stats.caidasMade, 45);
      expect(stats.mesasLimpias, 15);

      // Derrota resetea racha actual
      stats.recordGameResult(
        won: false,
        isTeams: false,
      );

      expect(stats.gamesPlayed, 7);
      expect(stats.gamesWon, 4);
      expect(stats.currentStreak, 0);
      expect(stats.maxStreak, 3);
    });

    test('recordCanto clasifica e incrementa cantos tradicionales', () {
      final stats = PlayerStatsModel();

      stats.recordCanto('Trivilín');
      stats.recordCanto('Registro');
      stats.recordCanto('Vigía');
      stats.recordCanto('Patrulla');
      stats.recordCanto('Ronda');

      expect(stats.trivilines, 4);
      expect(stats.registros, 36);
      expect(stats.vigias, 10);
      expect(stats.patrullas, 13);
      expect(stats.rondas, 29);
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
    testWidgets('Renderiza banner superior, cerrar, pestañas y tarjeta de perfil', (tester) async {
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
      expect(find.textContaining('Nivel'), findsWidgets);
      expect(find.text('Título: "Maestro del Trivilín"'), findsOneWidget);
    });

    testWidgets('Muestra todas las secciones de Estadísticas Generales, Jugadas y Cantos', (tester) async {
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
      expect(find.text('9,400'), findsOneWidget);
      expect(find.text('Partidas jugadas / Ganadas'), findsOneWidget);
      expect(find.text('5 (3 ganadas)'), findsOneWidget);
      expect(find.text('Efectividad de victoria'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('Racha actual / Máxima'), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget);

      expect(find.text('Caídas cantadas (rival cazado)'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Caídas recibidas'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('Mesas limpias'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);

      expect(find.text('Rondas'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.text('Patrullas'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Vigías'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('Trivilines cantados'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('Alternar a pestaña Logros muestra lista de logros con progreso', (tester) async {
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

    testWidgets('Boton Estadística en CaidaLobbyScreen abre el nuevo modal Perfil del jugador', (tester) async {
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
      expect(find.text('9,400'), findsOneWidget);

      // Tocar botón de cerrar [X]
      final closeIcon = find.byIcon(Icons.close_rounded);
      expect(closeIcon, findsOneWidget);
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      expect(find.text('Perfil del jugador'), findsNothing);
    });
  });
}
