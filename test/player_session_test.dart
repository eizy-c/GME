import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gme/features/la_caida/economy/player_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerSession - Modelo, JSON y Persistencia en SharedPreferences', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Serialización a JSON y reconstrucción desde JSON conservan todos los campos', () {
      final now = DateTime.utc(2026, 9, 18, 12, 0, 0);
      final session = PlayerSession(
        id: 'player_test_1',
        name: 'Carlos Pro',
        avatarIndex: 2,
        coins: 5400,
        tickets: 7,
        maxTickets: 10,
        xp: 450,
        level: 3,
        lastTicketRegen: now,
      );

      final json = session.toJson();
      expect(json['id'], equals('player_test_1'));
      expect(json['name'], equals('Carlos Pro'));
      expect(json['avatarIndex'], equals(2));
      expect(json['coins'], equals(5400));
      expect(json['tickets'], equals(7));
      expect(json['maxTickets'], equals(10));
      expect(json['xp'], equals(450));
      expect(json['level'], equals(3));
      expect(json['lastTicketRegen'], equals(now.toIso8601String()));

      final restored = PlayerSession.fromJson(json);
      expect(restored.id, equals(session.id));
      expect(restored.name, equals(session.name));
      expect(restored.avatarIndex, equals(session.avatarIndex));
      expect(restored.coins, equals(session.coins));
      expect(restored.tickets, equals(session.tickets));
      expect(restored.maxTickets, equals(session.maxTickets));
      expect(restored.xp, equals(session.xp));
      expect(restored.level, equals(session.level));
      expect(restored.lastTicketRegen, equals(session.lastTicketRegen));
    });

    test('load() crea una nueva sesión por defecto y la persiste si no existe estado previo', () async {
      final session = await PlayerSession.load();
      expect(session.id, isNotEmpty);
      expect(session.name, equals('Jugador'));
      expect(session.coins, equals(3000));
      expect(session.tickets, equals(10));
      expect(session.maxTickets, equals(10));
      expect(session.level, equals(1));

      // Verificar que se guardó en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(PlayerSession.storageKey), isTrue);
    });

    test('save() y load() recuperan y preservan modificaciones del jugador', () async {
      final session = await PlayerSession.load();
      session.updateProfile(name: 'Maestro Caída', avatarIndex: 3);
      session.deductCoinsForVipMatch(1000);
      await session.save();

      final reloaded = await PlayerSession.load();
      expect(reloaded.name, equals('Maestro Caída'));
      expect(reloaded.avatarIndex, equals(3));
      expect(reloaded.coins, equals(2000));
    });
  });

  group('PlayerSession - Regeneración Pasiva Offline (1 ticket cada 20 min)', () {
    test('Si han pasado menos de 20 minutos, no se añade ningún ticket', () {
      final start = DateTime.utc(2026, 9, 18, 10, 0, 0);
      final session = PlayerSession(
        id: 'user_1',
        name: 'Test',
        tickets: 4,
        maxTickets: 10,
        lastTicketRegen: start,
      );

      final now15MinLater = start.add(const Duration(minutes: 15));
      final added = session.regenerateTicketsPassive(nowUtc: now15MinLater);

      expect(added, equals(0));
      expect(session.tickets, equals(4));
    });

    test('Si han transcurrido 45 minutos, suma 2 tickets exactos (2 * 20 min)', () {
      final start = DateTime.utc(2026, 9, 18, 10, 0, 0);
      final session = PlayerSession(
        id: 'user_1',
        name: 'Test',
        tickets: 4,
        maxTickets: 10,
        lastTicketRegen: start,
      );

      final now45MinLater = start.add(const Duration(minutes: 45));
      final added = session.regenerateTicketsPassive(nowUtc: now45MinLater);

      expect(added, equals(2));
      expect(session.tickets, equals(6));
      // El nuevo punto de referencia se adelanta 40 min (2 intervalos de 20 min)
      expect(session.lastTicketRegen, equals(start.add(const Duration(minutes: 40))));
    });

    test('La regeneración pasiva respeta estrictamente el tope de maxTickets (10)', () {
      final start = DateTime.utc(2026, 9, 18, 10, 0, 0);
      final session = PlayerSession(
        id: 'user_1',
        name: 'Test',
        tickets: 8,
        maxTickets: 10,
        lastTicketRegen: start,
      );

      // Transcurren 5 horas (300 minutos = 15 tickets teóricos)
      final now5HoursLater = start.add(const Duration(hours: 5));
      final added = session.regenerateTicketsPassive(nowUtc: now5HoursLater);

      // Solo debía sumar 2 tickets hasta llegar al tope de 10
      expect(added, equals(2));
      expect(session.tickets, equals(10));
      expect(session.tickets, lessThanOrEqualTo(session.maxTickets));
    });

    test('timeUntilNextTicket calcula la cuenta regresiva restante del intervalo', () {
      final start = DateTime.utc(2026, 9, 18, 10, 0, 0);
      final session = PlayerSession(
        id: 'user_1',
        name: 'Test',
        tickets: 5,
        maxTickets: 10,
        lastTicketRegen: start,
      );

      final now = start.add(const Duration(minutes: 12, seconds: 30));
      final remaining = session.timeUntilNextTicket(nowUtc: now);

      // 20 minutos - 12m 30s = 7 minutos y 30 segundos
      expect(remaining.inMinutes, equals(7));
      expect(remaining.inSeconds, equals(7 * 60 + 30));

      // Si está lleno, retorna Duration.zero
      final fullSession = PlayerSession(
        id: 'user_2',
        name: 'Full',
        tickets: 10,
        maxTickets: 10,
        lastTicketRegen: start,
      );
      expect(fullSession.timeUntilNextTicket(nowUtc: now), equals(Duration.zero));
    });
  });

  group('PlayerSession - Consumo y Recargas de Tickets', () {
    test('consumeTicketForNormalMatch descuenta 1 ticket y actualiza el reloj si estaba lleno', () {
      final now = DateTime.utc(2026, 9, 18, 10, 0, 0);
      final session = PlayerSession(
        id: 'user_1',
        name: 'Test',
        tickets: 10,
        maxTickets: 10,
        lastTicketRegen: now.subtract(const Duration(hours: 2)),
      );

      final success = session.consumeTicketForNormalMatch(nowUtc: now);
      expect(success, isTrue);
      expect(session.tickets, equals(9));
      expect(session.lastTicketRegen, equals(now));

      // Consumir hasta quedar en 0
      for (int i = 0; i < 9; i++) {
        expect(session.consumeTicketForNormalMatch(nowUtc: now), isTrue);
      }
      expect(session.tickets, equals(0));

      // Sin tickets, la función retorna false
      expect(session.consumeTicketForNormalMatch(nowUtc: now), isFalse);
    });

    test('buyTicketsWithCoins compra 1 ticket por 400 monedas', () {
      final session = PlayerSession(
        id: 'user_1',
        name: 'Test',
        coins: 1000,
        tickets: 5,
        maxTickets: 10,
      );

      final success = session.buyTicketsWithCoins(1);
      expect(success, isTrue);
      expect(session.coins, equals(600));
      expect(session.tickets, equals(6));
    });

    test('buyTicketsWithCoins con paquete de 5 por 1,800 monedas aplica el descuento', () {
      final session = PlayerSession(
        id: 'user_1',
        name: 'Test',
        coins: 2000,
        tickets: 3,
        maxTickets: 10,
      );

      final success = session.buyTicketsWithCoins(5, customCoinCost: 1800);
      expect(success, isTrue);
      expect(session.coins, equals(200));
      expect(session.tickets, equals(8));
    });

    test('buyTicketsWithCoins falla si no hay saldo suficiente o si ya está lleno', () {
      final session = PlayerSession(
        id: 'user_1',
        name: 'Test',
        coins: 200,
        tickets: 5,
        maxTickets: 10,
      );

      expect(session.buyTicketsWithCoins(1), isFalse); // Requiere 400
      expect(session.tickets, equals(5));

      final fullSession = PlayerSession(
        id: 'user_2',
        name: 'Full',
        coins: 5000,
        tickets: 10,
        maxTickets: 10,
      );
      expect(fullSession.buyTicketsWithCoins(1), isFalse); // Ya está al tope
    });

    test('claimAdTicketReward suma +1 ticket gratis hasta el tope', () {
      final session = PlayerSession(
        id: 'user_1',
        name: 'Test',
        tickets: 9,
        maxTickets: 10,
      );

      expect(session.claimAdTicketReward(), isTrue);
      expect(session.tickets, equals(10));
      expect(session.claimAdTicketReward(), isFalse); // Al tope
    });
  });

  group('PlayerSession - Economía VIP y Sistema de Experiencia / Niveles', () {
    test('deductCoinsForVipMatch descuenta saldo si cuenta con los fondos', () {
      final session = PlayerSession(
        id: 'user_1',
        name: 'Test',
        coins: 5000,
      );

      expect(session.deductCoinsForVipMatch(1000), isTrue);
      expect(session.coins, equals(4000));
      expect(session.deductCoinsForVipMatch(4500), isFalse);
      expect(session.coins, equals(4000));
    });

    test('rewardCoins incrementa monedas y suma XP subiendo de nivel', () {
      final session = PlayerSession(
        id: 'user_1',
        name: 'Test',
        coins: 1000,
        xp: 0,
        level: 1,
      );

      session.rewardCoins(2000, xpGain: 600);
      expect(session.coins, equals(3000));
      expect(session.xp, equals(600));
      expect(session.level, greaterThan(1), reason: '600 XP debe subir al jugador de nivel');
    });
  });
}
