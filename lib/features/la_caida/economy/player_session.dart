import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chest_slot_model.dart';
import 'user_progress.dart';

/// Modelo y gestor de sesión local persistente del jugador para La Caída.
/// Implementa regeneración pasiva por tiempo (1 ticket cada 20 min), personalización (fondos, marcos, avatares),
/// sistema de nivel iniciando en Nivel 0 con 10 tickets y 0 monedas, y gestión de 4 cofres de recompensa.
class PlayerSession extends ChangeNotifier {
  static const String storageKey = 'caida_player_session_v3';
  static const int defaultMaxTickets = 10;
  static const int ticketRegenIntervalMinutes = 20;
  static const int ticketStandardCostCoins = 400;

  String _id;
  String _name;
  int _avatarIndex;
  String _selectedFrameId;
  String _selectedThemeId;
  int _coins;
  int _tickets;
  int _maxTickets;
  int _xp;
  int _level;
  DateTime _lastTicketRegen;
  bool _hasCompletedTutorial;
  bool _isFirstTime;
  List<ChestSlotModel> _chests;

  PlayerSession({
    required this._id,
    required this._name,
    this._avatarIndex = 2,
    this._selectedFrameId = 'wood',
    this._selectedThemeId = 'royal_blue',
    this._coins = 0,
    int tickets = defaultMaxTickets,
    this._maxTickets = defaultMaxTickets,
    this._xp = 0,
    this._level = 0,
    DateTime? lastTicketRegen,
    this._hasCompletedTutorial = false,
    this._isFirstTime = true,
    List<ChestSlotModel>? chests,
  })  : _tickets = tickets.clamp(0, _maxTickets),
        _lastTicketRegen = (lastTicketRegen ?? DateTime.now()).toUtc(),
        _chests = chests ?? List.generate(4, (i) => ChestSlotModel.empty(i));

  static PlayerSession? _shared;

  /// Instancia compartida en memoria para acceso unificado en toda la UI.
  static PlayerSession get shared =>
      _shared ??= PlayerSession.createDefault(name: 'Eizy', avatarIndex: 2, coins: 0, tickets: defaultMaxTickets);

  /// Permite establecer o restablecer la instancia compartida (útil para pruebas).
  static void setShared(PlayerSession session) => _shared = session;

  /// Factory para crear una sesión nueva para novatos:
  /// Todos comienzan formalmente en Nivel 0 con 10 tickets y 0 monedas.
  factory PlayerSession.createDefault({
    String? name,
    int? avatarIndex,
    String? selectedFrameId,
    String? selectedThemeId,
    int? coins,
    int? tickets,
    bool hasCompletedTutorial = false,
    bool isFirstTime = true,
  }) {
    return PlayerSession(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Eizy',
      avatarIndex: avatarIndex ?? 2,
      selectedFrameId: selectedFrameId ?? 'wood',
      selectedThemeId: selectedThemeId ?? 'royal_blue',
      coins: coins ?? 0,
      tickets: tickets ?? defaultMaxTickets,
      maxTickets: defaultMaxTickets,
      xp: 0,
      level: 0,
      lastTicketRegen: DateTime.now().toUtc(),
      hasCompletedTutorial: hasCompletedTutorial,
      isFirstTime: isFirstTime,
      chests: List.generate(4, (i) => ChestSlotModel.empty(i)),
    );
  }

  // Getters públicos
  String get id => _id;
  String get name => _name;
  int get avatarIndex => _avatarIndex;
  String get selectedFrameId => _selectedFrameId;
  String get selectedThemeId => _selectedThemeId;
  int get coins => _coins;
  int get tickets => _tickets;
  int get maxTickets => _maxTickets;
  int get xp => _xp;
  int get level => _level;
  DateTime get lastTicketRegen => _lastTicketRegen;
  bool get hasCompletedTutorial => _hasCompletedTutorial;
  bool get isFirstTime => _isFirstTime;
  List<ChestSlotModel> get chests => List.unmodifiable(_chests);

  // Setters de personalización
  void updateCustomization({
    String? name,
    int? avatarIndex,
    String? frameId,
    String? themeId,
  }) {
    if (name != null) _name = name;
    if (avatarIndex != null) _avatarIndex = avatarIndex;
    if (frameId != null) _selectedFrameId = frameId;
    if (themeId != null) _selectedThemeId = themeId;
    _isFirstTime = false;
    notifyListeners();
    save();
  }

  void updateProfile({String? name, int? avatarIndex}) {
    updateCustomization(name: name, avatarIndex: avatarIndex);
  }

  void markNotFirstTime() {
    if (_isFirstTime) {
      _isFirstTime = false;
      notifyListeners();
      save();
    }
  }

  /// Otorga la bonificación de graduación del tutorial (+1000 monedas),
  /// marca hasCompletedTutorial en true y persiste de inmediato en disco.
  void completeTutorialReward({int coinReward = 1000}) {
    if (_hasCompletedTutorial) return;
    _coins += coinReward;
    _hasCompletedTutorial = true;
    _isFirstTime = false;
    _addXpInternal(150);
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

  /// Incrementa el balance de monedas blandas
  void addCoins(int amount) {
    rewardCoins(amount);
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

  // --- GESTIÓN DE COFRES DE RECOMPENSA (4 SLOTS) ---

  /// Asigna un cofre de recompensa tras ganar una partida.
  /// Regla: solo se asigna si hay un slot libre y ningún otro cofre está en proceso de abrirse (2 min).
  bool addChestOnWin({DateTime? nowUtc}) {
    final hasUnlocking = _chests.any((c) => c.getState(nowUtc: nowUtc) == ChestState.unlocking);
    if (hasUnlocking) {
      return false;
    }

    final emptyIndex = _chests.indexWhere((c) => c.isEmpty);
    if (emptyIndex == -1) {
      return false;
    }

    final newChest = ChestSlotModel.newWonChest(emptyIndex, nowUtc: nowUtc);
    _chests[emptyIndex] = newChest;
    notifyListeners();
    save();
    return true;
  }

  /// Desbloquea instantáneamente un cofre consumiendo 2 tickets.
  bool unlockChestInstant(int slotIndex, {DateTime? nowUtc}) {
    if (slotIndex < 0 || slotIndex >= _chests.length) return false;
    final chest = _chests[slotIndex];
    if (chest.getState(nowUtc: nowUtc) != ChestState.unlocking) return false;

    if (_tickets < ChestSlotModel.instantTicketCost) {
      return false;
    }

    _tickets -= ChestSlotModel.instantTicketCost;
    _chests[slotIndex] = ChestSlotModel(
      slotIndex: slotIndex,
      id: chest.id,
      rarity: chest.rarity,
      unlockStartedAtUtc: DateTime.now().toUtc().subtract(Duration(seconds: chest.durationSeconds + 10)),
      durationSeconds: chest.durationSeconds,
      isOpened: false,
    );

    notifyListeners();
    save();
    return true;
  }

  /// Reclama la recompensa del cofre (entre 50 y 2500 monedas + XP) y vacía el slot.
  int? claimChestReward(int slotIndex, {DateTime? nowUtc}) {
    if (slotIndex < 0 || slotIndex >= _chests.length) return null;
    final chest = _chests[slotIndex];
    if (chest.getState(nowUtc: nowUtc) != ChestState.ready) return null;

    final coinsReward = chest.generateRewardCoins();
    final xpReward = chest.generateRewardXp();

    _coins += coinsReward;
    _addXpInternal(xpReward);

    _chests[slotIndex] = ChestSlotModel.empty(slotIndex);
    notifyListeners();
    save();
    return coinsReward;
  }

  // --- SERIALIZACIÓN JSON Y PERSISTENCIA ---

  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'name': _name,
      'avatarIndex': _avatarIndex,
      'selectedFrameId': _selectedFrameId,
      'selectedThemeId': _selectedThemeId,
      'coins': _coins,
      'tickets': _tickets,
      'maxTickets': _maxTickets,
      'xp': _xp,
      'level': _level,
      'lastTicketRegen': _lastTicketRegen.toIso8601String(),
      'hasCompletedTutorial': _hasCompletedTutorial,
      'isFirstTime': _isFirstTime,
      'chests': _chests.map((c) => c.toJson()).toList(),
    };
  }

  factory PlayerSession.fromJson(Map<String, dynamic> json) {
    final parsedMaxTickets = json['maxTickets'] as int? ?? defaultMaxTickets;
    final parsedTickets = (json['tickets'] as int? ?? defaultMaxTickets).clamp(0, parsedMaxTickets);
    final regenString = json['lastTicketRegen'] as String?;
    final parsedRegen = regenString != null
        ? DateTime.tryParse(regenString)?.toUtc() ?? DateTime.now().toUtc()
        : DateTime.now().toUtc();

    List<ChestSlotModel> parsedChests = List.generate(4, (i) => ChestSlotModel.empty(i));
    if (json['chests'] is List) {
      final list = json['chests'] as List;
      parsedChests = List.generate(4, (i) {
        if (i < list.length && list[i] is Map<String, dynamic>) {
          return ChestSlotModel.fromJson(list[i] as Map<String, dynamic>);
        }
        return ChestSlotModel.empty(i);
      });
    }

    return PlayerSession(
      id: json['id'] as String? ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Eizy',
      avatarIndex: json['avatarIndex'] as int? ?? 2,
      selectedFrameId: json['selectedFrameId'] as String? ?? 'wood',
      selectedThemeId: json['selectedThemeId'] as String? ?? 'royal_blue',
      coins: json['coins'] as int? ?? 0,
      tickets: parsedTickets,
      maxTickets: parsedMaxTickets,
      xp: json['xp'] as int? ?? 0,
      level: json['level'] as int? ?? 0,
      lastTicketRegen: parsedRegen,
      hasCompletedTutorial: json['hasCompletedTutorial'] as bool? ?? false,
      isFirstTime: json['isFirstTime'] as bool? ?? false,
      chests: parsedChests,
    );
  }

  /// Guarda el estado actual de la sesión en SharedPreferences.
  Future<void> save({SharedPreferences? prefs}) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final jsonString = jsonEncode(toJson());
      await p.setString(storageKey, jsonString);
    } catch (_) {}
  }

  /// Carga la sesión del jugador desde SharedPreferences.
  /// Si no existe, crea una nueva sesión por defecto para novatos (0 monedas, 3 tickets).
  /// Realiza la regeneración pasiva de tickets offline inmediatamente al cargar.
  static Future<PlayerSession> load({SharedPreferences? prefs, DateTime? nowUtc}) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final raw = p.getString(storageKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
        final session = PlayerSession.fromJson(decoded);
        session.regenerateTicketsPassive(nowUtc: nowUtc);
        _shared = session;
        return session;
      }
    } catch (_) {}

    // Si no hay datos guardados o hubo un error, inicializar por defecto para novatos
    final newSession = PlayerSession.createDefault(
      coins: 0,
      tickets: defaultMaxTickets,
      hasCompletedTutorial: false,
      isFirstTime: true,
    );
    await newSession.save(prefs: prefs);
    _shared = newSession;
    return newSession;
  }

  /// Elimina los datos de sesión almacenados (útil para pruebas o reinicio total).
  static Future<void> clear({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.remove(storageKey);
  }
}
