import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/models/cards/spanish_card.dart';
import '../../../core/models/cards/spanish_deck.dart';
import '../../../core/presentation/widgets/game_rules_dialog.dart';
import '../../../core/presentation/widgets/game_table_header.dart';
import '../../../core/presentation/widgets/spanish_card_view.dart';
import '../../../core/presentation/widgets/table_player_badge.dart';
import '../../../core/presentation/widgets/wood_table_background.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/debug_logger.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/services/user_profile_service.dart';
import '../domain/caida_models.dart';
import '../domain/caida_rules_engine.dart';
import '../domain/models/caida_match_config.dart';
import '../domain/models/mano_draw_session.dart';
import '../domain/models/match_play_tracker.dart';
import '../domain/models/player_callout.dart';
import '../domain/models/spatial_card_state.dart';
import '../domain/models/table_landing_zone.dart';
import '../economy/chest_slot_model.dart';
import '../economy/player_session.dart';
import '../economy/player_stats_model.dart';
import '../economy/vip_tier.dart';
import 'widgets/caida_game_over_modal.dart';
import 'widgets/card_flight_overlay.dart';
import 'widgets/deck_stack_view.dart';
import 'widgets/table_canto_dialog.dart';
import 'widgets/privacy_policy_dialog.dart';
import 'caida_lobby_screen.dart';

class _PlayerState {
  final String id;
  final String name;
  final bool isBot;
  final Color color;
  final int teamId;
  final int avatarId;
  final int? level;
  List<SpanishCard> hand = [];
  int score = 0;
  int cardsWon = 0;
  int totalMatchCardsWon = 0;
  PlayerCallout? callout;
  Canto? pendingCanto;

  String? get currentCallout => callout?.text;
  set currentCallout(String? text) {
    if (text == null) {
      callout?.cancel();
      callout = null;
    } else {
      callout?.cancel();
      callout = PlayerCallout(text: text);
    }
  }

  Timer? get calloutTimer => callout?.timer;
  set calloutTimer(Timer? timer) {
    if (callout != null) {
      callout!.timer = timer;
    }
  }

  _PlayerState({
    required this.id,
    required this.name,
    required this.isBot,
    required this.color,
    this.teamId = 0,
    this.avatarId = 2,
    this.level,
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
  final CaidaMatchConfig? config;
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
  final bool isMatandoCantos;

  const CaidaScreen({
    super.key,
    this.config,
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
    this.isMatandoCantos = false,
  });

  @override
  State<CaidaScreen> createState() => _CaidaScreenState();
}

class _CaidaScreenState extends State<CaidaScreen> with TickerProviderStateMixin {
  late SpanishDeck _deck;
  late List<_PlayerState> _players;
  final List<SpanishCard> _tableCards = [];
  final List<PlacedTableCard> _placedTableCards = [];
  int _tableCardZCounter = 0;
  bool _isProcessingPlay = false;
  List<CardFlightTrajectory> _activeTrajectories = [];

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

  // Sistema de Nivel
  int _userLevel = 1;

  // Estado de reparto animado
  bool _isDealing = false;
  bool _isFirstRoundDealing = true;

  // Acumulación persistente de trofeos de la sesión
  int _sessionTrophies = 7500;

  // Selección individual de cartas en la mano del usuario
  SpanishCard? _selectedCard;

  // Seguimiento de jugadas y estadísticas mediante Domain Object
  final MatchPlayTracker _playTracker = MatchPlayTracker();
  SpanishCard? get _lastPlayedCard => _playTracker.lastPlayedCard;
  set _lastPlayedCard(SpanishCard? c) => _playTracker.lastPlayedCard = c;
  int? get _lastPlayedPlayerIndex => _playTracker.lastPlayedPlayerIndex;
  set _lastPlayedPlayerIndex(int? i) => _playTracker.lastPlayedPlayerIndex = i;
  int? get _lastCapturingPlayerIndex => _playTracker.lastCapturingPlayerIndex;
  set _lastCapturingPlayerIndex(int? i) => _playTracker.lastCapturingPlayerIndex = i;

  int get _matchUserCaidas => _playTracker.userCaidas;
  set _matchUserCaidas(int val) => _playTracker.userCaidas = val;
  int get _matchUserLimpias => _playTracker.userLimpias;
  set _matchUserLimpias(int val) => _playTracker.userLimpias = val;
  int get _matchUserCantos => _playTracker.userCantos;
  set _matchUserCantos(int val) => _playTracker.userCantos = val;

  // Canto de Mesa del repartidor
  DealDirection _cantoDirection = DealDirection.ascending;
  String? _pointEventBanner;

  // Sorteo interactivo de Mano ("¡ELIGE UNA CARTA!") encapsulado en Domain Object
  ManoDrawSession _manoSession = ManoDrawSession();
  bool get _isChoosingMano => _manoSession.isActive;
  set _isChoosingMano(bool val) => _manoSession.isActive = val;
  List<ManoCardCandidate> get _manoCandidates => _manoSession.candidates;
  String? get _manoAnnouncement => _manoSession.announcement;
  set _manoAnnouncement(String? val) => _manoSession.announcement = val;

  // Temporizadores y animaciones
  late AnimationController _timerController;
  late AnimationController _dealingController;
  Timer? _botTimer;
  Timer? _finishTimer;
  final List<Timer> _cantoAudioTimers = [];
  final List<Timer> _pendingAsyncTimers = [];

  Future<void> _safeDelay(Duration duration) {
    if (!mounted) return Future.value();
    final completer = Completer<void>();
    late Timer timer;
    timer = Timer(duration, () {
      _pendingAsyncTimers.remove(timer);
      if (!completer.isCompleted) completer.complete();
    });
    _pendingAsyncTimers.add(timer);
    return completer.future;
  }

  int get _effectivePlayers => widget.config?.initialPlayers ?? widget.initialPlayers;
  bool get _effectiveAutoStart => widget.config?.autoStart ?? widget.autoStart;
  bool get _effectiveAnimateDealing => widget.config?.animateDealing ?? widget.animateDealing;
  bool get _effectiveTeams => widget.config?.initialTeams ?? widget.initialTeams;
  bool get _effectiveChooseMano => widget.config?.chooseMano ?? widget.chooseMano;
  String? get _effectiveUserName => widget.config?.userName ?? widget.userName;
  List<String>? get _effectiveBotNames => widget.config?.botNames ?? widget.botNames;
  VipTierOffer? get _vipTier => widget.config?.vipTier ?? widget.vipTier;
  int? get _vipPrizePool => widget.config?.vipPrizePool ?? widget.vipPrizePool;
  int? get _vipWinnerReward => widget.config?.vipWinnerReward ?? widget.vipWinnerReward;
  bool get _effectiveIsMatandoCantos => widget.config?.isMatandoCantos ?? widget.isMatandoCantos;

  @override
  void initState() {
    super.initState();
    _playerCount = _effectivePlayers.clamp(2, 4);
    _botCount = (_playerCount - 1).clamp(1, 3);
    _hasGameStarted = _effectiveAutoStart;
    _isTeams = _effectiveTeams;

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
    final initialUserName = _effectiveUserName ?? 'Tú';
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
        animate: _effectiveAnimateDealing,
        startWithManoSelection: _effectiveChooseMano,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SpanishCardView.precacheAllCards(context);
  }

  @override
  void dispose() {
    for (final t in _pendingAsyncTimers) {
      t.cancel();
    }
    _pendingAsyncTimers.clear();
    _timerController.dispose();
    _dealingController.dispose();
    _botTimer?.cancel();
    _finishTimer?.cancel();
    for (final t in _cantoAudioTimers) {
      t.cancel();
    }
    _cantoAudioTimers.clear();
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
    for (final t in _pendingAsyncTimers) {
      t.cancel();
    }
    _pendingAsyncTimers.clear();
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
    _playTracker.reset();
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
      _startManoSelection(animate: animate ?? widget.animateDealing);
    } else {
      _manoIndex = 0;
      final shouldAnimate = animate ?? widget.animateDealing;
      _startDeal(isFirstRound: true, animate: shouldAnimate);
    }
  }

  void _startManoSelection({bool animate = true}) async {
    _manoSession = ManoDrawSession.startNew(
      initialAnnouncement: 'Sorteo de Mano: Toca una carta para ver quién sale',
    );
    _pointEventBanner = '¡BIENVENIDOS A LA MESA DE CAÍDA!';
    DebugLogger.instance.logGame('Iniciando sorteo interactivo de Mano');

    setState(() {});

    if (animate) {
      final spreadFlights = <CardFlightTrajectory>[];
      for (final cand in _manoCandidates) {
        spreadFlights.add(CardFlightTrajectory(
          id: 'mano_spread_${cand.id}_${DateTime.now().millisecondsSinceEpoch}',
          card: cand.card,
          startAnchor: SpatialCardAnchor.deckAnchor,
          targetAnchor: SpatialCardAnchor(
            offset: Offset(cand.leftOffset, cand.topOffset),
            rotation: cand.rotation,
          ),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          isFaceUp: false,
        ));
      }

      setState(() {
        _activeTrajectories = spreadFlights;
      });

      await _safeDelay(const Duration(milliseconds: 400));
      if (!mounted) return;

      setState(() {
        _activeTrajectories.clear();
      });
    }
  }

  void _onCandidateCardTapped(ManoCardCandidate userChoice) async {
    if (userChoice.chosenByPlayerIndex != null || !_isChoosingMano) return;

    // 1. Revelar la carta del usuario de inmediato
    setState(() {
      _manoSession.pickCard(userChoice, 0);
      _manoAnnouncement = 'Tú sacas: ${userChoice.card.displayName}';
    });

    await _safeDelay(const Duration(milliseconds: 650));
    if (!mounted || !_isChoosingMano) return;

    // 2. Cada bot elige de forma visible y secuencial
    final unchosen = _manoSession.unchosenCandidates;
    unchosen.shuffle();

    for (int i = 1; i < _players.length; i++) {
      if (unchosen.isNotEmpty) {
        setState(() {
          _manoAnnouncement = '${_players[i].name} está eligiendo...';
        });
        await _safeDelay(const Duration(milliseconds: 450));
        if (!mounted || !_isChoosingMano) return;

        final botPick = unchosen.removeLast();
        setState(() {
          _manoSession.pickCard(botPick, i);
          _manoAnnouncement = '${_players[i].name} sacó: ${botPick.card.displayName}';
        });
        await _safeDelay(const Duration(milliseconds: 650));
        if (!mounted || !_isChoosingMano) return;
      }
    }

    // 3. Determinar la carta mayor entre los jugadores
    final winnerChoice = _manoSession.determineWinner()!;
    final winnerIndex = winnerChoice.chosenByPlayerIndex!;
    final winner = _players[winnerIndex];

    setState(() {
      _manoIndex = winnerIndex;
      _manoAnnouncement = '¡${winner.name} saca el ${winnerChoice.card.number} y es MANO!';
    });

    await _safeDelay(const Duration(milliseconds: 2200));
    if (!mounted) return;

    // 4. Cinemática: Todas las cartas del sorteo se van en manojo hacia la estación del ganador
    final winnerAnchor = SpatialCardAnchor.playerStationAnchor(
      playerIndex: winnerIndex,
      totalPlayers: _players.length,
    );

    final collectFlights = <CardFlightTrajectory>[];
    for (final cand in _manoCandidates.where((c) => c.chosenByPlayerIndex != null)) {
      collectFlights.add(CardFlightTrajectory(
        id: 'mano_bundle_${cand.id}_${DateTime.now().millisecondsSinceEpoch}',
        card: cand.card,
        startAnchor: SpatialCardAnchor(
          offset: Offset(cand.leftOffset, cand.topOffset),
          rotation: cand.rotation,
        ),
        targetAnchor: winnerAnchor,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
        isFaceUp: false,
      ));
    }

    setState(() {
      _isChoosingMano = false;
      _manoAnnouncement = null;
      _manoCandidates.clear();
      _activeTrajectories = collectFlights;
    });

    await _safeDelay(const Duration(milliseconds: 560));
    if (!mounted) return;

    setState(() {
      _activeTrajectories.clear();
    });

    // 5. Si el usuario es la Mano, SIEMPRE se le ofrece elegir Canto de Mesa (1 o 4) en modal atenuado
    if (_manoIndex == 0) {
      final dir = await TableCantoDialog.show(context);
      if (dir != null && mounted) {
        setState(() => _cantoDirection = dir);
      }
    } else {
      _cantoDirection = DealDirection.ascending;
    }

    // 6. Iniciar el reparto en sentido de las agujas del reloj
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
      level: _userLevel,
    ));

    // Nombres y avatares según bots configurados o por defecto
    final defaultBotNames = [
      for (int i = 1; i < totalPlayers; i++) 'Player $i'
    ];
    final effectiveBotNames = _effectiveBotNames ?? defaultBotNames;
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

  void _addPoints(_PlayerState player, int points) {
    if (points <= 0) return;
    if (_isTeams) {
      for (final p in _players) {
        if (p.teamId == player.teamId) {
          p.score += points;
        }
      }
    } else {
      player.score += points;
    }
  }

  void _addCardsWon(_PlayerState player, int count) {
    if (count <= 0) return;
    if (_isTeams) {
      for (final p in _players) {
        if (p.teamId == player.teamId) {
          p.cardsWon += count;
          p.totalMatchCardsWon += count;
        }
      }
    } else {
      player.cardsWon += count;
      player.totalMatchCardsWon += count;
    }
  }

  bool _checkGameOver() {
    if (_isGameOver) return true;
    if (_players.any((p) => p.score >= 24)) {
      _finishGame();
      return true;
    }
    return false;
  }

  void _startDeal({required bool isFirstRound, required bool animate}) async {
    _clearAllCallouts();
    _timerController.stop();
    _isFirstRoundDealing = isFirstRound;

    if (!animate) {
      // Modo instantáneo para pruebas automatizadas
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
          _addPoints(dealer, dealResult.dealerPoints);
          _triggerCallout(dealer, 'Canto de Mesa (+${dealResult.dealerPoints} pts)');
        }
        if (dealResult.opponentPoints > 0) {
          _addPoints(opponent, dealResult.opponentPoints);
          _triggerCallout(opponent, '+${dealResult.opponentPoints} pt (Mesa)');
        }

        if (_checkGameOver()) return;
      }

      for (final p in _players) {
        p.hand.clear();
        p.pendingCanto = null;
      }

      // Reparto de 1 en 1 en sentido horario desde la Mano (3 vueltas = 3 cartas cada uno)
      for (int round = 0; round < 3; round++) {
        for (int step = 0; step < _players.length; step++) {
          final pIndex = (_manoIndex + step) % _players.length;
          final c = _deck.draw();
          if (c != null) _players[pIndex].hand.add(c);
        }
      }

      _isDealing = false;
      _onDealingCompleted();
      return;
    }

    // Modo animado
    _isDealing = true;
    if (isFirstRound) {
      _tableCards.clear();
      _placedTableCards.clear();
      _tableCardZCounter = 0;
      _lastCapturingPlayerIndex = null;
      _lastPlayedCard = null;
      _lastPlayedPlayerIndex = null;
      _pointEventBanner = '¡BIENVENIDOS A LA MESA DE CAÍDA!';
    }

    for (final p in _players) {
      p.hand.clear();
      p.pendingCanto = null;
    }
    setState(() {});

    if (isFirstRound) {
      await _safeDelay(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _pointEventBanner = null;
      });
    }

    // 1. Repartir 1 carta a la vez en sentido horario comenzando desde el jugador que es Mano (3 vueltas)
    for (int round = 0; round < 3; round++) {
      for (int step = 0; step < _players.length; step++) {
        final pIndex = (_manoIndex + step) % _players.length;
        final player = _players[pIndex];
        final drawn = _deck.draw();
        if (drawn == null) continue;

        final targetStation = SpatialCardAnchor.playerStationAnchor(
          playerIndex: pIndex,
          totalPlayers: _players.length,
        );

        setState(() {
          _activeTrajectories = [
            CardFlightTrajectory(
              id: 'deal_hand_${round}_${pIndex}_${DateTime.now().millisecondsSinceEpoch}',
              card: drawn,
              startAnchor: SpatialCardAnchor.deckAnchor,
              targetAnchor: targetStation,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              isFaceUp: pIndex == 0,
            ),
          ];
        });

        await _safeDelay(const Duration(milliseconds: 270));
        if (!mounted) return;

        setState(() {
          _activeTrajectories.clear();
          player.hand.add(drawn);
        });

        await _safeDelay(const Duration(milliseconds: 70));
        if (!mounted) return;
      }
    }

    // 2. Si es la primera ronda, repartir las 4 cartas a la mesa de 1 en 1 con animación y Canto de Mesa
    if (isFirstRound) {
      final dealer = _players[_manoIndex];
      final opponent = _players[(_manoIndex + 1) % _players.length];

      final dealResult = CaidaRulesEngine.dealInitialTable(
        direction: _cantoDirection,
        deck: _deck,
        dealerId: dealer.id,
        opponentId: opponent.id,
      );

      for (int i = 0; i < dealResult.tableCards.length; i++) {
        final tableCard = dealResult.tableCards[i];
        final placement = _computePlacementForCard(tableCard);

        setState(() {
          _activeTrajectories = [
            CardFlightTrajectory(
              id: 'deal_table_${i}_${DateTime.now().millisecondsSinceEpoch}',
              card: tableCard,
              startAnchor: SpatialCardAnchor.deckAnchor,
              targetAnchor: SpatialCardAnchor(
                card: tableCard,
                offset: placement.offset,
                rotation: placement.rotation,
              ),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              isFaceUp: true,
            ),
          ];
        });

        await _safeDelay(const Duration(milliseconds: 330));
        if (!mounted) return;

        setState(() {
          _activeTrajectories.clear();
          _tableCards.add(tableCard);
          _placedTableCards.add(placement);
        });

        await _safeDelay(const Duration(milliseconds: 140));
        if (!mounted) return;
      }

      if (dealResult.dealerPoints > 0) {
        _addPoints(dealer, dealResult.dealerPoints);
        _triggerCallout(dealer, 'Canto de Mesa (+${dealResult.dealerPoints} pts)');
        await _safeDelay(const Duration(milliseconds: 500));
      }
      if (dealResult.opponentPoints > 0) {
        _addPoints(opponent, dealResult.opponentPoints);
        _triggerCallout(opponent, '+${dealResult.opponentPoints} pt (Mesa)');
        await _safeDelay(const Duration(milliseconds: 500));
      }

      if (_checkGameOver()) return;
    }

    _isDealing = false;
    _onDealingCompleted();
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

  void _onRoundFinished() async {
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

      if (_isTeams) {
        // Asegurar que los puntos y cartas recogidas sean exactamente iguales para ambos miembros del equipo
        for (int team = 1; team <= 2; team++) {
          final teamPlayers = _players.where((pl) => pl.teamId == team).toList();
          if (teamPlayers.isNotEmpty) {
            final maxScore = teamPlayers.map((pl) => pl.score).reduce(math.max);
            final maxCards = teamPlayers.map((pl) => pl.cardsWon).reduce(math.max);
            for (final pl in teamPlayers) {
              pl.score = maxScore;
              pl.cardsWon = maxCards;
            }
          }
        }
      }

      _tableCards.clear();
      _placedTableCards.clear();

      if (_checkGameOver()) return;

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

      // Consulta obligatoria si le toca ser Mano al usuario en modal atenuado
      if (_manoIndex == 0 && mounted) {
        final dir = await TableCantoDialog.show(context);
        if (dir != null && mounted) {
          setState(() => _cantoDirection = dir);
        }
      } else {
        _cantoDirection = DealDirection.ascending;
      }

      _startDeal(isFirstRound: true, animate: widget.animateDealing);
      return;
    }

    // Aún quedan cartas en el mazo: se reparten 3 cartas más dentro del mismo manojo.
    // La Mano se mantiene fija durante todo el manojo hasta agotarse el mazo completo.
    _roundNumber++;
    _lastPlayedCard = null;
    _lastPlayedPlayerIndex = null;
    _startDeal(isFirstRound: false, animate: widget.animateDealing);
  }

  bool _allHandsEmpty() => _players.every((p) => p.hand.isEmpty);

  void _onHandsExhausted() async {
    final hadCantos = _players.any((p) => p.pendingCanto != null);
    if (hadCantos) {
      _resolveAndAwardCantos();
      setState(() {});

      if (_checkGameOver()) return;

      await _safeDelay(const Duration(milliseconds: 1800));
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
          final timer = Timer(Duration(milliseconds: captureDelay), () {
            if (mounted) {
              AudioService().playCanto(cantoName);
            }
          });
          _cantoAudioTimers.add(timer);
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
        _addPoints(p, canto.points);
        if (p.id == 'user' || (_isTeams && p.teamId == _players[0].teamId)) {
          _matchUserCantos++;
          PlayerStatsModel.shared.recordCanto(canto.name);
        }
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

    _checkGameOver();
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

  void _playCard(_PlayerState player, SpanishCard card) async {
    if (_isProcessingPlay || _isGameOver || _isDealing || _isChoosingMano) return;
    if (!player.hand.contains(card)) return;

    _isProcessingPlay = true;
    _botTimer?.cancel();
    _timerController.stop();

    final previousCard = (_lastPlayedPlayerIndex != null && _lastPlayedPlayerIndex != _currentTurnIndex)
        ? _lastPlayedCard
        : null;

    final eval = CaidaRulesEngine.evaluatePlay(
      playedCard: card,
      tableCards: _tableCards,
      previousCard: previousCard,
      isDeckEmpty: _deck.isEmpty,
    );

    final playerIdx = _players.indexOf(player);
    final isUser = playerIdx == 0;
    final handIndex = player.hand.indexOf(card);

    final startAnchor = isUser
        ? SpatialCardAnchor.userHandSlotAnchor(
            cardIndex: handIndex.clamp(0, 2),
            totalCardsInHand: player.hand.length,
          )
        : SpatialCardAnchor.playerStationAnchor(
            playerIndex: playerIdx,
            totalPlayers: _players.length,
          );

    SpatialCardAnchor targetAnchor;
    PlacedTableCard? plannedPlacement;
    if (eval.didCapture) {
      final matchedPlaced = _placedTableCards.where((p) => p.card.number == card.number).firstOrNull;
      if (matchedPlaced != null) {
        targetAnchor = SpatialCardAnchor(
          card: card,
          offset: matchedPlaced.offset,
          rotation: matchedPlaced.rotation,
          scale: 1.0,
        );
      } else {
        targetAnchor = const SpatialCardAnchor(offset: Offset(0, 0));
      }
    } else {
      plannedPlacement = _computePlacementForCard(card);
      targetAnchor = SpatialCardAnchor(
        card: card,
        offset: plannedPlacement.offset,
        rotation: plannedPlacement.rotation,
        scale: 1.0,
      );
    }

    if (widget.animateDealing) {
      // 1. Quitar de la mano y lanzar el vuelo hacia la mesa / carta objetivo
      setState(() {
        player.hand.remove(card);
        _selectedCard = null;
        _activeTrajectories = [
          CardFlightTrajectory(
            id: 'play_${card.shortCode}_${DateTime.now().millisecondsSinceEpoch}',
            card: card,
            startAnchor: startAnchor,
            targetAnchor: targetAnchor,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            isCaidaImpact: eval.isCaida,
          ),
        ];
      });

      await _safeDelay(const Duration(milliseconds: 440));
      if (eval.didCapture) {
        final isUserSide = player.id == 'user' || (_isTeams && player.teamId == _players[0].teamId);
        if (eval.isCaida) {
          if (isUserSide) {
            _matchUserCaidas++;
            PlayerStatsModel.shared.recordCaidaMade(withLimpia: eval.isLimpia);
          } else {
            final lastPlayedPlayer = (_lastPlayedPlayerIndex != null && _lastPlayedPlayerIndex! >= 0 && _lastPlayedPlayerIndex! < _players.length)
                ? _players[_lastPlayedPlayerIndex!]
                : null;
            final lastWasUserSide = lastPlayedPlayer != null && (lastPlayedPlayer.id == 'user' || (_isTeams && lastPlayedPlayer.teamId == _players[0].teamId));
            if (lastWasUserSide) {
              PlayerStatsModel.shared.recordCaidaReceived();
            }
          }
        } else if (eval.isLimpia && isUserSide) {
          _matchUserLimpias++;
          PlayerStatsModel.shared.recordMesaLimpia();
        }

        // Sonidos de Caída / Limpia al impactar
        if (eval.isCaida) AudioService().playCaida();
        if (eval.isLimpia) {
          _safeDelay(const Duration(milliseconds: 400)).then((_) {
            if (mounted) AudioService().playMesaLimpia();
          });
        }

        // 2. Vuelo de recogida: todas las cartas capturadas vuelan suavemente hacia el avatar del jugador
        final returnAnchor = SpatialCardAnchor.playerStationAnchor(
          playerIndex: playerIdx,
          totalPlayers: _players.length,
        );

        final returnFlights = <CardFlightTrajectory>[];
        for (final capCard in eval.capturedCards) {
          final capPlaced = _placedTableCards.where((p) => p.card == capCard).firstOrNull;
          final capOrigin = capPlaced != null
              ? SpatialCardAnchor(card: capCard, offset: capPlaced.offset, rotation: capPlaced.rotation)
              : targetAnchor;

          returnFlights.add(
            CardFlightTrajectory(
              id: 'collect_${capCard.shortCode}_${DateTime.now().millisecondsSinceEpoch}',
              card: capCard,
              startAnchor: capOrigin,
              targetAnchor: returnAnchor,
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeInOutCubic,
            ),
          );
        }

        setState(() {
          _activeTrajectories = returnFlights;
          _tableCards.clear();
          _tableCards.addAll(eval.newTableCards);
          _syncPlacedCards();
        });

        await _safeDelay(const Duration(milliseconds: 560));
        if (!mounted || _isGameOver) return;

        setState(() {
          _activeTrajectories.clear();
        });

        _addCardsWon(player, eval.capturedCards.length);
        _lastCapturingPlayerIndex = _currentTurnIndex;

        if (eval.totalPoints > 0) {
          _addPoints(player, eval.totalPoints);
          _triggerCallout(player, eval.breakdownMessage);
        } else if (eval.capturedCards.length > 2) {
          _triggerCallout(player, eval.breakdownMessage);
        }
      } else {
        // No hubo captura: la carta se asienta sobre la mesa exactamente donde aterrizó el vuelo
        setState(() {
          _activeTrajectories.clear();
          _tableCards.clear();
          _tableCards.addAll(eval.newTableCards);
          if (plannedPlacement != null && !_placedTableCards.any((p) => p.card == plannedPlacement!.card)) {
            _placedTableCards.add(plannedPlacement);
          }
          _syncPlacedCards();
        });
      }
    } else {
      // Modo instantáneo para pruebas y autoStart
      setState(() {
        player.hand.remove(card);
        _selectedCard = null;
        _tableCards.clear();
        _tableCards.addAll(eval.newTableCards);
        _syncPlacedCards();
      });

      if (eval.didCapture) {
        final isUserSide = player.id == 'user' || (_isTeams && player.teamId == _players[0].teamId);
        if (eval.isCaida) {
          if (isUserSide) {
            _matchUserCaidas++;
            PlayerStatsModel.shared.recordCaidaMade(withLimpia: eval.isLimpia);
          } else {
            final lastPlayedPlayer = (_lastPlayedPlayerIndex != null && _lastPlayedPlayerIndex! >= 0 && _lastPlayedPlayerIndex! < _players.length)
                ? _players[_lastPlayedPlayerIndex!]
                : null;
            final lastWasUserSide = lastPlayedPlayer != null && (lastPlayedPlayer.id == 'user' || (_isTeams && lastPlayedPlayer.teamId == _players[0].teamId));
            if (lastWasUserSide) {
              PlayerStatsModel.shared.recordCaidaReceived();
            }
          }
        } else if (eval.isLimpia && isUserSide) {
          _matchUserLimpias++;
          PlayerStatsModel.shared.recordMesaLimpia();
        }
        _addCardsWon(player, eval.capturedCards.length);
        _lastCapturingPlayerIndex = _currentTurnIndex;
      }

      if (eval.totalPoints > 0) {
        _addPoints(player, eval.totalPoints);
        _triggerCallout(player, eval.breakdownMessage);
      } else if (eval.didCapture && eval.capturedCards.length > 2) {
        _triggerCallout(player, eval.breakdownMessage);
      }

      if (eval.isCaida && eval.isLimpia) {
        AudioService().playCaida();
        AudioService().playMesaLimpia();
      } else if (eval.isCaida) {
        AudioService().playCaida();
      } else if (eval.isLimpia) {
        AudioService().playMesaLimpia();
      }
    }

    _lastPlayedCard = card;
    _lastPlayedPlayerIndex = _currentTurnIndex;
    _isProcessingPlay = false;

    // Comprobar si algún jugador o equipo alcanzó los 24 puntos
    if (_checkGameOver()) return;

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
    final session = PlayerSession.shared;
    final initialLevel = session.level;
    final int rawXpGained = userWon
        ? (60 + (_players[0].totalMatchCardsWon * 2) + (_matchUserCaidas * 10) + (_matchUserLimpias * 15))
        : (20 + (_players[0].totalMatchCardsWon * 1));
    final int xpGained = _vipTier != null ? (rawXpGained * 1.25).round() : rawXpGained;

    if (userWon) {
      _sessionTrophies += 2000 + (_players[0].score * 50);
    } else {
      _sessionTrophies = math.max(0, _sessionTrophies - 500 + (_players[0].score * 20));
    }
    _userLevel = session.level;

    // Recompensas del sistema de economía de Fase 2 (PlayerSession)
    int vipCoinsWon = 0;
    bool chestAwarded = false;
    int? chestSlotIndex;

    if (_vipTier != null) {
      if (userWon) {
        vipCoinsWon = _vipWinnerReward ?? _vipTier!.calculateNetPrizePerWinner(isTeams: _isTeams);
        session.rewardCoins(vipCoinsWon, xpGain: xpGained);
        chestAwarded = session.addChestOnWin();
        if (chestAwarded) {
          chestSlotIndex = session.chests.indexWhere((c) => c.getState() == ChestState.unlocking);
          if (chestSlotIndex == -1) chestSlotIndex = 0;
        }
      } else {
        session.addXp(xpGained);
      }
    } else {
      if (userWon) {
        vipCoinsWon = 150;
        session.rewardCoins(150, xpGain: xpGained);
        chestAwarded = session.addChestOnWin();
        if (chestAwarded) {
          chestSlotIndex = session.chests.indexWhere((c) => c.getState() == ChestState.unlocking);
          if (chestSlotIndex == -1) chestSlotIndex = 0;
        }
      } else {
        session.addXp(xpGained);
      }
    }

    // Registrar en estadísticas persistentes del jugador
    PlayerStatsModel.shared.recordGameResult(
      won: userWon,
      isTeams: _isTeams,
      coinsWon: vipCoinsWon,
      cardsWon: _players[0].totalMatchCardsWon,
    );

    final finalLevel = session.level;
    final didLevelUp = finalLevel > initialLevel;

    final userTeamPlayers = _isTeams ? _players.where((p) => p.teamId == _players[0].teamId).toList() : [_players[0]];
    final oppTeamPlayers = _isTeams ? _players.where((p) => p.teamId != _players[0].teamId).toList() : _players.where((p) => p.id != 'user').toList();

    final userTeamScore = userTeamPlayers.isNotEmpty ? userTeamPlayers.map((p) => p.score).reduce(math.max) : _players[0].score;
    final oppTeamScore = oppTeamPlayers.isNotEmpty ? oppTeamPlayers.map((p) => p.score).reduce(math.max) : (sorted.length > 1 ? sorted[1].score : 0);

    final userTeamCards = userTeamPlayers.isNotEmpty ? userTeamPlayers.map((p) => p.totalMatchCardsWon).reduce(math.max) : _players[0].totalMatchCardsWon;
    final oppTeamCards = oppTeamPlayers.isNotEmpty ? oppTeamPlayers.map((p) => p.totalMatchCardsWon).reduce(math.max) : (sorted.length > 1 ? sorted[1].totalMatchCardsWon : 0);

    setState(() {});

    _finishTimer?.cancel();
    _finishTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        String? customSubtitle;
        if (_vipTier != null) {
          customSubtitle = userWon
              ? '¡VICTORIA VIP EN MESA ${_vipTier!.name.toUpperCase()}!\nPremio obtenido: +$vipCoinsWon monedas (+$xpGained XP)'
              : 'Mesa ${_vipTier!.name}: Ganó ${winner.name} con ${winner.score} pts (+$xpGained XP)';
        }

        final matchSummary = CaidaMatchSummary(
          userWon: userWon,
          userTeamScore: userTeamScore,
          opponentTeamScore: oppTeamScore,
          userTeamCardsWon: userTeamCards,
          opponentTeamCardsWon: oppTeamCards,
          caidasCount: _matchUserCaidas,
          limpiasCount: _matchUserLimpias,
          cantosCount: _matchUserCantos,
          coinsWon: userWon ? vipCoinsWon : 0,
          xpWon: xpGained,
          chestAwarded: chestAwarded,
          chestSlotIndex: chestSlotIndex,
          didLevelUp: didLevelUp,
          initialLevel: initialLevel,
          finalLevel: finalLevel,
          customSubtitle: customSubtitle,
          isTeams: _isTeams,
        );

        CaidaGameOverModal.show(
          context,
          summary: matchSummary,
          onRematch: () {
            Navigator.pop(context);
            _initMatch(_playerCount, _isTeams, _players[0].name);
          },
          onBackToMenu: () {
            Navigator.pop(context);
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
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
                leading: const Icon(Icons.exit_to_app_rounded, color: Color(0xFFEF4444)),
                title: const Text('Salir al Menú Principal de CaidaGO', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const CaidaLobbyScreen()),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.feedback_rounded, color: Color(0xFFF59E0B)),
                title: const Text('Buzón de Sugerencias', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Comparte tus ideas o reportes con el equipo', style: TextStyle(color: Colors.white54, fontSize: 11)),
                trailing: const Icon(Icons.open_in_new_rounded, color: Colors.white54, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  FeedbackService.openFeedbackForm(context: context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded, color: Color(0xFFFBBF24)),
                title: const Text('Reglas de CaidaGO', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  GameRulesDialog.show(context, 'la_caida');
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_rounded, color: Color(0xFF38BDF8)),
                title: const Text('Política de Privacidad', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  PrivacyPolicyDialog.show(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.verified_user_rounded, color: Color(0xFF34D399)),
                title: const Text('Licencias y Software Libre', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  showLicensePage(
                    context: context,
                    applicationName: 'CaidaGO',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2026 CaidaGO • Desarrollado por Eizy Systems\nTodos los derechos reservados.',
                  );
                },
              ),
              const Divider(color: Colors.white12),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'CaidaGO v1.0.0\nDesarrollado por Eizy Systems • 2026\n© 2026 CaidaGO. Todos los derechos reservados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
        title: 'CaidaGO',
        onBack: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CaidaLobbyScreen()),
            );
          }
        },
        onOpenRules: () => GameRulesDialog.show(context, 'la_caida'),
        onSettings: _openMatchSettings,
        showTrophies: false,
        playerLevel: null,
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
                          'CAIDAGO',
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
            if (_vipTier != null)
              Positioned(
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_vipTier!.accentColor, const Color(0xFF0F172A)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _vipTier!.accentColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: _vipTier!.accentColor.withValues(alpha: 0.4),
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
                        'Mesa ${_vipTier!.name} • Pozo: ${_vipPrizePool ?? _vipTier!.calculatePrizePool(isTeams: _isTeams)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.monetization_on_rounded, color: Color(0xFFFBBF24), size: 12),
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

            // 8. Capa superior de naipes en vuelo y efectos de impacto
            CardFlightOverlay(
              activeTrajectories: _activeTrajectories,
              onAllCompleted: () {
                if (mounted) {
                  setState(() {
                    _activeTrajectories.clear();
                  });
                }
              },
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
            playerLevel: rival.isBot ? null : rival.level,
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
            playerLevel: rival1.isBot ? null : rival1.level,
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
            playerLevel: rival2.isBot ? null : rival2.level,
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
            playerLevel: rival1.isBot ? null : rival1.level,
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
            playerLevel: rival2.isBot ? null : rival2.level,
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
            playerLevel: rival3.isBot ? null : rival3.level,
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
        playerLevel: _userLevel,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '¡BIENVENIDOS A LA MESA DE CAÍDA!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '¡ELIGE UNA CARTA!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFDE047),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (_manoAnnouncement != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _manoAnnouncement!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
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
                                ? Container(
                                    decoration: cand.isWinner
                                        ? BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0xFFFDE047),
                                                blurRadius: 16,
                                                spreadRadius: 3,
                                              ),
                                            ],
                                          )
                                        : null,
                                    child: SpanishCardView(
                                      card: cand.card,
                                      width: 52,
                                      isSelected: cand.chosenByPlayerIndex == 0 || cand.isWinner,
                                    ),
                                  )
                                : const SpanishCardView.back(
                                    width: 52,
                                  ),
                            if (cand.isWinner)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFFFDE047), Color(0xFFF59E0B)]),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white, width: 1),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black45, blurRadius: 4),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.workspace_premium_rounded, color: Color(0xFF713F12), size: 10),
                                    SizedBox(width: 2),
                                    Text(
                                      '¡MANO!',
                                      style: TextStyle(
                                        color: Color(0xFF713F12),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (player != null)
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

  PlacedTableCard _computePlacementForCard(SpanishCard card) {
    _tableCardZCounter++;
    return PlacedTableCard.computePlacementForCard(
      card: card,
      currentPlacedCards: _placedTableCards,
      zCounter: _tableCardZCounter,
    );
  }

  void _syncPlacedCards() {
    // 1. Eliminar cartas capturadas que ya no están en mesa
    _placedTableCards.removeWhere((placed) => !_tableCards.contains(placed.card));

    // 2. Colocar nuevas cartas manteniendo estabilidad de las ya existentes
    for (final card in _tableCards) {
      final alreadyPlaced = _placedTableCards.any((p) => p.card == card);
      if (!alreadyPlaced) {
        _placedTableCards.add(_computePlacementForCard(card));
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

    final cardsToShow = _tableCards;

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Número cantado durante el Canto de Mesa (estampado en madera con sombra pura)
                    if (_isDealing && _isFirstRoundDealing && spokenNum != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isHit ? '¡$spokenNum!' : '$spokenNum',
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
                            if (isHit) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.star_rounded, color: Color(0xFFFDE047), size: 22),
                            ],
                          ],
                        ),
                      ),
                    SpanishCardView(
                      card: card,
                      width: 58,
                    ),
                  ],
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
