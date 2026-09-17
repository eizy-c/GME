import 'package:flutter/material.dart';
import '../../../core/rules/game_rules_data.dart';
import '../../../core/services/user_profile_service.dart';
import 'caida_screen.dart';
import 'widgets/avatar_view.dart';
import 'widgets/profile_options_dialog.dart';

/// Lobby principal de La Caída inspirado en las capturas de referencia:
/// Barra superior con saldo de monedas y tickets, tarjetas coloridas de modos,
/// sub-pantalla de "Un Jugador" y modal de "Preferencias de juego".
class CaidaLobbyScreen extends StatefulWidget {
  const CaidaLobbyScreen({super.key});

  @override
  State<CaidaLobbyScreen> createState() => _CaidaLobbyScreenState();
}

class _CaidaLobbyScreenState extends State<CaidaLobbyScreen> {
  final _profileService = UserProfileService();

  // Estado del flujo del lobby: 'main' o 'un_jugador'
  String _currentView = 'main';

  // Opciones seleccionadas para la partida
  bool _isMatandoCantos = true;
  int _selectedTotalPlayers = 2;
  bool _selectedTeams = false;

  @override
  void initState() {
    super.initState();
    _profileService.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _profileService.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  void _openProfileDialog() {
    ProfileOptionsDialog.show(context);
  }

  void _openLearnRulesDialog() {
    final rules = GameRulesData.getRules('la_caida');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: Color(0xFF38BDF8)),
            const SizedBox(width: 8),
            Text(rules.title, style: const TextStyle(color: Colors.white, fontSize: 18)),
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
            child: const Text('Entendido', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showGamePreferencesDialog({required int players, required bool teams}) {
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
                color: const Color(0xFF708FA8), // Fondo azul pastel de la captura 4
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFBAE6FD), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Preferencias de juego\nUn Jugador',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1E1B4B),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contenedor interior blanco
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        // Fila de Entrada: Ticket 1
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Entrada',
                              style: TextStyle(
                                color: Color(0xFF1E3A8A),
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
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
                                const Text(
                                  '1',
                                  style: TextStyle(
                                    color: Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Switch: Matando cantos
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Matando cantos',
                              style: TextStyle(
                                color: Color(0xFF1E1B4B),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Switch(
                              value: _isMatandoCantos,
                              activeThumbColor: Colors.white,
                              activeTrackColor: const Color(0xFF38BDF8),
                              onChanged: (val) {
                                setDialogState(() => _isMatandoCantos = val);
                                setState(() => _isMatandoCantos = val);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Modo de juego: 2 Jugadores / 4 Jugadores
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Modo de juego',
                              style: TextStyle(
                                color: Color(0xFF1E1B4B),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  if (_selectedTotalPlayers == 2) {
                                    _selectedTotalPlayers = 3;
                                    _selectedTeams = false;
                                  } else if (_selectedTotalPlayers == 3) {
                                    _selectedTotalPlayers = 4;
                                    _selectedTeams = true;
                                  } else {
                                    _selectedTotalPlayers = 2;
                                    _selectedTeams = false;
                                  }
                                });
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _selectedTeams
                                      ? '4 Jug. (Parejas)'
                                      : '$_selectedTotalPlayers Jugadores',
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
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Botón Empezar
                  GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _startMatch();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1), // Índigo vibrante
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4338CA).withValues(alpha: 0.6),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Empezar',
                          style: TextStyle(
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
    _profileService.useTicket();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaidaScreen(
          initialPlayers: _selectedTotalPlayers,
          autoStart: true,
          initialTeams: _selectedTeams,
          chooseMano: true,
          userName: _profileService.name,
          botNames: const ['Alejandro', 'Carl', 'Jhonny'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1B4B), // Púrpura oscuro base
      body: SafeArea(
        child: Column(
          children: [
            // 1. Barra Superior con Perfil, Monedas y Tickets
            _buildTopBar(),

            // 2. Contenido Central (Lobby Principal o Sub-menú Un Jugador)
            Expanded(
              child: _currentView == 'un_jugador'
                  ? _buildUnJugadorView()
                  : _buildMainLobbyView(),
            ),

            // 3. Barra Inferior de Iconos
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2E1065).withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          // Avatar con lápiz y nombre
          GestureDetector(
            onTap: _openProfileDialog,
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    AvatarView(
                      avatarId: _profileService.avatarId,
                      size: 40,
                      showBorder: true,
                    ),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 10, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  _profileService.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Píldora de Monedas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B4B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE047), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_rounded, color: Color(0xFFFDE047), size: 16),
                const SizedBox(width: 4),
                Text(
                  _profileService.coins.toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (Match m) => '${m[1]},',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Píldora de Tickets
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B4B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_rounded, color: Color(0xFFF59E0B), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_profileService.tickets}/10',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Engranaje de Ajustes
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white70),
            onPressed: () {
              // Dialog de ajustes rápidos o info
              _openLearnRulesDialog();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainLobbyView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Lado Izquierdo: Iconos laterales pequeños
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSideIcon(Icons.ondemand_video_rounded, Colors.redAccent),
              const SizedBox(height: 16),
              _buildSideIcon(Icons.shopping_cart_rounded, Colors.orangeAccent),
              const SizedBox(height: 16),
              _buildSideIcon(Icons.camera_alt_rounded, Colors.pinkAccent),
              const SizedBox(height: 16),
              _buildSideIcon(Icons.mail_rounded, Colors.amberAccent),
            ],
          ),
          const Spacer(),

          // Lado Derecho: Tarjetas principales curvadas
          SizedBox(
            width: 220,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Multijugador
                _buildActionCard(
                  title: 'Multijugador',
                  bgColor: const Color(0xFFFACC15), // Amarillo
                  textColor: const Color(0xFF78350F),
                  icon: Icons.public_rounded,
                  iconColor: const Color(0xFF0284C7),
                  onTap: () {
                    // Modal de multijugador o red local
                    _showGamePreferencesDialog(players: 2, teams: false);
                  },
                ),
                const SizedBox(height: 12),

                // 2. Un Jugador
                _buildActionCard(
                  title: 'Un Jugador',
                  bgColor: const Color(0xFFFB923C), // Naranja
                  textColor: const Color(0xFF7C2D12),
                  badge: 'VS',
                  badgeColor: const Color(0xFFEF4444),
                  icon: Icons.smartphone_rounded,
                  iconColor: const Color(0xFF1E3A8A),
                  onTap: () {
                    setState(() => _currentView = 'un_jugador');
                  },
                ),
                const SizedBox(height: 12),

                // 3. Aprende (Tutorial y Reglas)
                _buildActionCard(
                  title: 'Aprende',
                  bgColor: const Color(0xFF38BDF8), // Cian
                  textColor: const Color(0xFF0C4A6E),
                  icon: Icons.menu_book_rounded,
                  iconColor: Colors.purpleAccent,
                  onTap: _openLearnRulesDialog,
                ),
                const SizedBox(height: 12),

                // 4. Personalizar (Bloqueado)
                _buildActionCard(
                  title: 'Personalizar',
                  bgColor: const Color(0xFF475569), // Gris
                  textColor: Colors.white,
                  icon: Icons.style_rounded,
                  iconColor: Colors.white70,
                  isLocked: true,
                ),
                const SizedBox(height: 12),

                // 5. Amigos (Bloqueado)
                _buildActionCard(
                  title: 'Amigos',
                  bgColor: const Color(0xFF64748B), // Gris pizarra
                  textColor: Colors.white,
                  icon: Icons.people_alt_rounded,
                  iconColor: Colors.white70,
                  isLocked: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnJugadorView() {
    return Column(
      children: [
        // Cabecera con botón de regreso
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _currentView = 'main'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 4),
                      Text(
                        'Un Jugador',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
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

        // Tarjetas de Selección "Vs Bot" y "2 vs 2"
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Opción 1: Vs Bot (1 vs 1)
            GestureDetector(
              onTap: () => _showGamePreferencesDialog(players: 2, teams: false),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7), // Púrpura
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFC084FC), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7E22CE).withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.smart_toy_rounded, color: Color(0xFF86EFAC), size: 52),
                    SizedBox(height: 6),
                    Text(
                      'Vs Bot',
                      style: TextStyle(
                        color: Color(0xFF86EFAC),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Mano a Mano (1v1)',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),

            // Opción 2: 2 vs 2 (Parejas)
            GestureDetector(
              onTap: () => _showGamePreferencesDialog(players: 4, teams: true),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488), // Verde azulado
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2DD4BF), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_rounded, color: Color(0xFFC084FC), size: 52),
                    SizedBox(height: 6),
                    Text(
                      '2 vs 2',
                      style: TextStyle(
                        color: Color(0xFFC084FC),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'En Parejas (4 Jug.)',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required Color bgColor,
    required Color textColor,
    required IconData icon,
    required Color iconColor,
    String? badge,
    Color? badgeColor,
    bool isLocked = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            if (isLocked)
              const Icon(Icons.lock_rounded, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSideIcon(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF2E1065),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E1065).withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomIcon(Icons.video_collection_rounded, Colors.blueAccent),
          _buildBottomIcon(Icons.card_giftcard_rounded, Colors.orangeAccent),
          _buildBottomIcon(Icons.star_rounded, Colors.yellowAccent, isBig: true),
          _buildBottomIcon(Icons.handshake_rounded, Colors.tealAccent),
        ],
      ),
    );
  }

  Widget _buildBottomIcon(IconData icon, Color color, {bool isBig = false}) {
    final s = isBig ? 46.0 : 38.0;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: isBig ? 2 : 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: color, size: isBig ? 24 : 18),
      ),
    );
  }
}
