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
      builder: (_) => const TableCantoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF38BDF8), width: 1),
              ),
              child: const Icon(Icons.record_voice_over_rounded, color: Color(0xFF38BDF8), size: 28),
            ),
            const SizedBox(height: 12),
            const Text(
              '¡ERES EL REPARTIDOR!',
              style: TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Elige tu Canto de Mesa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Se colocarán 4 cartas en la mesa. Si el valor coincide con el número cantado, sumas el valor de la carta.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 18),
            // Opción Ascendente
            _buildOptionButton(
              context: context,
              direction: DealDirection.ascending,
              title: 'Ascendente',
              sequence: '1 → 2 → 3 → 4',
              color: const Color(0xFF10B981),
              icon: Icons.arrow_upward_rounded,
            ),
            const SizedBox(height: 10),
            // Opción Descendente
            _buildOptionButton(
              context: context,
              direction: DealDirection.descending,
              title: 'Descendente',
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
    required String title,
    required String sequence,
    required Color color,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(direction),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
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
