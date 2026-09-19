import 'package:flutter/material.dart';

/// Objeto de Dominio que encapsula una oferta en la Tienda de Tickets.
class TicketShopOffer {
  final String id;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String priceLabel;
  final bool isPriceCoin;
  final int coinCost;
  final int ticketsGranted;
  final String? oldPriceLabel;
  final String? badgeText;
  final Color? badgeColor;
  final bool isHighlighted;
  final bool isAd;

  const TicketShopOffer({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    this.isPriceCoin = true,
    this.coinCost = 0,
    required this.ticketsGranted,
    this.oldPriceLabel,
    this.badgeText,
    this.badgeColor,
    this.isHighlighted = false,
    this.isAd = false,
  });

  /// Determina si el jugador puede costear la oferta con su saldo actual
  bool canAfford(int playerCoins) => isAd || playerCoins >= coinCost;

  /// Determina si la oferta está habilitada dadas las condiciones actuales
  bool isEnabled({required bool isMaxTickets, required int playerCoins}) {
    if (isMaxTickets) return false;
    return canAfford(playerCoins);
  }

  /// Etiqueta cuando el botón está deshabilitado
  String disabledLabel({required bool isMaxTickets, required int playerCoins}) {
    if (isMaxTickets) {
      return isAd ? 'LLENO (10/10)' : 'LLENO';
    }
    if (!canAfford(playerCoins)) {
      return 'SIN MONEDAS';
    }
    return 'NO DISP.';
  }

  /// Catálogo estándar de ofertas oficiales en la tienda de tickets
  static const List<TicketShopOffer> standardOffers = [
    // Opción 1: Ver Video (+1 Gratis)
    TicketShopOffer(
      id: 'ad_video_ticket',
      icon: Icons.play_circle_fill_rounded,
      iconColor: Color(0xFF34D399),
      badgeText: 'GRATIS',
      badgeColor: Color(0xFF059669),
      title: 'Ver Video Corto',
      subtitle: '+1 Ticket de acceso inmediato',
      priceLabel: 'Ver Video',
      isPriceCoin: false,
      coinCost: 0,
      ticketsGranted: 1,
      isAd: true,
    ),

    // Opción 2: 1 Ticket por 400 Monedas
    TicketShopOffer(
      id: 'single_ticket_400',
      icon: Icons.confirmation_num_rounded,
      iconColor: Color(0xFFF59E0B),
      title: 'Pase Individual (1x)',
      subtitle: '+1 Ticket para juego casual',
      priceLabel: '400',
      isPriceCoin: true,
      coinCost: 400,
      ticketsGranted: 1,
    ),

    // Opción 3: Paquete de 5 Tickets por 1,800 Monedas (Descuento)
    TicketShopOffer(
      id: 'pack_five_tickets_1800',
      icon: Icons.local_activity_rounded,
      iconColor: Color(0xFFFDE047),
      badgeText: 'AHORRA 10%',
      badgeColor: Color(0xFFD97706),
      title: 'Paquete Aventurero (5x)',
      subtitle: '+5 Tickets (200 monedas de ahorro)',
      priceLabel: '1,800',
      oldPriceLabel: '2,000',
      isPriceCoin: true,
      coinCost: 1800,
      ticketsGranted: 5,
      isHighlighted: true,
    ),
  ];
}
