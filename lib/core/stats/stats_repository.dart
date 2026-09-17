import 'game_stats.dart';

/// Contrato abstracto para el almacenamiento offline de estadísticas de partidas.
abstract class StatsRepository {
  Future<GameStats> getStats(GameType gameType);
  Future<void> saveStats(GameStats stats);
  Future<Map<GameType, GameStats>> getAllStats();
  Future<void> resetStats(GameType gameType);
}

/// Implementación offline en memoria con persistencia desacoplada.
class InMemoryStatsRepository implements StatsRepository {
  final Map<GameType, GameStats> _storage = {};

  InMemoryStatsRepository({Map<GameType, GameStats>? initialStats}) {
    if (initialStats != null) {
      _storage.addAll(initialStats);
    }
  }

  @override
  Future<GameStats> getStats(GameType gameType) async {
    return _storage[gameType] ?? GameStats(gameType: gameType);
  }

  @override
  Future<void> saveStats(GameStats stats) async {
    _storage[stats.gameType] = stats;
  }

  @override
  Future<Map<GameType, GameStats>> getAllStats() async {
    final result = <GameType, GameStats>{};
    for (final type in GameType.values) {
      result[type] = _storage[type] ?? GameStats(gameType: type);
    }
    return result;
  }

  @override
  Future<void> resetStats(GameType gameType) async {
    _storage[gameType] = GameStats(gameType: gameType);
  }
}
