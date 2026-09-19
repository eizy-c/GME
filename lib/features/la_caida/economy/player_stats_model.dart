import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/debug_logger.dart';

/// Modelo de estadísticas avanzadas y detalladas del jugador en La Caída.
/// Registra estadísticas generales, jugadas en mesa (caídas, limpias, registros) y cantos tradicionales.
class PlayerStatsModel extends ChangeNotifier {
  static const String storageKey = 'caida_player_game_stats_v3';

  // --- ESTADÍSTICAS GENERALES ---
  int totalEarnings;
  int gamesPlayed;
  int gamesWon;
  int currentStreak;
  int maxStreak;
  int soloWins;
  int teamWins;

  // --- JUGADAS Y MESA (CAÍDA) ---
  int caidasMade;
  int caidasReceived;
  int mesasLimpias;
  int caidasWithLimpia;
  int registros;
  int totalCardsWon;

  // --- CANTOS TRADICIONALES ---
  int rondas;
  int patrullas;
  int vigias;
  int trivilines;

  // --- LOGROS RECLAMADOS ---
  final Set<String> claimedAchievementIds;

  PlayerStatsModel({
    this.totalEarnings = 0,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.soloWins = 0,
    this.teamWins = 0,
    this.caidasMade = 0,
    this.caidasReceived = 0,
    this.mesasLimpias = 0,
    this.caidasWithLimpia = 0,
    this.registros = 0,
    this.totalCardsWon = 0,
    this.rondas = 0,
    this.patrullas = 0,
    this.vigias = 0,
    this.trivilines = 0,
    Set<String>? claimedAchievementIds,
  }) : claimedAchievementIds = claimedAchievementIds ?? <String>{};

  static PlayerStatsModel? _shared;

  /// Instancia compartida en memoria para acceso unificado y reactivo.
  static PlayerStatsModel get shared => _shared ??= PlayerStatsModel();

  static void setShared(PlayerStatsModel model) => _shared = model;

  /// Porcentaje de victorias (0 a 100).
  int get winRatePercentage =>
      gamesPlayed == 0 ? 0 : ((gamesWon / gamesPlayed) * 100).round();

  /// Registra el fin de una partida oficial
  void recordGameResult({
    required bool won,
    required bool isTeams,
    int coinsWon = 0,
    int cardsWon = 0,
    int caidas = 0,
    int limpias = 0,
    int cantos = 0,
  }) {
    gamesPlayed++;
    totalEarnings += coinsWon;
    totalCardsWon += cardsWon;
    caidasMade += caidas;
    mesasLimpias += limpias;

    if (won) {
      gamesWon++;
      currentStreak++;
      if (currentStreak > maxStreak) {
        maxStreak = currentStreak;
      }
      if (isTeams) {
        teamWins++;
      } else {
        soloWins++;
      }
    } else {
      currentStreak = 0;
    }

    notifyListeners();
    save();
  }

  /// Registra un canto cantado por el jugador
  void recordCanto(String cantoName) {
    final lower = cantoName.toLowerCase();
    if (lower.contains('trivil')) {
      trivilines++;
    } else if (lower.contains('registro')) {
      registros++;
    } else if (lower.contains('vigi') || lower.contains('vigí')) {
      vigias++;
    } else if (lower.contains('patrulla')) {
      patrullas++;
    } else if (lower.contains('ronda')) {
      rondas++;
    }
    notifyListeners();
    save();
  }

  /// Registra una caída cantada al rival
  void recordCaidaMade({bool withLimpia = false}) {
    caidasMade++;
    if (withLimpia) {
      caidasWithLimpia++;
      mesasLimpias++;
    }
    notifyListeners();
    save();
  }

  /// Registra una caída recibida por parte del rival
  void recordCaidaReceived() {
    caidasReceived++;
    notifyListeners();
    save();
  }

  /// Registra una mesa limpia
  void recordMesaLimpia() {
    mesasLimpias++;
    notifyListeners();
    save();
  }

  /// Marca un logro como reclamado
  bool claimAchievement(String id) {
    if (claimedAchievementIds.contains(id)) return false;
    claimedAchievementIds.add(id);
    notifyListeners();
    save();
    return true;
  }

  // --- SERIALIZACIÓN JSON Y PERSISTENCIA LOCAL ---

  Map<String, dynamic> toJson() => {
        'totalEarnings': totalEarnings,
        'gamesPlayed': gamesPlayed,
        'gamesWon': gamesWon,
        'currentStreak': currentStreak,
        'maxStreak': maxStreak,
        'soloWins': soloWins,
        'teamWins': teamWins,
        'caidasMade': caidasMade,
        'caidasReceived': caidasReceived,
        'mesasLimpias': mesasLimpias,
        'caidasWithLimpia': caidasWithLimpia,
        'registros': registros,
        'totalCardsWon': totalCardsWon,
        'rondas': rondas,
        'patrullas': patrullas,
        'vigias': vigias,
        'trivilines': trivilines,
        'claimedAchievementIds': claimedAchievementIds.toList(),
      };

  factory PlayerStatsModel.fromJson(Map<String, dynamic> json) {
    final claimed = (json['claimedAchievementIds'] as List?)
            ?.map((e) => e.toString())
            .toSet() ??
        <String>{};

    return PlayerStatsModel(
      totalEarnings: json['totalEarnings'] as int? ?? 0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      gamesWon: json['gamesWon'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      maxStreak: json['maxStreak'] as int? ?? 0,
      soloWins: json['soloWins'] as int? ?? 0,
      teamWins: json['teamWins'] as int? ?? 0,
      caidasMade: json['caidasMade'] as int? ?? 0,
      caidasReceived: json['caidasReceived'] as int? ?? 0,
      mesasLimpias: json['mesasLimpias'] as int? ?? 0,
      caidasWithLimpia: json['caidasWithLimpia'] as int? ?? 0,
      registros: json['registros'] as int? ?? 0,
      totalCardsWon: json['totalCardsWon'] as int? ?? 0,
      rondas: json['rondas'] as int? ?? 0,
      patrullas: json['patrullas'] as int? ?? 0,
      vigias: json['vigias'] as int? ?? 0,
      trivilines: json['trivilines'] as int? ?? 0,
      claimedAchievementIds: claimed,
    );
  }

  /// Restablece todas las estadísticas a 0 (útil para pruebas y reinicios).
  void reset() {
    totalEarnings = 0;
    gamesPlayed = 0;
    gamesWon = 0;
    currentStreak = 0;
    maxStreak = 0;
    soloWins = 0;
    teamWins = 0;
    caidasMade = 0;
    caidasReceived = 0;
    mesasLimpias = 0;
    caidasWithLimpia = 0;
    registros = 0;
    totalCardsWon = 0;
    rondas = 0;
    patrullas = 0;
    vigias = 0;
    trivilines = 0;
    claimedAchievementIds.clear();
    notifyListeners();
    save();
  }

  /// Carga las estadísticas desde SharedPreferences
  Future<void> load({SharedPreferences? prefs}) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final raw = p.getString(storageKey);
      if (raw != null && raw.isNotEmpty) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final loaded = PlayerStatsModel.fromJson(data);
        _copyFrom(loaded);
        notifyListeners();
      }
    } catch (e) {
      DebugLogger.instance.log(
        'Error cargando PlayerStatsModel: $e',
        category: 'Sistema',
        level: LogLevel.warning,
      );
    }
  }

  /// Guarda las estadísticas en SharedPreferences
  void save({SharedPreferences? prefs}) {
    final raw = jsonEncode(toJson());
    if (prefs != null) {
      prefs.setString(storageKey, raw).catchError((_) => false);
      return;
    }
    SharedPreferences.getInstance().then((p) {
      p.setString(storageKey, raw).catchError((_) => false);
    }).catchError((_) {});
  }

  void _copyFrom(PlayerStatsModel other) {
    totalEarnings = other.totalEarnings;
    gamesPlayed = other.gamesPlayed;
    gamesWon = other.gamesWon;
    currentStreak = other.currentStreak;
    maxStreak = other.maxStreak;
    soloWins = other.soloWins;
    teamWins = other.teamWins;
    caidasMade = other.caidasMade;
    caidasReceived = other.caidasReceived;
    mesasLimpias = other.mesasLimpias;
    caidasWithLimpia = other.caidasWithLimpia;
    registros = other.registros;
    totalCardsWon = other.totalCardsWon;
    rondas = other.rondas;
    patrullas = other.patrullas;
    vigias = other.vigias;
    trivilines = other.trivilines;
    claimedAchievementIds.clear();
    claimedAchievementIds.addAll(other.claimedAchievementIds);
  }
}
