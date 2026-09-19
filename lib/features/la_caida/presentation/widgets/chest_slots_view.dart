import 'dart:async';
import 'package:flutter/material.dart';
import '../../economy/chest_slot_model.dart';
import '../../economy/player_session.dart';
import '../../../../core/presentation/widgets/app_3d_button.dart';

/// Widget interactivo para la barra de 4 slots de cofres de recompensa en la parte inferior del lobby.
class ChestSlotsView extends StatefulWidget {
  final PlayerSession session;
  final Function(int coinsEarned)? onChestClaimed;

  const ChestSlotsView({
    super.key,
    required this.session,
    this.onChestClaimed,
  });

  @override
  State<ChestSlotsView> createState() => _ChestSlotsViewState();
}

class _ChestSlotsViewState extends State<ChestSlotsView> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _onSlotTapped(ChestSlotModel chest) {
    final state = chest.getState();
    if (state == ChestState.empty) {
      _showEmptySlotInfo();
    } else if (state == ChestState.ready) {
      _claimReward(chest.slotIndex);
    } else if (state == ChestState.unlocking) {
      _showSpeedUpDialog(chest);
    }
  }

  void _showEmptySlotInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFDE047), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: Color(0xFFFDE047)),
            SizedBox(width: 8),
            Text('Ranura de Cofre', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Gana una partida en CaidaGO para recibir un nuevo cofre con entre 50 y 2500 monedas y XP.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          App3dButton(
            label: 'Entendido',
            variant: App3dButtonVariant.gold,
            depth: 3.5,
            borderRadius: 10,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _claimReward(int slotIndex) {
    final coins = widget.session.claimChestReward(slotIndex);
    if (coins != null) {
      widget.onChestClaimed?.call(coins);
      _showClaimRewardDialog(coins);
    }
  }

  void _showClaimRewardDialog(int coins) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFDE047), width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFFFDE047), size: 56),
              const SizedBox(height: 12),
              const Text(
                '¡COFRE RECLAMADO!',
                style: TextStyle(
                  color: Color(0xFFFDE047),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCA8A04), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFFFDE047), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '+$coins Monedas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '+ Experiencia (XP) para subir de nivel',
                style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              App3dButton(
                label: '¡EXCELENTE!',
                variant: App3dButtonVariant.emerald,
                depth: 4.0,
                expand: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpeedUpDialog(ChestSlotModel chest) {
    final remainingStr = chest.getFormattedRemainingTime();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Color(0xFF38BDF8)),
            SizedBox(width: 8),
            Text('Abriendo Cofre', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tiempo restante: $remainingStr',
              style: const TextStyle(color: Color(0xFFFDE047), fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '¿Deseas acelerar la apertura de inmediato usando 2 Tickets?',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Esperar', style: TextStyle(color: Colors.white54)),
          ),
          App3dButton.icon(
            icon: Icons.confirmation_number_rounded,
            label: 'Abrir ya (2 Tickets)',
            variant: App3dButtonVariant.cyan,
            depth: 3.5,
            borderRadius: 10,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            onPressed: () {
              Navigator.of(context).pop();
              final success = widget.session.unlockChestInstant(chest.slotIndex);
              if (success) {
                _claimReward(chest.slotIndex);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No tienes suficientes tickets (se requieren 2 tickets).'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chests = widget.session.chests;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (i) {
          final chest = i < chests.length ? chests[i] : ChestSlotModel.empty(i);
          return _buildChestSlot(chest);
        }),
      ),
    );
  }

  Widget _buildChestSlot(ChestSlotModel chest) {
    final state = chest.getState();

    Color borderColor;
    Color bgColor;
    Widget centerContent;

    switch (state) {
      case ChestState.empty:
        borderColor = Colors.white24;
        bgColor = const Color(0xFF1E293B).withValues(alpha: 0.5);
        centerContent = const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, color: Colors.white30, size: 22),
            SizedBox(height: 2),
            Text('Cofre', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        );
        break;
      case ChestState.unlocking:
        borderColor = const Color(0xFF38BDF8);
        bgColor = const Color(0xFF1E1B4B);
        final rem = chest.getFormattedRemainingTime();
        centerContent = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.archive_rounded, color: Color(0xFF38BDF8), size: 22),
            const SizedBox(height: 2),
            Text(
              rem,
              style: const TextStyle(
                color: Color(0xFFFDE047),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        );
        break;
      case ChestState.ready:
        borderColor = const Color(0xFFFDE047);
        bgColor = const Color(0xFF78350F).withValues(alpha: 0.85);
        centerContent = const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard_rounded, color: Color(0xFFFDE047), size: 24),
            SizedBox(height: 2),
            Text(
              '¡ABRIR!',
              style: TextStyle(
                color: Color(0xFFFDE047),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        );
        break;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => _onSlotTapped(chest),
        child: Container(
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              if (state == ChestState.ready)
                BoxShadow(
                  color: const Color(0xFFFDE047).withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: centerContent,
        ),
      ),
    );
  }
}
