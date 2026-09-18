import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_progress.dart';

/// Modelo y gestor de sesión local persistente del jugador para La Caída.
/// Implementa regeneración pasiva por tiempo (1 ticket cada 20 min) y arquitectura reactiva.
class PlayerSession extends ChangeNotifier {
  static const String storageKey = 'caida_player_session_v2';
  static const int defaultMaxTickets = 10;
  static const int ticketRegenIntervalMinutes = 20;
  static const int ticketStandardCostCoins = 400;

  String _id;
  String _name;
  int _avatarIndex;
  int _coins;
  int _tickets;
  int _maxTickets;
  int _xp;
  int _level;
  DateTime _lastTicketRegen;

  PlayerSession({
    required this._id,
    required this._name,
    this._avatarIndex = 0,
    this._coins = 3000,
    int tickets = defaultMaxTickets,
    this._maxTickets = defaultMaxTickets,
    this._xp = 0,
    this._level = 1,
    DateTime? lastTicketRegen,
  })  : _tickets = tickets.clamp(0, _maxTickets),
        _lastTicketRegen = (lastTicketRegen ?? DateTime.now()).toUtc();

  /// Factory para crear una sesión nueva con valores por defecto equilibrados.
  factory PlayerSession.createDefault({String? name, int? avatarIndex}) {
    return PlayerSession(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Jugador',
      avatarIndex: avatarIndex ?? 0,
      coins: 3000,
      tickets: defaultMaxTickets,
      maxTickets: defaultMaxTickets,
      xp: 0,
      level: 1,
      lastTicketRegen: DateTime.now().toUtc(),
    );
  }

  // Getters públicos
  String get id => _id;
  String get name => _name;
  int get avatarIndex => _avatarIndex;
  int get coins => _coins;
  int get tickets => _tickets;
  int get maxTickets => _maxTickets;
  int get xp => _xp;
  int get level => _level;
  DateTime get lastTicketRegen => _lastTicketRegen;

  // Setters de perfil
  void updateProfile({String? name, int? avatarIndex}) {
    if (name != null) _name = name;
    if (avatarIndex != null) _avatarIndex = avatarIndex;
    notifyListeners();
    save();
  }

  /// Regenera tickets pasivamente según el tiempo transcurrido desde `_lastTicketRegen`.
  /// Añade 1 ticket por cada intervalo de 20 minutos hasta el tope de `maxTickets`.
  /// Permite inyectar [nowUtc] para verificación y pruebas unitarias deterministas.
  int regenerateTicketsPassive({DateTime? nowUtc}) {
    final now = (nowUtc ?? DateTime.now()).toUtc();

    if (_tickets >= _maxTickets) {
      _lastTicketRegen = now;
      return 0;
    }

    final elapsed = now.difference(_lastTicketRegen);
    if (elapsed.isNegative) {
      _lastTicketRegen = now;
      return 0;
    }

    final intervals = elapsed.inMinutes ~/ ticketRegenIntervalMinutes;
    if (intervals <= 0) {
      return 0;
    }

    final int spaceAvailable = _maxTickets - _tickets;
    final int toAdd = intervals.clamp(0, spaceAvailable);

    _tickets += toAdd;

    if (_tickets >= _maxTickets) {
      _lastTicketRegen = now;
    } else {
      _lastTicketRegen = _lastTicketRegen.add(
        Duration(minutes: toAdd * ticketRegenIntervalMinutes),
      );
    }

    notifyListeners();
    save();
    return toAdd;
  }

  /// Retorna el tiempo restante hasta el próximo ticket regenerado.
  /// Si los tickets ya están al máximo, retorna Duration.zero.
  Duration timeUntilNextTicket({DateTime? nowUtc}) {
    if (_tickets >= _maxTickets) {
      return Duration.zero;
    }

    final now = (nowUtc ?? DateTime.now()).toUtc();
    final elapsed = now.difference(_lastTicketRegen);
    final intervalDuration = const Duration(minutes: ticketRegenIntervalMinutes);

    final remainingInCurrentInterval = intervalDuration - Duration(
      minutes: elapsed.inMinutes % ticketRegenIntervalMinutes,
      seconds: elapsed.inSeconds % 60,
    );

    if (remainingInCurrentInterval.isNegative) {
      return Duration.zero;
    }
    return remainingInCurrentInterval;
  }

  /// Consume 1 ticket para iniciar una partida normal / casual.
  /// Retorna true si pudo consumirse, false si no cuenta con tickets disponibles.
  bool consumeTicketForNormalMatch({DateTime? nowUtc}) {
    regenerateTicketsPassive(nowUtc: nowUtc);

    if (_tickets < 1) {
      return false;
    }

    // Si estaba al máximo, el reloj de recarga pasiva comienza a correr ahora
    if (_tickets == _maxTickets) {
      _lastTicketRegen = (nowUtc ?? DateTime.now()).toUtc();
    }

    _tickets -= 1;
    notifyListeners();
    save();
    return true;
  }

  /// Compra [quantity] tickets a cambio de monedas.
  /// Costo por defecto: 1 Ticket = 400 Monedas (o [customCoinCost] para paquetes con descuento).
  /// Retorna true si la compra fue exitosa.
  bool buyTicketsWithCoins(int quantity, {int? customCoinCost, DateTime? nowUtc}) {
    if (quantity <= 0) return false;

    regenerateTicketsPassive(nowUtc: nowUtc);

    if (_tickets >= _maxTickets) {
      return false;
    }

    final int cost = customCoinCost ?? (quantity * ticketStandardCostCoins);
    if (_coins < cost) {
      return false;
    }

    final int space = _maxTickets - _tickets;
    final int actualToAdd = quantity.clamp(0, space);
    if (actualToAdd <= 0) {
      return false;
    }

    _coins -= cost;
    _tickets += actualToAdd;

    if (_tickets >= _maxTickets) {
      _lastTicketRegen = (nowUtc ?? DateTime.now()).toUtc();
    }

    notifyListeners();
    save();
    return true;
  }

  /// Otorga +1 ticket como recompensa tras ver un anuncio en video.
  /// Retorna true si se pudo agregar el ticket, o false si ya está al tope.
  bool claimAdTicketReward({DateTime? nowUtc}) {
    regenerateTicketsPassive(nowUtc: nowUtc);

    if (_tickets >= _maxTickets) {
      return false;
    }

    _tickets += 1;
    if (_tickets >= _maxTickets) {
      _lastTicketRegen = (nowUtc ?? DateTime.now()).toUtc();
    }

    notifyListeners();
    save();
    return true;
  }

  /// Descuenta saldo en monedas para ingresar a una mesa de apuesta VIP.
  /// Retorna true si el jugador contaba con los fondos suficientes.
  bool deductCoinsForVipMatch(int amount) {
    if (amount <= 0 || _coins < amount) {
      return false;
    }

    _coins -= amount;
    notifyListeners();
    save();
    return true;
  }

  /// Otorga monedas ganadas en una partida y calcula la subida de XP y nivel.
  void rewardCoins(int amount, {int? xpGain}) {
    if (amount <= 0) return;

    _coins += amount;
    final int gainedXp = xpGain ?? (amount ~/ 4).clamp(25, 2000);
    _addXpInternal(gainedXp);

    notifyListeners();
    save();
  }

  /// Suma experiencia y actualiza automáticamente el nivel del jugador.
  void addXp(int amount) {
    if (amount <= 0) return;
    _addXpInternal(amount);
    notifyListeners();
    save();
  }

  void _addXpInternal(int amount) {
    _xp += amount;
    final progress = UserProgress(totalXp: _xp);
    _level = progress.currentLevel;
  }

  // --- SERIALIZACIÓN JSON Y PERSISTENCIA ---

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'name': _name,
      'avatarIndex': _avatarIndex,
      'coins': _coins,
      'tickets': _tickets,
      'maxTickets': _maxTickets,
      'xp': _xp,
      'level': _level,
      'lastTicketRegen': _lastTicketRegen.toIso8601String(),
    };
  }

  factory PlayerSession.fromJson(Map<String, dynamic> json) {
    final parsedMaxTickets = json['maxTickets'] as int? ?? defaultMaxTickets;
    final parsedTickets = (json['tickets'] as int? ?? defaultMaxTickets).clamp(0, parsedMaxTickets);
    final regenString = json['lastTicketRegen'] as String?;
    final parsedRegen = regenString != null
        ? DateTime.tryParse(regenString)?.toUtc() ?? DateTime.now().toUtc()
        : DateTime.now().toUtc();

    return PlayerSession(
      id: json['id'] as String? ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Jugador',
      avatarIndex: json['avatarIndex'] as int? ?? 0,
      coins: json['coins'] as int? ?? 3000,
      tickets: parsedTickets,
      maxTickets: parsedMaxTickets,
      xp: json['xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      lastTicketRegen: parsedRegen,
    );
  }

  /// Guarda el estado actual de la sesión en SharedPreferences.
  Future<void> save({SharedPreferences? prefs}) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final jsonString = jsonEncode(toJson());
      await p.setString(storageKey, jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Error al guardar PlayerSession: $e');
      }
    }
  }

  /// Carga la sesión del jugador desde SharedPreferences.
  /// Si no existe, crea una nueva sesión por defecto.
  /// Realiza la regeneración pasiva de tickets offline inmediatamente al cargar.
  static Future<PlayerSession> load({SharedPreferences? prefs, DateTime? nowUtc}) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final raw = p.getString(storageKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
        final session = PlayerSession.fromJson(decoded);
        session.regenerateTicketsPassive(nowUtc: nowUtc);
        return session;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar PlayerSession: $e');
      }
    }

    // Si no hay datos guardados o hubo un error, inicializar por defecto
    final newSession = PlayerSession.createDefault();
    await newSession.save(prefs: prefs);
    return newSession;
  }

  /// Elimina los datos de sesión almacenados (útil para pruebas o reinicio total).
  static Future<void> clear({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.remove(storageKey);
  }
}
