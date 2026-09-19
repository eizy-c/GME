import 'package:flutter/material.dart';
import '../../../../core/models/cards/spanish_card.dart';

/// Representa una zona predefinida de aterrizaje en la mesa de juego.
/// Diseñada para distribuir naipes de manera orgánica, evitando solapamientos obstructivos.
class TableLandingZone {
  final int index;
  final Offset offset;
  final double rotation;
  final String description;

  const TableLandingZone({
    required this.index,
    required this.offset,
    required this.rotation,
    required this.description,
  });

  /// Catálogo oficial de las 17 zonas de aterrizaje en el tapete central de madera.
  static const List<TableLandingZone> catalog = [
    // 0..3: Cuadrantes amplios para el reparto inicial de 4 cartas
    TableLandingZone(index: 0, offset: Offset(-68, -80), rotation: -0.08, description: 'Cuadrante Superior Izquierdo'),
    TableLandingZone(index: 1, offset: Offset(68, -80),  rotation: 0.07,  description: 'Cuadrante Superior Derecho'),
    TableLandingZone(index: 2, offset: Offset(-68, 75),  rotation: 0.09,  description: 'Cuadrante Inferior Izquierdo'),
    TableLandingZone(index: 3, offset: Offset(68, 75),   rotation: -0.06, description: 'Cuadrante Inferior Derecho'),

    // 4..8: Zonas centrales e intermedias despejadas
    TableLandingZone(index: 4, offset: Offset(0, 0),     rotation: 0.03,  description: 'Centro absoluto de mesa'),
    TableLandingZone(index: 5, offset: Offset(-82, -2),  rotation: -0.07, description: 'Flanco Izquierdo central'),
    TableLandingZone(index: 6, offset: Offset(82, -2),   rotation: 0.08,  description: 'Flanco Derecho central'),
    TableLandingZone(index: 7, offset: Offset(0, -96),   rotation: -0.05, description: 'Centro Superior'),
    TableLandingZone(index: 8, offset: Offset(0, 96),    rotation: 0.06,  description: 'Centro Inferior'),

    // 9..12: Anillo intermedio diagonal
    TableLandingZone(index: 9,  offset: Offset(-40, -42), rotation: 0.08,  description: 'Intermedio Superior Izquierdo'),
    TableLandingZone(index: 10, offset: Offset(40, -42),  rotation: -0.07, description: 'Intermedio Superior Derecho'),
    TableLandingZone(index: 11, offset: Offset(-40, 42),  rotation: -0.06, description: 'Intermedio Inferior Izquierdo'),
    TableLandingZone(index: 12, offset: Offset(40, 42),   rotation: 0.07,  description: 'Intermedio Inferior Derecho'),

    // 13..16: Flancos exteriores diagonales
    TableLandingZone(index: 13, offset: Offset(-84, -45), rotation: -0.09, description: 'Exterior Izquierdo Alto'),
    TableLandingZone(index: 14, offset: Offset(84, -45),  rotation: 0.08,  description: 'Exterior Derecho Alto'),
    TableLandingZone(index: 15, offset: Offset(-84, 45),  rotation: 0.06,  description: 'Exterior Izquierdo Bajo'),
    TableLandingZone(index: 16, offset: Offset(84, 45),   rotation: -0.08, description: 'Exterior Derecho Bajo'),
  ];
}

/// Naipe colocado físicamente sobre el tapete central con posición, rotación y profundidad zIndex.
class PlacedTableCard {
  final SpanishCard card;
  final Offset offset;
  final double rotation;
  final int zIndex;
  final int zoneIndex;

  const PlacedTableCard({
    required this.card,
    required this.offset,
    required this.rotation,
    required this.zIndex,
    required this.zoneIndex,
  });

  /// Calcula la ubicación óptima para una nueva carta sobre la mesa manteniendo
  /// separación máxima respecto a las cartas ya existentes y agregando micro-jitter determinista.
  static PlacedTableCard computePlacementForCard({
    required SpanishCard card,
    required List<PlacedTableCard> currentPlacedCards,
    required int zCounter,
    List<TableLandingZone> zones = TableLandingZone.catalog,
  }) {
    final occupiedZones = currentPlacedCards.map((p) => p.zoneIndex).toSet();
    int chosenZone = -1;

    // Para las 4 cartas iniciales, asignar cuadrantes 0..3 si están disponibles
    if (currentPlacedCards.length < 4 && !occupiedZones.contains(currentPlacedCards.length)) {
      chosenZone = currentPlacedCards.length;
    } else {
      double maxMinDist = -1;
      for (int z = 0; z < zones.length; z++) {
        if (occupiedZones.contains(z)) continue;
        final candidateOffset = zones[z].offset;

        if (currentPlacedCards.isEmpty) {
          chosenZone = z;
          break;
        }

        double minDistToPlaced = double.infinity;
        for (final placed in currentPlacedCards) {
          final d = (candidateOffset - placed.offset).distance;
          if (d < minDistToPlaced) {
            minDistToPlaced = d;
          }
        }

        if (minDistToPlaced > maxMinDist) {
          maxMinDist = minDistToPlaced;
          chosenZone = z;
        }
      }

      if (chosenZone == -1) {
        chosenZone = zCounter % zones.length;
      }
    }

    final baseZone = zones[chosenZone];

    // Micro-jitter determinista por carta (±3.6 px y ±0.02 rad) para aspecto natural
    final jitterX = ((card.number * 7 + card.suit.index * 13) % 7 - 3) * 1.2;
    final jitterY = ((card.number * 11 + card.suit.index * 19) % 7 - 3) * 1.2;
    final jitterRot = ((card.number * 13 + card.suit.index * 17) % 5 - 2) * 0.01;

    return PlacedTableCard(
      card: card,
      offset: Offset(baseZone.offset.dx + jitterX, baseZone.offset.dy + jitterY),
      rotation: baseZone.rotation + jitterRot,
      zIndex: zCounter,
      zoneIndex: chosenZone,
    );
  }
}
