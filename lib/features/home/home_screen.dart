import 'package:flutter/material.dart';

import '../../core/models/domino/domino_tile.dart';
import '../../core/presentation/widgets/domino_tile_view.dart';
import '../../core/presentation/widgets/game_rules_dialog.dart';
import '../../core/stats/game_stats.dart';
import '../../core/stats/stats_repository.dart';
import '../cinquillo/presentation/cinquillo_screen.dart';
import '../deck_showcase/deck_showcase_screen.dart';
import '../domino/presentation/domino_screen.dart';
import '../la_caida/presentation/caida_screen.dart';
import '../la_vieja/presentation/vieja_screen.dart';
import '../truco/presentation/truco_screen.dart';

enum GameCategoryFilter { all, board, cards }

/// Pantalla principal y menú categorizado del compendio de juegos tradicionales.
/// Todos los juegos están activos y cuentan con botón de guía de reglas "¿Cómo jugar?".
class HomeScreen extends StatefulWidget {
  final StatsRepository statsRepository;

  const HomeScreen({super.key, required this.statsRepository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GameStats _viejaStats = const GameStats(gameType: GameType.laVieja);
  GameCategoryFilter _selectedCategory = GameCategoryFilter.all;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    final s = await widget.statsRepository.getStats(GameType.laVieja);
    if (mounted) setState(() => _viejaStats = s);
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
            onPressed: () => GameRulesDialog.show(context, 'la_vieja'),
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
                label: 'Todos (6)',
                filter: GameCategoryFilter.all,
                icon: Icons.grid_view_rounded,
              ),
              const SizedBox(width: 8),
              _buildCategoryChip(
                label: 'Juegos de Mesa (2)',
                filter: GameCategoryFilter.board,
                icon: Icons.casino_rounded,
              ),
              const SizedBox(width: 8),
              _buildCategoryChip(
                label: 'Juegos de Cartas (4)',
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
        return 6;
      case GameCategoryFilter.board:
        return 2;
      case GameCategoryFilter.cards:
        return 4;
    }
  }

  List<Widget> _buildFilteredGameCards() {
    final cards = <Widget>[];

    final showLaVieja = _selectedCategory == GameCategoryFilter.all ||
        _selectedCategory == GameCategoryFilter.board;
    final showBaraja = _selectedCategory == GameCategoryFilter.all ||
        _selectedCategory == GameCategoryFilter.cards;
    final showDomino = _selectedCategory == GameCategoryFilter.all ||
        _selectedCategory == GameCategoryFilter.board;
    final showCaida = _selectedCategory == GameCategoryFilter.all ||
        _selectedCategory == GameCategoryFilter.cards;
    final showTruco = _selectedCategory == GameCategoryFilter.all ||
        _selectedCategory == GameCategoryFilter.cards;
    final showCinquillo = _selectedCategory == GameCategoryFilter.all ||
        _selectedCategory == GameCategoryFilter.cards;

    // 1. La Vieja
    if (showLaVieja) {
      cards.add(
        _buildGameCard(
          title: 'La Vieja (Tres en Raya)',
          subtitle: 'Tablero 3x3 contra Bot Heurístico o 2 Jugadores locales',
          badgeText: 'JUGABLE AHORA',
          badgeColor: const Color(0xFF10B981),
          playersText: '1 - 2 JUG',
          categoryText: 'MESA / ARCADE',
          rulesGameId: 'la_vieja',
          icon: Icons.grid_3x3_rounded,
          gradientColors: [const Color(0xFF064E3B), const Color(0xFF0F1E2E)],
          accentColor: const Color(0xFF10B981),
          statInfo:
              'Historial: ${_viejaStats.wins}V - ${_viejaStats.losses}D (${_viejaStats.winRate.toStringAsFixed(0)}% efectividad)',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ViejaScreen(statsRepository: widget.statsRepository),
              ),
            );
            _refreshStats();
          },
        ),
      );
      cards.add(const SizedBox(height: 12));
    }

    // 2. Baraja Española
    if (showBaraja) {
      cards.add(
        _buildGameCard(
          title: 'Baraja Española: Motor & Simulador',
          subtitle: '40 naipes de alta fidelidad, barajado Fisher-Yates y reparto',
          badgeText: 'MOTOR LISTO',
          badgeColor: const Color(0xFF38BDF8),
          playersText: '1 - 2 JUG',
          categoryText: 'CARTAS / MESA',
          rulesGameId: 'baraja_espanola',
          icon: Icons.style_rounded,
          gradientColors: [const Color(0xFF1E3A8A), const Color(0xFF0F1E2E)],
          accentColor: const Color(0xFF38BDF8),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DeckShowcaseScreen(),
              ),
            );
          },
        ),
      );
      cards.add(const SizedBox(height: 12));
    }

    // 3. Dominó Doble 6 (¡ACTIVO!)
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
          previewWidget: Transform.scale(
            scale: 0.65,
            child: const DominoTileView(
              tile: DominoTile(6, 6),
              size: 40,
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DominoScreen(),
              ),
            );
          },
        ),
      );
      cards.add(const SizedBox(height: 12));
    }

    // 4. La Caída (¡ACTIVO!)
    if (showCaida) {
      cards.add(
        _buildGameCard(
          title: 'La Caída Tradicional',
          subtitle: 'Mesa de madera, cantos de Ronda, Patrulla, Trivilín y Limpia',
          badgeText: 'JUGABLE AHORA',
          badgeColor: const Color(0xFF10B981),
          playersText: '1 - 4 JUGADORES',
          categoryText: 'CARTAS / CANTO',
          rulesGameId: 'la_caida',
          icon: Icons.layers_rounded,
          gradientColors: [const Color(0xFF063E2D), const Color(0xFF0F1E2E)],
          accentColor: const Color(0xFF10B981),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CaidaScreen(),
              ),
            );
          },
        ),
      );
      cards.add(const SizedBox(height: 12));
    }

    // 5. Truco Venezolano (¡ACTIVO!)
    if (showTruco) {
      cards.add(
        _buildGameCard(
          title: 'Truco Venezolano',
          subtitle: 'Con Vira, Perico, Perica, cantos de Envido, Flor, Truco y Parejas',
          badgeText: 'JUGABLE AHORA',
          badgeColor: const Color(0xFF10B981),
          playersText: '1 - 4 JUGADORES',
          categoryText: 'CARTAS / FAROL',
          rulesGameId: 'truco',
          icon: Icons.local_fire_department_rounded,
          gradientColors: [const Color(0xFF4A1F0D), const Color(0xFF1A130E)],
          accentColor: const Color(0xFFF97316),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TrucoScreen(),
              ),
            );
          },
        ),
      );
      cards.add(const SizedBox(height: 12));
    }

    // 6. Cinquillo (¡ACTIVO!)
    if (showCinquillo) {
      cards.add(
        _buildGameCard(
          title: 'Cinquillo',
          subtitle: 'Apertura con 5 de Oros y escaleras de naipes por palos',
          badgeText: 'JUGABLE AHORA',
          badgeColor: const Color(0xFF10B981),
          playersText: '1 - 4 JUGADORES',
          categoryText: 'CARTAS / ORDEN',
          rulesGameId: 'cinquillo',
          icon: Icons.view_week_rounded,
          gradientColors: [const Color(0xFF1E293B), const Color(0xFF0F172A)],
          accentColor: const Color(0xFF38BDF8),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CinquilloScreen(),
              ),
            );
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

                const Spacer(),

                if (isAvailable) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'JUGAR',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
