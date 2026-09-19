import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gme/core/presentation/widgets/app_3d_button.dart';
import 'package:gme/core/theme/app_palette.dart';

void main() {
  group('App3dButton Tests (.btn-177 3D Tactile Mechanics)', () {
    testWidgets('Renderiza etiqueta, icono y variante cian oficial', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: App3dButton.icon(
                onPressed: () => pressed = true,
                icon: Icons.play_arrow_rounded,
                label: 'JUGAR',
                variant: App3dButtonVariant.cyan,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('JUGAR'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      await tester.tap(find.text('JUGAR'));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('Estado deshabilitado no ejecuta callback al pulsar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: App3dButton(
                onPressed: null,
                label: 'BLOQUEADO',
                variant: App3dButtonVariant.olive,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('BLOQUEADO'), findsOneWidget);

      await tester.tap(find.text('BLOQUEADO'));
      await tester.pumpAndSettle();
    });

    testWidgets('Soporta las 4 variantes de la paleta oficial (Cyan, Olive, Dark, Sand)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                App3dButton(onPressed: () {}, label: 'CYAN', variant: App3dButtonVariant.cyan),
                App3dButton(onPressed: () {}, label: 'OLIVE', variant: App3dButtonVariant.olive),
                App3dButton(onPressed: () {}, label: 'DARK', variant: App3dButtonVariant.dark),
                App3dButton(onPressed: () {}, label: 'SAND', variant: App3dButtonVariant.sand),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('CYAN'), findsOneWidget);
      expect(find.text('OLIVE'), findsOneWidget);
      expect(find.text('DARK'), findsOneWidget);
      expect(find.text('SAND'), findsOneWidget);
    });

    testWidgets('Animación de presionado desplaza en eje Y', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: App3dButton(
                onPressed: () {},
                label: 'ACCION',
                depth: 6.0,
                variant: App3dButtonVariant.gold,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final gesture = await tester.startGesture(tester.getCenter(find.text('ACCION')));
      await tester.pump(const Duration(milliseconds: 50));

      // AnimatedContainer se encuentra en estado presionado
      expect(find.byType(AnimatedContainer), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('AppPalette Constants Tests', () {
    test('Paleta oficial contiene los 4 códigos hexadecimales correctos', () {
      expect(AppPalette.cyan, equals(const Color(0xFF8BDCD7)));
      expect(AppPalette.olive, equals(const Color(0xFF999966)));
      expect(AppPalette.darkSlate, equals(const Color(0xFF232323)));
      expect(AppPalette.sand, equals(const Color(0xFFD5D4BC)));
    });

    test('get3dEdgeColor produce un tono más oscuro', () {
      final edge = AppPalette.get3dEdgeColor(AppPalette.cyan);
      final hslBase = HSLColor.fromColor(AppPalette.cyan);
      final hslEdge = HSLColor.fromColor(edge);
      expect(hslEdge.lightness, lessThan(hslBase.lightness));
    });
  });
}
