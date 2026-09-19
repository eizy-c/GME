import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gme/features/la_caida/economy/player_session.dart';
import 'package:gme/features/la_caida/presentation/widgets/bot_customization_modal.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlayerSession.setShared(PlayerSession.createDefault());
  });

  group('BotCustomizationModal Widget Tests', () {
    testWidgets('Renderiza 3 bots con nombres por defecto y chips de sugerencias', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => BotCustomizationModal.show(context),
                child: const Text('ABRIR BOTS'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('ABRIR BOTS'));
      await tester.pumpAndSettle();

      expect(find.text('Personalizar Bots (IA)'), findsOneWidget);
      expect(find.text('Bot 1 • Rival Oeste (Izquierda)'), findsOneWidget);
      expect(find.text('Bot 2 • Norte (Frente)'), findsOneWidget);
      expect(find.text('Bot 3 • Rival Este (Derecha)'), findsOneWidget);

      // Comprobar presencia de campos y presets
      expect(find.text('Alejandro'), findsWidgets);
      expect(find.text('Carl'), findsWidgets);
      expect(find.text('Jhonny'), findsWidgets);
      expect(find.text('El Chamo'), findsOneWidget);
      expect(find.text('La Catira'), findsOneWidget);
      expect(find.text('El Guaro'), findsOneWidget);
    });

    testWidgets('Seleccionar un chip actualiza el nombre del bot', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => BotCustomizationModal.show(context),
                child: const Text('ABRIR BOTS'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('ABRIR BOTS'));
      await tester.pumpAndSettle();

      // Pulsar chip "El Chamo" para el Bot 1
      await tester.tap(find.text('El Chamo'));
      await tester.pumpAndSettle();

      // Pulsar "Guardar Cambios"
      await tester.tap(find.text('Guardar Cambios'));
      await tester.pumpAndSettle();

      expect(PlayerSession.shared.botNames[0], equals('El Chamo'));
    });

    testWidgets('Botón Restablecer recupera los nombres por defecto', (tester) async {
      PlayerSession.shared.updateBotNames(['X', 'Y', 'Z']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => BotCustomizationModal.show(context),
                child: const Text('ABRIR BOTS'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('ABRIR BOTS'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restablecer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guardar Cambios'));
      await tester.pumpAndSettle();

      expect(PlayerSession.shared.botNames, equals(['Alejandro', 'Carl', 'Jhonny']));
    });

    testWidgets('Botón Aleatorio Criollo genera 3 nombres distintos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => BotCustomizationModal.show(context),
                child: const Text('ABRIR BOTS'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('ABRIR BOTS'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('🎲 Aleatorio Criollo'));
      await tester.tap(find.text('🎲 Aleatorio Criollo'), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Guardar Cambios'));
      await tester.tap(find.text('Guardar Cambios'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final names = PlayerSession.shared.botNames;
      expect(names.length, equals(3));
      expect(names[0], isNotEmpty);
      expect(names[1], isNotEmpty);
      expect(names[2], isNotEmpty);
      // Deben ser distintos entre sí
      expect(names[0] != names[1] && names[1] != names[2], isTrue);
    });
  });
}
