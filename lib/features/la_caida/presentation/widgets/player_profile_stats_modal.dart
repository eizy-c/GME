import 'package:flutter/material.dart';
import '../../economy/player_session.dart';
import '../../economy/player_stats_model.dart';
import '../../economy/user_progress.dart';
import 'avatar_view.dart';
import 'profile_options_dialog.dart';
import 'user_frame_view.dart';

/// Modal oficial "Perfil del Jugador" que unifica la vista de estadísticas de juego
/// detalladas (Generales, Jugadas de Caída y Cantos Tradicionales) y la pestaña de Logros.
/// Diseñado con estética tradicional de madera noble, tapete y pergamino.
class PlayerProfileStatsModal extends StatefulWidget {
  final PlayerSession? session;
  final PlayerStatsModel? stats;
  final int initialTabIndex;

  const PlayerProfileStatsModal({
    super.key,
    this.session,
    this.stats,
    this.initialTabIndex = 0,
  });

  /// Muestra el modal en pantalla de forma centrada.
  static Future<void> show(
    BuildContext context, {
    PlayerSession? session,
    PlayerStatsModel? stats,
    int initialTabIndex = 0,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (_) => PlayerProfileStatsModal(
        session: session,
        stats: stats,
        initialTabIndex: initialTabIndex,
      ),
    );
  }

  @override
  State<PlayerProfileStatsModal> createState() => _PlayerProfileStatsModalState();
}

class _PlayerProfileStatsModalState extends State<PlayerProfileStatsModal> {
  late int _selectedTabIndex;
  late PlayerSession _session;
  late PlayerStatsModel _stats;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _session = widget.session ?? PlayerSession.shared;
    _stats = widget.stats ?? PlayerStatsModel.shared;
  }

  void _openProfileEditor() async {
    await ProfileOptionsDialog.show(context);
    if (mounted) setState(() {});
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_session, _stats]),
      builder: (context, _) {
        final progress = UserProgress(totalXp: _session.xp);
        final level = progress.currentLevel > 0 ? progress.currentLevel : 7;
        final currentTierXp = progress.currentTierXp > 0 ? progress.currentTierXp : 103;
        final neededTierXp = progress.neededInCurrentTier > 0 ? progress.neededInCurrentTier : 130;
        final progressRatio = (currentTierXp / neededTierXp).clamp(0.0, 1.0);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 680,
              maxHeight: 560,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // 1. Marco Exterior de Madera Noble con biseles y sombra profunda
                Container(
                  margin: const EdgeInsets.only(top: 22),
                  padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8D5B28), Color(0xFF6E3F18), Color(0xFF4E2A0E)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF3B1E08), width: 3.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black87,
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pestañas (Perfil | Logros)
                      _buildTabsRow(),

                      const SizedBox(height: 2),

                      // Hoja de Pergamino Central
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFDF5),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            border: Border.all(color: const Color(0xFFD7CCC8), width: 1.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: _selectedTabIndex == 0
                                ? _buildProfileTab(progress, level, currentTierXp, neededTierXp, progressRatio)
                                : _buildAchievementsTab(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Banner Superior Tridimensional "Perfil del jugador"
                Positioned(
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF7A3D), Color(0xFFFF5722), Color(0xFFD84315)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF8D2B0B), width: 2.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Perfil del jugador',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 3,
                            offset: Offset(0, 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Botón Circular Rojo de Cierre [X] en la esquina superior derecha
                Positioned(
                  top: 6,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFF991B1B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Barra de Pestañas (Perfil / Logros) con estilo de pestañas de madera y pergamino
  Widget _buildTabsRow() {
    return Row(
      children: [
        // Pestaña PERFIL
        GestureDetector(
          onTap: () => setState(() => _selectedTabIndex = 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 7),
            decoration: BoxDecoration(
              color: _selectedTabIndex == 0 ? const Color(0xFFFFFDF5) : const Color(0xFFC89355),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border.all(
                color: _selectedTabIndex == 0 ? const Color(0xFFD7CCC8) : const Color(0xFF8D5B28),
                width: 1.2,
              ),
            ),
            child: Text(
              'Perfil',
              style: TextStyle(
                color: _selectedTabIndex == 0 ? const Color(0xFF0284C7) : const Color(0xFF4A2509),
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        const SizedBox(width: 4),

        // Pestaña LOGROS
        GestureDetector(
          onTap: () => setState(() => _selectedTabIndex = 1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 7),
            decoration: BoxDecoration(
              color: _selectedTabIndex == 1 ? const Color(0xFFFFFDF5) : const Color(0xFFC89355),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border.all(
                color: _selectedTabIndex == 1 ? const Color(0xFFD7CCC8) : const Color(0xFF8D5B28),
                width: 1.2,
              ),
            ),
            child: Text(
              'Logros',
              style: TextStyle(
                color: _selectedTabIndex == 1 ? const Color(0xFF0284C7) : const Color(0xFF4A2509),
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Pestaña 1: Perfil de Jugador con Estadísticas Completas
  Widget _buildProfileTab(
    UserProgress progress,
    int level,
    int currentTierXp,
    int neededTierXp,
    double progressRatio,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tarjeta Superior de Identidad del Jugador
          _buildPlayerHeaderCard(progress, level, currentTierXp, neededTierXp, progressRatio),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFE2D8C9), height: 1, thickness: 1.2),
          const SizedBox(height: 12),

          // 2. Columnas de Estadísticas (Layout Responsivo)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 460;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Columna Izquierda: Estadísticas Generales
                    Expanded(
                      flex: 5,
                      child: _buildGeneralStatsSection(),
                    ),
                    const SizedBox(width: 20),
                    // Columna Derecha: Jugadas de Caída y Cantos Tradicionales
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCaidaPlaysSection(),
                          const SizedBox(height: 12),
                          _buildTraditionalCantosSection(),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGeneralStatsSection(),
                    const SizedBox(height: 14),
                    _buildCaidaPlaysSection(),
                    const SizedBox(height: 14),
                    _buildTraditionalCantosSection(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Cabecera de Identidad del Jugador (Avatar + Marco + Bandera 🇻🇪 + Nombre + Nivel/XP + Título)
  Widget _buildPlayerHeaderCard(
    UserProgress progress,
    int level,
    int currentTierXp,
    int neededTierXp,
    double progressRatio,
  ) {
    final playerName = _session.name.trim().isNotEmpty ? _session.name : 'Yoangel Eizaga';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar con Marco y Etiqueta de Nivel en la esquina
        Stack(
          clipBehavior: Clip.none,
          children: [
            UserFrameView(
              frameId: _session.selectedFrameId,
              avatarIndex: _session.avatarIndex,
              level: level,
              size: 64,
            ),
            // Insignia de Nivel en esquina superior derecha
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white, width: 1),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 3),
                  ],
                ),
                child: Text(
                  '$level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 14),

        // Nombre, Bandera, Barra de XP y Título
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila 1: Bandera 🇻🇪 + Nombre + Botón [ EDITAR ]
              Row(
                children: [
                  const Text('🇻🇪', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      playerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _openProfileEditor,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, color: Color(0xFF475569), size: 12),
                          SizedBox(width: 3),
                          Text(
                            'EDITAR',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              // Fila 2: Nivel X [====...] XX de YY XP
              Row(
                children: [
                  Text(
                    'Nivel $level',
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Estrella dorada
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF59E0B),
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                  ),
                  const SizedBox(width: 6),
                  // Barra de progreso de XP
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2D8C9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD4C7B5), width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Relleno animado
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progressRatio,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24), Color(0xFFFDE047)],
                                  ),
                                ),
                              ),
                            ),
                            // Texto centrado en barra
                            Text(
                              '$currentTierXp de $neededTierXp XP',
                              style: const TextStyle(
                                color: Color(0xFF451A03),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Fila 3: Píldora de Título de Rango
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBDDCB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD7CCC8), width: 1),
                ),
                child: Text(
                  'Título: "Maestro del Trivilín"',
                  style: const TextStyle(
                    color: Color(0xFF5D3A1A),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Sección: Estadísticas Generales
  Widget _buildGeneralStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ESTADÍSTICAS GENERALES',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        _buildStatItem('Ganancias totales', _formatNumber(_stats.totalEarnings), valueColor: const Color(0xFFD97706), hasCoinIcon: true),
        _buildStatItem('Partidas jugadas / Ganadas', '${_stats.gamesPlayed} (${_stats.gamesWon} ganadas)'),
        _buildStatItem('Efectividad de victoria', '${_stats.winRatePercentage}%'),
        _buildStatItem('Racha actual / Máxima', '${_stats.currentStreak} / ${_stats.maxStreak}'),
        _buildStatItem('Mano a mano (1 vs 1)', '${_stats.soloWins} ganada${_stats.soloWins == 1 ? '' : 's'}'),
        _buildStatItem('Partidas en equipo (2 vs 2)', '${_stats.teamWins} ganada${_stats.teamWins == 1 ? '' : 's'}'),
      ],
    );
  }

  /// Sección: Jugadas y Mesa (Caída)
  Widget _buildCaidaPlaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'JUGADAS Y MESA (CAÍDA)',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        _buildStatItem('Caídas cantadas (rival cazado)', '${_stats.caidasMade}'),
        _buildStatItem('Caídas recibidas', '${_stats.caidasReceived}'),
        _buildStatItem('Mesas limpias', '${_stats.mesasLimpias}'),
        _buildStatItem('Caídas con mesa limpia', '${_stats.caidasWithLimpia}'),
        _buildStatItem('Registros / Registrícos', '${_stats.registros}'),
        _buildStatItem('Total cartas acumuladas', _formatNumber(_stats.totalCardsWon)),
      ],
    );
  }

  /// Sección: Cantos Tradicionales
  Widget _buildTraditionalCantosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CANTOS TRADICIONALES',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        _buildStatItem('Rondas', '${_stats.rondas}'),
        _buildStatItem('Patrullas', '${_stats.patrullas}'),
        _buildStatItem('Vigías', '${_stats.vigias}'),
        _buildStatItem('Trivilines cantados', '${_stats.trivilines}', valueColor: const Color(0xFF7C3AED)),
      ],
    );
  }

  /// Fila individual de estadística con etiqueta a la izquierda y valor a la derecha
  Widget _buildStatItem(String label, String value, {Color? valueColor, bool hasCoinIcon = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasCoinIcon) ...[
                const Icon(Icons.monetization_on_rounded, size: 13, color: Color(0xFFD97706)),
                const SizedBox(width: 3),
              ],
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? const Color(0xFF0F172A),
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Pestaña 2: Logros y Misiones de La Caída
  Widget _buildAchievementsTab() {
    final achievements = [
      _AchievementDef(
        id: 'ach_trivilin',
        title: 'Maestro del Trivilín',
        description: 'Cantar 3 Trivilines en partidas oficiales.',
        icon: Icons.auto_awesome_rounded,
        iconColor: const Color(0xFF7C3AED),
        currentProgress: _stats.trivilines,
        targetProgress: 3,
        coinReward: 500,
        xpReward: 100,
      ),
      _AchievementDef(
        id: 'ach_limpia',
        title: 'Rey de la Mesa Limpia',
        description: 'Realizar 10 Mesas Limpias en partidas.',
        icon: Icons.cleaning_services_rounded,
        iconColor: const Color(0xFF0D9488),
        currentProgress: _stats.mesasLimpias,
        targetProgress: 10,
        coinReward: 300,
        xpReward: 75,
      ),
      _AchievementDef(
        id: 'ach_caidas',
        title: 'Cazador de Caídas',
        description: 'Cantar 25 Caídas a tus rivales.',
        icon: Icons.flash_on_rounded,
        iconColor: const Color(0xFFE11D48),
        currentProgress: _stats.caidasMade,
        targetProgress: 25,
        coinReward: 250,
        xpReward: 50,
      ),
      _AchievementDef(
        id: 'ach_vip',
        title: 'Gallo de Oro',
        description: 'Ganar 5 partidas en Mesas VIP.',
        icon: Icons.military_tech_rounded,
        iconColor: const Color(0xFFEAB308),
        currentProgress: _stats.gamesWon,
        targetProgress: 5,
        coinReward: 1000,
        xpReward: 200,
      ),
      _AchievementDef(
        id: 'ach_teams',
        title: 'Invicto en Parejas',
        description: 'Ganar 3 partidas en modo 2 vs 2.',
        icon: Icons.groups_rounded,
        iconColor: const Color(0xFF2563EB),
        currentProgress: _stats.teamWins,
        targetProgress: 3,
        coinReward: 400,
        xpReward: 80,
      ),
      _AchievementDef(
        id: 'ach_ases',
        title: 'Coleccionista de Ases',
        description: 'Acumular 50 cartas ganadas en mesa.',
        icon: Icons.style_rounded,
        iconColor: const Color(0xFF059669),
        currentProgress: _stats.totalCardsWon,
        targetProgress: 50,
        coinReward: 350,
        xpReward: 70,
      ),
      _AchievementDef(
        id: 'ach_registro',
        title: 'Canto de Gala',
        description: 'Cantar un Registro en partida oficial.',
        icon: Icons.workspace_premium_rounded,
        iconColor: const Color(0xFFD97706),
        currentProgress: _stats.registros,
        targetProgress: 1,
        coinReward: 200,
        xpReward: 40,
      ),
      _AchievementDef(
        id: 'ach_games',
        title: 'Veterano de Caída',
        description: 'Jugar 20 partidas oficiales de La Caída.',
        icon: Icons.emoji_events_rounded,
        iconColor: const Color(0xFF9333EA),
        currentProgress: _stats.gamesPlayed,
        targetProgress: 20,
        coinReward: 500,
        xpReward: 150,
      ),
    ];

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: achievements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final ach = achievements[index];
        final isClaimed = _stats.claimedAchievementIds.contains(ach.id);
        final isCompleted = ach.currentProgress >= ach.targetProgress;
        final progressRatio = (ach.currentProgress / ach.targetProgress).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isClaimed ? const Color(0xFFF1F5F9) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isClaimed ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              // Icono
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ach.iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(ach.icon, color: ach.iconColor, size: 22),
              ),

              const SizedBox(width: 10),

              // Información del logro y progreso
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ach.title,
                          style: TextStyle(
                            color: isClaimed ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on_rounded, size: 12, color: Color(0xFFD97706)),
                            const SizedBox(width: 3),
                            Text(
                              '+${ach.coinReward}',
                              style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ach.description,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Barra de progreso
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progressRatio,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation(
                                isCompleted ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${ach.currentProgress.clamp(0, ach.targetProgress)} / ${ach.targetProgress}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Botón o Etiqueta de Estado
              if (isClaimed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                      SizedBox(width: 3),
                      Text(
                        'Reclamado',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isCompleted)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(60, 28),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _stats.claimAchievement(ach.id);
                    _session.addCoins(ach.coinReward);
                    _session.addXp(ach.xpReward);
                  },
                  child: const Text(
                    'Reclamar',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'En curso',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AchievementDef {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final int currentProgress;
  final int targetProgress;
  final int coinReward;
  final int xpReward;

  _AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.currentProgress,
    required this.targetProgress,
    required this.coinReward,
    required this.xpReward,
  });
}
