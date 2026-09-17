import 'package:flutter/material.dart';

import '../../../core/models/cards/card_suit.dart';
import '../../../core/models/cards/spanish_card.dart';
import '../../../core/models/cards/spanish_deck.dart';
import '../../../core/presentation/widgets/game_rules_dialog.dart';
import '../../../core/presentation/widgets/spanish_card_view.dart';

/// Pantalla interactiva con tapete verde para simular la Baraja Española tradicional.
/// Permite barajar, cortar, repartir manos (ej. Truco, Caída) e inspeccionar los 4 palos
/// con renderizado fotorrealista de naipes.
class DeckShowcaseScreen extends StatefulWidget {
  const DeckShowcaseScreen({super.key});

  @override
  State<DeckShowcaseScreen> createState() => _DeckShowcaseScreenState();
}

class _DeckShowcaseScreenState extends State<DeckShowcaseScreen> {
  late SpanishDeck _deck;
  Map<String, List<SpanishCard>> _hands = {};
  String _message = 'Mazo preparado con 40 naipes tradicionales.';
  CardSuit? _selectedSuitFilter;
  SpanishCard? _inspectedCard;

  @override
  void initState() {
    super.initState();
    _deck = SpanishDeck();
  }

  void _shuffleDeck() {
    setState(() {
      _deck.shuffle();
      _message = '¡Mazo barajado con algoritmo Fisher-Yates!';
      _inspectedCard = null;
    });
  }

  void _cutDeck() {
    setState(() {
      _deck.cut();
      _message = 'Mazo cortado tradicionalmente por la mitad.';
    });
  }

  void _dealHands(int cardsPerPlayer) {
    setState(() {
      final playerIds = ['Jugador 1 (Tú)', 'Jugador 2 (Rival)'];
      _hands = _deck.dealToPlayers(playerIds, cardsPerPlayer);
      _message =
          'Repartidas $cardsPerPlayer cartas a cada jugador. Quedan ${_deck.remainingCount} cartas en el pozo.';
    });
  }

  void _resetDeck() {
    setState(() {
      _deck.reset();
      _hands.clear();
      _selectedSuitFilter = null;
      _inspectedCard = null;
      _message = 'Mazo reiniciado a las 40 cartas originales.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07241A), // Tapete verde casino oscuro
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3B2C),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.style_rounded, color: Color(0xFFFDE047), size: 22),
            SizedBox(width: 8),
            Text(
              'Mesa de Baraja Española',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFFFDE047)),
            tooltip: 'Reglas y Palos de la Baraja',
            onPressed: () => GameRulesDialog.show(context, 'baraja_espanola'),
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, color: Colors.white70),
            tooltip: 'Reiniciar mazo',
            onPressed: _resetDeck,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTableHeroCard(),
              const SizedBox(height: 16),
              _buildActionsBar(),
              const SizedBox(height: 20),

              // Manos repartidas en la mesa
              if (_hands.isNotEmpty) ...[
                _buildSectionHeader('Cartas en Mesa (Manos Repartidas)', Icons.table_bar_rounded),
                const SizedBox(height: 12),
                for (final entry in _hands.entries) ...[
                  _buildPlayerHand(entry.key, entry.value),
                  const SizedBox(height: 16),
                ],
              ],

              // Filtro por palos para inspeccionar el mazo
              _buildSectionHeader('Inspección de Naipes (${_deck.remainingCount} disponibles)', Icons.visibility_rounded),
              const SizedBox(height: 10),
              _buildSuitFilters(),
              const SizedBox(height: 14),

              // Parrilla de cartas restantes
              _buildRemainingCardsGrid(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFDE047), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D3324),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E563E), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mazo de cartas apiladas en el pozo
          Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(4, 4),
                child: SpanishCardView.back(width: 58, height: 86),
              ),
              Transform.translate(
                offset: const Offset(2, 2),
                child: SpanishCardView.back(width: 58, height: 86),
              ),
              SpanishCardView.back(
                width: 58,
                height: 86,
                onTap: _deck.remainingCount > 0 ? () => _dealHands(3) : null,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mazo Tradicional (40 Naipes)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cartas restantes: ${_deck.remainingCount} / 40',
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _message,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsBar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildActionButton(
          label: 'Barajar',
          icon: Icons.shuffle_rounded,
          color: const Color(0xFF2563EB),
          onPressed: _shuffleDeck,
        ),
        _buildActionButton(
          label: 'Cortar',
          icon: Icons.content_cut_rounded,
          color: const Color(0xFF7C3AED),
          onPressed: _deck.remainingCount > 1 ? _cutDeck : null,
        ),
        _buildActionButton(
          label: 'Repartir 3 c/u',
          icon: Icons.front_hand_rounded,
          color: const Color(0xFF059669),
          onPressed: _deck.remainingCount >= 6 ? () => _dealHands(3) : null,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.white10,
        disabledForegroundColor: Colors.white38,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
      ),
    );
  }

  Widget _buildPlayerHand(String playerTitle, List<SpanishCard> cards) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2D20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1D5A3F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                playerTitle,
                style: const TextStyle(
                  color: Color(0xFFFDE047),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${cards.length} cartas',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: cards.map((c) {
                final isSelected = _inspectedCard == c;
                return SpanishCardView(
                  card: c,
                  width: 82,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _inspectedCard = isSelected ? null : c;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuitFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSuitChip('Todos', null, Icons.auto_awesome_rounded),
          const SizedBox(width: 8),
          _buildSuitChip('Oros', CardSuit.oros, Icons.wb_sunny_rounded),
          const SizedBox(width: 8),
          _buildSuitChip('Copas', CardSuit.copas, Icons.wine_bar_rounded),
          const SizedBox(width: 8),
          _buildSuitChip('Espadas', CardSuit.espadas, Icons.colorize_rounded),
          const SizedBox(width: 8),
          _buildSuitChip('Bastos', CardSuit.bastos, Icons.park_rounded),
        ],
      ),
    );
  }

  Widget _buildSuitChip(String label, CardSuit? suit, IconData icon) {
    final isSelected = _selectedSuitFilter == suit;
    return GestureDetector(
      onTap: () => setState(() => _selectedSuitFilter = suit),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFDE047) : const Color(0xFF0F3B2C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFCA8A04) : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? const Color(0xFF78350F) : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF78350F) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemainingCardsGrid() {
    var cards = _deck.remainingCards;
    if (_selectedSuitFilter != null) {
      cards = cards.where((c) => c.suit == _selectedSuitFilter).toList();
    }

    if (cards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text(
          'No quedan cartas con este filtro.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Center(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: cards.map((c) {
          final isSelected = _inspectedCard == c;
          return SpanishCardView(
            card: c,
            width: 72,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _inspectedCard = isSelected ? null : c;
                _message = 'Naipe seleccionado: ${c.displayName}';
              });
            },
          );
        }).toList(),
      ),
    );
  }
}
