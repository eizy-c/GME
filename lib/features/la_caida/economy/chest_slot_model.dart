import 'dart:math' as math;

enum ChestState {
  empty,
  unlocking,
  ready,
}

enum ChestRarity {
  madera,
  bronce,
  plata,
  oro,
}

/// Modelo de datos para un slot de cofre en el lobby principal.
/// Se desbloquea con temporizador de 2 minutos o instantáneamente por 2 tickets.
/// Entrega entre 50 y 2500 monedas de recompensa al azar.
class ChestSlotModel {
  final int slotIndex; // 0, 1, 2, 3
  final String? id;
  final ChestRarity rarity;
  final DateTime? unlockStartedAtUtc;
  final int durationSeconds; // 120 s por defecto (2 minutos)
  final bool isOpened;

  static const int standardDurationSeconds = 120; // 2 minutos
  static const int instantTicketCost = 2; // 2 tickets para abrir de inmediato
  static const int minRewardCoins = 50;
  static const int maxRewardCoins = 2500;

  const ChestSlotModel({
    required this.slotIndex,
    this.id,
    this.rarity = ChestRarity.madera,
    this.unlockStartedAtUtc,
    this.durationSeconds = standardDurationSeconds,
    this.isOpened = false,
  });

  /// Crea un slot vacío por defecto
  factory ChestSlotModel.empty(int index) => ChestSlotModel(slotIndex: index);

  /// Crea un nuevo cofre asignado tras una victoria e inicia su cuenta regresiva de 2 min
  factory ChestSlotModel.newWonChest(int index, {ChestRarity rarity = ChestRarity.madera, DateTime? nowUtc}) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    return ChestSlotModel(
      slotIndex: index,
      id: 'chest_${now.millisecondsSinceEpoch}_$index',
      rarity: rarity,
      unlockStartedAtUtc: now,
      durationSeconds: standardDurationSeconds,
      isOpened: false,
    );
  }

  bool get isEmpty => id == null || isOpened;

  /// Retorna el estado actual del cofre evaluando el tiempo transcurrido
  ChestState getState({DateTime? nowUtc}) {
    if (isEmpty) return ChestState.empty;
    if (unlockStartedAtUtc == null) return ChestState.ready;

    final now = (nowUtc ?? DateTime.now()).toUtc();
    final elapsedSeconds = now.difference(unlockStartedAtUtc!).inSeconds;
    if (elapsedSeconds >= durationSeconds) {
      return ChestState.ready;
    }
    return ChestState.unlocking;
  }

  /// Retorna el tiempo restante para poder abrir el cofre
  Duration getRemainingDuration({DateTime? nowUtc}) {
    if (isEmpty || unlockStartedAtUtc == null) return Duration.zero;

    final now = (nowUtc ?? DateTime.now()).toUtc();
    final elapsed = now.difference(unlockStartedAtUtc!);
    final totalDuration = Duration(seconds: durationSeconds);
    final remaining = totalDuration - elapsed;
    if (remaining.isNegative) return Duration.zero;
    return remaining;
  }

  /// Formato legible del tiempo restante (ej. "01:45")
  String getFormattedRemainingTime({DateTime? nowUtc}) {
    final rem = getRemainingDuration(nowUtc: nowUtc);
    if (rem == Duration.zero) return '¡LISTO!';
    final minutes = rem.inMinutes.toString().padLeft(2, '0');
    final seconds = (rem.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Genera una cantidad de monedas al azar entre 50 y 2500
  int generateRewardCoins({math.Random? random}) {
    final rng = random ?? math.Random();
    return minRewardCoins + rng.nextInt(maxRewardCoins - minRewardCoins + 1);
  }

  /// Genera XP de recompensa al azar entre 30 y 150
  int generateRewardXp({math.Random? random}) {
    final rng = random ?? math.Random();
    return 30 + rng.nextInt(121);
  }

  Map<String, dynamic> toJson() => {
        'slotIndex': slotIndex,
        'id': id,
        'rarity': rarity.name,
        'unlockStartedAtUtc': unlockStartedAtUtc?.toIso8601String(),
        'durationSeconds': durationSeconds,
        'isOpened': isOpened,
      };

  factory ChestSlotModel.fromJson(Map<String, dynamic> json) {
    final rarityStr = json['rarity'] as String? ?? 'madera';
    final rarity = ChestRarity.values.where((r) => r.name == rarityStr).firstOrNull ?? ChestRarity.madera;
    final timeStr = json['unlockStartedAtUtc'] as String?;

    return ChestSlotModel(
      slotIndex: json['slotIndex'] as int? ?? 0,
      id: json['id'] as String?,
      rarity: rarity,
      unlockStartedAtUtc: timeStr != null ? DateTime.tryParse(timeStr)?.toUtc() : null,
      durationSeconds: json['durationSeconds'] as int? ?? standardDurationSeconds,
      isOpened: json['isOpened'] as bool? ?? false,
    );
  }
}
