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
import '../../../core/services/audio_service.dart';
import '../../../core/services/user_profile_service.dart';
import '../domain/caida_models.dart';
import '../domain/caida_rules_engine.dart';
import '../economy/player_session.dart';
import '../economy/vip_tier.dart';
import 'widgets/deck_stack_view.dart';
import 'widgets/table_canto_dialog.dart';
import 'caida_lobby_screen.dart';

/// Candidato para el sorteo interactivo de Mano ("¡ELIGE UNA CARTA!")
class _ManoCardCandidate {
  final int id;
  final SpanishCard card;
  final double topOffset;
  final double leftOffset;
  final double rotation;
  int? chosenByPlayerIndex;
  bool isRevealed = false;

  _ManoCardCandidate({
    required this.id,
    required this.card,
    required this.topOffset,
    required this.leftOffset,
    required this.rotation,
  });
}

/// Naipe colocado sobre el tapete central con posición y rotación orgánicas ("regadas al azar").
class _PlacedTableCard {
  final SpanishCard card;
  final Offset offset;
  final double rotation;
  final int zIndex;
  final int zoneIndex;

  _PlacedTableCard({
    required this.card,
    required this.offset,
    required this.rotation,
    required this.zIndex,
    required this.zoneIndex,
  });
}

class _PlayerState {
  final String id;
  final String name;
  final bool isBot;
  final Color color;
  final int teamId;
  final int avatarId;
  List<SpanishCard> hand = [];
  int score = 0;
  int cardsWon = 0;
  String? currentCallout;
  Timer? calloutTimer;
  Canto? pendingCanto;

  _PlayerState({
    required this.id,
    required this.name,
    required this.isBot,
    required this.color,
    this.teamId = 0,
    this.avatarId = 2,
  });
}

/// Pantalla de La Caída Tradicional venezolana.
/// Soporta:
/// - Menú previo de selección: Bot vs Multijugador, 1 a 3 bots, Parejas vs Individual.
/// - Selección individual de naipes limpia, sin solapamiento obstructivo.
/// - Animación secuencial de reparto (4 cartas a la mesa y 3 a los jugadores).
/// - Indicador de "Mano" con rotación en el sentido de las manecillas del reloj.
/// - Sistema de progresión de nivel y experiencia (XP).
/// - Desaparición automática e independiente de bocadillos de cantos.
/// - Reglas tradicionales de puntuación venezolana:
///     • Ronda: 1-7 (+1), 10 (+2), 11 (+3), 12 (+4)
///     • Caída: 1-7 (+1), 10 (+2), 11 (+3), 12 (+4)
///     • Mesa Limpia: +4 (si quedan cartas en mazo/manojo) / +2 (manojo vacío)
/// - Acumulación persistente de puntos/trofeos en la sesión.
/// - Indicador de latencia (ms) visible ÚNICAMENTE en partidas online o red local.
class CaidaScreen extends StatefulWidget {
  final int initialPlayers;
  final bool autoStart;
  final bool animateDealing;
  final bool initialTeams;
  final bool chooseMano;
  final String? userName;
  final List<String>? botNames;
  final VipTierOffer? vipTier;
  final int? vipPrizePool;
  final int? vipWinnerReward;

  const CaidaScreen({
    super.key,
    this.initialPlayers = 2,
    this.autoStart = false,
    this.animateDealing = true,
    this.initialTeams = false,
    this.chooseMano = false,
    this.userName,
    this.botNames,
    this.vipTier,
    this.vipPrizePool,
    this.vipWinnerReward,
  });

  @override
  State<CaidaScreen> createState() => _CaidaScreenState();
}

class _CaidaScreenState extends State<CaidaScreen> with TickerProviderStateMixin {
  late SpanishDeck _deck;
  late List<_PlayerState> _players;
  final List<SpanishCard> _tableCards = [];
  final List<_PlacedTableCard> _placedTableCards = [];
  int _tableCardZCounter = 0;
  bool _isProcessingPlay = false;

  // Configuración de la partida
  bool _hasGameStarted = false;
  bool _isMultiplayerNetwork = false;
  int _botCount = 1; // 1, 2 o 3 bots
  int _playerCount = 2; // 2, 3 o 4 jugadores en mesa
  bool _isTeams = false;
  int _currentTurnIndex = 0;
  bool _isGameOver = false;

  // Mano actual y ronda
  int _manoIndex = 0; // Índice del jugador que es Mano (juega primero)
  int _roundNumber = 1; // Contador de rondas de la partida

  // Sistema de Nivel y Experiencia (XP)
  int _userLevel = 1;
  int _userXp = 250;
  int _xpToNextLevel = 600;

  // Estado de reparto animado
  bool _isDealing = false;
  bool _isFirstRoundDealing = true;

  // Acumulación persistente de trofeos de la sesión
  int _sessionTrophies = 7500;

  // Selección individual de cartas en la mano del usuario
  SpanishCard? _selectedCard;

  // Seguimiento de caída, arrastre y última captura
  SpanishCard? _lastPlayedCard;
  int? _lastPlayedPlayerIndex;
  int? _lastCapturingPlayerIndex;

  // Canto de Mesa del repartidor
  DealDirection _cantoDirection = DealDirection.ascending;
  String? _pointEventBanner;

  // Sorteo interactivo de Mano ("¡ELIGE UNA CARTA!")
  bool _isChoosingMano = false;
  final List<_ManoCardCandidate> _manoCandidates = [];
  String? _manoAnnouncement;

  // Temporizadores y animaciones
  late AnimationController _timerController;
  late AnimationController _dealingController;
  Timer? _botTimer;
  Timer? _finishTimer;

  @override
  void initState() {
    super.initState();
    _playerCount = widget.initialPlayers.clamp(2, 4);
    _botCount = (_playerCount - 1).clamp(1, 3);
    _hasGameStarted = widget.autoStart;
    _isTeams = widget.initialTeams;

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _onTurnTimeout();
        }
      });

    _dealingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(() {
        if (mounted) setState(() {});
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _onDealingCompleted();
        }
      });

    // Inicializar jugadores mínimos para evitar excepciones de índice antes de iniciar
    final initialUserName = widget.userName ?? 'Tú';
    _setupPlayers(
      totalPlayers: _playerCount,
      userName: initialUserName,
      teams: _isTeams,
    );

    if (_hasGameStarted) {
      _initMatch(
        _playerCount,
        _isTeams,
        initialUserName,
        animate: !widget.autoStart && widget.animateDealing,
        startWithManoSelection: widget.chooseMano,
      );
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    _dealingController.dispose();
    _botTimer?.cancel();
    _finishTimer?.cancel();
    _clearAllCallouts();
    super.dispose();
  }

  void _clearAllCallouts() {
    for (final p in _players) {
      p.calloutTimer?.cancel();
      p.calloutTimer = null;
      p.currentCallout = null;
    }
  }

  void _initMatch(int count, bool teams, String userName, {bool? animate, bool startWithManoSelection = false}) {
    _botTimer?.cancel();
    _finishTimer?.cancel();
    _timerController.stop();
    _isProcessingPlay = false;
    _playerCount = count;
    _isTeams = teams;
    _deck = SpanishDeck()..shuffle();
    _tableCards.clear();
    _placedTableCards.clear();
    _tableCardZCounter = 0;
    _lastPlayedCard = null;
    _lastPlayedPlayerIndex = null;
    _lastCapturingPlayerIndex = null;
    _pointEventBanner = null;
    _isGameOver = false;
    _selectedCard = null;
    _roundNumber = 1;
    _clearAllCallouts();

    _setupPlayers(
      totalPlayers: count,
      userName: userName,
      teams: teams,
    );

    if (startWithManoSelection) {
      _startManoSelection();
    } else {
      _manoIndex = 0;
      final shouldAnimate = animate ?? (widget.animateDealing && !widget.autoStart);
      _startDeal(isFirstRound: true, animate: shouldAnimate);
    }
  }

  void _startManoSelection() {
    _manoCandidates.clear();
    _manoAnnouncement = null;
    final tempDeck = SpanishDeck()..shuffle();

    // 10 posiciones orgánicas y naturales sobre el tapete de madera
    final positions = [
      const Offset(-70, -70),
      const Offset(15, -75),
      const Offset(85, -70),
      const Offset(-35, -20),
      const Offset(55, -15),
      const Offset(-75, 30),
      const Offset(5, 35),
      const Offset(75, 35),
      const Offset(-40, 80),
      const Offset(45, 75),
    ];
    final rotations = [-0.06, 0.04, -0.05, 0.08, -0.04, 0.05, -0.07, 0.06, -0.03, 0.05];

    for (int i = 0; i < 10; i++) {
      final card = tempDeck.draw()!;
      _manoCandidates.add(_ManoCardCandidate(
        id: i,
        card: card,
        topOffset: positions[i].dy,
        leftOffset: positions[i].dx,
        rotation: rotations[i],
      ));
    }

    setState(() {
      _isChoosingMano = true;
    });
  }

  void _onCandidateCardTapped(_ManoCardCandidate userChoice) async {
    if (userChoice.chosenByPlayerIndex != null || !_isChoosingMano) return;

    setState(() {
      userChoice.chosenByPlayerIndex = 0; // Usuario
      userChoice.isRevealed = true;
    });

    // Los bots escogen entre las cartas restantes sin revelar inmediatamente
    final unchosen = _manoCandidates.where((c) => c.chosenByPlayerIndex == null).toList();
    unchosen.shuffle();

    for (int i = 1; i < _players.length; i++) {
      if (unchosen.isNotEmpty) {
        final botPick = unchosen.removeLast();
        botPick.chosenByPlayerIndex = i;
        botPick.isRevealed = true;
      }
    }

    setState(() {});

    // Determinar la carta mayor entre los jugadores
    final chosenEntries = _manoCandidates
        .where((c) => c.chosenByPlayerIndex != null)
        .toList();

    chosenEntries.sort((a, b) {
      if (a.card.number != b.card.number) {
        return b.card.number.compareTo(a.card.number);
      }
      return b.card.suit.index.compareTo(a.card.suit.index);
    });

    final winnerChoice = chosenEntries.first;
    final winnerIndex = winnerChoice.chosenByPlayerIndex!;
    final winner = _players[winnerIndex];

    setState(() {
      _manoIndex = winnerIndex;
      _manoAnnouncement = '¡${winner.name} saca el ${winnerChoice.card.number} y es MANO! ✋';
    });

    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    setState(() {
      _isChoosingMano = false;
      _manoAnnouncement = null;
    });

    // Si el usuario es el repartidor / Mano, se le ofrece elegir Canto de Mesa
    if (_manoIndex == 0) {
      final dir = await TableCantoDialog.show(context);
      if (dir != null && mounted) {
        setState(() => _cantoDirection = dir);
      }
    }

    _startDeal(isFirstRound: true, animate: true);
  }

  void _setupPlayers({
    required int totalPlayers,
    required String userName,
    bool teams = false,
  }) {
    _players = [];
    final profileService = UserProfileService();
    final effectiveUserName = (widget.userName != null && widget.userName!.isNotEmpty)
        ? widget.userName!
        : (userName.isNotEmpty ? userName : profileService.name);

    // 1. Asiento 0: Jugador local (abajo en pantalla)
    _players.add(_PlayerState(
      id: 'user',
      name: effectiveUserName,
      isBot: false,
      color: const Color(0xFF38BDF8),
      teamId: teams ? 1 : 0,
      avatarId: profileService.avatarId,
    ));

    // Nombres y avatares según bots configurados o por defecto
    final defaultBotNames = [
      for (int i = 1; i < totalPlayers; i++) 'Player $i'
    ];
    final effectiveBotNames = widget.botNames ?? defaultBotNames;
    const botAvatars = [1, 14, 5];
    const botColors = [
      Color(0xFFF43F5E), // Izquierda / Rival 1 (Rojo)
      Color(0xFF10B981), // Frente / Compañero o Rival 2 (Verde)
      Color(0xFFA855F7), // Derecha / Rival 3 (Morado)
    ];

    final rivalCount = totalPlayers - 1;

    for (int i = 1; i <= rivalCount; i++) {
      final isTeammate = (totalPlayers == 4 && teams && i == 2);
      final rawName = effectiveBotNames[(i - 1) % effectiveBotNames.length];
      final playerName = isTeammate ? '$rawName (Compañero)' : rawName;

      _players.add(_PlayerState(
        id: 'player_$i',
        name: playerName,
        isBot: !_isMultiplayerNetwork,
        color: botColors[(i - 1) % botColors.length],
        teamId: teams ? (i % 2 == 0 ? 1 : 2) : i,
        avatarId: botAvatars[(i - 1) % botAvatars.length],
      ));
    }
  }

  void _startDeal({required bool isFirstRound, required bool animate}) {
    _clearAllCallouts();
    _timerController.stop();
    _isFirstRoundDealing = isFirstRound;

    if (isFirstRound) {
      _tableCards.clear();
      _placedTableCards.clear();
      _tableCardZCounter = 0;
      _lastCapturingPlayerIndex = null;
      _lastPlayedCard = null;
      _lastPlayedPlayerIndex = null;

      final dealer = _players[_manoIndex];
      final opponent = _players[(_manoIndex + 1) % _players.length];

      final dealResult = CaidaRulesEngine.dealInitialTable(
        direction: _cantoDirection,
        deck: _deck,
        dealerId: dealer.id,
        opponentId: opponent.id,
      );

      _tableCards.addAll(dealResult.tableCards);
      _syncPlacedCards();

      if (dealResult.dealerPoints > 0) {
        dealer.score += dealResult.dealerPoints;
        _triggerCallout(dealer, 'Canto de Mesa (+${dealResult.dealerPoints} pts)');
      }
      if (dealResult.opponentPoints > 0) {
        opponent.score += dealResult.opponentPoints;
        _triggerCallout(opponent, '+${dealResult.opponentPoints} pt (Mesa)');
      }
    }

    for (final p in _players) {
      p.hand.clear();
      p.pendingCanto = null;
      for (int i = 0; i < 3; i++) {
        final c = _deck.draw();
        if (c != null) p.hand.add(c);
      }
    }

    if (!animate) {
      _isDealing = false;
      _onDealingCompleted();
      return;
    }

    _isDealing = true;
    setState(() {});

    _dealingController.reset();
    _dealingController.forward();
  }

  void _onDealingCompleted() {
    _isDealing = false;
    _isFirstRoundDealing = false;

    // Al recibir las 3 cartas, se canta únicamente la presencia del canto sin sumar puntos aún
    _announceInitialCantos();

    _currentTurnIndex = _manoIndex;
    _selectedCard = null;

    if (!mounted) return;
    final activePlayer = _players[_currentTurnIndex];
    setState(() {});

    _resetTurnTimer();

    if (activePlayer.isBot) {
      _botTimer?.cancel();
      _botTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted && !_isGameOver && _currentTurnIndex == _players.indexOf(activePlayer)) {
          _botPlay(activePlayer);
        }
      });
    }
  }

  void _dealNewRound() {
    _onRoundFinished();
  }

  void _onRoundFinished() {
    // Si ya no quedan suficientes cartas para otra mano de 3 por jugador
    if (_deck.remainingCount < _players.length * 3) {
      final playerStates = _players.map((p) => CaidaPlayerState(
        id: p.id,
        name: p.name,
        teamId: p.teamId,
        initialScore: p.score,
        initialCardsWon: p.cardsWon,
      )).toList();

      final lastCapturingId = _lastCapturingPlayerIndex != null
          ? _players[_lastCapturingPlayerIndex!].id
          : null;

      final res = CaidaRulesEngine.resolveHandEnd(
        players: playerStates,
        remainingTable: _tableCards,
        lastCapturingPlayerId: lastCapturingId,
        isTeams: _isTeams,
        dealerId: _players[_manoIndex].id,
      );

      for (final p in _players) {
        p.cardsWon = res.totalCardsWon[p.id] ?? p.cardsWon;
        p.score = res.updatedScores[p.id] ?? p.score;
        final vol = res.volumeBonusPoints[p.id] ?? 0;
        if (vol > 0) {
          _triggerCallout(p, 'Volumen (+$vol pts)');
        }
      }
      _tableCards.clear();

      if (_players.any((p) => p.score >= 24)) {
        _finishGame();
        return;
      }

      // Iniciar nuevo manojo con mazo completo de 40 cartas barajado
      // La Mano rota en sentido de las manecillas del reloj
      _manoIndex = (_manoIndex + 1) % _players.length;
      _roundNumber++;
      _deck = SpanishDeck()..shuffle();
      _tableCards.clear();
      _placedTableCards.clear();
      _tableCardZCounter = 0;
      _lastPlayedCard = null;
      _lastPlayedPlayerIndex = null;
      _lastCapturingPlayerIndex = null;

      // CRÍTICO: Reiniciar las cartas recogidas a 0 para el nuevo manojo de 40 cartas
      for (final p in _players) {
        p.cardsWon = 0;
      }

      _startDeal(isFirstRound: true, animate: widget.animateDealing && !widget.autoStart);
      return;
    }

    // Aún quedan cartas en el mazo: se reparten 3 cartas más dentro del mismo manojo.
    // La Mano se mantiene fija durante todo el manojo hasta agotarse el mazo completo.
    _roundNumber++;
    _lastPlayedCard = null;
    _lastPlayedPlayerIndex = null;
    _startDeal(isFirstRound: false, animate: widget.animateDealing && !widget.autoStart);
  }

  bool _allHandsEmpty() => _players.every((p) => p.hand.isEmpty);

  void _onHandsExhausted() async {
    final hadCantos = _players.any((p) => p.pendingCanto != null);
    if (hadCantos) {
      _resolveAndAwardCantos();
      setState(() {});

      if (_players.any((p) => p.score >= 24)) {
        _finishGame();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted || _isGameOver) return;
    }

    _dealNewRound();
  }

  void _announceInitialCantos() {
    int delayMs = 0;
    for (final p in _players) {
      p.pendingCanto = CaidaRulesEngine.evaluateCantos(p.hand);
      if (p.pendingCanto != null) {
        // En el reparto inicial solo se canta la presencia del canto sin sumar puntos aún
        _triggerCallout(p, p.pendingCanto!.name);
        final cantoName = p.pendingCanto!.name;
        if (delayMs == 0) {
          AudioService().playCanto(cantoName);
        } else {
          final captureDelay = delayMs;
          Future.delayed(Duration(milliseconds: captureDelay), () {
            if (mounted) {
              AudioService().playCanto(cantoName);
            }
          });
        }
        delayMs += 1100;
      }
    }
  }

  void _resolveAndAwardCantos() {
    final cantosMap = <String, Canto?>{};
    final teamsMap = <String, int>{};
    for (final p in _players) {
      cantosMap[p.id] = p.pendingCanto;
      teamsMap[p.id] = p.teamId;
    }

    final resolved = CaidaRulesEngine.resolveCantosConflict(
      playerCantos: cantosMap,
      playerTeams: teamsMap,
      manoIndex: _manoIndex,
      playerIdsOrder: _players.map((p) => p.id).toList(),
    );

    for (final p in _players) {
      final canto = resolved[p.id];
      if (canto != null) {
        p.score += canto.points;
        final detail = canto is RondaCanto
            ? 'Ronda de ${canto.pairNumber}'
            : canto.name.replaceAll('¡', '').replaceAll('!', '');
        _triggerCallout(p, '¡$detail! (+${canto.points} pts)');
        AudioService().playCanto(canto.name);
      } else if (p.pendingCanto != null) {
        final defeated = p.pendingCanto!;
        final detail = defeated is RondaCanto
            ? 'Ronda de ${defeated.pairNumber}'
            : defeated.name.replaceAll('¡', '').replaceAll('!', '');
        _triggerCallout(p, '$detail (Matada)');
      }
      p.pendingCanto = null;
    }
  }

  void _triggerCallout(_PlayerState player, String text) {
    player.calloutTimer?.cancel();
    setState(() {
      player.currentCallout = text;
      _pointEventBanner = '${player.name}: $text';
    });
    player.calloutTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() {
          player.currentCallout = null;
          _pointEventBanner = null;
        });
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
    if (_currentTurnIndex != 0 || _isGameOver || _isDealing || _isChoosingMano || _isProcessingPlay) return;

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
    if (_isProcessingPlay || _isGameOver || _isDealing || _isChoosingMano) return;
    if (!player.hand.contains(card)) return;

    _isProcessingPlay = true;
    _botTimer?.cancel();
    _timerController.stop();

    setState(() {
      player.hand.remove(card);
      _selectedCard = null;
    });

    final previousCard = (_lastPlayedPlayerIndex != null && _lastPlayedPlayerIndex != _currentTurnIndex)
        ? _lastPlayedCard
        : null;

    final eval = CaidaRulesEngine.evaluatePlay(
      playedCard: card,
      tableCards: _tableCards,
      previousCard: previousCard,
      isDeckEmpty: _deck.isEmpty,
    );

    setState(() {
      _tableCards.clear();
      _tableCards.addAll(eval.newTableCards);
      _syncPlacedCards();
    });

    if (eval.didCapture) {
      player.cardsWon += eval.capturedCards.length;
      _lastCapturingPlayerIndex = _currentTurnIndex;
    }

    if (eval.totalPoints > 0) {
      player.score += eval.totalPoints;
      _triggerCallout(player, eval.breakdownMessage);
    } else if (eval.didCapture && eval.capturedCards.length > 2) {
      _triggerCallout(player, eval.breakdownMessage);
    }

    // Efectos de sonido para Caída y Mesa Limpia
    if (eval.isCaida && eval.isLimpia) {
      AudioService().playCaida();
      Future.delayed(const Duration(milliseconds: 900), () {
        AudioService().playMesaLimpia();
      });
    } else if (eval.isCaida) {
      AudioService().playCaida();
    } else if (eval.isLimpia) {
      AudioService().playMesaLimpia();
    }

    _lastPlayedCard = card;
    _lastPlayedPlayerIndex = _currentTurnIndex;

    _isProcessingPlay = false;

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
      _onHandsExhausted();
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

    setState(() {});

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

    // Acumulación persistente de puntos/trofeos y nivel
    bool didLevelUp = false;
    final int xpGained = userWon ? 500 + (_players[0].cardsWon * 10) : 100 + (_players[0].cardsWon * 5);
    if (userWon) {
      _sessionTrophies += 2000 + (_players[0].score * 50);
    } else {
      _sessionTrophies = math.max(0, _sessionTrophies - 500 + (_players[0].score * 20));
    }
    _userXp += xpGained;
    while (_userXp >= _xpToNextLevel) {
      _userXp -= _xpToNextLevel;
      _userLevel++;
      _xpToNextLevel = _userLevel * 600;
      didLevelUp = true;
    }

    // Recompensas del sistema de economía de Fase 2 (PlayerSession)
    int vipCoinsWon = 0;
    if (widget.vipTier != null) {
      if (userWon) {
        vipCoinsWon = widget.vipWinnerReward ?? widget.vipTier!.calculateNetPrizePerWinner(isTeams: widget.initialTeams);
        PlayerSession.shared.rewardCoins(vipCoinsWon, xpGain: xpGained);
      } else {
        PlayerSession.shared.addXp(xpGained);
      }
    } else {
      if (userWon) {
        PlayerSession.shared.rewardCoins(150, xpGain: xpGained);
      } else {
        PlayerSession.shared.addXp(xpGained);
      }
    }

    final resultEntries = _players.map((p) {
      final isWin = p.id == winner.id || (_isTeams && p.teamId == winner.teamId);
      final change = isWin
          ? (widget.vipTier != null ? vipCoinsWon : 2000)
          : (widget.vipTier != null ? -(widget.vipTier!.entryFee) : -1000);
      return GameResultEntry(
        name: p.name,
        scoreChange: change,
        isWinner: isWin,
        isUser: p.id == 'user',
      );
    }).toList();

    setState(() {});

    _finishTimer?.cancel();
    _finishTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        String customSubtitle;
        if (widget.vipTier != null) {
          customSubtitle = userWon
              ? '👑 ¡VICTORIA VIP EN MESA ${widget.vipTier!.name.toUpperCase()}!\nPremio obtenido: +🪙 $vipCoinsWon monedas (+$xpGained XP)'
              : 'Mesa ${widget.vipTier!.name}: Ganó ${winner.name} con ${winner.score} pts (+$xpGained XP)';
        } else {
          customSubtitle = didLevelUp
              ? '🎉 ¡SUBISTE AL NIVEL $_userLevel! (+$xpGained XP)\nPuntuación final: ${winner.name} con ${winner.score} pts'
              : 'Puntuación final: ${winner.name} con ${winner.score} pts (+$xpGained XP • Nv. $_userLevel)';
        }

        GameResultDialog.show(
          context,
          userWon: userWon,
          subtitle: customSubtitle,
          entries: resultEntries,
          onRematch: () {
            Navigator.pop(context);
            _initMatch(_playerCount, _isTeams, _players[0].name);
          },
          onBackToMenu: () {
            Navigator.pop(context); // Cierra el modal de GameResultDialog
            if (Navigator.canPop(context)) {
              Navigator.pop(context); // Regresa al lobby principal de La Caída
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CaidaLobbyScreen()),
              );
            }
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
                leading: const Icon(Icons.record_voice_over_rounded, color: Color(0xFF38BDF8)),
                title: Text('Canto de Mesa: ${_cantoDirection == DealDirection.ascending ? "Ascendente (1..4)" : "Descendente (4..1)"}', style: const TextStyle(color: Colors.white)),
                subtitle: const Text('Cambiar dirección del conteo inicial del repartidor', style: TextStyle(color: Colors.white54, fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final dir = await TableCantoDialog.show(context);
                  if (dir != null) {
                    setState(() => _cantoDirection = dir);
                  }
                },
              ),
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
        playerLevel: _userLevel,
        // Los ms SOLO se muestran en partidas por internet o red local
        showPing: _isMultiplayerNetwork,
        pingMs: 55,
        isMuted: AudioService().isMuted,
        onToggleMute: () {
          setState(() {
            AudioService().toggleMute();
          });
        },
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

              // 4. Dirección del Canto de Mesa inicial
              const SizedBox(height: 16),
              const Text(
                'Canto de Mesa inicial del Repartidor:',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildCountOption(
                      label: 'Ascendente',
                      sublabel: '1 → 2 → 3 → 4',
                      isSelected: _cantoDirection == DealDirection.ascending,
                      onTap: () => setState(() => _cantoDirection = DealDirection.ascending),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCountOption(
                      label: 'Descendente',
                      sublabel: '4 → 3 → 2 → 1',
                      isSelected: _cantoDirection == DealDirection.descending,
                      onTap: () => setState(() => _cantoDirection = DealDirection.descending),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 5. Tarjeta resumen de reglas de puntos activas en esta mesa
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
                        Expanded(
                          child: Text(
                            'Reglas Oficiales Tradicionales:',
                            style: TextStyle(color: Color(0xFFFDE047), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      '• Canto de Mesa: Acierto nominal suma puntos; repetidas dan +1 pt a rivales; sin aciertos +1 pt a rivales.\n'
                      '• Cantos: Trivilín (+24), Registro (+12), Vigía (+8), Patrulla (+4), Ronda (+2..+5). En conflicto solo cobra el bando superior.\n'
                      '• Jugadas: Caída (+1..+4), Arrastre en seguidilla (1..7, 10..12), Mesa Limpia (+4/+2).\n'
                      '• Volumen: Quien supere 20 cartas físicas suma (Cartas - 20) puntos.\n'
                      '• Meta: 24 puntos para ganar la partida.',
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
    return AnimatedBuilder(
      animation: _timerController,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 1. Cartas sobre el tapete central (directo sobre la madera, 100% natural, sin BOX)
            _buildTableCenterCards(),

            // 2. Mazo en la esquina superior izquierda despejada si hay cartas restantes
            if (_deck.remainingCount > 0 && !_isChoosingMano)
              Positioned(
                left: 14,
                top: 10,
                child: DeckStackView(
                  remainingCards: _deck.remainingCount,
                ),
              ),

            // 3. Estaciones de los rivales limpias y despejadas (sin cajas estorbando)
            ..._buildOpponents(),

            // 4. Estación del usuario en la esquina inferior izquierda
            _buildUserBottomArea(user),

            // 5. Abanico de cartas en mano en la parte inferior derecha
            Positioned(
              right: 14,
              bottom: 8,
              child: _buildUserHandFan(user),
            ),

            // 6. Indicador de Mesa VIP en la parte superior si aplica
            if (widget.vipTier != null)
              Positioned(
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.vipTier!.accentColor, const Color(0xFF0F172A)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: widget.vipTier!.accentColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.vipTier!.accentColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFDE047), size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'Mesa ${widget.vipTier!.name} • Pozo: 🪙 ${widget.vipPrizePool ?? widget.vipTier!.calculatePrizePool(isTeams: widget.initialTeams)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 7. Notificación flotante de jugadas (Arrastre, Caída, etc.)
            if (_pointEventBanner != null)
              Positioned(
                top: 88,
                child: _buildPointEventBanner(),
              ),

            // 7. Indicador sutil de jugadores en la esquina superior derecha
            Positioned(
              top: 8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B4B).withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_playerCount Jug.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_roundNumber > 1) ...[
                      const SizedBox(width: 4),
                      Text(
                        '• R$_roundNumber',
                        style: const TextStyle(
                          color: Color(0xFFFDE047),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPointEventBanner() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      builder: (context, val, child) => Opacity(
        opacity: val,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE047), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEAB308).withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _pointEventBanner!,
            style: const TextStyle(
              color: Color(0xFFFDE047),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
            score: rival.score,
            cardsWon: rival.cardsWon,
            isBot: rival.isBot,
            isCurrentTurn: _currentTurnIndex == 1,
            turnProgress: 1.0 - _timerController.value,
            position: PlayerPositionOnTable.top,
            calloutMessage: rival.currentCallout,
            cardsInHandCount: rival.hand.length,
            avatarColor: rival.color,
            avatarId: rival.avatarId,
            isMano: _manoIndex == 1,
          ),
        ),
      );
    } else if (_players.length == 3) {
      final rival1 = _players[1];
      final rival2 = _players[2];

      widgets.add(
        Positioned(
          left: 12,
          top: 100,
          child: TablePlayerBadge(
            name: rival1.name,
            score: rival1.score,
            cardsWon: rival1.cardsWon,
            isBot: rival1.isBot,
            isCurrentTurn: _currentTurnIndex == 1,
            turnProgress: 1.0 - _timerController.value,
            position: PlayerPositionOnTable.left,
            calloutMessage: rival1.currentCallout,
            cardsInHandCount: rival1.hand.length,
            avatarColor: rival1.color,
            avatarId: rival1.avatarId,
            isMano: _manoIndex == 1,
          ),
        ),
      );

      widgets.add(
        Positioned(
          right: 12,
          top: 100,
          child: TablePlayerBadge(
            name: rival2.name,
            score: rival2.score,
            cardsWon: rival2.cardsWon,
            isBot: rival2.isBot,
            isCurrentTurn: _currentTurnIndex == 2,
            turnProgress: 1.0 - _timerController.value,
            position: PlayerPositionOnTable.right,
            calloutMessage: rival2.currentCallout,
            cardsInHandCount: rival2.hand.length,
            avatarColor: rival2.color,
            avatarId: rival2.avatarId,
            isMano: _manoIndex == 2,
          ),
        ),
      );
    } else if (_players.length == 4) {
      final rival1 = _players[1];
      final rival2 = _players[2];
      final rival3 = _players[3];

      // Rival 1 (Izquierda / Alejandro)
      widgets.add(
        Positioned(
          left: 12,
          top: 130,
          child: TablePlayerBadge(
            name: rival1.name,
            score: rival1.score,
            cardsWon: rival1.cardsWon,
            isBot: rival1.isBot,
            isCurrentTurn: _currentTurnIndex == 1,
            turnProgress: 1.0 - _timerController.value,
            position: PlayerPositionOnTable.left,
            calloutMessage: rival1.currentCallout,
            cardsInHandCount: rival1.hand.length,
            avatarColor: rival1.color,
            avatarId: rival1.avatarId,
            isMano: _manoIndex == 1,
          ),
        ),
      );

      // Rival 2 (Frente / Carl)
      widgets.add(
        Positioned(
          top: 8,
          child: TablePlayerBadge(
            name: rival2.name,
            score: rival2.score,
            cardsWon: rival2.cardsWon,
            isBot: rival2.isBot,
            isCurrentTurn: _currentTurnIndex == 2,
            turnProgress: 1.0 - _timerController.value,
            position: PlayerPositionOnTable.top,
            calloutMessage: rival2.currentCallout,
            cardsInHandCount: rival2.hand.length,
            avatarColor: rival2.color,
            avatarId: rival2.avatarId,
            isMano: _manoIndex == 2,
          ),
        ),
      );

      // Rival 3 (Derecha / Jhonny)
      widgets.add(
        Positioned(
          right: 12,
          top: 130,
          child: TablePlayerBadge(
            name: rival3.name,
            score: rival3.score,
            cardsWon: rival3.cardsWon,
            isBot: rival3.isBot,
            isCurrentTurn: _currentTurnIndex == 3,
            turnProgress: 1.0 - _timerController.value,
            position: PlayerPositionOnTable.right,
            calloutMessage: rival3.currentCallout,
            cardsInHandCount: rival3.hand.length,
            avatarColor: rival3.color,
            avatarId: rival3.avatarId,
            isMano: _manoIndex == 3,
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildUserBottomArea(_PlayerState user) {
    return Positioned(
      left: 14,
      bottom: 10,
      child: TablePlayerBadge(
        name: user.name,
        score: user.score,
        cardsWon: user.cardsWon,
        isBot: false,
        isCurrentTurn: _currentTurnIndex == 0,
        turnProgress: 1.0 - _timerController.value,
        position: PlayerPositionOnTable.bottom,
        calloutMessage: user.currentCallout,
        cardsInHandCount: user.hand.length,
        avatarColor: user.color,
        avatarId: user.avatarId,
        isMano: _manoIndex == 0,
      ),
    );
  }

  Widget _buildChoosingManoView() {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Banner superior "¡ELIGE UNA CARTA!" limpio sobre la madera
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE047), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _manoAnnouncement ?? '¡ELIGE UNA CARTA!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFDE047),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Mesa con cartas esparcidas boca abajo de forma natural
            SizedBox(
              width: 340,
              height: 330,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: _manoCandidates.map((cand) {
                  final isChosen = cand.chosenByPlayerIndex != null;
                  final player = isChosen ? _players[cand.chosenByPlayerIndex!] : null;

                  return Positioned(
                    top: 125 + cand.topOffset,
                    left: 140 + cand.leftOffset,
                    child: GestureDetector(
                      onTap: () => _onCandidateCardTapped(cand),
                      child: Transform.rotate(
                        angle: cand.rotation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            cand.isRevealed
                                ? SpanishCardView(
                                    card: cand.card,
                                    width: 52,
                                    isSelected: cand.chosenByPlayerIndex == 0,
                                  )
                                : const SpanishCardView.back(
                                    width: 52,
                                  ),
                            if (player != null)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: player.color.withValues(alpha: 0.88),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white70, width: 1),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black38, blurRadius: 3),
                                  ],
                                ),
                                child: Text(
                                  player.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Zonas fijas de aterrizaje en tapete central para dispersión orgánica y amplia.
  /// Distribuidas para aprovechar al máximo la mesa de madera evitando solapamiento total.
  static const List<Offset> _tableLandingZones = [
    // 0..3: Cuadrantes amplios para el reparto inicial de 4 cartas
    Offset(-68, -80), // 0: Cuadrante Superior Izquierdo
    Offset(68, -80),  // 1: Cuadrante Superior Derecho
    Offset(-68, 75),  // 2: Cuadrante Inferior Izquierdo
    Offset(68, 75),   // 3: Cuadrante Inferior Derecho

    // 4..8: Zonas centrales e intermedias despejadas
    Offset(0, 0),     // 4: Centro absoluto de la mesa
    Offset(-82, -2),  // 5: Flanco Izquierdo central
    Offset(82, -2),   // 6: Flanco Derecho central
    Offset(0, -96),   // 7: Centro Superior
    Offset(0, 96),    // 8: Centro Inferior

    // 9..12: Anillo intermedio diagonal
    Offset(-40, -42), // 9: Intermedio Superior Izquierdo
    Offset(40, -42),  // 10: Intermedio Superior Derecho
    Offset(-40, 42),  // 11: Intermedio Inferior Izquierdo
    Offset(40, 42),   // 12: Intermedio Inferior Derecho

    // 13..16: Flancos exteriores diagonales
    Offset(-84, -45), // 13: Exterior Izquierdo Alto
    Offset(84, -45),  // 14: Exterior Derecho Alto
    Offset(-84, 45),  // 15: Exterior Izquierdo Bajo
    Offset(84, 45),   // 16: Exterior Derecho Bajo
  ];

  static const List<double> _tableLandingRotations = [
    -0.08, // 0
     0.07, // 1
     0.09, // 2
    -0.06, // 3
     0.03, // 4
    -0.07, // 5
     0.08, // 6
    -0.05, // 7
     0.06, // 8
     0.08, // 9
    -0.07, // 10
    -0.06, // 11
     0.07, // 12
    -0.09, // 13
     0.08, // 14
     0.06, // 15
    -0.08, // 16
  ];

  void _syncPlacedCards() {
    // 1. Eliminar cartas capturadas que ya no están en mesa
    _placedTableCards.removeWhere((placed) => !_tableCards.contains(placed.card));

    // 2. Obtener conjunto de zonas actualmente ocupadas
    final occupiedZones = _placedTableCards.map((p) => p.zoneIndex).toSet();

    // 3. Colocar nuevas cartas manteniendo estabilidad de las ya existentes
    for (int i = 0; i < _tableCards.length; i++) {
      final card = _tableCards[i];
      final alreadyPlaced = _placedTableCards.any((p) => p.card == card);
      if (!alreadyPlaced) {
        int chosenZone = -1;

        // Para las 4 cartas iniciales, asignar los cuadrantes 0..3 si están disponibles
        if (i < 4 && !occupiedZones.contains(i)) {
          chosenZone = i;
        } else {
          // Seleccionar la zona libre que maximice la distancia mínima a todas las cartas ya colocadas
          double maxMinDist = -1;
          for (int z = 0; z < _tableLandingZones.length; z++) {
            if (occupiedZones.contains(z)) continue;
            final candidateOffset = _tableLandingZones[z];

            if (_placedTableCards.isEmpty) {
              chosenZone = z;
              break;
            }

            double minDistToPlaced = double.infinity;
            for (final placed in _placedTableCards) {
              final d = (candidateOffset - placed.offset).distance;
              if (d < minDistToPlaced) {
                minDistToPlaced = d;
              }
            }

            if (minDistToPlaced > maxMinDist) {
              maxMinDist = minDistToPlaced;
              chosenZone = z;
            }
          }

          // Fallback de seguridad si todas las zonas estuvieran ocupadas (>17 cartas)
          if (chosenZone == -1) {
            chosenZone = _tableCardZCounter % _tableLandingZones.length;
          }
        }

        occupiedZones.add(chosenZone);

        final baseOffset = _tableLandingZones[chosenZone];
        final baseRot = _tableLandingRotations[chosenZone];

        // Micro-jitter determinista por carta (±3.6 px y ±0.02 rad) para aspecto natural
        final jitterX = ((card.number * 7 + card.suit.index * 13) % 7 - 3) * 1.2;
        final jitterY = ((card.number * 11 + card.suit.index * 19) % 7 - 3) * 1.2;
        final jitterRot = ((card.number * 13 + card.suit.index * 17) % 5 - 2) * 0.01;

        _tableCardZCounter++;
        _placedTableCards.add(_PlacedTableCard(
          card: card,
          offset: Offset(baseOffset.dx + jitterX, baseOffset.dy + jitterY),
          rotation: baseRot + jitterRot,
          zIndex: _tableCardZCounter,
          zoneIndex: chosenZone,
        ));
      }
    }
  }

  /// Cartas en tapete central: colocadas directamente sobre la madera (100% natural, "regadas al azar")
  Widget _buildTableCenterCards() {
    if (_isChoosingMano) {
      return _buildChoosingManoView();
    }

    if (_placedTableCards.length != _tableCards.length) {
      _syncPlacedCards();
    }

    final cardsToShow = (_isDealing && _isFirstRoundDealing)
        ? _tableCards.take(((_dealingController.value) * 6).clamp(1, 4).toInt()).toList()
        : _tableCards;

    final spokenSeq = _cantoDirection.sequence;

    if (_tableCards.isEmpty) {
      return Center(
        child: Text(
          _isDealing ? 'Repartiendo cartas...' : 'Mesa Limpia',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
        ),
      );
    }

    // Filtrar y ordenar naipes visibles según su zIndex para que se solapen naturalmente
    final visiblePlaced = _placedTableCards
        .where((p) => cardsToShow.contains(p.card))
        .toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return Center(
      child: SizedBox(
        height: 310,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: visiblePlaced.map((placed) {
            final card = placed.card;
            final cardIndex = _tableCards.indexOf(card);
            final spokenNum = (_isDealing && _isFirstRoundDealing && cardIndex >= 0 && cardIndex < spokenSeq.length)
                ? spokenSeq[cardIndex]
                : null;
            final isHit = spokenNum != null && card.number == spokenNum;

            return Transform.translate(
              key: ValueKey('table_card_${card.suit.index}_${card.number}'),
              offset: placed.offset,
              child: Transform.rotate(
                angle: placed.rotation,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('scale_${card.suit.index}_${card.number}'),
                  duration: const Duration(milliseconds: 250),
                  tween: Tween<double>(begin: 0.5, end: 1.0),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Número cantado durante el Canto de Mesa (estampado en madera con sombra pura)
                      if (_isDealing && _isFirstRoundDealing && spokenNum != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            isHit ? '¡$spokenNum! ⭐' : '$spokenNum',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: isHit ? const Color(0xFFFDE047) : Colors.white,
                              shadows: [
                                Shadow(
                                  color: isHit ? const Color(0xFFCA8A04) : Colors.black87,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SpanishCardView(
                        card: card,
                        width: 58,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Abanico de cartas en disposición real (fan layout) con selección individual limpia:
  /// Cada carta tiene su inclinación natural (-0.08, 0.0, 0.08) emulando sostener naipes reales.
  Widget _buildUserHandFan(_PlayerState user) {
    if (user.hand.isEmpty) {
      return const SizedBox.shrink();
    }

    final cardCount = user.hand.length;
    final isMyTurn = _currentTurnIndex == 0 && !_isGameOver && !_isDealing && !_isChoosingMano;
    final fanAngles = cardCount == 3
        ? [-0.08, 0.0, 0.08]
        : (cardCount == 2 ? [-0.05, 0.05] : [0.0]);
    final fanYOffsets = cardCount == 3
        ? [6.0, 0.0, 6.0]
        : (cardCount == 2 ? [3.0, 3.0] : [0.0]);

    // Cartas individuales en abanico (fan layout) con sombreado de selección limpio
    return SizedBox(
      height: 132,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(cardCount, (index) {
              final card = user.hand[index];
              final isSelected = isMyTurn && _selectedCard == card;
              final angle = isSelected ? 0.0 : fanAngles[index % fanAngles.length];
              final yOffset = isSelected ? -18.0 : fanYOffsets[index % fanYOffsets.length];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.translationValues(0, yOffset, 0),
                  child: Transform.rotate(
                    angle: angle,
                    child: AnimatedScale(
                      scale: isSelected ? 1.06 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: SpanishCardView(
                        key: ValueKey('user_card_$index'),
                        card: card,
                        width: 76,
                        isSelected: isSelected,
                        onTap: isMyTurn ? () => _onUserCardTap(card) : null,
                      ),
                    ),
                  ),
                ),
              );
        }),
      ),
    );
  }
}
