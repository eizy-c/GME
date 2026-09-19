import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de datos del perfil del jugador.
class UserProfileData {
  final String name;
  final int avatarId;
  final int coins;
  final int tickets;
  final bool isFirstTime;

  const UserProfileData({
    required this.name,
    required this.avatarId,
    required this.coins,
    required this.tickets,
    required this.isFirstTime,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'avatarId': avatarId,
        'coins': coins,
        'tickets': tickets,
        'isFirstTime': isFirstTime,
      };

  factory UserProfileData.fromJson(Map<String, dynamic> json) => UserProfileData(
        name: json['name'] as String? ?? 'Jugador',
        avatarId: json['avatarId'] as int? ?? 2,
        coins: json['coins'] as int? ?? 0,
        tickets: json['tickets'] as int? ?? 3,
        isFirstTime: json['isFirstTime'] as bool? ?? false,
      );

  UserProfileData copyWith({
    String? name,
    int? avatarId,
    int? coins,
    int? tickets,
    bool? isFirstTime,
  }) {
    return UserProfileData(
      name: name ?? this.name,
      avatarId: avatarId ?? this.avatarId,
      coins: coins ?? this.coins,
      tickets: tickets ?? this.tickets,
      isFirstTime: isFirstTime ?? this.isFirstTime,
    );
  }
}

/// Servicio singleton reactivo para gestionar el perfil, monedas y tickets del usuario con persistencia en disco.
class UserProfileService extends ChangeNotifier {
  static const String _storageKey = 'user_profile_data_v1';
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;

  UserProfileService._internal();

  UserProfileData _profile = const UserProfileData(
    name: 'Jugador',
    avatarId: 2, // Avatar inicial de chico con lentes
    coins: 0,
    tickets: 3,
    isFirstTime: true,
  );

  UserProfileData get profile => _profile;
  String get name => _profile.name;
  int get avatarId => _profile.avatarId;
  int get coins => _profile.coins;
  int get tickets => _profile.tickets;
  bool get isFirstTime => _profile.isFirstTime;

  /// Carga el perfil persistido desde SharedPreferences.
  Future<void> load({SharedPreferences? prefs}) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final raw = p.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _profile = UserProfileData.fromJson(decoded);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Guarda el perfil actual en SharedPreferences de forma segura.
  void save({SharedPreferences? prefs}) {
    if (prefs != null) {
      prefs.setString(_storageKey, jsonEncode(_profile.toJson())).catchError((_) => false);
      return;
    }
    SharedPreferences.getInstance().then((p) {
      p.setString(_storageKey, jsonEncode(_profile.toJson())).catchError((_) => false);
    }).catchError((_) {});
  }

  void updateProfile({String? name, int? avatarId}) {
    _profile = _profile.copyWith(
      name: name?.trim().isNotEmpty == true ? name!.trim() : _profile.name,
      avatarId: avatarId ?? _profile.avatarId,
      isFirstTime: false,
    );
    notifyListeners();
    save();
  }

  void markNotFirstTime() {
    if (_profile.isFirstTime) {
      _profile = _profile.copyWith(isFirstTime: false);
      notifyListeners();
      save();
    }
  }

  bool useTicket() {
    if (_profile.tickets > 0) {
      _profile = _profile.copyWith(tickets: _profile.tickets - 1);
      notifyListeners();
      save();
      return true;
    }
    return false;
  }

  void addCoins(int amount) {
    _profile = _profile.copyWith(coins: _profile.coins + amount);
    notifyListeners();
    save();
  }

  void addTickets(int amount) {
    _profile = _profile.copyWith(tickets: (_profile.tickets + amount).clamp(0, 10));
    notifyListeners();
    save();
  }

  void resetToDefault() {
    _profile = const UserProfileData(
      name: 'Jugador',
      avatarId: 2,
      coins: 6000,
      tickets: 10,
      isFirstTime: true,
    );
    notifyListeners();
  }
}
