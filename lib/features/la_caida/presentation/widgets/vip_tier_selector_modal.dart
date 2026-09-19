import 'package:flutter/material.dart';
import '../../economy/player_session.dart';
import '../../economy/vip_tier.dart';

/// Modal interactivo para seleccionar y apostar en salas / mesas VIP de La Caída.
/// Incluye toggle entre 1v1 y Parejas (4P) con actualización en vivo de pozos y premios netos,
/// y un carrusel horizontal de tarjetas estilizadas por nivel y color temático.
class VipTierSelectorModal extends StatefulWidget {
  final PlayerSession session;
  final bool initialIsTeams;
  final void Function(VipTierOffer tier, bool isTeams)? onTierSelected;

  const VipTierSelectorModal({
    super.key,
    required this.session,
    this.initialIsTeams = false,
    this.onTierSelected,
  });

  /// Muestra el modal en un bottom sheet estilizado de alta gama.
  static Future<void> show(
    BuildContext context, {
    required PlayerSession session,
    bool initialIsTeams = false,
    void Function(VipTierOffer tier, bool isTeams)? onTierSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => VipTierSelectorModal(
        session: session,
        initialIsTeams: initialIsTeams,
        onTierSelected: onTierSelected,
      ),
    );
  }

  @override
  State<VipTierSelectorModal> createState() => _VipTierSelectorModalState();
}

class _VipTierSelectorModalState extends State<VipTierSelectorModal> {
  late bool _isTeams;

  @override
  void initState() {
    super.initState();
    _isTeams = widget.initialIsTeams;
  }

  void _onEnterTier(VipTierOffer tier) {
    if (!tier.isUnlockedFor(widget.session.level) || !tier.canAfford(widget.session.coins)) {
      return;
    }

    final success = widget.session.deductCoinsForVipMatch(tier.entryFee);
    if (!success) return;

    Navigator.pop(context);
    widget.onTierSelected?.call(tier, _isTeams);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final session = widget.session;

        return SafeArea(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1130), Color(0xFF0C0614)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: const Color(0xFFEAB308), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 30,
                  offset: Offset(0, -8),
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
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Encabezado con título, nivel y saldo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAB308).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFDE047), width: 1.2),
                            ),
                            child: const Icon(
                              Icons.stars_rounded,
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
                                  'PARTIDAS VIP',
                                  style: TextStyle(
                                    color: Color(0xFFFDE047),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  'Salas de Apuestas',
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

                    // Nivel y saldo actual del jugador
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B0764),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFA855F7), width: 1),
                          ),
                          child: Text(
                            'Nv. ${session.level}',
                            style: const TextStyle(
                              color: Color(0xFFE9D5FF),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1B4B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.monetization_on_rounded, size: 14, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 4),
                              Text(
                                '${session.coins}',
                                style: const TextStyle(
                                  color: Color(0xFFFDE047),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Pestañas Toggle: [ 1 vs 1 ] y [ Parejas (4P) ]
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF150B24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildModeToggle(
                          title: '1 vs 1',
                          subtitle: '2 Jugadores',
                          icon: Icons.flash_on_rounded,
                          isSelected: !_isTeams,
                          onTap: () => setState(() => _isTeams = false),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildModeToggle(
                          title: 'En Parejas',
                          subtitle: '4 Jugadores (2v2)',
                          icon: Icons.groups_rounded,
                          isSelected: _isTeams,
                          onTap: () => setState(() => _isTeams = true),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Carrusel horizontal de tarjetas de mesas VIP
                SizedBox(
                  height: 335,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: VipTierOffer.tiers.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(width: 14),
                    itemBuilder: (ctx, index) {
                      final tier = VipTierOffer.tiers[index];
                      return _buildTierCard(tier, session);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFC084FC) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.white38,
                      fontSize: 9.5,
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

  Widget _buildTierCard(VipTierOffer tier, PlayerSession session) {
    final isUnlocked = tier.isUnlockedFor(session.level);
    final canAfford = tier.canAfford(session.coins);
    final totalPot = tier.getTotalPot(isTeams: _isTeams);
    final netPrize = tier.getNetPrize(isTeams: _isTeams);

    return Container(
      width: 255,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tier.gradientStart, tier.gradientEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isUnlocked ? tier.primaryColor : Colors.white12,
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnlocked
                ? tier.primaryColor.withValues(alpha: 0.3)
                : Colors.black45,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header de la tarjeta: Icono del tier y badge de nivel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? tier.primaryColor.withValues(alpha: 0.2)
                      : Colors.white10,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnlocked ? tier.accentColor : Colors.white24,
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  isUnlocked ? tier.icon : Icons.lock_rounded,
                  color: isUnlocked ? tier.accentColor : Colors.white38,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUnlocked ? tier.primaryColor.withValues(alpha: 0.5) : Colors.white12,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isUnlocked) ...[
                      const Icon(Icons.lock_rounded, size: 10, color: Colors.white38),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      isUnlocked ? 'NIVEL ${tier.minPlayerLevel}+' : 'NV. ${tier.minPlayerLevel}',
                      style: TextStyle(
                        color: isUnlocked ? tier.accentColor : Colors.white38,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Nombre y subtítulo
          Text(
            tier.name,
            style: TextStyle(
              color: isUnlocked ? Colors.white : Colors.white54,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tier.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),

          const Spacer(),

          // Bloque financiero: Entrada, Pozo y Premio Neto
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10, width: 0.8),
            ),
            child: Column(
              children: [
                _buildFinanceRow('Entrada:', '${tier.entryFee}', isBold: false),
                const SizedBox(height: 4),
                _buildFinanceRow(
                  _isTeams ? 'Pozo (4P):' : 'Pozo (1v1):',
                  '$totalPot',
                  valueColor: const Color(0xFF38BDF8),
                ),
                const Divider(color: Colors.white12, height: 10),
                _buildFinanceRow(
                  _isTeams ? 'Premio Ganador (c/u):' : 'Premio Ganador:',
                  '$netPrize',
                  valueColor: const Color(0xFFFDE047),
                  isHighlight: true,
                ),
                const SizedBox(height: 2),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '8% comisión de mesa incluida',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Botón de acción directo
          _buildActionButton(tier, isUnlocked, canAfford),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(
    String label,
    String value, {
    Color valueColor = Colors.white,
    bool isBold = true,
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isHighlight ? 10.5 : 10,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monetization_on_rounded, size: isHighlight ? 13 : 11, color: const Color(0xFFFBBF24)),
            const SizedBox(width: 3),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: isHighlight ? 12.5 : 11,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(VipTierOffer tier, bool isUnlocked, bool canAfford) {
    String label;
    IconData? buttonIcon;
    Color buttonColor;
    bool isEnabled;

    if (!isUnlocked) {
      buttonIcon = Icons.lock_rounded;
      label = 'NIVEL ${tier.minPlayerLevel} REQUERIDO';
      buttonColor = Colors.white10;
      isEnabled = false;
    } else if (!canAfford) {
      buttonIcon = Icons.warning_amber_rounded;
      label = 'SIN SALDO (${tier.entryFee})';
      buttonColor = const Color(0xFF7F1D1D);
      isEnabled = false;
    } else {
      buttonIcon = Icons.play_arrow_rounded;
      label = 'ENTRAR (${tier.entryFee})';
      buttonColor = tier.primaryColor;
      isEnabled = true;
    }

    return ElevatedButton(
      onPressed: isEnabled ? () => _onEnterTier(tier) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: buttonColor,
        disabledForegroundColor: Colors.white38,
        padding: const EdgeInsets.symmetric(vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: isEnabled ? 3 : 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (buttonIcon != null) ...[
            Icon(buttonIcon, size: isEnabled ? 15 : 13, color: isEnabled ? Colors.white : Colors.white54),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isEnabled ? 11.5 : 10,
              fontWeight: FontWeight.w900,
              color: isEnabled ? Colors.white : Colors.white54,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
