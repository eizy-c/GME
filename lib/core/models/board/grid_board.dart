/// Tablero de cuadrícula bidimensional genérico para juegos de mesa.
class GridBoard<T> {
  final int rows;
  final int cols;
  final T emptyValue;
  final List<List<T>> _cells;

  GridBoard({
    required this.rows,
    required this.cols,
    required this.emptyValue,
  }) : _cells = List.generate(
          rows,
          (_) => List.filled(cols, emptyValue),
        );

  /// Constructor para clonar un tablero existente.
  GridBoard.fromCells({
    required this.rows,
    required this.cols,
    required this.emptyValue,
    required List<List<T>> cells,
  }) : _cells = [
          for (final row in cells) [...row],
        ];

  /// Obtiene el valor en la posición ([row], [col]).
  T get(int row, int col) {
    _validateBounds(row, col);
    return _cells[row][col];
  }

  /// Establece el valor en la posición ([row], [col]).
  void set(int row, int col, T value) {
    _validateBounds(row, col);
    _cells[row][col] = value;
  }

  /// Comprueba si las coordenadas ([row], [col]) son válidas dentro del tablero.
  bool isValidCoordinate(int row, int col) =>
      row >= 0 && row < rows && col >= 0 && col < cols;

  /// Comprueba si la celda ([row], [col]) contiene el valor vacío [emptyValue].
  bool isEmpty(int row, int col) => get(row, col) == emptyValue;

  /// Retorna una lista con todas las coordenadas libres [(row, col)].
  List<(int row, int col)> get availablePositions {
    final positions = <(int, int)>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (_cells[r][c] == emptyValue) {
          positions.add((r, c));
        }
      }
    }
    return positions;
  }

  /// Indica si el tablero está completamente lleno (sin casillas con [emptyValue]).
  bool get isFull => availablePositions.isEmpty;

  /// Retorna una fila completa como lista inmutable.
  List<T> getRow(int row) {
    _validateBounds(row, 0);
    return List.unmodifiable(_cells[row]);
  }

  /// Retorna una columna completa como lista inmutable.
  List<T> getColumn(int col) {
    _validateBounds(0, col);
    return List.unmodifiable([for (var r = 0; r < rows; r++) _cells[r][col]]);
  }

  /// Retorna la diagonal principal (superior izquierda a inferior derecha) si es cuadrado.
  List<T> getMainDiagonal() {
    assert(rows == cols, 'Las diagonales requieren una matriz cuadrada.');
    return [for (var i = 0; i < rows; i++) _cells[i][i]];
  }

  /// Retorna la diagonal secundaria (superior derecha a inferior izquierda) si es cuadrado.
  List<T> getAntiDiagonal() {
    assert(rows == cols, 'Las diagonales requieren una matriz cuadrada.');
    return [for (var i = 0; i < rows; i++) _cells[i][cols - 1 - i]];
  }

  /// Limpia todas las celdas asignando [emptyValue].
  void clear() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        _cells[r][c] = emptyValue;
      }
    }
  }

  /// Crea una copia profunda e independiente del tablero.
  GridBoard<T> clone() => GridBoard.fromCells(
        rows: rows,
        cols: cols,
        emptyValue: emptyValue,
        cells: _cells,
      );

  void _validateBounds(int row, int col) {
    if (!isValidCoordinate(row, col)) {
      throw RangeError('Coordenada ($row, $col) fuera de rango ($rows x $cols).');
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    for (var r = 0; r < rows; r++) {
      buffer.writeln(_cells[r].map((e) => e.toString()).join(' | '));
    }
    return buffer.toString();
  }
}
