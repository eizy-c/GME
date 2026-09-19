import 'dart:math';

/// Cálculo matemático puro de nivel y progreso porcentual mediante curva exponencial.
/// Todos los jugadores inician formalmente en Nivel 0 (0 XP).
class UserProgress {
  final int totalXp;

  const UserProgress({required this.totalXp});

  /// XP total acumulada requerida para alcanzar un nivel dado.
  /// Nivel 0: 0 XP
  /// Nivel 1: 100 XP
  /// Nivel N: 100 * (N ^ 1.5)
  static int xpRequiredForLevel(int level) {
    if (level <= 0) return 0;
    if (level == 1) return 100;
    return (100 * pow(level, 1.5)).floor();
  }

  /// Nivel actual basado en la XP total acumulada (iniciando en 0).
  int get currentLevel {
    int level = 0;
    while (totalXp >= xpRequiredForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  /// Base de XP al comenzar el nivel actual.
  int get currentLevelBaseXp => xpRequiredForLevel(currentLevel);

  /// Meta de XP para desbloquear el siguiente nivel.
  int get nextLevelTargetXp => xpRequiredForLevel(currentLevel + 1);

  /// XP ganada dentro del rango del nivel actual.
  int get currentTierXp => totalXp - currentLevelBaseXp;

  /// XP total necesaria dentro del rango para subir al siguiente nivel.
  int get neededInCurrentTier => nextLevelTargetXp - currentLevelBaseXp;

  /// XP exacta que le falta al jugador para subir al siguiente nivel.
  int get xpRemainingToNextLevel => (nextLevelTargetXp - totalXp).clamp(0, 9999999);

  /// Progreso porcentual normalizado (0.0 a 1.0) dentro del nivel actual.
  double get levelProgressPercentage {
    if (neededInCurrentTier <= 0) return 1.0;
    return (currentTierXp / neededInCurrentTier).clamp(0.0, 1.0);
  }

  /// Título honorífico según el nivel alcanzado.
  String get rankTitle {
    if (currentLevel == 0) return 'Novato';
    if (currentLevel <= 2) return 'Aprendiz';
    if (currentLevel <= 4) return 'Aficionado';
    if (currentLevel <= 6) return 'Estratega';
    if (currentLevel <= 9) return 'Maestro de Caída';
    return 'Leyenda Criolla';
  }
}
