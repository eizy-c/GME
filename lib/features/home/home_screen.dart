import 'package:flutter/material.dart';

import '../../core/models/domino/domino_tile.dart';
import '../../core/presentation/widgets/domino_tile_view.dart';
import '../../core/presentation/widgets/game_rules_dialog.dart';
import '../../core/stats/game_stats.dart';
import '../../core/stats/stats_repository.dart';
import '../domino/presentation/domino_screen.dart';
import '../la_caida/presentation/caida_splash_screen.dart';

enum GameCategoryFilter { all, board, cards }

/// Pantalla principal y menú categorizado del compendio de juegos tradicionales.
/// Configurado exclusivamente para Dominó y La Caída.
class HomeScreen extends StatefulWidget {
  final StatsRepository statsRepository;

  const HomeScreen({super.key, required this.statsRepository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameStats _dominoStats = const GameStats(gameType: GameType.domino);
  GameStats _caidaStats = const GameStats(gameType: GameType.laCaida);
  GameCategoryFilter _selectedCategory = GameCategoryFilter.all;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    final d = await widget.statsRepository.getStats(GameType.domino);
    final c = await widget.statsRepository.getStats(GameType.laCaida);
    if (mounted) {
      setState(() {
        _dominoStats = d;
        _caidaStats = c;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11192A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0D9488)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.casino_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Compendio de Juegos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.3),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: Color(0xFFFDE047)),
            tooltip: 'Guía de Reglas',
            onPressed: () => GameRulesDialog.show(context, 'domino'),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF065F46).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981), width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded, size: 14, color: Color(0xFF34D399)),
                SizedBox(width: 6),
                Text(
                  '100% OFFLINE',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeroBanner(),
            const SizedBox(height: 18),
            _buildCategorySelector(),
            const SizedBox(height: 16),
            ..._buildFilteredGameCards(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16233B), Color(0xFF0D1524)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF233653), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 0.8),
                  ),
                  child: const Text(
                    'MOTOR MODULAR DE JUEGOS',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tradición en tu Bolsillo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Todos los juegos activos contra Bots o rivales locales con reglas explicadas.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0E4E4A)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF14B8A6), width: 1),
            ),
            child: const Icon(Icons.videogame_asset_rounded, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Catálogo Activo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
            Text(
              '${_getFilteredCount()} juegos disponibles',
              style: const TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip(
                label: 'Todos (2)',
                filter: GameCategoryFilter.all,
                icon: Icons.grid_view_rounded,
              ),
              const SizedBox(width: 8),
              _buildCategoryChip(
                label: 'Dominó (Mesa)',
                filter: GameCategoryFilter.board,
                icon: Icons.casino_rounded,
              ),
              const SizedBox(width: 8),
              _buildCategoryChip(
                label: 'CaidaGO (Cartas)',
                filter: GameCategoryFilter.cards,
                icon: Icons.style_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required GameCategoryFilter filter,
    required IconData icon,
  }) {
    final isSelected = _selectedCategory == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF141F32),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : Colors.white12,
            width: 1.2,
          ),
          boxShadow: isSelected
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getFilteredCount() {
    switch (_selectedCategory) {
      case GameCategoryFilter.all:
        return 2;
      case GameCategoryFilter.board:
        return 1;
      case GameCategoryFilter.cards:
        return 1;
    }
  }

  List<Widget> _buildFilteredGameCards() {
    final cards = <Widget>[];

    final showDomino = _selectedCategory == GameCategoryFilter.all ||
        _selectedCategory == GameCategoryFilter.board;
    final showCaida = _selectedCategory == GameCategoryFilter.all ||
        _selectedCategory == GameCategoryFilter.cards;

    // 1. Dominó Doble 6 (¡ACTIVO!)
    if (showDomino) {
      cards.add(
        _buildGameCard(
          title: 'Dominó (Doble 6)',
          subtitle: '28 fichas de marfil pulido, pozo, tranques e Individual o Parejas',
          badgeText: 'JUGABLE AHORA',
          badgeColor: const Color(0xFF10B981),
          playersText: '1 - 4 JUGADORES',
          categoryText: 'MESA / ESTRATEGIA',
          rulesGameId: 'domino',
          icon: Icons.blur_linear_rounded,
          gradientColors: [const Color(0xFF33200D), const Color(0xFF141A24)],
          accentColor: const Color(0xFFF59E0B),
          statInfo: _dominoStats.totalGames > 0
              ? 'Historial: ${_dominoStats.wins}V - ${_dominoStats.losses}D (${_dominoStats.winRate.toStringAsFixed(0)}% efectividad)'
              : null,
          previewWidget: Transform.scale(
            scale: 0.65,
            child: const DominoTileView(
              tile: DominoTile(6, 6),
              size: 40,
            ),
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DominoScreen(),
              ),
            );
            _refreshStats();
          },
        ),
      );
      cards.add(const SizedBox(height: 12));
    }

    // 2. CaidaGO (¡ACTIVO!)
    if (showCaida) {
      cards.add(
        _buildGameCard(
          title: 'CaidaGO',
          subtitle: 'Mesa tradicional, cantos de Ronda, Patrulla, Trivilín, Limpia y niveles',
          badgeText: 'JUGABLE AHORA',
          badgeColor: const Color(0xFF10B981),
          playersText: '1 - 4 JUGADORES',
          categoryText: 'CARTAS / CANTO',
          rulesGameId: 'la_caida',
          icon: Icons.layers_rounded,
          gradientColors: [const Color(0xFF063E2D), const Color(0xFF0F1E2E)],
          accentColor: const Color(0xFF10B981),
          statInfo: _caidaStats.totalGames > 0
              ? 'Historial: ${_caidaStats.wins}V - ${_caidaStats.losses}D (${_caidaStats.winRate.toStringAsFixed(0)}% efectividad)'
              : null,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CaidaSplashScreen(),
              ),
            );
            _refreshStats();
          },
        ),
      );
      cards.add(const SizedBox(height: 12));
    }

    return cards;
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required String playersText,
    required String categoryText,
    required IconData icon,
    required List<Color> gradientColors,
    required Color accentColor,
    String? rulesGameId,
    String? statInfo,
    Widget? previewWidget,
    VoidCallback? onTap,
    bool isAvailable = true,
  }) {
    return InkWell(
      onTap: isAvailable ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAvailable ? accentColor.withValues(alpha: 0.5) : Colors.white12,
            width: isAvailable ? 1.5 : 1,
          ),
          boxShadow: isAvailable
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (previewWidget != null)
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(child: previewWidget),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: isAvailable ? Colors.white : Colors.white60,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: badgeColor, width: 0.8),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 10),

            // Fila de metadatos (Jugadores, Categoría, Botón de Reglas "¿Cómo jugar?" y Acción JUGAR)
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Etiqueta Jugadores
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_alt_outlined, size: 12, color: Colors.white60),
                              const SizedBox(width: 4),
                              Text(
                                playersText,
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Etiqueta Categoría
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            categoryText,
                            style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),

                        // Botón interactivo de Reglas "¿Cómo jugar?"
                        if (rulesGameId != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => GameRulesDialog.show(context, rulesGameId),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFCA8A04).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFDE047), width: 0.8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.help_outline_rounded, size: 12, color: Color(0xFFFDE047)),
                                  SizedBox(width: 4),
                                  Text(
                                    '¿Cómo jugar?',
                                    style: TextStyle(
                                      color: Color(0xFFFDE047),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                if (isAvailable) ...[
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'JUGAR',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: accentColor),
                    ],
                  ),
                ],
              ],
            ),

            if (statInfo != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF047857).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statInfo,
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
