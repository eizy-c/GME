import 'package:flutter/foundation.dart';

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

/// Servicio singleton reactivo para gestionar el perfil, monedas y tickets del usuario.
class UserProfileService extends ChangeNotifier {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;

  UserProfileService._internal();

  UserProfileData _profile = const UserProfileData(
    name: 'Eizy',
    avatarId: 2, // Avatar inicial de chico con lentes
    coins: 6000,
    tickets: 10,
    isFirstTime: true,
  );

  UserProfileData get profile => _profile;
  String get name => _profile.name;
  int get avatarId => _profile.avatarId;
  int get coins => _profile.coins;
  int get tickets => _profile.tickets;
  bool get isFirstTime => _profile.isFirstTime;

  void updateProfile({String? name, int? avatarId}) {
    _profile = _profile.copyWith(
      name: name?.trim().isNotEmpty == true ? name!.trim() : _profile.name,
      avatarId: avatarId ?? _profile.avatarId,
      isFirstTime: false,
    );
    notifyListeners();
  }

  void markNotFirstTime() {
    if (_profile.isFirstTime) {
      _profile = _profile.copyWith(isFirstTime: false);
      notifyListeners();
    }
  }

  bool useTicket() {
    if (_profile.tickets > 0) {
      _profile = _profile.copyWith(tickets: _profile.tickets - 1);
      notifyListeners();
      return true;
    }
    return false;
  }

  void addCoins(int amount) {
    _profile = _profile.copyWith(coins: _profile.coins + amount);
    notifyListeners();
  }

  void addTickets(int amount) {
    _profile = _profile.copyWith(tickets: (_profile.tickets + amount).clamp(0, 10));
    notifyListeners();
  }

  void resetToDefault() {
    _profile = const UserProfileData(
      name: 'Eizy',
      avatarId: 2,
      coins: 6000,
      tickets: 10,
      isFirstTime: true,
    );
    notifyListeners();
  }
}
