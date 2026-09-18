import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gme/core/presentation/widgets/spanish_card_view.dart';
import 'package:gme/core/services/user_profile_service.dart';
import 'package:gme/features/la_caida/presentation/caida_lobby_screen.dart';
import 'package:gme/features/la_caida/presentation/caida_screen.dart';
import 'package:gme/features/la_caida/presentation/caida_splash_screen.dart';
import 'package:gme/features/la_caida/presentation/widgets/avatar_view.dart';
import 'package:gme/features/la_caida/presentation/widgets/profile_options_dialog.dart';

void main() {
  setUp(() {
    UserProfileService().resetToDefault();
  });

  group('Flujo de Entrada y Personalizacion de La Caida', () {
    testWidgets('CaidaSplashScreen renderiza portada de bienvenida y boton de entrada', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaidaSplashScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('CAÍDA'), findsWidgets);
      expect(find.text('Tradicional'), findsOneWidget);
      expect(find.text('TOCAR PARA ENTRAR'), findsOneWidget);
    });

    testWidgets('ProfileOptionsDialog permite editar nombre y seleccionar avatar de Estilo A y B', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ProfileOptionsDialog.show(context),
                child: const Text('ABRIR PERFIL'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('ABRIR PERFIL'));
      await tester.pumpAndSettle();

      expect(find.text('Opciones del perfil'), findsOneWidget);
      expect(find.text('Eizy'), findsOneWidget);
      expect(find.text('Estilo A'), findsOneWidget);
      expect(find.text('Estilo B'), findsOneWidget);

      // Cambiar de pestana a Estilo B
      await tester.tap(find.text('Estilo B'));
      await tester.pumpAndSettle();

      // Pulsar Ok para guardar
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();

      expect(find.text('Opciones del perfil'), findsNothing);
    });

    testWidgets('CaidaLobbyScreen renderiza barra superior, monedas, tickets y modos', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaidaLobbyScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Eizy'), findsOneWidget);
      expect(find.text('6,000'), findsOneWidget);
      expect(find.text('10/10'), findsOneWidget);
      expect(find.text('Un Jugador'), findsOneWidget);
      expect(find.text('Multijugador'), findsOneWidget);
      expect(find.text('Aprende'), findsOneWidget);
      expect(find.text('Personalizar'), findsOneWidget);
    });

    testWidgets('2 vs 2 oculta selector de jugadores y Vs Bot lo muestra en preferencias', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaidaLobbyScreen(),
        ),
      );
      await tester.pump();

      // Tocar "Un Jugador" para entrar al sub-menú
      await tester.tap(find.text('Un Jugador'));
      await tester.pumpAndSettle();

      expect(find.text('Vs Bot'), findsOneWidget);
      expect(find.text('2 vs 2'), findsOneWidget);

      // Probar 2 vs 2: NO debe mostrar el selector de jugadores "Modo de juego"
      await tester.tap(find.text('2 vs 2'));
      await tester.pumpAndSettle();

      expect(find.textContaining('2 vs 2 (Parejas)'), findsOneWidget);
      expect(find.text('Modo de juego'), findsNothing);
      expect(find.text('¡Empezar!'), findsOneWidget);

      // Cerrar diálogo pulsando atrás o tocando fuera
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Probar Vs Bot: SÍ debe mostrar el selector de jugadores "Modo de juego"
      await tester.tap(find.text('Vs Bot'));
      await tester.pumpAndSettle();

      expect(find.text('Preferencias de juego\nVs Bot'), findsOneWidget);
      expect(find.text('Modo de juego'), findsOneWidget);
      expect(find.text('2 Jugadores'), findsOneWidget);

      // Alternar a 3 jugadores tocando el botón
      await tester.tap(find.text('2 Jugadores'));
      await tester.pumpAndSettle();
      expect(find.text('3 Jugadores'), findsOneWidget);
    });

    testWidgets('CaidaScreen con chooseMano muestra el sorteo de Mano ¡ELIGE UNA CARTA!', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaidaScreen(
            initialPlayers: 2,
            autoStart: true,
            chooseMano: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('¡ELIGE UNA CARTA!'), findsOneWidget);

      // Tocar una de las cartas para elegir
      final cardBacks = find.byType(SpanishCardView);
      expect(cardBacks, findsWidgets);

      await tester.tap(cardBacks.first);
      await tester.pump();

      // Dejar transcurrir el timer de animación del ganador
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('AvatarView renderiza los avatares sin errores graficos', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                AvatarView(avatarId: 2, size: 48),
                AvatarView(avatarId: 14, size: 48),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AvatarView), findsNWidgets(2));
    });
  });
}
