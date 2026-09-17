import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/models/cards/spanish_card.dart';
import '../../../core/models/cards/spanish_deck.dart';
import '../../../core/presentation/widgets/game_result_dialog.dart';
import '../../../core/presentation/widgets/game_rules_dialog.dart';
import '../../../core/presentation/widgets/game_table_header.dart';
import '../../../core/presentation/widgets/spanish_card_view.dart';
import '../../../core/presentation/widgets/table_player_badge.dart';
import '../../../core/presentation/widgets/wood_table_background.dart';

class _PlayerState {
  final String id;
  final String name;
  final bool isBot;
  final Color color;
  final int teamId;
  List<SpanishCard> hand = [];
  int score = 0;
  int cardsWon = 0;
  String? currentCallout;

  _PlayerState({
    required this.id,
    required this.name,
    required this.isBot,
    required this.color,
    this.teamId = 0,
  });
}

/// Pantalla de La Caída Tradicional venezolana.
/// Soporta:
/// - Menú previo de selección: Bot vs Multijugador, 1 a 3 bots, Parejas vs Individual.
/// - Selección individual de naipes (solo la carta tocada se eleva y resplandece).
/// - Reglas tradicionales de puntuación venezolana:
///     • Ronda: 1-7 (+1), 10 (+2), 11 (+3), 12 (+4)
///     • Caída: 1-7 (+1), 10 (+2), 11 (+3), 12 (+4)
///     • Mesa Limpia: +4 (si quedan cartas en mazo/manojo) / +2 (manojo vacío)
/// - Acumulación persistente de puntos/trofeos en la sesión.
/// - Indicador de latencia (ms) visible ÚNICAMENTE en partidas online o red local.
class CaidaScreen extends StatefulWidget {
  final int initialPlayers;
  final bool autoStart;

  const CaidaScreen({
    super.key,
    this.initialPlayers = 2,
    this.autoStart = false,
  });

  @override
  State<CaidaScreen> createState() => _CaidaScreenState();
}

class _CaidaScreenState extends State<CaidaScreen> with TickerProviderStateMixin {
  late SpanishDeck _deck;
  late List<_PlayerState> _players;
  final List<SpanishCard> _tableCards = [];

  // Configuración de la partida
  bool _hasGameStarted = false;
  bool _isMultiplayerNetwork = false;
  int _botCount = 1; // 1, 2 o 3 bots
  int _playerCount = 2; // 2, 3 o 4 jugadores en mesa
  bool _isTeams = false;
  int _currentTurnIndex = 0;
  bool _isGameOver = false;
  String _statusBanner = 'Bienvenido a La Caída Tradicional';

  // Acumulación persistente de trofeos de la sesión
  int _sessionTrophies = 7500;

  // Selección individual de cartas en la mano del usuario
  SpanishCard? _selectedCard;

  // Seguimiento de caída
  SpanishCard? _lastPlayedCard;
  int? _lastPlayedPlayerIndex;

  // Temporizadores y animaciones
  late AnimationController _timerController;
  Timer? _calloutTimer;
  Timer? _botTimer;
  Timer? _finishTimer;

  @override
  void initState() {
    super.initState();
    _playerCount = widget.initialPlayers.clamp(2, 4);
    _botCount = (_playerCount - 1).clamp(1, 3);
    _hasGameStarted = widget.autoStart;

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _onTurnTimeout();
        }
      });

    // Inicializar jugadores mínimos para evitar excepciones de índice antes de iniciar
    _setupPlayers(
      totalPlayers: _playerCount,
      userName: 'Tú',
      teams: _isTeams,
    );

    if (_hasGameStarted) {
      _initMatch(_playerCount, _isTeams, 'Tú');
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    _calloutTimer?.cancel();
    _botTimer?.cancel();
    _finishTimer?.cancel();
    super.dispose();
  }

  void _initMatch(int count, bool teams, String userName) {
    _playerCount = count;
    _isTeams = teams;
    _deck = SpanishDeck()..shuffle();
    _tableCards.clear();
    _lastPlayedCard = null;
    _lastPlayedPlayerIndex = null;
    _isGameOver = false;
    _selectedCard = null;

    _setupPlayers(
      totalPlayers: count,
      userName: userName,
      teams: teams,
    );

    // 4 cartas iniciales a la mesa
    for (int i = 0; i < 4; i++) {
      final c = _deck.draw();
      if (c != null) _tableCards.add(c);
    }

    _dealNewRound();
  }

  void _setupPlayers({
    required int totalPlayers,
    required String userName,
    bool teams = false,
  }) {
    _players = [];

    // 1. Asiento 0: Jugador local (tú, abajo en pantalla)
    _players.add(_PlayerState(
      id: 'user',
      name: userName,
      isBot: false,
      color: const Color(0xFF38BDF8),
      teamId: teams ? 1 : 0,
    ));

    // Paleta para rivales según posición en mesa (Oeste, Norte, Este)
    const botColors = [
      Color(0xFFF43F5E), // Izquierda / Rival 1 (Rojo)
      Color(0xFF10B981), // Frente / Compañero o Rival 2 (Verde)
      Color(0xFFA855F7), // Derecha / Rival 3 (Morado)
    ];

    // Cantidad de rivales
    final rivalCount = totalPlayers - 1;

    for (int i = 1; i <= rivalCount; i++) {
      final isTeammate = (totalPlayers == 4 && teams && i == 2);
      final playerName = isTeammate ? 'Player $i (Compañero)' : 'Player $i';

      _players.add(_PlayerState(
        id: 'player_$i',
        name: playerName,
        isBot: !_isMultiplayerNetwork,
        color: botColors[(i - 1) % botColors.length],
        teamId: teams ? (i % 2 == 0 ? 1 : 2) : i,
      ));
    }
  }

  void _dealNewRound() {
    if (_deck.remainingCount < _players.length * 3 && _allHandsEmpty()) {
      _finishGame();
      return;
    }

    // Repartir 3 cartas a cada jugador
    for (final p in _players) {
      p.hand.clear();
      for (int i = 0; i < 3; i++) {
        final c = _deck.draw();
        if (c != null) p.hand.add(c);
      }
      _checkHandCantos(p);
    }

    _currentTurnIndex = 0;
    _selectedCard = null;
    _resetTurnTimer();
    setState(() {
      _statusBanner = 'Nueva mano repartida (3 cartas). Es tu turno.';
    });
  }

  bool _allHandsEmpty() => _players.every((p) => p.hand.isEmpty);

  /// Regla de puntuación de Ronda según especificación:
  /// Del 1 al 7: +1 punto
  /// 10 (Sota): +2 puntos
  /// 11 (Caballo): +3 puntos
  /// 12 (Rey): +4 puntos
  int _getRondaPoints(int cardNumber) {
    switch (cardNumber) {
      case 10:
        return 2;
      case 11:
        return 3;
      case 12:
        return 4;
      default:
        return 1;
    }
  }

  /// Regla de puntuación de Caída según especificación:
  /// Del 1 al 7: +1 punto
  /// 10 (Sota): +2 puntos
  /// 11 (Caballo): +3 puntos
  /// 12 (Rey): +4 puntos
  int _getCaidaPoints(int cardNumber) {
    switch (cardNumber) {
      case 10:
        return 2;
      case 11:
        return 3;
      case 12:
        return 4;
      default:
        return 1;
    }
  }

  void _checkHandCantos(_PlayerState player) {
    if (player.hand.length < 3) return;
    final n1 = player.hand[0].number;
    final n2 = player.hand[1].number;
    final n3 = player.hand[2].number;

    // 1. Trivilín (3 cartas iguales)
    if (n1 == n2 && n2 == n3) {
      player.score += 5;
      _triggerCallout(player, '¡Trivilín! (+5)');
      return;
    }

    // 2. Patrulla (3 números consecutivos)
    final sorted = [n1, n2, n3]..sort();
    if (sorted[0] + 1 == sorted[1] && sorted[1] + 1 == sorted[2]) {
      player.score += 3;
      _triggerCallout(player, 'Patrulla (+3)');
      return;
    }

    // 3. Ronda (2 cartas iguales)
    int? pairNumber;
    if (n1 == n2) {
      pairNumber = n1;
    } else if (n2 == n3) {
      pairNumber = n2;
    } else if (n1 == n3) {
      pairNumber = n1;
    }

    if (pairNumber != null) {
      final pts = _getRondaPoints(pairNumber);
      player.score += pts;
      _triggerCallout(player, 'Ronda (+$pts)');
    }
  }

  void _triggerCallout(_PlayerState player, String text) {
    _calloutTimer?.cancel();
    setState(() => player.currentCallout = text);
    _calloutTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => player.currentCallout = null);
      }
    });
  }

  void _resetTurnTimer() {
    _timerController.reset();
    _timerController.forward();
  }

  void _onTurnTimeout() {
    final active = _players[_currentTurnIndex];
    if (active.hand.isNotEmpty) {
      _playCard(active, active.hand.first);
    }
  }

  /// Manejo de toque sobre una carta en mano:
  /// 1. Si no estaba seleccionada: la selecciona individualmente.
  /// 2. Si ya estaba seleccionada: confirma y la juega a la mesa.
  void _onUserCardTap(SpanishCard card) {
    if (_currentTurnIndex != 0 || _isGameOver) return;

    if (_selectedCard == card) {
      // Segundo toque en la misma carta -> Jugar
      _playCard(_players[0], card);
    } else {
      // Primer toque -> Seleccionar únicamente esta carta
      setState(() {
        _selectedCard = card;
      });
    }
  }

  void _playCard(_PlayerState player, SpanishCard card) {
    setState(() {
      player.hand.remove(card);
      _selectedCard = null;
    });

    // 1. ¿Es Caída sobre la carta del jugador anterior?
    if (_lastPlayedCard != null &&
        _lastPlayedPlayerIndex != null &&
        _lastPlayedPlayerIndex != _currentTurnIndex &&
        _lastPlayedCard!.number == card.number) {
      final caidaPts = _getCaidaPoints(card.number);
      player.score += caidaPts;
      _triggerCallout(player, '¡Caída! (+$caidaPts)');
    }

    _lastPlayedCard = card;
    _lastPlayedPlayerIndex = _currentTurnIndex;

    // 2. Captura en mesa
    final captures = _tableCards.where((c) => c.number == card.number).toList();
    if (captures.isNotEmpty) {
      _tableCards.removeWhere((c) => c.number == card.number);
      player.cardsWon += captures.length + 1;
      player.score += 1;

      // 3. Mesa Limpia:
      // Si aún hay cartas en el mazo/manojo vale +4; si ya no hay cartas en el manojo +2
      if (_tableCards.isEmpty) {
        final hasCardsInDeck = _deck.remainingCount > 0;
        final limpiaPts = hasCardsInDeck ? 4 : 2;
        player.score += limpiaPts;
        _triggerCallout(player, '¡Mesa Limpia! (+$limpiaPts)');
      }
    } else {
      _tableCards.add(card);
    }

    // Comprobar si alguien llegó a 24 puntos
    if (_players.any((p) => p.score >= 24)) {
      _finishGame();
      return;
    }

    // Avanzar turno
    _nextTurn();
  }

  void _nextTurn() {
    if (_allHandsEmpty()) {
      _dealNewRound();
      return;
    }

    _currentTurnIndex = (_currentTurnIndex + 1) % _players.length;
    _selectedCard = null;
    _resetTurnTimer();

    final nextPlayer = _players[_currentTurnIndex];
    if (nextPlayer.hand.isEmpty) {
      _nextTurn();
      return;
    }

    setState(() {
      _statusBanner = nextPlayer.isBot
          ? 'Turno de ${nextPlayer.name} pensando...'
          : '¡Es tu turno! Toca una carta para seleccionarla.';
    });

    if (nextPlayer.isBot) {
      _botTimer?.cancel();
      _botTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted && !_isGameOver && _currentTurnIndex == _players.indexOf(nextPlayer)) {
          _botPlay(nextPlayer);
        }
      });
    }
  }

  void _botPlay(_PlayerState bot) {
    if (bot.hand.isEmpty) return;

    SpanishCard chosen = bot.hand.first;
    for (final c in bot.hand) {
      if (_lastPlayedCard != null && c.number == _lastPlayedCard!.number) {
        chosen = c;
        break;
      }
      if (_tableCards.any((tc) => tc.number == c.number)) {
        chosen = c;
      }
    }

    _playCard(bot, chosen);
  }

  void _finishGame() {
    _isGameOver = true;
    _timerController.stop();

    final sorted = [..._players]..sort((a, b) => b.score.compareTo(a.score));
    final winner = sorted.first;
    final userWon = winner.id == 'user' || (_isTeams && winner.teamId == _players[0].teamId);

    // Acumulación persistente de puntos/trofeos en la sesión
    if (userWon) {
      _sessionTrophies += 2000 + (_players[0].score * 50);
    } else {
      _sessionTrophies = math.max(0, _sessionTrophies - 500 + (_players[0].score * 20));
    }

    final resultEntries = _players.map((p) {
      final isWin = p.id == winner.id || (_isTeams && p.teamId == winner.teamId);
      return GameResultEntry(
        name: p.name,
        scoreChange: isWin ? 2000 : -1000,
        isWinner: isWin,
        isUser: p.id == 'user',
      );
    }).toList();

    setState(() {
      _statusBanner = userWon
          ? '¡Felicidades! Has ganado la partida de Caída.'
          : 'Partida concluida. Ganó ${winner.name}.';
    });

    _finishTimer?.cancel();
    _finishTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        GameResultDialog.show(
          context,
          userWon: userWon,
          subtitle: 'Puntuación final: ${winner.name} con ${winner.score} pts',
          entries: resultEntries,
          onRematch: () {
            Navigator.pop(context);
            _initMatch(_playerCount, _isTeams, _players[0].name);
          },
          onBackToMenu: () {
            Navigator.pop(context);
            setState(() {
              _hasGameStarted = false;
            });
          },
        );
      }
    });
  }

  void _openMatchSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E143C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'OPCIONES DE PARTIDA',
                style: TextStyle(
                  color: Color(0xFFFDE047),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8)),
                title: const Text('Reiniciar mano actual', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _initMatch(_playerCount, _isTeams, _players[0].name);
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune_rounded, color: Color(0xFF10B981)),
                title: const Text('Configurar / Volver al Menú', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _hasGameStarted = false;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded, color: Color(0xFFFBBF24)),
                title: const Text('Reglas de La Caída', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  GameRulesDialog.show(context, 'la_caida');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _players.isNotEmpty ? _players[0] : null;

    return Scaffold(
      appBar: GameTableHeader(
        title: 'La Caída Tradicional',
        onBack: () {
          if (_hasGameStarted) {
            setState(() => _hasGameStarted = false);
          } else {
            Navigator.pop(context);
          }
        },
        onOpenRules: () => GameRulesDialog.show(context, 'la_caida'),
        onSettings: _openMatchSettings,
        trophies: _sessionTrophies,
        // Los ms SOLO se muestran en partidas por internet o red local
        showPing: _isMultiplayerNetwork,
        pingMs: 55,
      ),
      body: WoodTableBackground(
        child: SafeArea(
          child: !_hasGameStarted
              ? _buildPreGameLobby()
              : (user == null ? const SizedBox() : _buildGameTable(user)),
        ),
      ),
    );
  }

  /// Menú inicial / Lobby previo para configurar y comenzar a jugar
  Widget _buildPreGameLobby() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E1960), Color(0xFF160B33)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF7C4DFF), width: 2),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono y título de bienvenida
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF9F75FF), width: 1.2),
                    ),
                    child: const Icon(Icons.style_rounded, color: Color(0xFFFDE047), size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LA CAÍDA TRADICIONAL',
                          style: TextStyle(
                            color: Color(0xFFFDE047),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '¿Deseas comenzar a jugar?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 1. Selector de Modo: Bot vs Multijugador
              const Text(
                'Modo de Juego:',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildModeCard(
                      title: 'Contra Bot',
                      subtitle: 'Offline / Solitario',
                      icon: Icons.smart_toy_rounded,
                      isSelected: !_isMultiplayerNetwork,
                      onTap: () => setState(() => _isMultiplayerNetwork = false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildModeCard(
                      title: 'Multijugador',
                      subtitle: 'Red Local / Online',
                      icon: Icons.wifi_rounded,
                      isSelected: _isMultiplayerNetwork,
                      onTap: () => setState(() => _isMultiplayerNetwork = true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 2. Cantidad en la mesa: 1 bot (2 jug), 2 bots (3 jug), 3 bots (4 jug)
              Text(
                !_isMultiplayerNetwork ? 'Cantidad de Bots en la mesa:' : 'Jugadores en la mesa:',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildCountOption(
                      label: !_isMultiplayerNetwork ? '1 Bot' : '2 Jug.',
                      sublabel: 'Mesa de 2',
                      isSelected: _botCount == 1,
                      onTap: () => setState(() {
                        _botCount = 1;
                        _playerCount = 2;
                        _isTeams = false;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCountOption(
                      label: !_isMultiplayerNetwork ? '2 Bots' : '3 Jug.',
                      sublabel: 'Mesa de 3',
                      isSelected: _botCount == 2,
                      onTap: () => setState(() {
                        _botCount = 2;
                        _playerCount = 3;
                        _isTeams = false;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCountOption(
                      label: !_isMultiplayerNetwork ? '3 Bots' : '4 Jug.',
                      sublabel: 'Mesa de 4',
                      isSelected: _botCount == 3,
                      onTap: () => setState(() {
                        _botCount = 3;
                        _playerCount = 4;
                      }),
                    ),
                  ),
                ],
              ),

              // 3. Modalidad: Pareja o Individual (solo si son 4 jugadores / 3 bots)
              if (_playerCount == 4) ...[
                const SizedBox(height: 16),
                const Text(
                  'Modalidad (Mesa de 4):',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildCountOption(
                        label: 'Individual',
                        sublabel: 'Todos vs Todos',
                        isSelected: !_isTeams,
                        onTap: () => setState(() => _isTeams = false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCountOption(
                        label: 'En Pareja',
                        sublabel: '2 vs 2 (Con Player 2)',
                        isSelected: _isTeams,
                        onTap: () => setState(() => _isTeams = true),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 18),

              // 4. Tarjeta resumen de reglas de puntos activas en esta mesa
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events_rounded, color: Color(0xFFFDE047), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Puntuación Tradicional:',
                          style: TextStyle(color: Color(0xFFFDE047), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      '• Ronda: 1 al 7 (+1), 10 (+2), 11 (+3), 12 (+4)\n'
                      '• Caída: 1 al 7 (+1), 10 (+2), 11 (+3), 12 (+4)\n'
                      '• Mesa Limpia: +4 (con cartas en mazo) / +2 (manojo vacío)\n'
                      '• Meta: 24 puntos para ganar',
                      style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 5. Botón de inicio
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasGameStarted = true;
                  });
                  _initMatch(_playerCount, _isTeams, 'Tú');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 8,
                  shadowColor: const Color(0xFF10B981).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 24),
                    SizedBox(width: 8),
                    Text(
                      '¡COMENZAR A JUGAR!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
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

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A2B99) : const Color(0xFF1C1033),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF3B256B),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF38BDF8) : Colors.white60,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountOption({
    required String label,
    required String sublabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF1E143C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2DD4BF) : const Color(0xFF4A347F),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mesa de juego activa con cartas, rivales y mano del usuario
  Widget _buildGameTable(_PlayerState user) {
    return Column(
      children: [
        _buildStatusBar(),
        Expanded(
          child: AnimatedBuilder(
            animation: _timerController,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  _buildTableCenterCards(),
                  ..._buildOpponents(),
                  _buildUserBottomArea(user),
                ],
              );
            },
          ),
        ),
        _buildUserHandFan(user),
        const SizedBox(height: 10),
      ],
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
              _statusBanner,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFDE047),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          InkWell(
            onTap: _openMatchSettings,
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
                  Text(
                    '$_playerCount Jug.',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
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
          top: 16,
          child: TablePlayerBadge(
            name: rival.name,
            scoreOrCards: rival.cardsWon,
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
            scoreOrCards: rival1.cardsWon,
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
            scoreOrCards: rival2.cardsWon,
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
            scoreOrCards: rival1.cardsWon,
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
            scoreOrCards: rival2.cardsWon,
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
            scoreOrCards: rival3.cardsWon,
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

  Widget _buildUserBottomArea(_PlayerState user) {
    return Positioned(
      left: 16,
      bottom: 6,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TablePlayerBadge(
            name: user.name,
            scoreOrCards: user.cardsWon,
            isBot: false,
            isCurrentTurn: _currentTurnIndex == 0,
            turnProgress: 1.0 - _timerController.value,
            position: PlayerPositionOnTable.bottom,
            calloutMessage: user.currentCallout,
            cardsInHandCount: user.hand.length,
            avatarColor: user.color,
          ),
          const SizedBox(width: 8),
          // Indicador de Puntos en la mano actual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.6), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFBBF24)),
                const SizedBox(width: 4),
                Text(
                  '${user.score} pts',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCenterCards() {
    if (_tableCards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12, width: 1),
        ),
        child: const Text(
          'Mesa Limpia\n(Juega para abrir captura)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260, maxHeight: 220),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: _tableCards.map((card) {
            final angle = (card.number % 3 - 1) * 0.05;
            return Transform.rotate(
              angle: angle,
              child: SpanishCardView(
                card: card,
                width: 60,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Abanico de cartas con selección individual:
  /// Solo la carta tocada se eleva y tiene resplandor.
  Widget _buildUserHandFan(_PlayerState user) {
    if (user.hand.isEmpty) {
      return const SizedBox(
        height: 125,
        child: Center(
          child: Text(
            'Esperando nueva mano...',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final cardCount = user.hand.length;
    final isMyTurn = _currentTurnIndex == 0 && !_isGameOver;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón de acción rápida o texto guía cuando hay carta seleccionada
        if (_selectedCard != null && isMyTurn)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ElevatedButton.icon(
              onPressed: () => _playCard(user, _selectedCard!),
              icon: const Icon(Icons.arrow_upward_rounded, size: 16, color: Colors.white),
              label: Text(
                'JUGAR ${_selectedCard!.displayName.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: const Color(0xFF10B981).withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          )
        else if (isMyTurn)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Toca una carta para seleccionarla',
                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),

        SizedBox(
          height: 125,
          width: double.infinity,
          child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: List.generate(cardCount, (index) {
                final card = user.hand[index];
                final mid = (cardCount - 1) / 2.0;
                final offsetIndex = index - mid;
                final angle = offsetIndex * 0.07;
                final xTranslation = offsetIndex * 40.0;
                final yTranslation = math.pow(offsetIndex.abs(), 1.5) * 4.0;

                // Solo la carta seleccionada se eleva y resplandece
                final isCardSelected = isMyTurn && _selectedCard == card;
                final yOffset = isCardSelected ? -22.0 : 0.0;

                return Transform.translate(
                  offset: Offset(xTranslation, yTranslation + yOffset),
                  child: Transform.rotate(
                    angle: angle,
                    child: SpanishCardView(
                      key: ValueKey('user_card_$index'),
                      card: card,
                      width: 74,
                      isSelected: isCardSelected,
                      onTap: isMyTurn ? () => _onUserCardTap(card) : null,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      );
  }
}
