import 'dart:math';

/// Cálculo matemático puro de nivel y progreso porcentual mediante curva exponencial.
class UserProgress {
  final int totalXp;

  const UserProgress({required this.totalXp});

  /// XP total acumulada requerida para alcanzar un nivel dado.
  /// Curva exponencial: 100 * (nivel ^ 1.5).
  static int xpRequiredForLevel(int level) {
    if (level <= 1) return 0;
    return (100 * pow(level, 1.5)).floor();
  }

  /// Nivel actual basado en la XP total acumulada.
  int get currentLevel {
    int level = 1;
    while (totalXp >= xpRequiredForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  /// Base de XP al comenzar el nivel actual.
  int get currentLevelBaseXp => xpRequiredForLevel(currentLevel);

  /// Meta de XP para desbloquear el siguiente nivel.
  int get nextLevelTargetXp => xpRequiredForLevel(currentLevel + 1);

  /// Progreso porcentual normalizado (0.0 a 1.0) dentro del nivel actual.
  double get levelProgressPercentage {
    final currentTierXp = totalXp - currentLevelBaseXp;
    final neededInTier = nextLevelTargetXp - currentLevelBaseXp;
    if (neededInTier <= 0) return 1.0;
    return (currentTierXp / neededInTier).clamp(0.0, 1.0);
  }
}
