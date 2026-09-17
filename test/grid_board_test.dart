import 'package:flutter_test/flutter_test.dart';
import 'package:gme/core/models/board/grid_board.dart';

void main() {
  group('GridBoard Tests', () {
    test('Inicializa correctamente dimensiones y valor vacío', () {
      final board = GridBoard<String>(rows: 3, cols: 3, emptyValue: '.');
      expect(board.rows, equals(3));
      expect(board.cols, equals(3));
      expect(board.availablePositions.length, equals(9));
      expect(board.isFull, isFalse);
      expect(board.get(1, 1), equals('.'));
    });

    test('Asignación de celdas y verificación de estado', () {
      final board = GridBoard<String>(rows: 3, cols: 3, emptyValue: '.');
      board.set(0, 0, 'X');
      board.set(1, 1, 'O');

      expect(board.get(0, 0), equals('X'));
      expect(board.get(1, 1), equals('O'));
      expect(board.isEmpty(0, 0), isFalse);
      expect(board.isEmpty(0, 1), isTrue);
      expect(board.availablePositions.length, equals(7));
    });

    test('Lanza RangeError en coordenadas fuera de límites', () {
      final board = GridBoard<String>(rows: 3, cols: 3, emptyValue: '.');
      expect(() => board.get(-1, 0), throwsRangeError);
      expect(() => board.get(0, 3), throwsRangeError);
      expect(() => board.set(3, 0, 'X'), throwsRangeError);
    });

    test('Extracción de filas, columnas y diagonales', () {
      final board = GridBoard<int>(rows: 3, cols: 3, emptyValue: 0);
      var count = 1;
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          board.set(r, c, count++);
        }
      }

      // Matriz:
      // 1 2 3
      // 4 5 6
      // 7 8 9
      expect(board.getRow(0), equals([1, 2, 3]));
      expect(board.getRow(1), equals([4, 5, 6]));
      expect(board.getColumn(1), equals([2, 5, 8]));
      expect(board.getMainDiagonal(), equals([1, 5, 9]));
      expect(board.getAntiDiagonal(), equals([3, 5, 7]));
      expect(board.isFull, isTrue);
    });

    test('Clonación genera una copia profunda independiente', () {
      final board = GridBoard<String>(rows: 3, cols: 3, emptyValue: '.');
      board.set(0, 0, 'X');

      final clone = board.clone();
      clone.set(0, 0, 'O');

      expect(board.get(0, 0), equals('X'));
      expect(clone.get(0, 0), equals('O'));
    });
  });
}
