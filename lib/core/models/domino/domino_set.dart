import 'dart:math';

import 'domino_tile.dart';

/// Conjunto de dominó tradicional Doble 6 (28 fichas).
class DominoSet {
  final List<DominoTile> _tiles = [];

  DominoSet() {
    reset();
  }

  /// Reinicia el set con las 28 fichas únicas del dominó doble 6.
  void reset() {
    _tiles.clear();
    for (var i = 0; i <= 6; i++) {
      for (var j = i; j <= 6; j++) {
        _tiles.add(DominoTile(i, j));
      }
    }
  }

  /// Fichas restantes en el pozo / boneyard.
  int get remainingCount => _tiles.length;

  /// Retorna una copia de las fichas restantes.
  List<DominoTile> get remainingTiles => List.unmodifiable(_tiles);

  /// Baraja las fichas en la mesa.
  void shuffle([Random? random]) {
    _tiles.shuffle(random ?? Random());
  }

  /// Roba una ficha del pozo.
  DominoTile? draw() {
    if (_tiles.isEmpty) return null;
    return _tiles.removeAt(0);
  }

  /// Reparte [tilesPerPlayer] fichas a cada participante (típicamente 7 fichas).
  Map<String, List<DominoTile>> dealToPlayers(
    List<String> playerIds,
    int tilesPerPlayer,
  ) {
    final hands = <String, List<DominoTile>>{
      for (final id in playerIds) id: <DominoTile>[],
    };

    for (var round = 0; round < tilesPerPlayer; round++) {
      for (final id in playerIds) {
        final tile = draw();
        if (tile != null) {
          hands[id]!.add(tile);
        }
      }
    }

    return hands;
  }
}
