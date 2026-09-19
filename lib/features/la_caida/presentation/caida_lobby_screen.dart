import 'package:flutter/material.dart';
import '../../../core/presentation/widgets/spanish_card_view.dart';
import '../../../core/rules/game_rules_data.dart';
import '../../../core/services/user_profile_service.dart';
import '../economy/player_session.dart';
import '../economy/user_progress.dart';
import 'caida_screen.dart';
import 'widgets/avatar_view.dart';
import 'widgets/buy_tickets_modal.dart';
import 'widgets/chest_slots_view.dart';
import 'widgets/four_aces_display_view.dart';
import 'widgets/profile_and_level_modal.dart';
import 'widgets/user_frame_view.dart';
import 'widgets/vip_tier_selector_modal.dart';
import 'widgets/privacy_policy_dialog.dart';
import '../tutorial/presentation/tutorial_screen.dart';

/// Lobby principal de La Caída inspirado en el boceto de referencia:
/// Barra superior con ajustes, tickets y monedas;
/// Sub-cabecera con Logo del juego, botones de Estadística y Desafíos, y Perfil con Marco y Nivel 0;
/// Centro con abanico de los 4 Ases de la baraja y botones grandes de JUGAR y TUTORIAL;
/// Barra inferior con los 4 slots de cofres de recompensa (2 min de apertura).
class CaidaLobbyScreen extends StatefulWidget {
  const CaidaLobbyScreen({super.key});

  @override
  State<CaidaLobbyScreen> createState() => _CaidaLobbyScreenState();
}

class _CaidaLobbyScreenState extends State<CaidaLobbyScreen> {
  final _profileService = UserProfileService();
  late PlayerSession _session;

  // Estado del flujo del lobby: 'main' o 'un_jugador'
  String _currentView = 'main';

  // Opciones seleccionadas para la partida
  bool _isMatandoCantos = true;
  int _selectedTotalPlayers = 2;
  bool _selectedTeams = false;

  // Configuración de audio y efectos
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _session = PlayerSession.shared;
    _session.addListener(_onProfileChanged);
    _profileService.addListener(_onProfileChanged);
    _loadSessionAsync();
  }

  Future<void> _loadSessionAsync() async {
    final loaded = await PlayerSession.load();
    if (mounted) {
      setState(() {
        _session.removeListener(_onProfileChanged);
        _session = loaded;
        _session.addListener(_onProfileChanged);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SpanishCardView.precacheAllCards(context);
  }

  @override
  void dispose() {
    _session.removeListener(_onProfileChanged);
    _profileService.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  void _openProfileAndLevelModal({int initialTabIndex = 0}) {
    ProfileAndLevelModal.show(context, session: _session, initialTabIndex: initialTabIndex);
  }

  void _openVipModal({bool initialIsTeams = false}) {
    VipTierSelectorModal.show(
      context,
      session: _session,
      initialIsTeams: initialIsTeams,
      onTierSelected: (tier, isTeams) {
        final totalPlayers = isTeams ? 4 : 2;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CaidaScreen(
              initialPlayers: totalPlayers,
              autoStart: true,
              initialTeams: isTeams,
              chooseMano: true,
              userName: _session.name,
              botNames: const ['Alejandro', 'Carl', 'Jhonny'],
              vipTier: tier,
              vipPrizePool: tier.calculatePrizePool(isTeams: isTeams),
              vipWinnerReward: tier.calculateNetPrizePerWinner(isTeams: isTeams),
            ),
          ),
        );
      },
    );
  }

  void _openBuyTicketsModal() {
    BuyTicketsModal.show(context, session: _session);
  }

  void _openTutorial() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => const TutorialScreen(),
      ),
    )
        .then((_) {
      setState(() {
        _session = PlayerSession.shared;
      });
    });
  }

  void _openStatisticsDialog() {
    final progress = UserProgress(totalXp: _session.xp);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: Color(0xFF38BDF8), size: 28),
            SizedBox(width: 10),
            Text(
              'Estadísticas del Jugador',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Nivel Actual', '${progress.currentLevel} (${progress.rankTitle})', const Color(0xFFFDE047)),
            _buildStatRow('Experiencia Total', '${_session.xp} XP', const Color(0xFF38BDF8)),
            _buildStatRow('Saldo de Monedas', '${_session.coins} 🪙', const Color(0xFFFBBF24)),
            _buildStatRow('Tickets Disponibles', '${_session.tickets} / ${_session.maxTickets} 🎫', const Color(0xFF4ADE80)),
            _buildStatRow('Tutorial de Novatos', _session.hasCompletedTutorial ? 'Completado (100%)' : 'Pendiente', Colors.white70),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  void _openChallengesDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: Color(0xFFFDE047), size: 28),
            SizedBox(width: 10),
            Text(
              'Desafíos Diarios',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildChallengeItem('Gana 1 partida en CaidaGO', '0 / 1', '+250 🪙  +50 XP', false),
            _buildChallengeItem('Realiza 2 Caídas en una partida', '0 / 2', '+150 🪙  +30 XP', false),
            _buildChallengeItem('Juega en Parejas (2 vs 2)', '0 / 1', '+200 🪙  +40 XP', false),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeItem(String title, String progress, String reward, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isCompleted ? const Color(0xFF22C55E) : const Color(0xFFFDE047),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(reward, style: const TextStyle(color: Color(0xFFFDE047), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(progress, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
            title: const Row(
              children: [
                Icon(Icons.settings_rounded, color: Color(0xFF818CF8), size: 26),
                SizedBox(width: 10),
                Text(
                  'Ajustes del Juego',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Efectos de Sonido', style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: _soundEnabled,
                  activeColor: const Color(0xFF818CF8),
                  onChanged: (val) {
                    setDialogState(() => _soundEnabled = val);
                    setState(() => _soundEnabled = val);
                  },
                ),
                SwitchListTile(
                  title: const Text('Vibración Háptica', style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: _vibrationEnabled,
                  activeColor: const Color(0xFF818CF8),
                  onChanged: (val) {
                    setDialogState(() => _vibrationEnabled = val);
                    setState(() => _vibrationEnabled = val);
                  },
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.menu_book_rounded, color: Color(0xFFFDE047)),
                  title: const Text('Reglas de CaidaGO', style: TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openLearnRulesDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_rounded, color: Color(0xFF38BDF8)),
                  title: const Text('Política de Privacidad', style: TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    PrivacyPolicyDialog.show(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.verified_user_rounded, color: Color(0xFF34D399)),
                  title: const Text('Licencias y Software Libre', style: TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    showLicensePage(
                      context: context,
                      applicationName: 'CaidaGO',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2026 CaidaGO • Desarrollado por Eizy Systems\nTodos los derechos reservados.',
                    );
                  },
                ),
                const Divider(color: Colors.white12),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'CaidaGO v1.0.0\nDesarrollado por Eizy Systems • 2026\n© 2026 CaidaGO. Todos los derechos reservados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Listo', style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openLearnRulesDialog() {
    final rules = GameRulesData.getRules('la_caida');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: Color(0xFFFBBF24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                rules.title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rules.objective, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                const Text('Dinámica de juego:', style: TextStyle(color: Color(0xFFFDE047), fontWeight: FontWeight.bold)),
                ...rules.steps.map((s) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• $s', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    )),
                const SizedBox(height: 12),
                const Text('Cantos y Jugadas Especiales:', style: TextStyle(color: Color(0xFFFDE047), fontWeight: FontWeight.bold)),
                ...rules.specialRules.map((s) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• $s', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido', style: TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showGamePreferencesDialog({
    required int players,
    required bool teams,
    bool isVsBot = false,
  }) {
    setState(() {
      _selectedTotalPlayers = players;
      _selectedTeams = teams;
    });

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                    ),
                    child: Text(
                      isVsBot
                          ? 'Preferencias de juego\nVs Bot'
                          : 'Preferencias de juego\n2 vs 2 (Parejas)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF334155), width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Entrada',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDE68A),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFD97706), width: 1),
                                  ),
                                  child: const Icon(Icons.confirmation_number_rounded, color: Color(0xFFB45309), size: 18),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '1  (${_session.tickets} disp.)',
                                  style: const TextStyle(
                                    color: Color(0xFFFDE047),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Colors.white12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Matando cantos',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Switch(
                              value: _isMatandoCantos,
                              activeThumbColor: Colors.white,
                              activeTrackColor: const Color(0xFFF59E0B),
                              onChanged: (val) {
                                setDialogState(() => _isMatandoCantos = val);
                                setState(() => _isMatandoCantos = val);
                              },
                            ),
                          ],
                        ),

                        if (isVsBot) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Modo de juego',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    if (_selectedTotalPlayers == 2) {
                                      _selectedTotalPlayers = 3;
                                    } else if (_selectedTotalPlayers == 3) {
                                      _selectedTotalPlayers = 4;
                                    } else {
                                      _selectedTotalPlayers = 2;
                                    }
                                    _selectedTeams = false;
                                  });
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                                  ),
                                  child: Text(
                                    '$_selectedTotalPlayers Jugadores',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      if (_session.tickets < 1) {
                        _openBuyTicketsModal();
                      } else {
                        _startMatch();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _session.tickets >= 1
                              ? [const Color(0xFFFBBF24), const Color(0xFFD97706)]
                              : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _session.tickets >= 1 ? const Color(0xFFFDE68A) : const Color(0xFFFCA5A5),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_session.tickets >= 1 ? const Color(0xFFD97706) : const Color(0xFFDC2626))
                                .withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _session.tickets >= 1 ? '¡Empezar!' : '¡SIN TICKETS! - RECARGAR',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _startMatch() {
    if (!_session.consumeTicketForNormalMatch()) {
      _openBuyTicketsModal();
      return;
    }
    _profileService.useTicket();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaidaScreen(
          initialPlayers: _selectedTotalPlayers,
          autoStart: true,
          initialTeams: _selectedTeams,
          chooseMano: true,
          userName: _session.name,
          botNames: const ['Alejandro', 'Carl', 'Jhonny'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = LobbyThemeOption.getById(_session.selectedThemeId);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.backgroundGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Barra Superior idéntica al boceto (Ajustes ⚙️ | Tickets 🎫 | Monedas 🪙)
              _buildTopBar(),

              // 2. Contenido dinámico del lobby
              Expanded(
                child: _currentView == 'main' ? _buildMainSketchLobbyView() : _buildUnJugadorView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- BARRA SUPERIOR ---
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.65),
        border: const Border(bottom: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Row(
        children: [
          // Engranaje de Ajustes
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 26),
            onPressed: _openSettingsDialog,
          ),
          const Spacer(),

          // Contador de Tickets: "10 +"
          GestureDetector(
            onTap: _openBuyTicketsModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.confirmation_number_rounded, color: Color(0xFF38BDF8), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${_session.tickets}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF38BDF8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 10, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Contador de Monedas: "0 +" / "1000 +"
          GestureDetector(
            onTap: _openBuyTicketsModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE047), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_rounded, color: Color(0xFFFDE047), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${_session.coins}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDE047),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 10, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- VISTA PRINCIPAL SEGÚN EL BOCETO ---
  Widget _buildMainSketchLobbyView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // 1. Fila Superior (Logo del Juego | Estadística / Desafíos | Perfil + Marco + Nivel)
          _buildSubHeaderRow(),
          const Spacer(),

          // 2. Zona Central (Abanico de los 4 Ases de la Baraja | Botones JUGAR y TUTORIAL)
          _buildCenterActionArea(),
          const Spacer(),

          // 3. Fila Inferior (4 Ranuras de Cofres de Recompensa)
          ChestSlotsView(
            session: _session,
            onChestClaimed: (coins) {
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        children: [
          // GAME LOGO Box
          Container(
            width: 78,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.style_rounded, color: Colors.white, size: 24),
                SizedBox(height: 2),
                Text(
                  'CAIDAGO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Columna Central: Botones "Estadística" y "Desafíos"
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSmallActionBtn('Estadística', Icons.leaderboard_rounded, const Color(0xFF38BDF8), _openStatisticsDialog),
                const SizedBox(height: 6),
                _buildSmallActionBtn('Desafíos', Icons.emoji_events_rounded, const Color(0xFFFDE047), _openChallengesDialog),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Tarjeta de Perfil del Usuario (Avatar + Marco + Insignia de Nivel)
          GestureDetector(
            onTap: () => _openProfileAndLevelModal(),
            child: UserFrameView(
              avatarIndex: _session.avatarIndex,
              frameId: _session.selectedFrameId,
              level: _session.level,
              size: 58,
              showLevelBadge: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionBtn(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 31,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterActionArea() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Izquierda: Abanico de los 4 Ases de la Baraja Española tradicional
        const FourAcesDisplayView(cardWidth: 68),
        const SizedBox(width: 14),

        // Derecha: Botones grandes de JUGAR y TUTORIAL
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón JOGAR / JUGAR
              GestureDetector(
                onTap: () {
                  setState(() => _currentView = 'un_jugador');
                },
                child: Container(
                  width: double.infinity,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'JUGAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Botón TUTORIAL
              GestureDetector(
                onTap: _openTutorial,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF047857)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF6EE7B7), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF047857).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.school_rounded, color: Color(0xFFFDE047), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'TUTORIAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SUB-VISTA DE SELECCIÓN DE MODOS DE JUEGO ---
  Widget _buildUnJugadorView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _currentView = 'main'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios_rounded, color: Color(0xFFFBBF24), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Volver al Menú',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _showGamePreferencesDialog(
                players: _selectedTeams ? 2 : _selectedTotalPlayers.clamp(2, 4),
                teams: false,
                isVsBot: true,
              ),
              child: Container(
                width: 145,
                height: 155,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD97706).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.smart_toy_rounded, color: Colors.white, size: 52),
                    SizedBox(height: 8),
                    Text(
                      'Vs Bot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Mano a Mano (1v1)',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),

            GestureDetector(
              onTap: () => _showGamePreferencesDialog(
                players: 4,
                teams: true,
                isVsBot: false,
              ),
              child: Container(
                width: 145,
                height: 155,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFDBA74), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC2410C).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_rounded, color: Colors.white, size: 52),
                    SizedBox(height: 8),
                    Text(
                      '2 vs 2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'En Parejas (4 Jug.)',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        GestureDetector(
          onTap: () => _openVipModal(),
          child: Container(
            width: 310,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFDE047), size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MESAS VIP • APUESTAS',
                        style: TextStyle(
                          color: Color(0xFFFDE047),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pozos y Premios en Monedas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
