import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/models/domino/domino_set.dart';
import '../../../core/models/domino/domino_tile.dart';
import '../../../core/presentation/widgets/domino_tile_view.dart';
import '../../../core/presentation/widgets/game_result_dialog.dart';
import '../../../core/presentation/widgets/game_rules_dialog.dart';
import '../../../core/presentation/widgets/game_table_header.dart';
import '../../../core/presentation/widgets/match_setup_dialog.dart';
import '../../../core/presentation/widgets/table_player_badge.dart';
import '../../../core/presentation/widgets/wood_table_background.dart';

class _DominoPlayer {
  final String id;
  final String name;
  final bool isBot;
  final Color color;
  final int team; // 1 o 2 (para 4 jugadores parejas)
  List<DominoTile> hand = [];
  String? currentCallout;

  _DominoPlayer({
    required this.id,
    required this.name,
    required this.isBot,
    required this.color,
    this.team = 1,
  });

  int get pipSum => hand.fold<int>(0, (sum, t) => sum + t.totalPips);
}

/// Pantalla interactiva del tradicional Dominó Doble 6.
/// Soporta 1, 2, 3 y 4 jugadores (Individual o Parejas 2v2 tradicional venezolano),
/// pozo de robo, tranques, mesa de madera rústica y cadena central.
class DominoScreen extends StatefulWidget {
  final int initialPlayers;
  const DominoScreen({super.key, this.initialPlayers = 4});

  @override
  State<DominoScreen> createState() => _DominoScreenState();
}

class _DominoScreenState extends State<DominoScreen> with SingleTickerProviderStateMixin {
  late DominoSet _dominoSet;
  late List<_DominoPlayer> _players;
  final List<DominoTile> _tableChain = [];

  int _playerCount = 4;
  bool _isTeams = true;
  int _currentTurnIndex = 0;
  int? _leftEnd;
  int? _rightEnd;
  bool _isGameOver = false;
  String _statusMessage = 'Iniciando partida de Dominó...';

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
    _initGame(_playerCount, _playerCount == 4, 'Tú');
  }

  @override
  void dispose() {
    _timerController.dispose();
    _botTimer?.cancel();
    _calloutTimer?.cancel();
    _finishTimer?.cancel();
    super.dispose();
  }

  void _initGame(int count, bool teams, String userName) {
    _playerCount = count;
    _isTeams = teams;
    _dominoSet = DominoSet()..shuffle();
    _tableChain.clear();
    _leftEnd = null;
    _rightEnd = null;
    _isGameOver = false;

    _setupPlayers(totalPlayers: count, userName: userName, teams: teams);

    // Repartir 7 fichas a cada jugador
    for (final p in _players) {
      p.hand.clear();
      for (int i = 0; i < 7; i++) {
        final t = _dominoSet.draw();
        if (t != null) p.hand.add(t);
      }
    }

    // Quién tiene el doble más alto realiza la salida
    int starterIndex = 0;
    int highestDouble = -1;
    for (int i = 0; i < _players.length; i++) {
      for (final t in _players[i].hand) {
        if (t.isDouble && t.left > highestDouble) {
          highestDouble = t.left;
          starterIndex = i;
        }
      }
    }

    _currentTurnIndex = starterIndex;
    _resetTurnTimer();

    final starter = _players[starterIndex];
    if (starter.isBot) {
      _statusMessage = '${starter.name} tiene el doble más alto y abre la mesa...';
      setState(() {});
      _botTimer?.cancel();
      _botTimer = Timer(const Duration(milliseconds: 800), () => _botPlay(starter));
    } else {
      _statusMessage = '¡Tienes el doble más alto! Juega tu ficha para iniciar.';
      setState(() {});
    }
  }

  void _setupPlayers({
    required int totalPlayers,
    required String userName,
    bool teams = false,
  }) {
    _players = [];

    _players.add(_DominoPlayer(
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

      _players.add(_DominoPlayer(
        id: 'bot_$i',
        name: botName,
        isBot: true,
        color: botColors[(i - 1) % botColors.length],
        team: teams ? (i % 2 == 0 ? 1 : 2) : (i + 1),
      ));
    }
  }

  void _resetTurnTimer() {
    _timerController.reset();
    _timerController.forward();
  }

  void _triggerCallout(_DominoPlayer player, String message) {
    _calloutTimer?.cancel();
    setState(() => player.currentCallout = message);
    _calloutTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => player.currentCallout = null);
    });
  }

  void _onPlayerTileTap(DominoTile tile) {
    if (_currentTurnIndex != 0 || _isGameOver) return;

    if (_tableChain.isEmpty) {
      _playTile(_players[0], tile, toLeft: false);
      return;
    }

    final fitsLeft = tile.canConnectWith(_leftEnd!);
    final fitsRight = tile.canConnectWith(_rightEnd!);

    if (!fitsLeft && !fitsRight) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esa ficha no encaja en los extremos abiertos de la mesa.'),
          duration: Duration(milliseconds: 900),
          backgroundColor: Color(0xFF991B1B),
        ),
      );
      return;
    }

    if (fitsLeft && fitsRight && _leftEnd != _rightEnd) {
      _showChooseEndDialog(tile);
    } else if (fitsLeft) {
      _playTile(_players[0], tile, toLeft: true);
    } else {
      _playTile(_players[0], tile, toLeft: false);
    }
  }

  void _showChooseEndDialog(DominoTile tile) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E143C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿En cuál extremo jugar?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'La ficha encaja en ambos extremos de la cadena.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _playTile(_players[0], tile, toLeft: true);
            },
            child: Text('Extremo Izquierdo ($_leftEnd)', style: const TextStyle(color: Color(0xFF38BDF8))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _playTile(_players[0], tile, toLeft: false);
            },
            child: Text('Extremo Derecho ($_rightEnd)', style: const TextStyle(color: Color(0xFF34D399))),
          ),
        ],
      ),
    );
  }

  void _playTile(_DominoPlayer player, DominoTile tile, {required bool toLeft}) {
    player.hand.remove(tile);

    DominoTile oriented = tile;
    if (_tableChain.isEmpty) {
      _leftEnd = tile.left;
      _rightEnd = tile.right;
      _tableChain.add(tile);
    } else if (toLeft) {
      if (tile.right == _leftEnd) {
        oriented = tile;
      } else {
        oriented = tile.flip();
      }
      _leftEnd = oriented.left;
      _tableChain.insert(0, oriented);
    } else {
      if (tile.left == _rightEnd) {
        oriented = tile;
      } else {
        oriented = tile.flip();
      }
      _rightEnd = oriented.right;
      _tableChain.add(oriented);
    }

    // Comprobar si ganó la mano (Dominó)
    if (player.hand.isEmpty) {
      _triggerCallout(player, '¡Dominó!');
      _finishGame(winner: player, isTranque: false);
      return;
    }

    _advanceTurn();
  }

  void _advanceTurn() {
    // Comprobar si la partida está trancada (nadie puede jugar ni hay fichas en el pozo)
    if (_isGameTranqued()) {
      _finishGame(winner: _resolveTranqueWinner(), isTranque: true);
      return;
    }

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

  bool _isGameTranqued() {
    if (_tableChain.isEmpty) return false;
    if (_dominoSet.remainingCount > 0) return false;
    for (final p in _players) {
      for (final t in p.hand) {
        if (t.canConnectWith(_leftEnd!) || t.canConnectWith(_rightEnd!)) {
          return false;
        }
      }
    }
    return true;
  }

  _DominoPlayer _resolveTranqueWinner() {
    // En tranque gana quien tenga menor cantidad de puntos en mano
    final sorted = [..._players]..sort((a, b) => a.pipSum.compareTo(b.pipSum));
    return sorted.first;
  }

  void _botPlay(_DominoPlayer bot) {
    if (_isGameOver) return;

    // Buscar ficha jugable
    DominoTile? chosen;
    bool toLeft = false;

    if (_tableChain.isEmpty) {
      // Primera ficha: bot sale con su doble más alto o la primera
      chosen = bot.hand.first;
      for (final t in bot.hand) {
        if (t.isDouble && (!chosen!.isDouble || t.left > chosen.left)) {
          chosen = t;
        }
      }
    } else {
      for (final t in bot.hand) {
        if (_leftEnd != null && t.canConnectWith(_leftEnd!)) {
          chosen = t;
          toLeft = true;
          break;
        }
        if (_rightEnd != null && t.canConnectWith(_rightEnd!)) {
          chosen = t;
          toLeft = false;
          break;
        }
      }
    }

    if (chosen != null) {
      _playTile(bot, chosen, toLeft: toLeft);
    } else if (_dominoSet.remainingCount > 0) {
      // Robar del pozo
      final drawn = _dominoSet.draw();
      if (drawn != null) {
        bot.hand.add(drawn);
        _triggerCallout(bot, 'Robó ficha');
        setState(() {});
        _botTimer?.cancel();
        _botTimer = Timer(const Duration(milliseconds: 600), () => _botPlay(bot));
      }
    } else {
      // Pasa turno
      _triggerCallout(bot, 'Paso');
      _advanceTurn();
    }
  }

  void _userDrawOrPass() {
    if (_currentTurnIndex != 0 || _isGameOver) return;

    final hasPlayable = _players[0].hand.any(
      (t) => _tableChain.isEmpty || t.canConnectWith(_leftEnd!) || t.canConnectWith(_rightEnd!),
    );

    if (hasPlayable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes pasar ni robar porque tienes una ficha jugable.'),
          duration: Duration(milliseconds: 900),
          backgroundColor: Color(0xFFB45309),
        ),
      );
      return;
    }

    if (_dominoSet.remainingCount > 0) {
      final drawn = _dominoSet.draw();
      if (drawn != null) {
        setState(() {
          _players[0].hand.add(drawn);
          _statusMessage = 'Robaste [$drawn]. Si encaja, puedes jugarla.';
        });
      }
    } else {
      _triggerCallout(_players[0], 'Paso');
      _advanceTurn();
    }
  }

  void _finishGame({required _DominoPlayer winner, required bool isTranque}) {
    _isGameOver = true;
    _timerController.stop();

    final userWon = (_isTeams && _playerCount == 4)
        ? (winner.team == _players[0].team)
        : (winner.id == _players[0].id);

    final resultEntries = _players.map((p) {
      final isWin = (_isTeams && _playerCount == 4) ? (p.team == winner.team) : (p.id == winner.id);
      return GameResultEntry(
        name: p.name,
        scoreChange: isWin ? 2000 : -1000,
        isWinner: isWin,
        isUser: p.id == 'user',
      );
    }).toList();

    setState(() {
      _statusMessage = isTranque
          ? '¡Partida Trancada! Ganó ${winner.name} con menor puntuación (${winner.pipSum} pts).'
          : '¡DOMINÓ! Ganó ${winner.name}.';
    });

    _finishTimer?.cancel();
    _finishTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        GameResultDialog.show(
          context,
          userWon: userWon,
          subtitle: isTranque
              ? 'Tranque resuelto por menor conteo de puntos en mano.'
              : '${winner.name} colocó todas sus fichas.',
          entries: resultEntries,
          onRematch: () {
            Navigator.pop(context);
            _initGame(_playerCount, _isTeams, _players[0].name);
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
      gameTitle: 'Dominó Doble 6',
      initialPlayerCount: _playerCount,
      supportTeams: true,
    );
    if (cfg != null && mounted) {
      _initGame(cfg.playerCount, cfg.isTeams, cfg.playerName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _players[0];

    return Scaffold(
      appBar: GameTableHeader(
        title: 'Dominó Tradicional (Doble 6)',
        onBack: () => Navigator.pop(context),
        onOpenRules: () => GameRulesDialog.show(context, 'domino'),
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
                        // Cadena central de dominó
                        _buildTableChainView(),

                        // Rivales en las posiciones correspondientes
                        ..._buildOpponents(),

                        // Jugador abajo (Sur)
                        _buildUserBottomArea(user),
                      ],
                    );
                  },
                ),
              ),

              // Mano del jugador (Fichas verticales marfil pulido)
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
          Row(
            children: [
              if (_dominoSet.remainingCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Pozo: ${_dominoSet.remainingCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
              ],
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
                  child: Text(
                    '$_playerCount Jug.',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
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
          top: 10,
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
          top: 40,
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
          top: 40,
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
          top: 50,
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
          top: 10,
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
          top: 50,
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

  Widget _buildUserBottomArea(_DominoPlayer user) {
    final isMyTurn = _currentTurnIndex == 0;
    return Positioned(
      left: 14,
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

          // Botón Robar / Pasar
          if (isMyTurn && !_isGameOver)
            ElevatedButton(
              onPressed: _userDrawOrPass,
              style: ElevatedButton.styleFrom(
                backgroundColor: _dominoSet.remainingCount > 0 ? const Color(0xFF0F766E) : const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _dominoSet.remainingCount > 0 ? 'Robar' : 'Pasar',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableChainView() {
    if (_tableChain.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: const Text(
          'Mesa vacía.\nRealiza la primera salida.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 220, maxWidth: 300),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _tableChain.map((t) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: DominoTileView(
                tile: t,
                size: 38,
                isVertical: t.isDouble,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUserHandRow(_DominoPlayer user) {
    if (user.hand.isEmpty) return const SizedBox(height: 80);

    final isMyTurn = _currentTurnIndex == 0;

    return Container(
      height: 95,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: user.hand.map((tile) {
              final canPlay = isMyTurn &&
                  (_tableChain.isEmpty || tile.canConnectWith(_leftEnd!) || tile.canConnectWith(_rightEnd!));

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: isMyTurn ? () => _onPlayerTileTap(tile) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.translationValues(0, canPlay ? -8 : 0, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        if (canPlay)
                          BoxShadow(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Opacity(
                      opacity: (!isMyTurn || canPlay) ? 1.0 : 0.6,
                      child: DominoTileView(
                        tile: tile,
                        size: 42,
                        isVertical: true,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
