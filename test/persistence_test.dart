import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gme/core/services/user_profile_service.dart';
import 'package:gme/core/stats/game_stats.dart';
import 'package:gme/core/stats/stats_repository.dart';
import 'package:gme/features/la_caida/economy/player_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Persistencia Permanente de Datos del Jugador', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('SharedPrefsStatsRepository almacena y recupera victorias y derrotas de forma persistente', () async {
      final repo1 = SharedPrefsStatsRepository();
      await repo1.load();

      final initialDomino = await repo1.getStats(GameType.domino);
      expect(initialDomino.wins, 0);

      // Registrar victorias y guardar
      await repo1.saveStats(initialDomino.recordWin().recordWin());

      // Crear una nueva instancia (simulando reiniciar la aplicación)
      final repo2 = SharedPrefsStatsRepository();
      await repo2.load();

      final loadedDomino = await repo2.getStats(GameType.domino);
      expect(loadedDomino.wins, 2);
      expect(loadedDomino.totalGames, 2);
    });

    test('UserProfileService persiste isFirstTime, nombre, monedas y tickets', () async {
      final service = UserProfileService();
      await service.load();

      // Al inicio para novato
      expect(service.isFirstTime, true);

      // Actualizar perfil
      service.updateProfile(name: 'Yoangel', avatarId: 5);
      service.addCoins(1000);
      expect(service.isFirstTime, false);
      expect(service.name, 'Yoangel');
      expect(service.coins, 1000);

      // Simular reinicio creando nuevo servicio
      final service2 = UserProfileService();
      await service2.load();

      expect(service2.name, 'Yoangel');
      expect(service2.avatarId, 5);
      expect(service2.coins, 1000);
      expect(service2.isFirstTime, false);
    });

    test('PlayerSession persiste hasCompletedTutorial, isFirstTime y saldo de monedas', () async {
      // Sesión de novato: inicia con 0 monedas y tutorial pendiente
      final session = PlayerSession.createDefault(name: 'Novato', coins: 0, hasCompletedTutorial: false);
      expect(session.coins, 0);
      expect(session.tickets, 3);
      expect(session.hasCompletedTutorial, false);
      expect(session.isFirstTime, true);
      await session.save();

      // Completar tutorial
      session.completeTutorialReward(coinReward: 1000);
      expect(session.coins, 1000);
      expect(session.hasCompletedTutorial, true);
      expect(session.isFirstTime, false);

      // Simular reinicio de la app cargando desde SharedPreferences
      final loadedSession = await PlayerSession.load();
      expect(loadedSession.coins, 1000);
      expect(loadedSession.hasCompletedTutorial, true);
      expect(loadedSession.isFirstTime, false);
      expect(loadedSession.name, 'Novato');
    });
  });
}
