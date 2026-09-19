/// Cálculo matemático puro de nivel y progreso porcentual mediante curva exponencial.
/// Todos los jugadores inician formalmente en Nivel 0 (0 XP).
class UserProgress {
  final int totalXp;

  const UserProgress({required this.totalXp});

  /// XP total acumulada requerida para alcanzar un nivel dado.
  /// Nivel 0: 0 XP
  /// Nivel 1: 100 XP
  /// Nivel N: 100 * (N ^ 1.5)
  static const List<int> _levelThresholds = [
    0,     // Nivel 0: Pichón (0 XP)
    100,   // Nivel 1: Caimanero (100 XP - 1 victoria)
    300,   // Nivel 2: El Avillao (300 XP - ~2-3 victorias)
    650,   // Nivel 3: Arrastrador (650 XP - ~5-6 victorias)
    1150,  // Nivel 4: Gallo Fino (1,150 XP - ~10 victorias)
    1850,  // Nivel 5: El Tigre (1,850 XP - ~17 victorias)
    2800,  // Nivel 6: El Baquiano (2,800 XP - ~26 victorias)
    4000,  // Nivel 7: Pana Bravo (4,000 XP - ~38 victorias)
    5500,  // Nivel 8: El Caballo (5,500 XP - ~52 victorias)
    7500,  // Nivel 9: El Papá de los Helados (7,500 XP - ~70 victorias)
    10000, // Nivel 10: Cacique del Trivilín (10,000 XP - ~95+ victorias)
  ];

  /// XP total acumulada requerida para alcanzar un nivel dado.
  static int xpRequiredForLevel(int level) {
    if (level <= 0) return 0;
    if (level < _levelThresholds.length) {
      return _levelThresholds[level];
    }
    // Niveles de prestigio mayores a 10
    final extra = level - 10;
    return 10000 + (extra * 3000);
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

  /// Título criollo venezolano según el nivel alcanzado.
  String get rankTitle {
    switch (currentLevel) {
      case 0:
        return 'Pichón';
      case 1:
        return 'Caimanero';
      case 2:
        return 'El Avillao';
      case 3:
        return 'Arrastrador';
      case 4:
        return 'Gallo Fino';
      case 5:
        return 'El Tigre';
      case 6:
        return 'El Baquiano';
      case 7:
        return 'Pana Bravo';
      case 8:
        return 'El Caballo';
      case 9:
        return 'El Papá de los Helados';
      default:
        return 'Cacique del Trivilín';
    }
  }
}

/// Representa una meta o hito de recompensa por alcanzar un nivel en La Caída.
class LevelMilestone {
  final int level;
  final String title;
  final String reward;

  const LevelMilestone({
    required this.level,
    required this.title,
    required this.reward,
  });

  bool isUnlocked(int playerLevel) => playerLevel >= level;

  /// Catálogo oficial de hitos de nivel para La Caída
  static const List<LevelMilestone> catalog = [
    LevelMilestone(level: 0, title: 'Nivel 0: Pichón', reward: '10 Tickets de cortesía, Modo Normal, Marco Madera Rústica'),
    LevelMilestone(level: 1, title: 'Nivel 1: Caimanero', reward: '+150 Monedas, Escuela de Novatos completada'),
    LevelMilestone(level: 2, title: 'Nivel 2: El Avillao', reward: 'Desbloqueo de Marco Plata Pulida'),
    LevelMilestone(level: 3, title: 'Nivel 3: Arrastrador', reward: '+250 Monedas, Desbloqueo Mesa VIP Bronce'),
    LevelMilestone(level: 4, title: 'Nivel 4: Gallo Fino', reward: 'Desbloqueo de Marco Oro Imperial'),
    LevelMilestone(level: 5, title: 'Nivel 5: El Tigre', reward: '+500 Monedas, Desbloqueo Mesa VIP Plata'),
    LevelMilestone(level: 6, title: 'Nivel 6: El Baquiano', reward: 'Desbloqueo de Marco Neón Cibernético'),
    LevelMilestone(level: 7, title: 'Nivel 7: Pana Bravo', reward: '+750 Monedas, Desbloqueo Mesa VIP Oro'),
    LevelMilestone(level: 8, title: 'Nivel 8: El Caballo', reward: 'Desbloqueo de Marco Llama Ardiente'),
    LevelMilestone(level: 9, title: 'Nivel 9: El Papá de los Helados', reward: '+1,000 Monedas de bonificación'),
    LevelMilestone(level: 10, title: 'Nivel 10: Cacique del Trivilín', reward: 'Desbloqueo Marco Diamante Real y Mesa Diamante'),
  ];
}
