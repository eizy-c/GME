import 'package:flutter/material.dart';

/// Tipos de mesas VIP disponibles para apuestas con moneda virtual.
enum VipTierType {
  taberna,
  clubPrivado,
  granCasino,
  highRoller,
}

/// Modelo inmutable que representa una sala/mesa de apuestas VIP predefinida.
/// Implementa reglas financieras exactas (comisión del 8% de la casa) tanto para 1v1 como para Parejas (4P).
class VipTierOffer {
  static const double houseFeeRate = 0.08; // 8% retenido por la casa

  final VipTierType type;
  final String name;
  final String subtitle;
  final int entryFee;
  final int minPlayerLevel;
  final Color primaryColor;
  final Color accentColor;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData icon;

  const VipTierOffer({
    required this.type,
    required this.name,
    required this.subtitle,
    required this.entryFee,
    required this.minPlayerLevel,
    required this.primaryColor,
    required this.accentColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.icon,
  });

  // --- CÁLCULOS FINANCIEROS 1v1 (2 JUGADORES) ---

  /// Pozo total acumulado en mesa de 2 jugadores (1v1).
  int get totalPot1v1 => entryFee * 2;

  /// Comisión retenida por la casa (8%) en 1v1.
  int get houseFee1v1 => (totalPot1v1 * houseFeeRate).round();

  /// Premio neto íntegro para el ganador en 1v1 (Pozo * 0.92).
  int get winnerPrize1v1 => (totalPot1v1 * (1.0 - houseFeeRate)).round();

  // --- CÁLCULOS FINANCIEROS EN PAREJAS (4 JUGADORES) ---

  /// Pozo total acumulado en mesa de 4 jugadores (Parejas).
  int get totalPotTeams => entryFee * 4;

  /// Comisión retenida por la casa (8%) en Parejas.
  int get houseFeeTeams => (totalPotTeams * houseFeeRate).round();

  /// Premio neto garantizado para cada uno de los 2 integrantes del equipo ganador ((Pozo * 0.92) / 2).
  int get winnerPrizePerPlayerTeams =>
      ((totalPotTeams * (1.0 - houseFeeRate)) / 2).round();

  // --- MÉTODOS DE CONSULTA DINÁMICA ---

  /// Pozo total calculado en función de la modalidad activa (1v1 o Parejas).
  int getTotalPot({required bool isTeams}) => isTeams ? totalPotTeams : totalPot1v1;

  /// Alias de cálculo de pozo total.
  int calculatePrizePool({required bool isTeams}) => getTotalPot(isTeams: isTeams);

  /// Premio neto a recibir por jugador ganador en función de la modalidad activa.
  int getNetPrize({required bool isTeams}) =>
      isTeams ? winnerPrizePerPlayerTeams : winnerPrize1v1;

  /// Alias de cálculo de premio neto.
  int calculateNetPrizePerWinner({required bool isTeams}) => getNetPrize(isTeams: isTeams);

  /// Determina si la mesa está desbloqueada según el nivel actual del jugador.
  bool isUnlockedFor(int playerLevel) => playerLevel >= minPlayerLevel;

  /// Determina si el jugador cuenta con saldo suficiente de monedas para la entrada.
  bool canAfford(int playerCoins) => playerCoins >= entryFee;

  // --- CATÁLOGO PREDEFINIDO DE TIERS VIP ---

  /// Los 4 tiers VIP oficiales para La Caída:
  /// 1. Taberna (Bronce) • Entrada 🪙 250 | Nivel mín: 1
  /// 2. Club Privado (Plata) • Entrada 🪙 1,000 | Nivel mín: 2
  /// 3. Gran Casino (Oro) • Entrada 🪙 5,000 | Nivel mín: 4
  /// 4. High Roller (Diamante) • Entrada 🪙 20,000 | Nivel mín: 8
  static const List<VipTierOffer> tiers = [
    VipTierOffer(
      type: VipTierType.taberna,
      name: 'Taberna',
      subtitle: 'Bronce • Apuestas iniciales',
      entryFee: 250,
      minPlayerLevel: 1,
      primaryColor: Color(0xFFCD7F32), // Bronce
      accentColor: Color(0xFFF59E0B),
      gradientStart: Color(0xFF2E1C12),
      gradientEnd: Color(0xFF140B06),
      icon: Icons.shield_rounded,
    ),
    VipTierOffer(
      type: VipTierType.clubPrivado,
      name: 'Club Privado',
      subtitle: 'Plata • Nivel experimentado',
      entryFee: 1000,
      minPlayerLevel: 2,
      primaryColor: Color(0xFFC0C0C0), // Plata
      accentColor: Color(0xFFE2E8F0),
      gradientStart: Color(0xFF1E293B),
      gradientEnd: Color(0xFF0F172A),
      icon: Icons.military_tech_rounded,
    ),
    VipTierOffer(
      type: VipTierType.granCasino,
      name: 'Gran Casino',
      subtitle: 'Oro • Gran apuesta y prestigio',
      entryFee: 5000,
      minPlayerLevel: 4,
      primaryColor: Color(0xFFFFD700), // Oro
      accentColor: Color(0xFFFDE047),
      gradientStart: Color(0xFF451A03),
      gradientEnd: Color(0xFF1A0A01),
      icon: Icons.workspace_premium_rounded,
    ),
    VipTierOffer(
      type: VipTierType.highRoller,
      name: 'High Roller',
      subtitle: 'Diamante • Duelo de Maestros',
      entryFee: 20000,
      minPlayerLevel: 8,
      primaryColor: Color(0xFF38BDF8), // Diamante Cyan
      accentColor: Color(0xFF7DD3FC),
      gradientStart: Color(0xFF0C4A6E),
      gradientEnd: Color(0xFF031E30),
      icon: Icons.diamond_rounded,
    ),
  ];
}
