import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../rules/game_rules_data.dart';

/// Diálogo modal estilizado con las reglas, preparación y estrategias de un juego.
/// Se presenta centrado en pantalla, con límites adaptativos y botón de cierre claro.
class GameRulesDialog extends StatelessWidget {
  final GameRules rules;

  const GameRulesDialog({super.key, required this.rules});

  /// Método estático conveniente para desplegar las reglas desde cualquier botón o pantalla.
  static void show(BuildContext context, String gameId) {
    final rules = GameRulesData.getRules(gameId);
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => GameRulesDialog(rules: rules),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxDialogHeight = screenSize.height * 0.82;
    final maxDialogWidth = math.min(screenSize.width * 0.90, 560.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: maxDialogWidth,
        constraints: BoxConstraints(
          maxHeight: maxDialogHeight,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 2,
            ),
            const BoxShadow(
              color: Colors.black87,
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabecera fija
              _buildHeader(context),
              const Divider(color: Colors.white12, height: 1),

              // Contenido desplazable con scrollbar
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      // Insignia de jugadores
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFF38BDF8)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  rules.playersCount,
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                // Objetivo
                _buildSectionCard(
                  icon: Icons.flag_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Objetivo del Juego',
                  content: Text(
                    rules.objective,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                  ),
                ),
                const SizedBox(height: 14),

                // Preparación
                _buildSectionCard(
                  icon: Icons.dashboard_customize_rounded,
                  iconColor: const Color(0xFF38BDF8),
                  title: 'Preparación y Reparto',
                  content: Column(
                    children: rules.setup
                        .map((item) => _buildBulletPoint(item, const Color(0xFF38BDF8)))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Paso a paso
                _buildSectionCard(
                  icon: Icons.play_arrow_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: '¿Cómo se Juega? (Paso a Paso)',
                  content: Column(
                    children: rules.steps
                        .asMap()
                        .entries
                        .map((entry) => _buildStepItem(entry.key + 1, entry.value))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Reglas especiales
                if (rules.specialRules.isNotEmpty) ...[
                  _buildSectionCard(
                    icon: Icons.bolt_rounded,
                    iconColor: const Color(0xFFEC4899),
                    title: 'Reglas Especiales y Cantos',
                    content: Column(
                      children: rules.specialRules
                          .map((item) => _buildBulletPoint(item, const Color(0xFFEC4899)))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Consejos
                if (rules.proTips.isNotEmpty) ...[
                  _buildSectionCard(
                    icon: Icons.lightbulb_rounded,
                    iconColor: const Color(0xFFFDE047),
                    title: 'Consejos y Estrategia Pro',
                    content: Column(
                      children: rules.proTips
                          .map((item) => _buildBulletPoint(item, const Color(0xFFFDE047)))
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // Pie de acción fijo
        const Divider(color: Colors.white12, height: 1),
        _buildFooter(context),
      ],
    ),
  ),
),
);
}

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      color: const Color(0xFF131F33),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF38BDF8), width: 1),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Color(0xFF38BDF8), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rules.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  rules.subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            tooltip: 'Cerrar',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      color: const Color(0xFF131F33),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_rounded, size: 18),
          label: const Text(
            '¡Entendido, vamos a jugar!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF162235),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepNumber, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1),
            ),
            child: Text(
              '$stepNumber',
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
