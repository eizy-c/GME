import 'package:flutter/material.dart';

import '../../../core/engine/game_phase.dart';
import '../../../core/engine/player.dart';
import '../../../core/stats/game_stats.dart';
import '../../../core/stats/stats_repository.dart';
import '../domain/vieja_ai_player.dart';
import '../domain/vieja_engine.dart';
import '../domain/vieja_models.dart';

import '../../../core/presentation/widgets/game_rules_dialog.dart';

/// Pantalla interactiva del juego La Vieja (Tic-Tac-Toe / Tres en Raya).
/// Diseñada con estética gamer/arcade premium: neones dinámicos, brillo exterior,
/// línea de victoria continua animada e indicador de enfrentamiento VS interactivo.
class ViejaScreen extends StatefulWidget {
  final StatsRepository statsRepository;

  const ViejaScreen({super.key, required this.statsRepository});

  @override
  State<ViejaScreen> createState() => _ViejaScreenState();
}

class _ViejaScreenState extends State<ViejaScreen> {
  late ViejaEngine _engine;
  bool _vsBot = true;
  GameStats _stats = const GameStats(gameType: GameType.laVieja);

  @override
  void initState() {
    super.initState();
    _setupGame();
    _loadStats();
  }

  void _setupGame() {
    final player1 = const HumanPlayer(id: 'human_1', name: 'Tú');
    final player2 = _vsBot
        ? const ViejaAIPlayer(
            id: 'bot_vieja',
            name: 'Bot Sabio',
            simulatedDelay: Duration(milliseconds: 380),
          )
        : const HumanPlayer(id: 'human_2', name: 'Rival');

    _engine = ViejaEngine(
      player1: player1,
      player2: player2,
      statsRepository: widget.statsRepository,
      autoPlayAI: true,
    );

    _engine.initializeGame();
  }

  Future<void> _loadStats() async {
    final s = await widget.statsRepository.getStats(GameType.laVieja);
    if (mounted) setState(() => _stats = s);
  }

  void _switchMode(bool vsBot) {
    if (_vsBot == vsBot) return;
    setState(() {
      _vsBot = vsBot;
      _engine.dispose();
      _setupGame();
    });
  }

  void _onCellTapped(int row, int col, ViejaState state) {
    if (state.isGameOver || state.phase != GamePhase.playing) return;

    final currentPlayer = state.currentPlayer;
    if (currentPlayer == null || !currentPlayer.isHuman) return;

    final action = ViejaAction(
      playerId: currentPlayer.id,
      row: row,
      col: col,
    );

    _engine.processAction(action).then((_) => _loadStats());
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D), // Fondo espacial oscuro profundo
      appBar: AppBar(
        backgroundColor: const Color(0xFF11192A),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.grid_3x3_rounded, color: Color(0xFF38BDF8), size: 22),
            SizedBox(width: 8),
            Text(
              'La Vieja (Tres en Raya)',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFFFDE047)),
            tooltip: 'Reglas de La Vieja',
            onPressed: () => GameRulesDialog.show(context, 'la_vieja'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Reiniciar tablero',
            onPressed: () {
              _engine.restartGame();
              _loadStats();
            },
          ),
        ],
      ),
      body: StreamBuilder<ViejaState>(
        stream: _engine.stateStream,
        initialData: _engine.state,
        builder: (context, snapshot) {
          final state = snapshot.data ?? _engine.state;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildModeSelector(),
                  const SizedBox(height: 10),
                  _buildVsBanner(state),
                  const SizedBox(height: 10),
                  _buildTurnMessage(state),
                  const SizedBox(height: 12),
                  Center(child: _buildBoard(state)),
                  const SizedBox(height: 14),
                  _buildStatsBar(),
                  const SizedBox(height: 10),
                  _buildFooterControls(state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF152033),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              title: 'Contra Bot',
              icon: Icons.smart_toy_rounded,
              selected: _vsBot,
              onTap: () => _switchMode(true),
            ),
          ),
          Expanded(
            child: _buildModeButton(
              title: '2 Jugadores',
              icon: Icons.people_alt_rounded,
              selected: !_vsBot,
              onTap: () => _switchMode(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0D9488)],
                )
              : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white60,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVsBanner(ViejaState state) {
    final isP1Turn = state.currentPlayer?.id == _engine.player1.id && !state.isGameOver;
    final isP2Turn = state.currentPlayer?.id == _engine.player2.id && !state.isGameOver;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131D2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Jugador 1 (X)
          _buildPlayerProfile(
            name: _engine.player1.name,
            symbol: 'X',
            symbolColor: const Color(0xFF38BDF8),
            icon: Icons.person_rounded,
            isActive: isP1Turn,
            isWinner: state.winnerId == _engine.player1.id,
          ),

          // Badge VS Central
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // Jugador 2 / Bot (O)
          _buildPlayerProfile(
            name: _engine.player2.name,
            symbol: 'O',
            symbolColor: const Color(0xFFF472B6),
            icon: _vsBot ? Icons.smart_toy_rounded : Icons.person_outline_rounded,
            isActive: isP2Turn,
            isWinner: state.winnerId == _engine.player2.id,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerProfile({
    required String name,
    required String symbol,
    required Color symbolColor,
    required IconData icon,
    required bool isActive,
    required bool isWinner,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? symbolColor.withValues(alpha: 0.15)
            : isWinner
                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? symbolColor
              : isWinner
                  ? const Color(0xFF34D399)
                  : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: symbolColor.withValues(alpha: 0.2),
            child: Icon(icon, color: symbolColor, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Ficha ',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                  ),
                  Text(
                    symbol,
                    style: TextStyle(
                      color: symbolColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTurnMessage(ViejaState state) {
    Color bannerBg = const Color(0xFF17253B);
    Color textColor = Colors.white;
    IconData icon = Icons.play_circle_outline_rounded;

    if (state.isGameOver) {
      if (state.isDraw) {
        bannerBg = const Color(0xFF78350F).withValues(alpha: 0.4);
        textColor = const Color(0xFFFCD34D);
        icon = Icons.handshake_rounded;
      } else {
        bannerBg = const Color(0xFF065F46).withValues(alpha: 0.4);
        textColor = const Color(0xFF6EE7B7);
        icon = Icons.emoji_events_rounded;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: state.isGameOver ? textColor.withValues(alpha: 0.6) : Colors.white12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Text(
            state.statusMessage ?? '',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(ViejaState state) {
    final winningCells = state.winningLine?.cells ?? [];

    return Container(
      width: 320,
      height: 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141F32),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF283B55), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cuadrícula 3x3
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final row = index ~/ 3;
              final col = index % 3;
              final symbol = state.board.get(row, col);
              final isWinningCell = winningCells.any((c) => c.$1 == row && c.$2 == col);

              return _buildBoardCell(
                row: row,
                col: col,
                symbol: symbol,
                isWinningCell: isWinningCell,
                onTap: () => _onCellTapped(row, col, state),
              );
            },
          ),

          // Línea de victoria animada atravesando casillas
          if (state.winningLine != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _WinningStrikePainter(cells: state.winningLine!.cells),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBoardCell({
    required int row,
    required int col,
    required ViejaSymbol symbol,
    required bool isWinningCell,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: symbol == ViejaSymbol.none ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF38BDF8).withValues(alpha: 0.25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isWinningCell
                ? const Color(0xFF065F46).withValues(alpha: 0.6)
                : const Color(0xFF1B2940),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isWinningCell
                  ? const Color(0xFF34D399)
                  : symbol == ViejaSymbol.none
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.16),
              width: isWinningCell ? 2.5 : 1.2,
            ),
            boxShadow: isWinningCell
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: AnimatedScale(
              scale: symbol == ViejaSymbol.none ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.elasticOut,
              child: _buildSymbolPiece(symbol),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSymbolPiece(ViejaSymbol symbol) {
    if (symbol == ViejaSymbol.x) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Text(
          '✕',
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w900,
            color: Color(0xFF38BDF8),
            shadows: [
              Shadow(
                color: Color(0xFF0284C7),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      );
    } else if (symbol == ViejaSymbol.o) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF472B6).withValues(alpha: 0.45),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Text(
          '○',
          style: TextStyle(
            fontSize: 54,
            fontWeight: FontWeight.w900,
            color: Color(0xFFF472B6),
            shadows: [
              Shadow(
                color: Color(0xFFDB2777),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131D2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Victorias', '${_stats.wins}', const Color(0xFF10B981)),
          _buildStatDivider(),
          _buildStatItem('Derrotas', '${_stats.losses}', const Color(0xFFEF4444)),
          _buildStatDivider(),
          _buildStatItem('Empates', '${_stats.draws}', const Color(0xFFF59E0B)),
          _buildStatDivider(),
          _buildStatItem(
            'Efectividad',
            '${_stats.winRate.toStringAsFixed(0)}%',
            const Color(0xFF38BDF8),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 24, width: 1, color: Colors.white12);
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white60),
        ),
      ],
    );
  }

  Widget _buildFooterControls(ViejaState state) {
    if (!state.isGameOver) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.replay_rounded, color: Colors.white),
        label: const Text(
          'Jugar otra partida',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D9488),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          shadowColor: const Color(0xFF0D9488).withValues(alpha: 0.5),
        ),
        onPressed: () {
          _engine.restartGame();
          _loadStats();
        },
      ),
    );
  }
}

/// Dibuja la línea de victoria sobre las casillas ganadoras
class _WinningStrikePainter extends CustomPainter {
  final List<(int row, int col)> cells;

  _WinningStrikePainter({required this.cells});

  @override
  void paint(Canvas canvas, Size size) {
    if (cells.length < 2) return;

    final paintGlow = Paint()
      ..color = const Color(0xFF34D399).withValues(alpha: 0.6)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final paintCore = Paint()
      ..color = const Color(0xFFFDE047)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cellWidth = size.width / 3;
    final cellHeight = size.height / 3;

    final first = cells.first;
    final last = cells.last;

    final start = Offset(
      (first.$2 * cellWidth) + (cellWidth / 2),
      (first.$1 * cellHeight) + (cellHeight / 2),
    );
    final end = Offset(
      (last.$2 * cellWidth) + (cellWidth / 2),
      (last.$1 * cellHeight) + (cellHeight / 2),
    );

    canvas.drawLine(start, end, paintGlow);
    canvas.drawLine(start, end, paintCore);
  }

  @override
  bool shouldRepaint(covariant _WinningStrikePainter oldDelegate) =>
      oldDelegate.cells != cells;
}
