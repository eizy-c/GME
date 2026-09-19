import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gme/core/presentation/widgets/spanish_card_view.dart';
import 'package:gme/features/la_caida/presentation/caida_screen.dart';

void main() {
  group('Dispersión amplia en mesa y prevención de solapamiento total', () {
    testWidgets('Las 4 cartas iniciales en mesa se dispersan aprovechando la amplitud sin amontonamiento', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CaidaScreen(initialPlayers: 2, autoStart: true, animateDealing: false),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final tableCards = tester.widgetList(find.byWidgetPredicate((w) {
        if (w.key is ValueKey<String>) {
          return (w.key as ValueKey<String>).value.startsWith('table_card_');
        }
        return false;
      }));

      expect(tableCards.length, equals(4));

      final positions = <Offset>[];
      for (final widget in tableCards) {
        final key = (widget.key as ValueKey<String>).value;
        final cardViewFinder = find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(SpanishCardView),
        );
        final center = tester.getCenter(cardViewFinder);
        positions.add(center);
      }

      final minX = positions.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
      final maxX = positions.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
      final minY = positions.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
      final maxY = positions.map((p) => p.dy).reduce((a, b) => a > b ? a : b);

      final horizontalSpread = maxX - minX;
      final verticalSpread = maxY - minY;

      expect(horizontalSpread, greaterThan(120.0), reason: 'Las cartas iniciales deben aprovechar el ancho de la mesa');
      expect(verticalSpread, greaterThan(140.0), reason: 'Las cartas iniciales deben aprovechar el alto de la mesa');

      for (int i = 0; i < positions.length; i++) {
        for (int j = i + 1; j < positions.length; j++) {
          final dist = (positions[i] - positions[j]).distance;
          expect(
            dist,
            greaterThanOrEqualTo(80.0),
            reason: 'Las cartas iniciales $i y $j deben estar ampliamente separadas (dist: $dist)',
          );
        }
      }
    });

    testWidgets('Al jugar cartas subsiguientes, ninguna carta se solapa totalmente ni oculta el número de otra', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CaidaScreen(initialPlayers: 2, autoStart: true, animateDealing: false),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final userCardFinder = find.byKey(const ValueKey('user_card_0'));
      expect(userCardFinder, findsOneWidget);
      await tester.tap(userCardFinder);
      await tester.pump();
      await tester.tap(userCardFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final tableCards = tester.widgetList(find.byWidgetPredicate((w) {
        if (w.key is ValueKey<String>) {
          return (w.key as ValueKey<String>).value.startsWith('table_card_');
        }
        return false;
      }));

      final positions = <Offset>[];
      for (final widget in tableCards) {
        final key = (widget.key as ValueKey<String>).value;
        final cardViewFinder = find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(SpanishCardView),
        );
        final center = tester.getCenter(cardViewFinder);
        positions.add(center);
      }

      for (int i = 0; i < positions.length; i++) {
        for (int j = i + 1; j < positions.length; j++) {
          final dist = (positions[i] - positions[j]).distance;
          expect(
            dist,
            greaterThanOrEqualTo(35.0),
            reason: 'Ninguna carta debe quedar encima de otra tapando sus índices (dist: $dist)',
          );
        }
      }
    });
  });
}
