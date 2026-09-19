import 'package:flutter/material.dart';
import '../../../../core/models/cards/spanish_card.dart';

/// Ubicación lógica de un naipe en el ciclo de vida de la partida.
enum CardLocationType {
  deck,
  playerHand,
  table,
  inFlight,
  collectedPile,
}

/// Representa el anclaje espacial de una carta o elemento en la pantalla del juego.
class SpatialCardAnchor {
  /// Identificador de la carta asociada (opcional si es un punto de mesa genérico).
  final SpanishCard? card;

  /// Coordenadas centrales relativas al centro del tapete de madera (0, 0 = centro de mesa).
  final Offset offset;

  /// Ángulo de rotación en radianes.
  final double rotation;

  /// Escala visual del naipe en este anclaje (por defecto 1.0).
  final double scale;

  const SpatialCardAnchor({
    this.card,
    required this.offset,
    this.rotation = 0.0,
    this.scale = 1.0,
  });

  /// Punto de anclaje del Mazo en la esquina superior izquierda.
  static const SpatialCardAnchor deckAnchor = SpatialCardAnchor(
    offset: Offset(-140, -180),
    rotation: -0.04,
    scale: 0.9,
  );

  /// Punto de anclaje de la estación / avatar de cada jugador según el número total de participantes.
  static SpatialCardAnchor playerStationAnchor({
    required int playerIndex,
    required int totalPlayers,
  }) {
    if (playerIndex == 0) {
      // Jugador local (abajo)
      return const SpatialCardAnchor(
        offset: Offset(-130, 240),
        rotation: 0.0,
        scale: 0.85,
      );
    }

    if (totalPlayers == 2) {
      // Rival único (arriba)
      return const SpatialCardAnchor(
        offset: Offset(0, -220),
        rotation: 0.0,
        scale: 0.85,
      );
    } else if (totalPlayers == 3) {
      if (playerIndex == 1) {
        // Rival 1 (izquierda)
        return const SpatialCardAnchor(
          offset: Offset(-145, -80),
          rotation: 0.0,
          scale: 0.85,
        );
      } else {
        // Rival 2 (derecha)
        return const SpatialCardAnchor(
          offset: Offset(145, -80),
          rotation: 0.0,
          scale: 0.85,
        );
      }
    } else {
      // 4 Jugadores (cruz tradicional)
      if (playerIndex == 1) {
        // Rival 1 (izquierda)
        return const SpatialCardAnchor(
          offset: Offset(-145, -30),
          rotation: 0.0,
          scale: 0.85,
        );
      } else if (playerIndex == 2) {
        // Rival 2 / Compañero (arriba / frente)
        return const SpatialCardAnchor(
          offset: Offset(0, -220),
          rotation: 0.0,
          scale: 0.85,
        );
      } else {
        // Rival 3 (derecha)
        return const SpatialCardAnchor(
          offset: Offset(145, -30),
          rotation: 0.0,
          scale: 0.85,
        );
      }
    }
  }

  /// Punto de anclaje de un slot específico en la mano del usuario (abanico inferior derecho).
  static SpatialCardAnchor userHandSlotAnchor({
    required int cardIndex,
    required int totalCardsInHand,
  }) {
    final fanAngles = totalCardsInHand == 3
        ? [-0.07, 0.0, 0.07]
        : (totalCardsInHand == 2 ? [-0.04, 0.04] : [0.0]);
    final fanYOffsets = totalCardsInHand == 3
        ? [6.0, 0.0, 6.0]
        : (totalCardsInHand == 2 ? [3.0, 3.0] : [0.0]);

    // Distribución horizontal en la esquina inferior derecha
    const baseCenterX = 100.0;
    const baseCenterY = 240.0;
    const cardSpacing = 42.0;

    final startX = baseCenterX - ((totalCardsInHand - 1) * cardSpacing / 2);
    final posX = startX + (cardIndex * cardSpacing);
    final posY = baseCenterY + (cardIndex < fanYOffsets.length ? fanYOffsets[cardIndex] : 0.0);
    final rot = cardIndex < fanAngles.length ? fanAngles[cardIndex] : 0.0;

    return SpatialCardAnchor(
      offset: Offset(posX, posY),
      rotation: rot,
      scale: 1.0,
    );
  }
}

/// Define una trayectoria de vuelo completa para un naipe.
class CardFlightTrajectory {
  final String id;
  final SpanishCard card;
  final SpatialCardAnchor startAnchor;
  final SpatialCardAnchor targetAnchor;
  final Duration duration;
  final Curve curve;
  final bool isCaidaImpact;
  final bool isFaceUp;
  final VoidCallback? onCompleted;

  const CardFlightTrajectory({
    required this.id,
    required this.card,
    required this.startAnchor,
    required this.targetAnchor,
    this.duration = const Duration(milliseconds: 360),
    this.curve = Curves.easeOutCubic,
    this.isCaidaImpact = false,
    this.isFaceUp = true,
    this.onCompleted,
  });

  /// Calcula la posición interpolada para un valor de progreso `t` (0.0 a 1.0).
  Offset positionAt(double t) {
    final curvedT = curve.transform(t);
    // Arco parabólico suave durante el vuelo para efecto de elevación en 3D
    final heightArc = -35.0 * (1.0 - 4.0 * (curvedT - 0.5) * (curvedT - 0.5)).clamp(0.0, 1.0);
    final directPos = Offset.lerp(startAnchor.offset, targetAnchor.offset, curvedT)!;
    return Offset(directPos.dx, directPos.dy + heightArc);
  }

  /// Calcula la rotación interpolada para un valor de progreso `t`.
  double rotationAt(double t) {
    final curvedT = curve.transform(t);
    return startAnchor.rotation + (targetAnchor.rotation - startAnchor.rotation) * curvedT;
  }

  /// Calcula la escala visual para un valor de progreso `t`.
  double scaleAt(double t) {
    final curvedT = curve.transform(t);
    // Crece ligeramente en el cenit del vuelo y se asienta al aterrizar
    final midScaleBoost = 0.12 * (1.0 - 4.0 * (curvedT - 0.5) * (curvedT - 0.5)).clamp(0.0, 1.0);
    final baseScale = startAnchor.scale + (targetAnchor.scale - startAnchor.scale) * curvedT;
    return baseScale + midScaleBoost;
  }
}
