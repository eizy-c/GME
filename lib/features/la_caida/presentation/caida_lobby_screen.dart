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

  void _showComingSoonToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_clock_rounded, color: Color(0xFFFDE047), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFF59E0B), width: 1.2),
        ),
        duration: const Duration(seconds: 2),
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
                  // Título con estilo de placa dorada
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

                  // Contenedor interior oscuro armonioso
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF334155), width: 1),
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
                                const Text(
                                  '1',
                                  style: TextStyle(
                                    color: Color(0xFFFDE047),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Colors.white12),

                        // Switch: Matando cantos
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

                        // Solo en modo Vs Bot se muestra el selector de cantidad de jugadores
                        // En 2 vs 2 no aparece ya que está predeterminado en parejas (4 Jug.)
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

                  // Botón Empezar dorado con brillo
                  GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _startMatch();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD97706).withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '¡Empezar!',
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A), // Midnight slate
              Color(0xFF1E1B4B), // Deep royal indigo
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
            width: 1,
          ),
        ),
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
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 10, color: Color(0xFF78350F)),
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
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_rounded, color: Color(0xFFFBBF24), size: 16),
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
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_rounded, color: Color(0xFFFBBF24), size: 16),
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

          // Engranaje de Ajustes / Guía
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white70),
            onPressed: _openLearnRulesDialog,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainLobbyView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Panel central de Opciones de Juego estilo arcade
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Plaqueta de encabezado estilo arcade
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Text(
                        'MODOS DE JUEGO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 1. Un Jugador (Hero Button principal activo)
                    _buildActionCard(
                      title: 'Un Jugador',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderColor: const Color(0xFFFDE68A),
                      textColor: Colors.white,
                      badge: 'VS',
                      badgeColor: const Color(0xFFDC2626),
                      icon: Icons.smart_toy_rounded,
                      iconColor: Colors.white,
                      onTap: () {
                        setState(() => _currentView = 'un_jugador');
                      },
                    ),
                    const SizedBox(height: 12),

                    // 2. Multijugador (BLOQUEADO: Para jugar Online o en Red)
                    _buildActionCard(
                      title: 'Multijugador',
                      subtitle: 'Online / Red local',
                      bgColor: const Color(0xFF1E293B),
                      borderColor: const Color(0xFF334155),
                      textColor: const Color(0xFFCBD5E1),
                      icon: Icons.public_rounded,
                      iconColor: const Color(0xFF64748B),
                      isLocked: true,
                      onTap: () {
                        _showComingSoonToast('Modo Multijugador (Online / Red local) próximamente.');
                      },
                    ),
                    const SizedBox(height: 12),

                    // 3. Aprende (Tutorial interactivo de reglas)
                    _buildActionCard(
                      title: 'Aprende',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderColor: const Color(0xFFFDBA74),
                      textColor: Colors.white,
                      icon: Icons.menu_book_rounded,
                      iconColor: Colors.white,
                      onTap: _openLearnRulesDialog,
                    ),
                    const SizedBox(height: 12),

                    // 4. Personalizar (Bloqueado)
                    _buildActionCard(
                      title: 'Personalizar',
                      bgColor: const Color(0xFF1E293B),
                      borderColor: const Color(0xFF334155),
                      textColor: const Color(0xFF94A3B8),
                      icon: Icons.style_rounded,
                      iconColor: const Color(0xFF64748B),
                      isLocked: true,
                      onTap: () {
                        _showComingSoonToast('Próximamente: Barajas y tapetes personalizados.');
                      },
                    ),
                    const SizedBox(height: 12),

                    // 5. Amigos (Bloqueado)
                    _buildActionCard(
                      title: 'Amigos',
                      bgColor: const Color(0xFF1E293B),
                      borderColor: const Color(0xFF334155),
                      textColor: const Color(0xFF94A3B8),
                      icon: Icons.people_alt_rounded,
                      iconColor: const Color(0xFF64748B),
                      isLocked: true,
                      onTap: () {
                        _showComingSoonToast('Próximamente: Lista y salas de amigos.');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnJugadorView() {
    return Column(
      children: [
        // Cabecera con botón de regreso
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _currentView = 'main'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        'Un Jugador',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
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

        // Tarjetas de Selección "Vs Bot" y "2 vs 2" con paleta armoniosa
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Opción 1: Vs Bot (Mano a Mano o varios jugadores individuales)
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

            // Opción 2: 2 vs 2 (Parejas fijas de 4 jugadores)
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
        const Spacer(),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    String? subtitle,
    Color? bgColor,
    Gradient? gradient,
    Color? borderColor,
    required Color textColor,
    required IconData icon,
    required Color iconColor,
    String? badge,
    Color? badgeColor,
    bool isLocked = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: subtitle != null ? 56 : 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bgColor,
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor ?? Colors.transparent,
            width: 1.5,
          ),
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
                margin: const EdgeInsets.only(right: 8),
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
                    fontSize: 10,
                  ),
                ),
              ),
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            if (isLocked)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock_rounded, color: Color(0xFF94A3B8), size: 16),
              ),
          ],
        ),
      ),
    );
  }
}
