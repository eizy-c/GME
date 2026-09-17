import 'dart:async';
import 'dart:math' as math;
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

class _TrucoPlayer {
  final String id;
  final String name;
  final bool isBot;
  final Color color;
  final int team; // 1 o 2 (en 4 jugadores)
  List<SpanishCard> hand = [];
  String? currentCallout;

  _TrucoPlayer({
    required this.id,
    required this.name,
    required this.isBot,
    required this.color,
    this.team = 1,
  });
}

class _TrickPlayedCard {
  final _TrucoPlayer player;
  final SpanishCard card;
  final int power;

  _TrickPlayedCard({required this.player, required this.card, required this.power});
}

/// Pantalla interactiva del Truco Venezolano tradicional.
/// Soporta 1, 2, 3 y 4 jugadores (con modalidad oficial en parejas 2v2),
/// Vira central con Perico y Perica, cantos de Envido/Flor/Truco con bocadillos,
/// mesa de madera oscura y mano en abanico.
class TrucoScreen extends StatefulWidget {
  final int initialPlayers;
  const TrucoScreen({super.key, this.initialPlayers = 2});

  @override
  State<TrucoScreen> createState() => _TrucoScreenState();
}

class _TrucoScreenState extends State<TrucoScreen> with SingleTickerProviderStateMixin {
  late SpanishDeck _deck;
  late List<_TrucoPlayer> _players;
  SpanishCard? _vira;

  int _playerCount = 2;
  bool _isTeams = false;
  int _currentTurnIndex = 0;
  bool _isGameOver = false;
  String _statusMessage = '¡Bienvenido al Truco!';

  // Puntuación acumulada por bando o jugador
  int _userScore = 0;
  int _rivalScore = 0;

  // Estado de la mano actual (3 bazas)
  int _trucoStake = 1;
  int _team1TricksWon = 0;
  int _team2TricksWon = 0;
  final List<_TrickPlayedCard> _currentTrickCards = [];
  SpanishCard? _selectedCard;

  late AnimationController _timerController;
  Timer? _botTimer;
  Timer? _calloutTimer;
  Timer? _trickTimer;
  Timer? _finishTimer;

  @override
  void initState() {
    super.initState();
    _playerCount = widget.initialPlayers;
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _initMatch(_playerCount, _playerCount == 4, 'Tú');
  }

  @override
  void dispose() {
    _timerController.dispose();
    _botTimer?.cancel();
    _calloutTimer?.cancel();
    _trickTimer?.cancel();
    _finishTimer?.cancel();
    super.dispose();
  }

  void _initMatch(int count, bool teams, String userName) {
    _playerCount = count;
    _isTeams = teams;
    _userScore = 0;
    _rivalScore = 0;
    _isGameOver = false;

    _setupPlayers(totalPlayers: count, userName: userName, teams: teams);

    _startNewHand();
  }

  void _setupPlayers({
    required int totalPlayers,
    required String userName,
    bool teams = false,
  }) {
    _players = [];

    _players.add(_TrucoPlayer(
      id: 'user',
      name: userName,
      isBot: false,
      color: const Color(0xFF38BDF8),
      team: 1,
    ));

    const botColors = [
      Color(0xFFF43F5E),
      Color(0xFF10B981),
      Color(0xFFA855F7),
    ];

    final botCount = totalPlayers == 1 ? 1 : totalPlayers - 1;
    for (int i = 1; i <= botCount; i++) {
      final isTeammate = (totalPlayers == 4 && teams && i == 2);
      final botName = isTeammate ? 'Player $i (Compañero)' : 'Player $i';

      _players.add(_TrucoPlayer(
        id: 'bot_$i',
        name: botName,
        isBot: true,
        color: botColors[(i - 1) % botColors.length],
        team: teams ? (i % 2 == 0 ? 1 : 2) : (i + 1),
      ));
    }
  }

  void _startNewHand() {
    _deck = SpanishDeck()..shuffle();
    _vira = _deck.draw();

    // 3 cartas a cada jugador
    for (final p in _players) {
      p.hand.clear();
      for (int i = 0; i < 3; i++) {
        final c = _deck.draw();
        if (c != null) p.hand.add(c);
      }
    }

    _currentTrickCards.clear();
    _team1TricksWon = 0;
    _team2TricksWon = 0;
    _trucoStake = 1;
    _currentTurnIndex = 0;
    _resetTurnTimer();

    _statusMessage = 'Vira: ${_vira?.displayName}. Perico es el Caballo y Perica la Sota.';
    setState(() {});
  }

  void _resetTurnTimer() {
    _timerController.reset();
    _timerController.forward();
  }

  int _calculateTrucoPower(SpanishCard card) {
    if (_vira == null) return card.number;

    final viraSuit = _vira!.suit;
    final pericoNumber = (_vira!.number == 11) ? 12 : 11;
    final pericaNumber = (_vira!.number == 10) ? 12 : 10;

    if (card.suit == viraSuit && card.number == pericoNumber) return 100;
    if (card.suit == viraSuit && card.number == pericaNumber) return 90;

    if (card.number == 1 && card.suit == CardSuit.espadas) return 50;
    if (card.number == 1 && card.suit == CardSuit.bastos) return 48;
    if (card.number == 7 && card.suit == CardSuit.espadas) return 46;
    if (card.number == 7 && card.suit == CardSuit.oros) return 44;

    if (card.number == 3) return 40;
    if (card.number == 2) return 38;
    if (card.number == 1) return 36;
    if (card.number == 12) return 34;
    if (card.number == 11) return 32;
    if (card.number == 10) return 30;
    if (card.number == 7) return 28;
    if (card.number == 6) return 26;
    if (card.number == 5) return 24;
    return 20;
  }

  void _triggerCallout(_TrucoPlayer player, String message) {
    _calloutTimer?.cancel();
    setState(() => player.currentCallout = message);
    _calloutTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => player.currentCallout = null);
    });
  }

  void _cantarEnvido() {
    if (_currentTurnIndex != 0) return;
    _triggerCallout(_players[0], '¡Envido!');
    _userScore += 2;
    _statusMessage = '¡Envido ganado! (+2 puntos). Juega carta para la baza.';
    setState(() {});
  }

  void _cantarFlor() {
    if (_currentTurnIndex != 0) return;
    _triggerCallout(_players[0], '¡Flor!');
    _userScore += 3;
    _statusMessage = '¡Flor aceptada! (+3 puntos).';
    setState(() {});
  }

  void _subirTruco() {
    if (_trucoStake >= 4) return;
    setState(() {
      _trucoStake += 1;
      final text = _trucoStake == 2 ? '¡Truco!' : _trucoStake == 3 ? '¡Retruco!' : '¡Vale Cuatro!';
      _triggerCallout(_players[0], text);
      _statusMessage = 'Aceptado el $text ($_trucoStake puntos en disputa).';
    });
  }

  void _onUserCardTap(SpanishCard card) {
    if (_currentTurnIndex != 0 || _isGameOver) return;
    if (_selectedCard == card) {
      _playCard(_players[0], card);
      setState(() => _selectedCard = null);
    } else {
      setState(() => _selectedCard = card);
    }
  }

  void _playCard(_TrucoPlayer player, SpanishCard card) {
    setState(() {
      _selectedCard = null;
    });
    player.hand.remove(card);
    final power = _calculateTrucoPower(card);
    _currentTrickCards.add(_TrickPlayedCard(player: player, card: card, power: power));

    setState(() {
      _statusMessage = '${player.name} jugó ${card.displayName}.';
    });

    // Si todos los jugadores jugaron su carta en esta baza
    if (_currentTrickCards.length == _players.length) {
      _trickTimer?.cancel();
      _trickTimer = Timer(const Duration(milliseconds: 800), _resolveTrick);
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

  void _botPlay(_TrucoPlayer bot) {
    if (bot.hand.isEmpty) return;

    // Buscar si puede ganar la carta más alta en mesa
    int highestPowerOnTable = -1;
    for (final t in _currentTrickCards) {
      if (t.power > highestPowerOnTable) highestPowerOnTable = t.power;
    }

    SpanishCard chosen = bot.hand.first;
    for (final c in bot.hand) {
      if (_calculateTrucoPower(c) > highestPowerOnTable) {
        chosen = c;
        break;
      }
    }

    // Posibilidad de cantar Truco
    if (_trucoStake == 1 && _calculateTrucoPower(chosen) >= 44 && math.Random().nextBool()) {
      _triggerCallout(bot, '¡Truco!');
      _trucoStake = 2;
    }

    _playCard(bot, chosen);
  }

  void _resolveTrick() {
    // Evaluar quién tuvo el mayor poder
    _currentTrickCards.sort((a, b) => b.power.compareTo(a.power));
    final winnerCard = _currentTrickCards.first;
    final winner = winnerCard.player;

    if (winner.team == 1) {
      _team1TricksWon += 1;
    } else {
      _team2TricksWon += 1;
    }

    _triggerCallout(winner, '¡Baza!');
    _statusMessage = '${winner.name} ganó la baza con ${winnerCard.card.displayName}.';
    setState(() {});

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _currentTrickCards.clear();

      // Comprobar si algún equipo se llevó 2 bazas
      if (_team1TricksWon >= 2) {
        _userScore += _trucoStake;
        _checkMatchEnd();
      } else if (_team2TricksWon >= 2) {
        _rivalScore += _trucoStake;
        _checkMatchEnd();
      } else if (_players[0].hand.isEmpty) {
        // Se acabaron las 3 bazas
        if (_team1TricksWon >= _team2TricksWon) {
          _userScore += _trucoStake;
        } else {
          _rivalScore += _trucoStake;
        }
        _checkMatchEnd();
      } else {
        // Siguiente baza: sale quien ganó la baza previa
        _currentTurnIndex = _players.indexOf(winner);
        _resetTurnTimer();
        final active = _players[_currentTurnIndex];
        _statusMessage = '${active.name} sale en la siguiente baza.';
        setState(() {});
        if (active.isBot) {
          Future.delayed(const Duration(milliseconds: 700), () => _botPlay(active));
        }
      }
    });
  }

  void _checkMatchEnd() {
    if (_userScore >= 12 || _rivalScore >= 12) {
      _finishGame();
    } else {
      _startNewHand();
    }
  }

  void _finishGame() {
    _isGameOver = true;
    _timerController.stop();

    final userWon = _userScore > _rivalScore;
    final resultEntries = [
      GameResultEntry(name: _players[0].name, scoreChange: userWon ? 2000 : -1000, isWinner: userWon, isUser: true),
      GameResultEntry(name: _players[1].name, scoreChange: userWon ? -1000 : 2000, isWinner: !userWon, isUser: false),
    ];

    setState(() {
      _statusMessage = userWon ? '¡Felicidades! Ganaste la partida de Truco.' : 'Partida terminada. Ganó el bando rival.';
    });

    _finishTimer?.cancel();
    _finishTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        GameResultDialog.show(
          context,
          userWon: userWon,
          subtitle: 'Puntuación final: $_userScore a $_rivalScore puntos',
          entries: resultEntries,
          onRematch: () {
            Navigator.pop(context);
            _initMatch(_playerCount, _isTeams, _players[0].name);
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
      gameTitle: 'Truco Venezolano',
      initialPlayerCount: _playerCount,
      supportTeams: true,
    );
    if (cfg != null && mounted) {
      _initMatch(cfg.playerCount, cfg.isTeams, cfg.playerName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _players[0];

    return Scaffold(
      appBar: GameTableHeader(
        title: 'Truco Venezolano',
        onBack: () => Navigator.pop(context),
        onOpenRules: () => GameRulesDialog.show(context, 'truco'),
        onSettings: _openSetupModal,
        trophies: 7500,
      ),
      body: WoodTableBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildStatusBar(),
              Expanded(
                child: AnimatedBuilder(
                  animation: _timerController,
                  builder: (context, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Vira y cartas en mesa
                        _buildTableCenterWithVira(),

                        // Rivales
                        ..._buildOpponents(),

                        // Jugador en el fondo (Sur)
                        _buildUserBottomArea(user),
                      ],
                    );
                  },
                ),
              ),

              // Botones de Cantos tradicionales
              _buildActionButtons(),

              // Abanico de mano del jugador
              _buildUserHandFan(user),
              const SizedBox(height: 10),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF166534),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF22C55E)),
            ),
            child: Text(
              'Tú: $_userScore | Rival: $_rivalScore',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
          top: 14,
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
          left: 16,
          top: 60,
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
          right: 16,
          top: 60,
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
          left: 14,
          top: 80,
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
          top: 14,
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
          right: 14,
          top: 80,
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

  Widget _buildUserBottomArea(_TrucoPlayer user) {
    return Positioned(
      left: 16,
      bottom: 6,
      child: TablePlayerBadge(
        name: user.name,
        scoreOrCards: user.hand.length,
        isBot: false,
        isCurrentTurn: _currentTurnIndex == 0,
        turnProgress: 1.0 - _timerController.value,
        position: PlayerPositionOnTable.bottom,
        calloutMessage: user.currentCallout,
        cardsInHandCount: user.hand.length,
        avatarColor: user.color,
      ),
    );
  }

  Widget _buildTableCenterWithVira() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Vira central
        if (_vira != null)
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('LA VIRA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Transform.rotate(
                angle: math.pi / 2, // Girada horizontalmente
                child: SpanishCardView(card: _vira!, width: 52),
              ),
            ],
          ),

        const SizedBox(height: 12),

        // Cartas jugadas en la baza actual
        if (_currentTrickCards.isNotEmpty)
          Wrap(
            spacing: 8,
            children: _currentTrickCards.map((tc) {
              return Column(
                children: [
                  SpanishCardView(card: tc.card, width: 56),
                  const SizedBox(height: 2),
                  Text(
                    tc.player.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isMyTurn = _currentTurnIndex == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: isMyTurn ? _cantarEnvido : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Envido', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isMyTurn ? _cantarFlor : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Flor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isMyTurn ? _subirTruco : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              _trucoStake == 1 ? 'Truco' : _trucoStake == 2 ? 'Retruco' : 'Vale 4',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHandFan(_TrucoPlayer user) {
    if (user.hand.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('Esperando nueva mano...', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      );
    }

    final cardCount = user.hand.length;
    final isMyTurn = _currentTurnIndex == 0;

    return SizedBox(
      height: 120,
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: List.generate(cardCount, (index) {
            final card = user.hand[index];
            final mid = (cardCount - 1) / 2.0;
            final offsetIndex = index - mid;
            final angle = offsetIndex * 0.08;
            final xTranslation = offsetIndex * 40.0;
            final yTranslation = math.pow(offsetIndex.abs(), 1.5) * 4.0;

            final isCardSelected = isMyTurn && _selectedCard == card;
            final yOffset = isCardSelected ? -20.0 : 0.0;

            return Transform.translate(
              offset: Offset(xTranslation, yTranslation + yOffset),
              child: Transform.rotate(
                angle: angle,
                child: GestureDetector(
                  onTap: isMyTurn ? () => _onUserCardTap(card) : null,
                  child: AnimatedScale(
                    scale: isCardSelected ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: isCardSelected
                                ? const Color(0xFF38BDF8).withValues(alpha: 0.9)
                                : Colors.black.withValues(alpha: 0.35),
                            blurRadius: isCardSelected ? 16 : 4,
                            spreadRadius: isCardSelected ? 3 : 0,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: SpanishCardView(
                        card: card,
                        width: 72,
                        isSelected: isCardSelected,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
