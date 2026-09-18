import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

/// Implementación persistente de estadísticas en disco local usando SharedPreferences.
class SharedPrefsStatsRepository implements StatsRepository {
  static const String _keyPrefix = 'game_stats_v1_';
  final SharedPreferences? _injectedPrefs;
  final Map<GameType, GameStats> _cache = {};
  bool _isLoaded = false;

  SharedPrefsStatsRepository({SharedPreferences? prefs}) : _injectedPrefs = prefs;

  Future<SharedPreferences> get _prefs async =>
      _injectedPrefs ?? await SharedPreferences.getInstance();

  /// Precarga inicial de estadísticas en memoria.
  Future<void> load() async {
    final p = await _prefs;
    for (final type in GameType.values) {
      final raw = p.getString('$_keyPrefix${type.name}');
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          _cache[type] = GameStats.fromJson(decoded);
        } catch (_) {
          _cache[type] = GameStats(gameType: type);
        }
      } else {
        _cache[type] = GameStats(gameType: type);
      }
    }
    _isLoaded = true;
  }

  @override
  Future<GameStats> getStats(GameType gameType) async {
    if (!_isLoaded) await load();
    return _cache[gameType] ?? GameStats(gameType: gameType);
  }

  @override
  Future<void> saveStats(GameStats stats) async {
    if (!_isLoaded) await load();
    _cache[stats.gameType] = stats;
    final p = await _prefs;
    final jsonStr = jsonEncode(stats.toJson());
    await p.setString('$_keyPrefix${stats.gameType.name}', jsonStr);
  }

  @override
  Future<Map<GameType, GameStats>> getAllStats() async {
    if (!_isLoaded) await load();
    return Map.unmodifiable(_cache);
  }

  @override
  Future<void> resetStats(GameType gameType) async {
    if (!_isLoaded) await load();
    _cache[gameType] = GameStats(gameType: gameType);
    final p = await _prefs;
    await p.remove('$_keyPrefix${gameType.name}');
  }
}
