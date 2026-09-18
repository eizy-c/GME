import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gme/features/la_caida/economy/player_session.dart';
import 'package:gme/features/la_caida/economy/vip_tier.dart';
import 'package:gme/features/la_caida/presentation/widgets/buy_tickets_modal.dart';
import 'package:gme/features/la_caida/presentation/widgets/vip_tier_selector_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VipTierOffer - Reglas Financieras y Comisión de la Casa (8%)', () {
    test('Los 4 tiers oficiales cuentan con sus cuotas y niveles mínimos requeridos', () {
      expect(VipTierOffer.tiers.length, equals(4));

      final taberna = VipTierOffer.tiers[0];
      expect(taberna.name, equals('Taberna'));
      expect(taberna.entryFee, equals(250));
      expect(taberna.minPlayerLevel, equals(1));

      final club = VipTierOffer.tiers[1];
      expect(club.name, equals('Club Privado'));
      expect(club.entryFee, equals(1000));
      expect(club.minPlayerLevel, equals(2));

      final casino = VipTierOffer.tiers[2];
      expect(casino.name, equals('Gran Casino'));
      expect(casino.entryFee, equals(5000));
      expect(casino.minPlayerLevel, equals(4));

      final highRoller = VipTierOffer.tiers[3];
      expect(highRoller.name, equals('High Roller'));
      expect(highRoller.entryFee, equals(20000));
      expect(highRoller.minPlayerLevel, equals(8));
    });

    test('Modo 1v1 (2 Jugadores): Pozo = Entrada * 2, Premio = Pozo * 0.92', () {
      final taberna = VipTierOffer.tiers[0];
      expect(taberna.totalPot1v1, equals(500));
      expect(taberna.houseFee1v1, equals(40)); // 8% de 500
      expect(taberna.winnerPrize1v1, equals(460)); // 500 - 40

      final club = VipTierOffer.tiers[1];
      expect(club.totalPot1v1, equals(2000));
      expect(club.houseFee1v1, equals(160));
      expect(club.winnerPrize1v1, equals(1840));

      final casino = VipTierOffer.tiers[2];
      expect(casino.totalPot1v1, equals(10000));
      expect(casino.houseFee1v1, equals(800));
      expect(casino.winnerPrize1v1, equals(9200));

      final highRoller = VipTierOffer.tiers[3];
      expect(highRoller.totalPot1v1, equals(40000));
      expect(highRoller.houseFee1v1, equals(3200));
      expect(highRoller.winnerPrize1v1, equals(36800));
    });

    test('Modo Parejas (4 Jugadores): Pozo = Entrada * 4, Premio c/u = (Pozo * 0.92) / 2', () {
      final taberna = VipTierOffer.tiers[0];
      expect(taberna.totalPotTeams, equals(1000));
      expect(taberna.houseFeeTeams, equals(80)); // 8% de 1000
      expect(taberna.winnerPrizePerPlayerTeams, equals(460)); // 920 / 2

      final club = VipTierOffer.tiers[1];
      expect(club.totalPotTeams, equals(4000));
      expect(club.houseFeeTeams, equals(320));
      expect(club.winnerPrizePerPlayerTeams, equals(1840));

      final casino = VipTierOffer.tiers[2];
      expect(casino.totalPotTeams, equals(20000));
      expect(casino.houseFeeTeams, equals(1600));
      expect(casino.winnerPrizePerPlayerTeams, equals(9200));

      final highRoller = VipTierOffer.tiers[3];
      expect(highRoller.totalPotTeams, equals(80000));
      expect(highRoller.houseFeeTeams, equals(6400));
      expect(highRoller.winnerPrizePerPlayerTeams, equals(36800));
    });

    test('Validación de desbloqueo por nivel y asequibilidad de saldo', () {
      final club = VipTierOffer.tiers[1]; // Nivel mín: 2, Entrada: 1000
      expect(club.isUnlockedFor(1), isFalse);
      expect(club.isUnlockedFor(2), isTrue);
      expect(club.isUnlockedFor(5), isTrue);

      expect(club.canAfford(800), isFalse);
      expect(club.canAfford(1000), isTrue);
      expect(club.canAfford(2500), isTrue);
    });
  });

  group('BuyTicketsModal - Widget & Interacciones de Tienda', () {
    testWidgets('Muestra saldo, tickets y permite reclamar video y comprar tickets reactivamente', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final session = PlayerSession(
        id: 'user_shop',
        name: 'Ana',
        coins: 1000,
        tickets: 4,
        maxTickets: 10,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuyTicketsModal(session: session),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar indicador de tickets y monedas en el encabezado
      expect(find.text('4 / 10 🎫'), findsOneWidget);
      expect(find.text('1000'), findsOneWidget);
      expect(find.text('TIENDA DE TICKETS'), findsOneWidget);

      // Verificar presencia de las 3 opciones
      expect(find.text('Ver Video Corto'), findsOneWidget);
      expect(find.text('Pase Individual (1x)'), findsOneWidget);
      expect(find.text('Paquete Aventurero (5x)'), findsOneWidget);

      // Opción 1: Reclamar video
      final videoBtn = find.text('Ver Video');
      expect(videoBtn, findsOneWidget);
      await tester.tap(videoBtn);
      await tester.pump();

      expect(session.tickets, equals(5));
      expect(find.text('5 / 10 🎫'), findsOneWidget);

      // Opción 2: Comprar 1 Ticket por 400 monedas
      final buySingleBtn = find.text('🪙 400');
      expect(buySingleBtn, findsOneWidget);
      await tester.tap(buySingleBtn);
      await tester.pump();

      expect(session.tickets, equals(6));
      expect(session.coins, equals(600));
      expect(find.text('6 / 10 🎫'), findsOneWidget);
      expect(find.text('600'), findsOneWidget);

      // Como ahora tiene 600 monedas, la opción 3 (1,800 monedas) debe estar deshabilitada
      expect(find.text('SIN MONEDAS'), findsOneWidget);

      // Avanzar el temporizador de feedback de 3 segundos para que no quede pendiente
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('VipTierSelectorModal - Widget & Carrusel de Mesas VIP', () {
    testWidgets('Renderiza carrusel de 4 tiers, toggle 1v1/Parejas actualiza pozos en vivo', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final session = PlayerSession(
        id: 'user_vip',
        name: 'Beto',
        coins: 6000,
        level: 3, // Nivel 3 desbloquea Taberna (1) y Club Privado (2), pero bloquea Gran Casino (4) y High Roller (8)
      );

      VipTierOffer? selectedTier;
      bool? selectedIsTeams;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VipTierSelectorModal(
              session: session,
              initialIsTeams: false,
              onTierSelected: (tier, isTeams) {
                selectedTier = tier;
                selectedIsTeams = isTeams;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar título, nivel y saldo
      expect(find.text('PARTIDAS VIP'), findsOneWidget);
      expect(find.text('Nv. 3'), findsOneWidget);
      expect(find.text('6000'), findsOneWidget);

      // Verificar que los primeros nombres de mesas en el carrusel aparecen
      expect(find.text('Taberna'), findsOneWidget);
      expect(find.text('Club Privado'), findsOneWidget);

      // En modo 1v1 inicial: Pozo de Taberna debe ser 🪙 500 y Premio 🪙 460
      expect(find.text('🪙 500'), findsOneWidget);
      expect(find.text('🪙 460'), findsOneWidget);

      // Cambiar a modalidad "En Parejas"
      final parejasTab = find.text('En Parejas');
      expect(parejasTab, findsOneWidget);
      await tester.tap(parejasTab);
      await tester.pumpAndSettle();

      // Pozo de Taberna en parejas debe actualizarse en vivo a 🪙 1000 (y Club Privado tiene entrada de 1000)
      expect(find.text('🪙 1000'), findsAtLeastNWidgets(1));

      // Desplazar horizontalmente el carrusel para revelar la última mesa (High Roller)
      await tester.drag(find.byType(ListView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('High Roller'), findsOneWidget);
      // High Roller (Nv 8): Bloqueada por nivel
      expect(find.text('🔒 NIVEL 8 REQUERIDO'), findsOneWidget);

      // Regresar al inicio del carrusel para entrar a Taberna
      await tester.drag(find.byType(ListView), const Offset(500, 0));
      await tester.pumpAndSettle();

      // Taberna (Nv 1, entrada 250): Desbloqueada y saldo disponible -> ENTRAR (🪙 250)
      final enterTabernaBtn = find.text('ENTRAR (🪙 250)');
      expect(enterTabernaBtn, findsOneWidget);

      // Al pulsar "ENTRAR" en Taberna:
      await tester.tap(enterTabernaBtn);
      await tester.pumpAndSettle();

      expect(selectedTier?.name, equals('Taberna'));
      expect(selectedIsTeams, isTrue);
      // Las 250 monedas debieron descontarse de la sesión
      expect(session.coins, equals(5750));
    });
  });
}
