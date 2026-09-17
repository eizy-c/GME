import 'dart:async';

import '../../../core/engine/player.dart';
import '../../../core/models/board/grid_board.dart';
import 'vieja_models.dart';

/// Bot local con heurística determinista para el juego La Vieja (Tres en Raya).
///
/// Estrategia de toma de decisiones priorizada:
/// 1. [Victoria Inmediata]: Si puede ganar en el turno actual, toma la casilla ganadora.
/// 2. [Bloqueo Defensivo]: Si el oponente está a una casilla de ganar, bloquea inmediatamente.
/// 3. [Control del Centro]: Toma la casilla central (1, 1) si está disponible.
/// 4. [Control de Esquinas]: Prioriza las esquinas del tablero.
/// 5. [Casillas Laterales]: Ocupa cualquier casilla lateral libre restante.
class ViejaAIPlayer extends AIPlayer<ViejaState, ViejaAction> {
  const ViejaAIPlayer({
    required super.id,
    required super.name,
    super.simulatedDelay = const Duration(milliseconds: 300),
  });

  @override
  Future<ViejaAction?> playTurn(ViejaState state) async {
    final mySymbol = state.playerSymbols[id];
    if (mySymbol == null || mySymbol == ViejaSymbol.none) return null;

    final opponentSymbol = mySymbol.opponent;
    final board = state.board;
    final available = board.availablePositions;

    if (available.isEmpty) return null;

    // 1. Victoria inmediata: ¿Puedo ganar en este movimiento?
    for (final pos in available) {
      if (_isWinningMove(board, pos.$1, pos.$2, mySymbol)) {
        return ViejaAction(playerId: id, row: pos.$1, col: pos.$2);
      }
    }

    // 2. Bloqueo defensivo: ¿El oponente puede ganar en su siguiente turno?
    for (final pos in available) {
      if (_isWinningMove(board, pos.$1, pos.$2, opponentSymbol)) {
        return ViejaAction(playerId: id, row: pos.$1, col: pos.$2);
      }
    }

    // 3. Tomar el centro si está disponible
    if (board.isEmpty(1, 1)) {
      return ViejaAction(playerId: id, row: 1, col: 1);
    }

    // 4. Tomar esquinas: (0,0), (0,2), (2,0), (2,2)
    const corners = [(0, 0), (0, 2), (2, 0), (2, 2)];
    for (final corner in corners) {
      if (board.isEmpty(corner.$1, corner.$2)) {
        return ViejaAction(playerId: id, row: corner.$1, col: corner.$2);
      }
    }

    // 5. Tomar laterales: (0,1), (1,0), (1,2), (2,1)
    const sides = [(0, 1), (1, 0), (1, 2), (2, 1)];
    for (final side in sides) {
      if (board.isEmpty(side.$1, side.$2)) {
        return ViejaAction(playerId: id, row: side.$1, col: side.$2);
      }
    }

    // Fallback de seguridad: primera casilla libre
    final fallback = available.first;
    return ViejaAction(playerId: id, row: fallback.$1, col: fallback.$2);
  }

  /// Simula la jugada en una copia del tablero para verificar si produce 3 en raya.
  static bool _isWinningMove(
    GridBoard<ViejaSymbol> originalBoard,
    int row,
    int col,
    ViejaSymbol symbol,
  ) {
    final tempBoard = originalBoard.clone();
    tempBoard.set(row, col, symbol);

    // Verificar fila
    if (tempBoard.getRow(row).every((s) => s == symbol)) return true;

    // Verificar columna
    if (tempBoard.getColumn(col).every((s) => s == symbol)) return true;

    // Verificar diagonal principal si aplica
    if (row == col && tempBoard.getMainDiagonal().every((s) => s == symbol)) {
      return true;
    }

    // Verificar diagonal secundaria si aplica
    if (row + col == 2 && tempBoard.getAntiDiagonal().every((s) => s == symbol)) {
      return true;
    }

    return false;
  }
}
