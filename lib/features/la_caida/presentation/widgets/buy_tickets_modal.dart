import 'dart:async';
import 'package:flutter/material.dart';
import '../../economy/player_session.dart';

/// Modal de Tienda de Tickets para partidas normales / casuales de La Caída.
/// Ofrece recarga gratuita mediante video y compra individual o en paquetes con monedas blandas.
class BuyTicketsModal extends StatefulWidget {
  final PlayerSession session;

  const BuyTicketsModal({
    super.key,
    required this.session,
  });

  /// Muestra el modal en un bottom sheet estilizado de alta gama.
  static Future<void> show(
    BuildContext context, {
    required PlayerSession session,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BuyTicketsModal(session: session),
    );
  }

  @override
  State<BuyTicketsModal> createState() => _BuyTicketsModalState();
}

class _BuyTicketsModalState extends State<BuyTicketsModal> {
  String? _feedbackMessage;
  Color _feedbackColor = const Color(0xFF10B981);
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _showFeedback(String message, {bool isError = false}) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedbackMessage = message;
      _feedbackColor = isError ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    });

    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _feedbackMessage = null);
      }
    });
  }

  void _claimAdTicket() {
    final success = widget.session.claimAdTicketReward();
    if (success) {
      _showFeedback('¡+1 Ticket obtenido viendo el video!');
    } else {
      _showFeedback('Ya tienes el máximo de tickets disponibles (10/10).', isError: true);
    }
  }

  void _buySingleTicket() {
    final success = widget.session.buyTicketsWithCoins(1);
    if (success) {
      _showFeedback('¡Compraste 1 Ticket por 400 monedas!');
    } else {
      if (widget.session.coins < 400) {
        _showFeedback('Monedas insuficientes (necesitas 400 monedas).', isError: true);
      } else {
        _showFeedback('Ya tienes el máximo de tickets disponibles.', isError: true);
      }
    }
  }

  void _buyFivePack() {
    final success = widget.session.buyTicketsWithCoins(5, customCoinCost: 1800);
    if (success) {
      _showFeedback('¡Paquete de 5 Tickets adquirido por 1,800 monedas!');
    } else {
      if (widget.session.coins < 1800) {
        _showFeedback('Monedas insuficientes (necesitas 1,800 monedas).', isError: true);
      } else {
        _showFeedback('Ya tienes el máximo de tickets disponibles.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final session = widget.session;
        final isMaxTickets = session.tickets >= session.maxTickets;

        return SafeArea(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF201335), Color(0xFF0F071A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: const Color(0xFF9333EA), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 25,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tirador superior para arrastre
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Encabezado con título, saldo y botón cerrar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9333EA).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFC084FC), width: 1.2),
                            ),
                            child: const Icon(
                              Icons.confirmation_num_rounded,
                              color: Color(0xFFFDE047),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TIENDA DE TICKETS',
                                  style: TextStyle(
                                    color: Color(0xFFFDE047),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  'Pases de Juego',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Contador de monedas del jugador
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B4B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded, size: 14, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 5),
                          Text(
                            '${session.coins}',
                            style: const TextStyle(
                              color: Color(0xFFFDE047),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Barra de energía / tickets actuales
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A102E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'TICKETS DISPONIBLES',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${session.tickets} / ${session.maxTickets}',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.confirmation_num_rounded, color: Color(0xFF38BDF8), size: 16),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: session.tickets / session.maxTickets,
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isMaxTickets
                                ? const Color(0xFF10B981)
                                : const Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isMaxTickets ? Icons.bolt_rounded : Icons.timer_outlined,
                                  size: 13,
                                  color: isMaxTickets ? const Color(0xFF10B981) : Colors.white54,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    isMaxTickets
                                        ? '¡Energía al 100%!'
                                        : '1 ticket cada 20 min',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isMaxTickets) ...[
                            const SizedBox(width: 8),
                            const Text(
                              'Activa',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                if (_feedbackMessage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _feedbackColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _feedbackColor, width: 1),
                    ),
                    child: Text(
                      _feedbackMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _feedbackColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // OPCIÓN 1: Ver Video (+1 Gratis)
                _buildOptionCard(
                  icon: Icons.play_circle_fill_rounded,
                  iconColor: const Color(0xFF34D399),
                  badgeText: 'GRATIS',
                  badgeColor: const Color(0xFF059669),
                  title: 'Ver Video Corto',
                  subtitle: '+1 Ticket de acceso inmediato',
                  priceLabel: 'Ver Video',
                  isPriceCoin: false,
                  isEnabled: !isMaxTickets,
                  disabledLabel: 'LLENO (10/10)',
                  onTap: _claimAdTicket,
                ),

                const SizedBox(height: 10),

                // OPCIÓN 2: 1 Ticket por 400 Monedas
                _buildOptionCard(
                  icon: Icons.confirmation_num_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Pase Individual (1x)',
                  subtitle: '+1 Ticket para juego casual',
                  priceLabel: '400',
                  isPriceCoin: true,
                  isEnabled: !isMaxTickets && session.coins >= 400,
                  disabledLabel: session.coins < 400 ? 'SIN MONEDAS' : 'LLENO',
                  onTap: _buySingleTicket,
                ),

                const SizedBox(height: 10),

                // OPCIÓN 3: Paquete de 5 Tickets por 1,800 Monedas (Descuento)
                _buildOptionCard(
                  icon: Icons.local_activity_rounded,
                  iconColor: const Color(0xFFFDE047),
                  badgeText: 'AHORRA 10%',
                  badgeColor: const Color(0xFFD97706),
                  title: 'Paquete Aventurero (5x)',
                  subtitle: '+5 Tickets (200 monedas de ahorro)',
                  priceLabel: '1,800',
                  oldPriceLabel: '2,000',
                  isPriceCoin: true,
                  isEnabled: !isMaxTickets && session.coins >= 1800,
                  disabledLabel: session.coins < 1800 ? 'SIN MONEDAS' : 'LLENO',
                  onTap: _buyFivePack,
                  isHighlighted: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String priceLabel,
    String? oldPriceLabel,
    String? badgeText,
    Color? badgeColor,
    required bool isPriceCoin,
    required bool isEnabled,
    String? disabledLabel,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFF2E1948)
            : const Color(0xFF19102B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFFC084FC)
              : Colors.white12,
          width: isHighlighted ? 1.5 : 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Icono temático
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.4), width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),

          // Títulos y badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: badgeColor ?? const Color(0xFFD97706),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              badgeText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        subtitle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    if (oldPriceLabel != null) ...[
                      const SizedBox(width: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded, size: 10, color: Colors.white38),
                          const SizedBox(width: 2),
                          Text(
                            oldPriceLabel,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9.5,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Botón de acción interactivo
          ElevatedButton(
            onPressed: isEnabled ? onTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled
                  ? (isHighlighted ? const Color(0xFF9333EA) : const Color(0xFF2563EB))
                  : Colors.white10,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white38,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: isEnabled ? 2 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEnabled && isPriceCoin) ...[
                  const Icon(Icons.monetization_on_rounded, size: 12, color: Color(0xFFFDE047)),
                  const SizedBox(width: 3),
                ],
                Text(
                  isEnabled ? priceLabel : (disabledLabel ?? 'NO DISP.'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isEnabled ? Colors.white : Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
