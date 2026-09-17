import 'package:flutter/material.dart';

import '../../models/domino/domino_tile.dart';

/// Componente visual táctil para representar una Ficha de Dominó tradicional (Doble 6).
/// Cuenta con acabado estilo marfil pulido, hendidura central con clavo de latón,
/// y pintas en bajo relieve.
class DominoTileView extends StatelessWidget {
  final DominoTile tile;
  final bool isVertical;
  final bool isFaceUp;
  final double size; // Ancho si es vertical, o Alto si es horizontal
  final VoidCallback? onTap;

  const DominoTileView({
    super.key,
    required this.tile,
    this.isVertical = true,
    this.isFaceUp = true,
    this.size = 54.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = isVertical ? size : size * 2;
    final height = isVertical ? size * 2 : size;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFDF8),
              Color(0xFFF4F0EA),
              Color(0xFFE5DFD5),
            ],
          ),
          border: Border.all(color: const Color(0xFFC8BFB2), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(1, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.12),
          child: isFaceUp ? _buildFaceUp(context) : _buildFaceDown(),
        ),
      ),
    );
  }

  Widget _buildFaceUp(BuildContext context) {
    return Flex(
      direction: isVertical ? Axis.vertical : Axis.horizontal,
      children: [
        // Extremo Superior o Izquierdo
        Expanded(child: Center(child: _buildPipsSquare(tile.left))),

        // Ranura central y clavo de latón (tradicional en dominós de mesa)
        _buildCentralDivider(),

        // Extremo Inferior o Derecho
        Expanded(child: Center(child: _buildPipsSquare(tile.right))),
      ],
    );
  }

  Widget _buildCentralDivider() {
    return Container(
      width: isVertical ? size * 0.88 : 2.5,
      height: isVertical ? 2.5 : size * 0.88,
      color: const Color(0xFF9E9589),
      child: Center(
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFD97706), // Clavo de latón dorado
            border: Border.all(color: const Color(0xFF78350F), width: 0.8),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaceDown() {
    return Container(
      color: const Color(0xFF1E293B),
      child: Center(
        child: Icon(
          Icons.grain_rounded,
          color: Colors.white24,
          size: size * 0.45,
        ),
      ),
    );
  }

  /// Construye la cuadrícula 3x3 tradicional de puntos (pintas)
  Widget _buildPipsSquare(int count) {
    final pipSize = size * 0.13;
    final spacing = size * 0.06;

    // Matriz de visibilidad para cada una de las 9 posiciones:
    // [0, 1, 2]
    // [3, 4, 5]
    // [6, 7, 8]
    final activeIndices = <int>{};
    switch (count) {
      case 1:
        activeIndices.add(4); // Centro
        break;
      case 2:
        activeIndices.addAll([2, 6]); // Diagonal
        break;
      case 3:
        activeIndices.addAll([2, 4, 6]); // Diagonal con centro
        break;
      case 4:
        activeIndices.addAll([0, 2, 6, 8]); // 4 esquinas
        break;
      case 5:
        activeIndices.addAll([0, 2, 4, 6, 8]); // 4 esquinas + centro
        break;
      case 6:
        activeIndices.addAll([0, 2, 3, 5, 6, 8]); // 2 columnas de 3
        break;
    }

    return SizedBox(
      width: (pipSize * 3) + (spacing * 2),
      height: (pipSize * 3) + (spacing * 2),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        children: List.generate(9, (index) {
          if (!activeIndices.contains(index)) {
            return const SizedBox.shrink();
          }
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF18181B), // Negro bajo relieve
              gradient: const RadialGradient(
                colors: [Color(0xFF27272A), Color(0xFF09090B)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 1,
                  offset: const Offset(0.5, 0.5),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
