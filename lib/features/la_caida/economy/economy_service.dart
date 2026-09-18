import 'package:flutter/foundation.dart';

/// Datos inmutables de la economía del jugador.
class EconomyBalance {
  final int coins;
  final int tickets;
  final int diamonds;

  const EconomyBalance({
    required this.coins,
    required this.tickets,
    required this.diamonds,
  });

  EconomyBalance copyWith({
    int? coins,
    int? tickets,
    int? diamonds,
  }) {
    return EconomyBalance(
      coins: coins ?? this.coins,
      tickets: tickets ?? this.tickets,
      diamonds: diamonds ?? this.diamonds,
    );
  }
}

/// Servicio singleton reactivo para gestionar el balance de monedas, tickets y diamantes.
class EconomyService extends ChangeNotifier {
  static final EconomyService _instance = EconomyService._internal();
  factory EconomyService() => _instance;

  EconomyService._internal();

  EconomyBalance _balance = const EconomyBalance(
    coins: 6000,
    tickets: 10,
    diamonds: 50,
  );

  EconomyBalance get balance => _balance;
  int get coins => _balance.coins;
  int get tickets => _balance.tickets;
  int get diamonds => _balance.diamonds;

  bool canAfford({int costCoins = 0, int costTickets = 0, int costDiamonds = 0}) {
    return _balance.coins >= costCoins &&
        _balance.tickets >= costTickets &&
        _balance.diamonds >= costDiamonds;
  }

  bool payEntryFee({int costCoins = 0, int costTickets = 1}) {
    if (!canAfford(costCoins: costCoins, costTickets: costTickets)) {
      return false;
    }
    _balance = _balance.copyWith(
      coins: _balance.coins - costCoins,
      tickets: _balance.tickets - costTickets,
    );
    notifyListeners();
    return true;
  }

  void awardVictory({int rewardCoins = 500, int rewardDiamonds = 5}) {
    _balance = _balance.copyWith(
      coins: _balance.coins + rewardCoins,
      diamonds: _balance.diamonds + rewardDiamonds,
    );
    notifyListeners();
  }

  void addCoins(int amount) {
    if (amount <= 0) return;
    _balance = _balance.copyWith(coins: _balance.coins + amount);
    notifyListeners();
  }

  void addTickets(int amount) {
    if (amount <= 0) return;
    _balance = _balance.copyWith(tickets: (_balance.tickets + amount).clamp(0, 50));
    notifyListeners();
  }

  void addDiamonds(int amount) {
    if (amount <= 0) return;
    _balance = _balance.copyWith(diamonds: _balance.diamonds + amount);
    notifyListeners();
  }

  void resetToDefault() {
    _balance = const EconomyBalance(
      coins: 6000,
      tickets: 10,
      diamonds: 50,
    );
    notifyListeners();
  }
}
