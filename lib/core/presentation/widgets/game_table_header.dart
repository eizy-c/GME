import 'package:flutter/material.dart';

/// Barra superior de navegación para mesas de juegos tradicionales.
/// Incluye degradado púrpura oscuro, botón de regreso, menú de reglas, trofeos/monedas y latencia.
class GameTableHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onOpenRules;
  final VoidCallback? onSettings;
  final int trophies;
  final int pingMs;
  final bool showPing;
  final int? playerLevel;

  const GameTableHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.onOpenRules,
    this.onSettings,
    this.trophies = 7500,
    this.pingMs = 60,
    this.showPing = false,
    this.playerLevel,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF381F78), Color(0xFF231252)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: const Border(
          bottom: BorderSide(color: Color(0xFF5533A8), width: 1.2),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Botón Atrás
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
              tooltip: 'Salir al menú',
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            const SizedBox(width: 4),

            // Botón Menú de reglas estilo cajón redondeado
            if (onOpenRules != null)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4A2B99),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6B42DC), width: 1),
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                  tooltip: 'Reglas y Guía',
                  onPressed: onOpenRules,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
            const SizedBox(width: 10),

            // Título breve o logo
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),

            // Indicador de Latencia / Ping (solo en partidas online o red local)
            if (showPing)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${pingMs}ms',
                      style: const TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.signal_cellular_alt_rounded, color: Color(0xFF4ADE80), size: 13),
                  ],
                ),
              ),

            // Indicador de Nivel del Jugador (si está presente)
            if (playerLevel != null) ...[
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2DD4BF), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFFFDE047), size: 14),
                    const SizedBox(width: 3),
                    Text(
                      'Nv. $playerLevel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Píldora de Trofeos / Puntos
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF261358),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF7C4DFF), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 16),
                  const SizedBox(width: 5),
                  Text(
                    _formatNumber(trophies),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      final k = number / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}k';
    }
    return number.toString();
  }
}
