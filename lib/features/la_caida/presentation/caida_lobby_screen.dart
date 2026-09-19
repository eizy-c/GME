import 'package:flutter/material.dart';
import '../../../core/presentation/widgets/app_3d_button.dart';
import '../../../core/presentation/widgets/spanish_card_view.dart';
import '../../../core/rules/game_rules_data.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/services/user_profile_service.dart';
import '../domain/models/caida_match_config.dart';
import '../economy/daily_challenge.dart';
import '../economy/player_session.dart';
import 'caida_screen.dart';
import 'widgets/bot_customization_modal.dart';
import 'widgets/buy_tickets_modal.dart';
import 'widgets/chest_slots_view.dart';
import 'widgets/four_aces_display_view.dart';
import 'widgets/player_profile_stats_modal.dart';
import 'widgets/profile_and_level_modal.dart';
import 'widgets/user_frame_view.dart';
import 'widgets/vip_tier_selector_modal.dart';
import 'widgets/privacy_policy_dialog.dart';
import '../tutorial/presentation/tutorial_screen.dart';

/// Modo de visualización de navegación del lobby
enum LobbyViewMode { main, unJugador }

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

  // Estado del flujo del lobby
  LobbyViewMode _currentView = LobbyViewMode.main;

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

  void _openBotCustomization() {
    BotCustomizationModal.show(
      context,
      session: _session,
      onSaved: (names) {
        setState(() {});
      },
    );
  }

  void _openVipModal({bool initialIsTeams = false}) {
    VipTierSelectorModal.show(
      context,
      session: _session,
      initialIsTeams: initialIsTeams,
      onTierSelected: (tier, isTeams) {
        final matchConfig = CaidaMatchConfig.vipMatch(
          tier: tier,
          isTeams: isTeams,
          userName: _session.name,
          botNames: _session.botNames,
          isMatandoCantos: _isMatandoCantos,
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CaidaScreen(
              config: matchConfig,
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
    PlayerProfileStatsModal.show(context, session: _session);
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
          children: DailyChallenge.defaultChallenges
              .map((c) => _buildChallengeItem(c))
              .toList(),
        ),
        actions: [
          App3dButton(
            label: 'Aceptar',
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

  Widget _buildChallengeItem(DailyChallenge challenge) {
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
            challenge.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: challenge.isCompleted ? const Color(0xFF22C55E) : const Color(0xFFFDE047),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(challenge.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(challenge.rewardText, style: const TextStyle(color: Color(0xFFFDE047), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(challenge.progressText, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
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
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                SwitchListTile(
                  title: const Text('Efectos de Sonido', style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: _soundEnabled,
                  activeThumbColor: const Color(0xFF818CF8),
                  onChanged: (val) {
                    setDialogState(() => _soundEnabled = val);
                    setState(() => _soundEnabled = val);
                  },
                ),
                SwitchListTile(
                  title: const Text('Vibración Háptica', style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: _vibrationEnabled,
                  activeThumbColor: const Color(0xFF818CF8),
                  onChanged: (val) {
                    setDialogState(() => _vibrationEnabled = val);
                    setState(() => _vibrationEnabled = val);
                  },
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.smart_toy_rounded, color: Color(0xFF60A5FA)),
                  title: const Text('Personalizar Bots (IA)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text('Rivales: ${_session.botNames.join(", ")}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openBotCustomization();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.feedback_rounded, color: Color(0xFFF59E0B)),
                  title: const Text('Buzón de Sugerencias', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Envíanos tus ideas, mejoras o comentarios', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: const Icon(Icons.open_in_new_rounded, color: Color(0xFF818CF8), size: 16),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    FeedbackService.openFeedbackForm(context: context);
                  },
                ),
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
              ),
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
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Rivales Bots (IA)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _openBotCustomization();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF334155),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF60A5FA), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.smart_toy_rounded, color: Color(0xFF60A5FA), size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        _session.botNames.isNotEmpty ? _session.botNames[0] : 'Editar',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
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

                  App3dButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      if (_session.tickets < 1) {
                        _openBuyTicketsModal();
                      } else {
                        _startMatch();
                      }
                    },
                    expand: true,
                    height: 48,
                    depth: 5,
                    borderRadius: 16,
                    variant: _session.tickets >= 1 ? App3dButtonVariant.gold : App3dButtonVariant.crimson,
                    label: _session.tickets >= 1 ? '¡Empezar!' : '¡SIN TICKETS! - RECARGAR',
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: 0.8,
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
    final matchConfig = CaidaMatchConfig.quickMatch(
      players: _selectedTotalPlayers,
      isTeams: _selectedTeams,
      userName: _session.name,
      botNames: _session.botNames,
      isMatandoCantos: _isMatandoCantos,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaidaScreen(
          config: matchConfig,
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
              // 1. Barra Superior idéntica al boceto (Ajustes | Tickets | Monedas)
              _buildTopBar(),

              // 2. Contenido dinámico del lobby
              Expanded(
                child: _currentView == LobbyViewMode.main ? _buildMainSketchLobbyView() : _buildUnJugadorView(),
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
            tooltip: 'Ajustes',
            onPressed: _openSettingsDialog,
          ),
          const SizedBox(width: 4),

          // Botón de Sugerencias (Google Forms)
          InkWell(
            onTap: () => FeedbackService.openFeedbackForm(context: context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF818CF8), width: 1.2),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_rounded, color: Color(0xFFFDE047), size: 15),
                  SizedBox(width: 5),
                  Text(
                    'Sugerencias',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
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
              App3dButton(
                onPressed: () {
                  setState(() => _currentView = LobbyViewMode.unJugador);
                },
                expand: true,
                height: 58,
                depth: 6,
                borderRadius: 20,
                variant: App3dButtonVariant.gold,
                label: 'JUGAR',
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 14),

              // Botón TUTORIAL
              App3dButton.icon(
                onPressed: _openTutorial,
                expand: true,
                height: 50,
                depth: 5,
                borderRadius: 18,
                variant: App3dButtonVariant.olive,
                icon: Icons.school_rounded,
                iconSize: 20,
                label: 'TUTORIAL',
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
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
                onTap: () => setState(() => _currentView = LobbyViewMode.main),
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
