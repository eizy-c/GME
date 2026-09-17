/// Identificadores de los juegos disponibles en el compendio.
enum GameType {
  laVieja('La Vieja (Tres en Raya)'),
  laCaida('La Caída'),
  cinquillo('Cinquillo'),
  truco('Truco Venezolano'),
  domino('Dominó');

  final String title;
  const GameType(this.title);
}

/// Registro inmutable de estadísticas de partidas para un juego.
class GameStats {
  final GameType gameType;
  final int wins;
  final int losses;
  final int draws;
  final DateTime? lastPlayed;

  const GameStats({
    required this.gameType,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.lastPlayed,
  });

  /// Total de partidas disputadas.
  int get totalGames => wins + losses + draws;

  /// Porcentaje de victorias (0.0 a 100.0).
  double get winRate =>
      totalGames == 0 ? 0.0 : ((wins / totalGames) * 100).toDouble();

  /// Registra una nueva victoria.
  GameStats recordWin() => GameStats(
        gameType: gameType,
        wins: wins + 1,
        losses: losses,
        draws: draws,
        lastPlayed: DateTime.now(),
      );

  /// Registra una nueva derrota.
  GameStats recordLoss() => GameStats(
        gameType: gameType,
        wins: wins,
        losses: losses + 1,
        draws: draws,
        lastPlayed: DateTime.now(),
      );

  /// Registra un empate o tranca.
  GameStats recordDraw() => GameStats(
        gameType: gameType,
        wins: wins,
        losses: losses,
        draws: draws + 1,
        lastPlayed: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'gameType': gameType.name,
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'lastPlayed': lastPlayed?.toIso8601String(),
      };

  factory GameStats.fromJson(Map<String, dynamic> json) {
    return GameStats(
      gameType: GameType.values.byName(json['gameType'] as String),
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      lastPlayed: json['lastPlayed'] != null
          ? DateTime.tryParse(json['lastPlayed'] as String)
          : null,
    );
  }

  @override
  String toString() =>
      'GameStats(${gameType.name}: $wins W / $losses L / $draws D, rate: ${winRate.toStringAsFixed(1)}%)';
}
