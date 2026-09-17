import 'package:flutter_test/flutter_test.dart';
import 'package:gme/core/models/domino/domino_set.dart';
import 'package:gme/core/models/domino/domino_tile.dart';

void main() {
  group('DominoTile & DominoSet Tests', () {
    test('DominoSet genera exactamente 28 fichas únicas para doble 6', () {
      final dominoSet = DominoSet();
      expect(dominoSet.remainingCount, equals(28));

      final uniqueTiles = <String>{};
      for (final tile in dominoSet.remainingTiles) {
        uniqueTiles.add(tile.toString());
      }
      expect(uniqueTiles.length, equals(28));
    });

    test('Identifica correctamente fichas dobles (7 dobles en total)', () {
      final dominoSet = DominoSet();
      final doubles = dominoSet.remainingTiles.where((t) => t.isDouble).toList();

      expect(doubles.length, equals(7));
      final expectedDoubles = [
        const DominoTile(0, 0),
        const DominoTile(1, 1),
        const DominoTile(2, 2),
        const DominoTile(3, 3),
        const DominoTile(4, 4),
        const DominoTile(5, 5),
        const DominoTile(6, 6),
      ];

      for (final expected in expectedDoubles) {
        expect(doubles.contains(expected), isTrue);
      }
    });

    test('Validación de conexión y rotación de extremos (canConnectWith, flip)', () {
      const tile = DominoTile(3, 5);
      expect(tile.totalPips, equals(8));
      expect(tile.isDouble, isFalse);
      expect(tile.canConnectWith(3), isTrue);
      expect(tile.canConnectWith(5), isTrue);
      expect(tile.canConnectWith(1), isFalse);

      final flipped = tile.flip();
      expect(flipped.left, equals(5));
      expect(flipped.right, equals(3));
      expect(tile == flipped, isTrue); // Coincidencia independientemente de orientación
    });

    test('Reparto tradicional a 4 jugadores (7 fichas c/u vacía el pozo)', () {
      final dominoSet = DominoSet();
      final players = ['jugador_1', 'jugador_2', 'jugador_3', 'jugador_4'];
      final hands = dominoSet.dealToPlayers(players, 7);

      for (final id in players) {
        expect(hands[id]!.length, equals(7));
      }
      expect(dominoSet.remainingCount, equals(0));
    });
  });
}
