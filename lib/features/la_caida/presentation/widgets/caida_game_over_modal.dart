import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../economy/player_session.dart';
import '../../economy/user_progress.dart';

/// Datos estadísticos de la partida jugada para el resumen final.
class CaidaMatchSummary {
  final bool userWon;
  final int userTeamScore;
  final int opponentTeamScore;
  final int userTeamCardsWon;
  final int opponentTeamCardsWon;
  final int caidasCount;
  final int limpiasCount;
  final int cantosCount;
  final int coinsWon;
  final int xpWon;
  final bool chestAwarded;
  final int? chestSlotIndex;
  final bool didLevelUp;
  final int initialLevel;
  final int finalLevel;
  final String? customSubtitle;
  final bool isTeams;

  const CaidaMatchSummary({
    required this.userWon,
    required this.userTeamScore,
    required this.opponentTeamScore,
    required this.userTeamCardsWon,
    required this.opponentTeamCardsWon,
    this.caidasCount = 0,
    this.limpiasCount = 0,
    this.cantosCount = 0,
    required this.coinsWon,
    required this.xpWon,
    this.chestAwarded = false,
    this.chestSlotIndex,
    this.didLevelUp = false,
    this.initialLevel = 0,
    this.finalLevel = 0,
    this.customSubtitle,
    this.isTeams = false,
  });
}

/// Modal enriquecido y animado de Fin de Partida para CaidaGO.
/// Presenta banner de victoria/derrota, entrega de cofre, barra de XP y nivel animada,
/// estadísticas de jugadas (Caídas, Limpias, Cantos) y botones de Revancha y Lobby.
class CaidaGameOverModal extends StatefulWidget {
  final CaidaMatchSummary summary;
  final VoidCallback onRematch;
  final VoidCallback onBackToMenu;

  const CaidaGameOverModal({
    super.key,
    required this.summary,
    required this.onRematch,
    required this.onBackToMenu,
  });

  static Future<void> show(
    BuildContext context, {
    required CaidaMatchSummary summary,
    required VoidCallback onRematch,
    required VoidCallback onBackToMenu,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'CaidaGameOverModal',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => CaidaGameOverModal(
        summary: summary,
        onRematch: onRematch,
        onBackToMenu: onBackToMenu,
      ),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  @override
  State<CaidaGameOverModal> createState() => _CaidaGameOverModalState();
}

class _CaidaGameOverModalState extends State<CaidaGameOverModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _xpProgressAnim;
  late Animation<double> _chestShineAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _xpProgressAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic),
    );

    _chestShineAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final isWin = summary.userWon;
    final session = PlayerSession.shared;
    final progress = UserProgress(totalXp: session.xp);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Caja Principal del Modal
          Container(
            constraints: const BoxConstraints(maxWidth: 420),
            margin: const EdgeInsets.only(top: 28),
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isWin
                    ? const [Color(0xFF1E143C), Color(0xFF0F0826), Color(0xFF080415)]
                    : const [Color(0xFF2D1515), Color(0xFF190B0B), Color(0xFF0F0404)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isWin ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isWin ? const Color(0xFFF59E0B) : const Color(0xFFEF4444))
                      .withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Subtítulo de evento / puntuación final
                  if (summary.customSubtitle != null) ...[
                    Text(
                      summary.customSubtitle!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 1. Marcador de Equipos / Jugadores
                  _buildScoreboardCard(summary),
                  const SizedBox(height: 14),

                  // 2. Tarjeta de Cofre de Recompensas (si ganó o bóveda ocupada)
                  if (isWin) ...[
                    _buildChestRewardCard(summary),
                    const SizedBox(height: 14),
                  ],

                  // 3. Tarjeta de Monedas, XP y Barra de Nivel
                  _buildProgressionCard(summary, progress),
                  const SizedBox(height: 14),

                  // 4. Estadísticas Clave de la Partida (Caídas, Limpias, Cantos, Cartas)
                  _buildMatchHighlightsGrid(summary),
                  const SizedBox(height: 20),

                  // 5. Botones de Acción: Lobby y Revancha
                  _buildActionButtons(),
                ],
              ),
            ),
          ),

          // Banner Superior Flotante: ¡VICTORIA! o ¡DERROTA!
          Positioned(
            top: 4,
            child: _buildHeaderBanner(isWin),
          ),
        ],
      ),
    );
  }

  /// Banner superior estilizado con relieves dorados o rojizos
  Widget _buildHeaderBanner(bool isWin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWin
              ? const [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)]
              : const [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFF991B1B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: (isWin ? const Color(0xFFF59E0B) : const Color(0xFFEF4444))
                .withValues(alpha: 0.6),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWin ? Icons.emoji_events_rounded : Icons.shield_outlined,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            isWin ? '¡VICTORIA!' : '¡DERROTA!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isWin ? Icons.star_rounded : Icons.replay_rounded,
            color: Colors.white,
            size: 22,
          ),
        ],
      ),
    );
  }

  /// Marcador comparativo de puntos
  Widget _buildScoreboardCard(CaidaMatchSummary summary) {
    final isTeams = summary.isTeams;
    final team1Label = isTeams ? 'Tu Equipo' : 'Tú';
    final team2Label = isTeams ? 'Rivales' : 'Rival';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF140D2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Equipo 1 (Tú)
          Expanded(
            child: Column(
              children: [
                Text(
                  team1Label,
                  style: TextStyle(
                    color: summary.userWon ? const Color(0xFF34D399) : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${summary.userTeamScore} pts',
                  style: TextStyle(
                    color: summary.userWon ? const Color(0xFFFDE047) : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${summary.userTeamCardsWon} cartas',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),

          // VS divisor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),

          // Equipo 2 (Rivales)
          Expanded(
            child: Column(
              children: [
                Text(
                  team2Label,
                  style: TextStyle(
                    color: !summary.userWon ? const Color(0xFF34D399) : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${summary.opponentTeamScore} pts',
                  style: TextStyle(
                    color: !summary.userWon ? const Color(0xFFFDE047) : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${summary.opponentTeamCardsWon} cartas',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta de Recompensa de Cofre
  Widget _buildChestRewardCard(CaidaMatchSummary summary) {
    if (summary.chestAwarded) {
      return AnimatedBuilder(
        animation: _chestShineAnim,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF78350F).withValues(alpha: 0.9),
                  const Color(0xFF451A03).withValues(alpha: 0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFDE047).withValues(alpha: 0.7 + (_chestShineAnim.value * 0.3)),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3 * _chestShineAnim.value),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: Color(0xFFFDE047), size: 14),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '¡NUEVO COFRE OBTENIDO!',
                              style: TextStyle(
                                color: Color(0xFFFDE047),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Desbloqueando en ranura ${(summary.chestSlotIndex ?? 0) + 1} (2m o 2 Tickets)',
                        style: const TextStyle(color: Colors.white, fontSize: 11.5),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Text(
                            'Premio: 50 a 2,500',
                            style: TextStyle(color: Color(0xFF34D399), fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.monetization_on_rounded, color: Color(0xFFFBBF24), size: 12),
                          const SizedBox(width: 3),
                          const Text(
                            '+ XP',
                            style: TextStyle(color: Color(0xFF34D399), fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: const Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.white38, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bóveda de cofres ocupada • Abre tus cofres en el lobby',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Tarjeta de Recompensas de Monedas, XP y Barra de Nivel animada
  Widget _buildProgressionCard(CaidaMatchSummary summary, UserProgress progress) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF160E30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3B2475), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila de Monedas y XP ganados
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Monedas
              Row(
                children: [
                  const Icon(Icons.monetization_on_rounded, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '+${summary.coinsWon}',
                    style: const TextStyle(
                      color: Color(0xFFFDE047),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),

              // XP
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFF38BDF8), size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '+${summary.xpWon} XP',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Subida de nivel banner (si ocurrió)
          if (summary.didLevelUp) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.military_tech_rounded, color: Color(0xFFFDE047), size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '¡SUBISTE A NIVEL ${summary.finalLevel}! (${progress.rankTitle})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Barra de Experiencia con Nivel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nivel ${progress.currentLevel} • ${progress.rankTitle}',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                '${progress.currentTierXp} / ${progress.neededInCurrentTier} XP',
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Barra de progreso interactiva
          AnimatedBuilder(
            animation: _xpProgressAnim,
            builder: (context, child) {
              final double targetPercent = progress.levelProgressPercentage.clamp(0.0, 1.0);
              final double currentPercent = (targetPercent * _xpProgressAnim.value).clamp(0.0, 1.0);

              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 10,
                  color: Colors.black45,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: currentPercent > 0 ? currentPercent : 0.02,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFF34D399)],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Grid con 4 chips de estadísticas clave
  Widget _buildMatchHighlightsGrid(CaidaMatchSummary summary) {
    return Row(
      children: [
        _buildStatChip(
          icon: Icons.bolt_rounded,
          iconColor: const Color(0xFFFDE047),
          value: '${summary.caidasCount}',
          label: 'Caídas',
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          icon: Icons.cleaning_services_rounded,
          iconColor: const Color(0xFF38BDF8),
          value: '${summary.limpiasCount}',
          label: 'Limpias',
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          icon: Icons.record_voice_over_rounded,
          iconColor: const Color(0xFFA78BFA),
          value: '${summary.cantosCount}',
          label: 'Cantos',
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          icon: Icons.layers_rounded,
          iconColor: const Color(0xFF34D399),
          value: '${summary.userTeamCardsWon}',
          label: 'Cartas',
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  /// Botones de acción: Lobby y Revancha
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Botón Lobby
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.onBackToMenu,
            icon: const Icon(Icons.home_rounded, size: 18),
            label: const Text(
              'LOBBY',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF334155),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white24, width: 1.2),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Botón Revancha
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.onRematch,
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: const Text(
              'REVANCHA',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFFDE047), width: 1.5),
              ),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }
}
