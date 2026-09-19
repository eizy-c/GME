import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gme/core/services/feedback_service.dart';
import 'package:gme/features/la_caida/economy/player_session.dart';
import 'package:gme/features/la_caida/presentation/caida_lobby_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlayerSession.setShared(PlayerSession.createDefault());
  });

  group('FeedbackService - Configuración y URL Oficial', () {
    test('Contiene el enlace exacto a Google Forms proporcionado por el usuario', () {
      expect(FeedbackService.feedbackFormUrl, 'https://forms.gle/YDJAVHHS3rsA6o4w8');
      final uri = Uri.tryParse(FeedbackService.feedbackFormUrl);
      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'forms.gle');
      expect(uri.path, '/YDJAVHHS3rsA6o4w8');
    });
  });

  group('Buzón de Sugerencias - Integración en Lobby UI', () {
    testWidgets('Renderiza el botón de Sugerencias en la barra superior del Lobby', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaidaLobbyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Botón visible en barra superior
      final suggestionsBtn = find.text('Sugerencias');
      expect(suggestionsBtn, findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_rounded), findsOneWidget);
    });

    testWidgets('Muestra la opción de Buzón de Sugerencias dentro del diálogo de Ajustes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaidaLobbyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tocar engranaje de ajustes
      final settingsGear = find.byIcon(Icons.settings_rounded);
      expect(settingsGear, findsOneWidget);
      await tester.tap(settingsGear);
      await tester.pumpAndSettle();

      // Verificar opción de buzón de sugerencias
      expect(find.text('Buzón de Sugerencias'), findsOneWidget);
      expect(find.text('Envíanos tus ideas, mejoras o comentarios'), findsOneWidget);
      expect(find.byIcon(Icons.feedback_rounded), findsOneWidget);
    });
  });
}
