import 'package:flutter/material.dart';
import '../../domain/caida_models.dart';

/// Diálogo modal para que el repartidor elija la dirección del Canto de Mesa:
/// Ascendente (1 -> 2 -> 3 -> 4) o Descendente (4 -> 3 -> 2 -> 1).
class TableCantoDialog extends StatelessWidget {
  const TableCantoDialog({super.key});

  static Future<DealDirection?> show(BuildContext context) {
    return showDialog<DealDirection>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.84),
      builder: (_) => const TableCantoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF38BDF8), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.5),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
              ),
              child: const Icon(Icons.record_voice_over_rounded, color: Color(0xFF38BDF8), size: 32),
            ),
            const SizedBox(height: 12),
            const Text(
              '¡ERES LA MANO!',
              style: TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '¿Desde dónde comienzas a contar?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Se repartirán las 4 cartas a la mesa. Elige si cantas desde el 1 hacia arriba o desde el 4 hacia abajo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 20),
            // Opción Comenzar en 1 (Ascendente)
            _buildOptionButton(
              context: context,
              direction: DealDirection.ascending,
              numberBadge: '1',
              title: 'Comenzar en 1 (Ascendente)',
              sequence: '1 → 2 → 3 → 4',
              color: const Color(0xFF10B981),
              icon: Icons.arrow_upward_rounded,
            ),
            const SizedBox(height: 12),
            // Opción Comenzar en 4 (Descendente)
            _buildOptionButton(
              context: context,
              direction: DealDirection.descending,
              numberBadge: '4',
              title: 'Comenzar en 4 (Descendente)',
              sequence: '4 → 3 → 2 → 1',
              color: const Color(0xFFF59E0B),
              icon: Icons.arrow_downward_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required DealDirection direction,
    required String numberBadge,
    required String title,
    required String sequence,
    required Color color,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(direction),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.8),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color, width: 1.2),
              ),
              child: Center(
                child: Text(
                  numberBadge,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    sequence,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
