import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/models/cards/card_suit.dart';
import '../../../core/models/cards/spanish_card.dart';
import '../../../core/models/cards/spanish_deck.dart';
import '../../../core/presentation/widgets/game_result_dialog.dart';
import '../../../core/presentation/widgets/game_rules_dialog.dart';
import '../../../core/presentation/widgets/game_table_header.dart';
import '../../../core/presentation/widgets/match_setup_dialog.dart';
import '../../../core/presentation/widgets/spanish_card_view.dart';
import '../../../core/presentation/widgets/table_player_badge.dart';
import '../../../core/presentation/widgets/wood_table_background.dart';

class _CinquilloPlayer {
  final String id;
  final String name;
  final bool isBot;
  final Color color;
  List<SpanishCard> hand = [];
  String? currentCallout;

  _CinquilloPlayer({
    required this.id,
    required this.name,
    required this.isBot,
    required this.color,
  });
}

/// Pantalla interactiva del juego tradicional "Cinquillo".
/// Soporta 1, 2, 3 y 4 jugadores (con reparto oficial de 10 cartas en 4 jugadores),
/// apertura con 5 de Oros, columnas centrales por palo y mesa de madera rústica.
class CinquilloScreen extends StatefulWidget {
  final int initialPlayers;
  const CinquilloScreen({super.key, this.initialPlayers = 4});

  @override
  State<CinquilloScreen> createState() => _CinquilloScreenState();
}

class _CinquilloScreenState extends State<CinquilloScreen> with SingleTickerProviderStateMixin {
  late SpanishDeck _deck;
  late List<_CinquilloPlayer> _players;
  int _playerCount = 4;
  int _currentTurnIndex = 0;
  bool _isGameOver = false;
  String _statusMessage = 'Iniciando Cinquillo...';

  // Cartas colocadas en mesa agrupadas por palo
  final Map<CardSuit, List<SpanishCard>> _tableCards = {
    CardSuit.oros: [],
    CardSuit.copas: [],
    CardSuit.espadas: [],
    CardSuit.bastos: [],
  };

  late AnimationController _timerController;
  Timer? _botTimer;
  Timer? _calloutTimer;
  Timer? _finishTimer;

  @override
  void initState() {
    super.initState();
    _playerCount = widget.initialPlayers;
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _initMatch(_playerCount, 'Tú');
  }

  @override
  void dispose() {
    _timerController.dispose();
    _botTimer?.cancel();
    _calloutTimer?.cancel();
    _finishTimer?.cancel();
    super.dispose();
  }

  void _initMatch(int count, String userName) {
    _playerCount = count;
    _deck = SpanishDeck()..shuffle();
    _tableCards.forEach((_, list) => list.clear());
    _isGameOver = false;

    _setupPlayers(totalPlayers: count, userName: userName);

    // Reparto equitativo de las 40 cartas
    final numPlayers = _players.length;
    int index = 0;
    while (_deck.remainingCount > 0) {
      final c = _deck.draw();
      if (c != null) {
        _players[index % numPlayers].hand.add(c);
        index++;
      }
    }

    for (final p in _players) {
      _sortHand(p.hand);
    }

    // Quién tiene el 5 de Oros abre la mesa
    int starterIndex = 0;
    for (int i = 0; i < _players.length; i++) {
      if (_players[i].hand.any((c) => c.suit == CardSuit.oros && c.number == 5)) {
        starterIndex = i;
        break;
      }
    }

    _currentTurnIndex = starterIndex;
    _resetTurnTimer();

    final starter = _players[starterIndex];
    if (starter.isBot) {
      _statusMessage = '${starter.name} tiene el 5 de Oros y abre la mesa...';
      setState(() {});
      _botTimer?.cancel();
      _botTimer = Timer(const Duration(milliseconds: 900), () => _botPlay(starter));
    } else {
      _statusMessage = '¡Tienes el 5 de Oros! Colócalo para iniciar la partida.';
      setState(() {});
    }
  }

  void _setupPlayers({required int totalPlayers, required String userName}) {
    _players = [];

    // 1. Asiento 0: Jugador local
    _players.add(_CinquilloPlayer(
      id: 'user',
      name: userName,
      isBot: false,
      color: const Color(0xFF38BDF8),
    ));

    const botColors = [
      Color(0xFFF43F5E),
      Color(0xFF10B981),
      Color(0xFFA855F7),
    ];

    final botCount = totalPlayers == 1 ? 1 : totalPlayers - 1;
    for (int i = 1; i <= botCount; i++) {
      _players.add(_CinquilloPlayer(
        id: 'bot_$i',
        name: 'Player $i',
        isBot: true,
        color: botColors[(i - 1) % botColors.length],
      ));
    }
  }

  void _sortHand(List<SpanishCard> hand) {
    hand.sort((a, b) {
      final suitCmp = a.suit.index.compareTo(b.suit.index);
      if (suitCmp != 0) return suitCmp;
      return a.number.compareTo(b.number);
    });
  }

  void _resetTurnTimer() {
    _timerController.reset();
    _timerController.forward();
  }

  bool _isPlayable(SpanishCard card) {
    final suitCards = _tableCards[card.suit]!;
    if (suitCards.isEmpty) {
      return card.number == 5; // Solo se abre con el 5 de cada palo
    }

    final minNumber = suitCards.map((c) => c.number).reduce((a, b) => a < b ? a : b);
    final maxNumber = suitCards.map((c) => c.number).reduce((a, b) => a > b ? a : b);

    // Hacia abajo: 5 -> 4 -> 3 -> 2 -> 1
    if (card.number == minNumber - 1) return true;
    if (minNumber == 10 && card.number == 7) return true;

    // Hacia arriba: 5 -> 6 -> 7 -> 10 -> 11 -> 12
    if (card.number == maxNumber + 1) return true;
    if (maxNumber == 7 && card.number == 10) return true;

    return false;
  }

  void _triggerCallout(_CinquilloPlayer player, String message) {
    _calloutTimer?.cancel();
    setState(() => player.currentCallout = message);
    _calloutTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => player.currentCallout = null);
    });
  }

  void _onUserCardTap(SpanishCard card) {
    if (_currentTurnIndex != 0 || _isGameOver) return;

    if (!_isPlayable(card)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No puedes jugar ${card.displayName}. Solo cartas consecutivas o el 5 de un palo.'),
          duration: const Duration(milliseconds: 900),
          backgroundColor: const Color(0xFF991B1B),
        ),
      );
      return;
    }

    _playCard(_players[0], card);
  }

  void _playCard(_CinquilloPlayer player, SpanishCard card) {
    player.hand.remove(card);
    final suitList = _tableCards[card.suit]!;
    suitList.add(card);
    _sortHand(suitList);

    if (player.hand.isEmpty) {
      _finishGame(player);
      return;
    }

    _advanceTurn();
  }

  void _advanceTurn() {
    _currentTurnIndex = (_currentTurnIndex + 1) % _players.length;
    _resetTurnTimer();

    final active = _players[_currentTurnIndex];
    setState(() {
      _statusMessage = active.isBot ? 'Turno de ${active.name} pensando...' : '¡Es tu turno!';
    });

    if (active.isBot) {
      _botTimer?.cancel();
      _botTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted && !_isGameOver && _currentTurnIndex == _players.indexOf(active)) {
          _botPlay(active);
        }
      });
    }
  }

  void _botPlay(_CinquilloPlayer bot) {
    if (_isGameOver) return;

    SpanishCard? playable;
    for (final c in bot.hand) {
      if (_isPlayable(c)) {
        playable = c;
        break;
      }
    }

    if (playable != null) {
      _playCard(bot, playable);
    } else {
      // Bot no tiene jugada: canta "Paso"
      _triggerCallout(bot, 'Paso');
      _advanceTurn();
    }
  }

  void _userPass() {
    if (_currentTurnIndex != 0 || _isGameOver) return;

    final hasPlayable = _players[0].hand.any(_isPlayable);
    if (hasPlayable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes pasar porque tienes al menos una carta jugable.'),
          duration: Duration(milliseconds: 900),
          backgroundColor: Color(0xFFB45309),
        ),
      );
      return;
    }

    _triggerCallout(_players[0], 'Paso');
    _advanceTurn();
  }

  void _finishGame(_CinquilloPlayer winner) {
    _isGameOver = true;
    _timerController.stop();

    final userWon = winner.id == 'user';
    final resultEntries = _players.map((p) {
      final isWin = p.id == winner.id;
      return GameResultEntry(
        name: p.name,
        scoreChange: isWin ? 2000 : -1000,
        isWinner: isWin,
        isUser: p.id == 'user',
      );
    }).toList();

    setState(() {
      _statusMessage = userWon ? '¡Felicidades! Ganaste el Cinquillo.' : 'Partida terminada. Ganó ${winner.name}.';
    });

    _finishTimer?.cancel();
    _finishTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        GameResultDialog.show(
          context,
          userWon: userWon,
          subtitle: '${winner.name} se quedó sin cartas y completó la mesa.',
          entries: resultEntries,
          onRematch: () {
            Navigator.pop(context);
            _initMatch(_playerCount, _players[0].name);
          },
          onBackToMenu: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        );
      }
    });
  }

  void _openSetupModal() async {
    final cfg = await MatchSetupDialog.show(
      context,
      gameTitle: 'Cinquillo Tradicional',
      initialPlayerCount: _playerCount,
      supportTeams: false,
    );
    if (cfg != null && mounted) {
      _initMatch(cfg.playerCount, cfg.playerName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _players[0];
    final hasPlayable = user.hand.any(_isPlayable);

    return Scaffold(
      appBar: GameTableHeader(
        title: 'Cinquillo Tradicional',
        onBack: () => Navigator.pop(context),
        onOpenRules: () => GameRulesDialog.show(context, 'cinquillo'),
        onSettings: _openSetupModal,
        trophies: 7500,
      ),
      body: WoodTableBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Barra de estado
              _buildStatusBar(),

              // Área de juego con rivales y las 4 columnas centrales
              Expanded(
                child: AnimatedBuilder(
                  animation: _timerController,
                  builder: (context, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Columnas centrales de naipes (Oros, Copas, Espadas, Bastos)
                        _buildSuitColumns(),

                        // Rivales alrededor de la mesa
                        ..._buildOpponents(),

                        // Badge del usuario abajo a la izquierda
                        _buildUserBottomArea(user, hasPlayable),
                      ],
                    );
                  },
                ),
              ),

              // Mano del jugador (scrollable horizontal o abanico de cartas)
              _buildUserHandRow(user),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.black.withValues(alpha: 0.45),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _statusMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFFDE047), fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          InkWell(
            onTap: _openSetupModal,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF381F78),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF7C4DFF), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text('$_playerCount Jug.', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOpponents() {
    final widgets = <Widget>[];

    if (_players.length == 2) {
      final rival = _players[1];
      widgets.add(
        Positioned(
          top: 8,
          child: TablePlayerBadge(
            name: rival.name,
            scoreOrCards: rival.hand.length,
            isBot: rival.isBot,
            isCurrentTurn: _currentTurnIndex == 1,
            turnProgress: 1.0 - _timerController.value,
            position: PlayerPositionOnTable.top,
            calloutMessage: rival.currentCallout,
            cardsInHandCount: rival.hand.length,
            avatarColor: rival.color,
          ),
        ),
      );
    } else if (_players.length == 3) {
      final rival1 = _players[1];
      final rival2 = _players[2];

      widgets.add(
        Positioned(
          left: 12,
          top: 30,
          child: TablePlayerBadge(
            name: rival1.name,
            scoreOrCards: rival1.hand.length,
            isBot: rival1.isBot,
            isCurrentTurn: _currentTurnIndex == 1,
            turnProgress: 1.0 - _timerController.value,
            position: PlayerPositionOnTable.left,
            calloutMessage: rival1.currentCallout,
            cardsInHandCount: rival1.hand.length,
            avatarColor: rival1.color,
          ),
        ),
      );

      widgets.add(
        Positioned(
          right: 12,
          top: 30,
          child: TablePlayerBadge(
            name: rival2.name,
            scoreOrCards: rival2.hand.length,
            isBot: rival2.isBot,
            isCurrentTurn: _currentTurnIndex == 2,
            turnProgress: 1.0 - _timerController.value,
            position: PlayerPositionOnTable.right,
            calloutMessage: rival2.currentCallout,
            cardsInHandCount: rival2.hand.length,
            avatarColor: rival2.color,
          ),
        ),
      );
    } else if (_players.length == 4) {
      final rival1 = _players[1];
      final rival2 = _players[2];
      final rival3 = _players[3];

      widgets.add(
        Positioned(
          left: 10,
          top: 35,
          child: TablePlayerBadge(
            name: rival1.name,
            scoreOrCards: rival1.hand.length,
            isBot: rival1.isBot,
            isCurrentTurn: _currentTurnIndex == 1,
            turnProgress: 1.0 - _timerController.value,
            position: PlayerPositionOnTable.left,
            calloutMessage: rival1.currentCallout,
            cardsInHandCount: rival1.hand.length,
            avatarColor: rival1.color,
          ),
        ),
      );

      widgets.add(
        Positioned(
          top: 8,
          child: TablePlayerBadge(
            name: rival2.name,
            scoreOrCards: rival2.hand.length,
            isBot: rival2.isBot,
            isCurrentTurn: _currentTurnIndex == 2,
            turnProgress: 1.0 - _timerController.value,
            position: PlayerPositionOnTable.top,
            calloutMessage: rival2.currentCallout,
            cardsInHandCount: rival2.hand.length,
            avatarColor: rival2.color,
          ),
        ),
      );

      widgets.add(
        Positioned(
          right: 10,
          top: 35,
          child: TablePlayerBadge(
            name: rival3.name,
            scoreOrCards: rival3.hand.length,
            isBot: rival3.isBot,
            isCurrentTurn: _currentTurnIndex == 3,
            turnProgress: 1.0 - _timerController.value,
            position: PlayerPositionOnTable.right,
            calloutMessage: rival3.currentCallout,
            cardsInHandCount: rival3.hand.length,
            avatarColor: rival3.color,
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildUserBottomArea(_CinquilloPlayer user, bool hasPlayable) {
    final isMyTurn = _currentTurnIndex == 0;
    return Positioned(
      left: 12,
      bottom: 6,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TablePlayerBadge(
            name: user.name,
            scoreOrCards: user.hand.length,
            isBot: false,
            isCurrentTurn: isMyTurn,
            turnProgress: 1.0 - _timerController.value,
            position: PlayerPositionOnTable.bottom,
            calloutMessage: user.currentCallout,
            cardsInHandCount: user.hand.length,
            avatarColor: user.color,
          ),
          const SizedBox(width: 8),

          // Botón "Pasar"
          if (isMyTurn && !_isGameOver)
            ElevatedButton(
              onPressed: !hasPlayable ? _userPass : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: !hasPlayable ? const Color(0xFFE11D48) : Colors.grey.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Pasar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildSuitColumns() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320, maxHeight: 250),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: CardSuit.values.map((suit) {
          final cards = _tableCards[suit]!;
          return _buildSingleSuitColumn(suit, cards);
        }).toList(),
      ),
    );
  }

  Widget _buildSingleSuitColumn(CardSuit suit, List<SpanishCard> cards) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Encabezado del palo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            suit.label,
            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 6),

        // Pila visual compacta de cartas jugadas en este palo
        Container(
          width: 58,
          height: 190,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: cards.isEmpty
            ? const Center(
                child: Text(
                  'Falta 5',
                  style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: cards.map((c) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.5),
                      child: SpanishCardView(
                        card: c,
                        width: 50,
                      ),
                    );
                  }).toList(),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildUserHandRow(_CinquilloPlayer user) {
    if (user.hand.isEmpty) return const SizedBox(height: 100);

    final isMyTurn = _currentTurnIndex == 0;

    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: user.hand.length,
        separatorBuilder: (_, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final card = user.hand[index];
          final playable = isMyTurn && _isPlayable(card);

          return GestureDetector(
            onTap: playable ? () => _onUserCardTap(card) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.translationValues(0, playable ? -8 : 0, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  if (playable)
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Opacity(
                opacity: (!isMyTurn || playable) ? 1.0 : 0.6,
                child: SpanishCardView(
                  card: card,
                  width: 66,
                  isSelected: playable,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
