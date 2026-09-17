import 'package:flutter_test/flutter_test.dart';
import 'package:gme/core/stats/game_stats.dart';
import 'package:gme/core/stats/stats_repository.dart';

void main() {
  group('StatsRepository & GameStats Tests', () {
    test('Calcula correctamente winRate y totales de partidas', () {
      var stats = const GameStats(gameType: GameType.domino);
      expect(stats.totalGames, equals(0));
      expect(stats.winRate, equals(0.0));

      stats = stats.recordWin();
      stats = stats.recordWin();
      stats = stats.recordLoss();
      stats = stats.recordDraw();

      expect(stats.wins, equals(2));
      expect(stats.losses, equals(1));
      expect(stats.draws, equals(1));
      expect(stats.totalGames, equals(4));
      expect(stats.winRate, equals(50.0));
      expect(stats.lastPlayed, isNotNull);
    });

    test('Serialización y deserialización JSON adecuada', () {
      final original = const GameStats(
        gameType: GameType.laCaida,
        wins: 5,
        losses: 2,
        draws: 1,
      );

      final json = original.toJson();
      final restored = GameStats.fromJson(json);

      expect(restored.gameType, equals(GameType.laCaida));
      expect(restored.wins, equals(5));
      expect(restored.losses, equals(2));
      expect(restored.draws, equals(1));
    });

    test('InMemoryStatsRepository almacena, recupera y reinicia estadísticas', () async {
      final repo = InMemoryStatsRepository();
      final initial = await repo.getStats(GameType.domino);
      expect(initial.wins, equals(0));

      await repo.saveStats(initial.recordWin());
      final updated = await repo.getStats(GameType.domino);
      expect(updated.wins, equals(1));

      await repo.resetStats(GameType.domino);
      final reset = await repo.getStats(GameType.domino);
      expect(reset.wins, equals(0));
    });
  });
}
