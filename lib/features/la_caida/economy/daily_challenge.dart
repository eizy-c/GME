/// Representa un desafío o misión diaria disponible para el jugador en el lobby.
class DailyChallenge {
  final String id;
  final String title;
  final int currentProgress;
  final int targetProgress;
  final int coinReward;
  final int xpReward;
  final bool isCompleted;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.currentProgress,
    required this.targetProgress,
    required this.coinReward,
    required this.xpReward,
    this.isCompleted = false,
  });

  String get progressText => '$currentProgress / $targetProgress';
  String get rewardText => '+$coinReward Monedas  +$xpReward XP';

  /// Catálogo estándar de desafíos iniciales del día
  static const List<DailyChallenge> defaultChallenges = [
    DailyChallenge(
      id: 'win_1_match',
      title: 'Gana 1 partida en CaidaGO',
      currentProgress: 0,
      targetProgress: 1,
      coinReward: 250,
      xpReward: 50,
    ),
    DailyChallenge(
      id: 'make_2_caidas',
      title: 'Realiza 2 Caídas en una partida',
      currentProgress: 0,
      targetProgress: 2,
      coinReward: 150,
      xpReward: 30,
    ),
    DailyChallenge(
      id: 'play_teams_match',
      title: 'Juega en Parejas (2 vs 2)',
      currentProgress: 0,
      targetProgress: 1,
      coinReward: 200,
      xpReward: 40,
    ),
  ];
}
