import 'package:flutter/material.dart';
import '../../../../core/models/cards/spanish_card.dart';
import '../../../../core/presentation/widgets/game_table_header.dart';
import '../../../../core/presentation/widgets/spanish_card_view.dart';
import '../../../../core/presentation/widgets/wood_table_background.dart';
import '../../../../core/services/audio_service.dart';
import '../tutorial_engine.dart';
import '../tutorial_step.dart';
import 'tutorial_completion_dialog.dart';
import 'tutorial_spotlight_overlay.dart';

/// Pantalla interactiva guiada para el Tour de Novatos (Tutorial Paso a Paso) de La Caída.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> with TickerProviderStateMixin {
  late final TutorialEngine _engine;
  final Map<String, GlobalKey> _cardKeys = {};
  final GlobalKey _cantoButtonKey = GlobalKey();
  Rect? _spotlightRect;
  late AnimationController _trivilinPulse;

  @override
  void initState() {
    super.initState();
    _engine = TutorialEngine();
    _engine.addListener(_onEngineChanged);

    _trivilinPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateSpotlightRect());
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineChanged);
    _engine.dispose();
    _trivilinPulse.dispose();
    super.dispose();
  }

  void _onEngineChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSpotlightRect();
      if (_engine.isCompleted && !_engine.showingFeedbackModal) {
        _showGraduationDialog();
      }
    });
  }

  void _updateSpotlightRect() {
    if (!mounted) return;

    Rect? newRect;
    final step = _engine.currentStep;

    if (step.actionType == TutorialActionType.playCard && step.targetCard != null) {
      final key = _getCardKey(step.targetCard!);
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        newRect = position & renderBox.size;
      }
    } else if (step.actionType == TutorialActionType.callCanto) {
      final renderBox = _cantoButtonKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        newRect = position & renderBox.size;
      }
    }

    if (newRect != _spotlightRect) {
      setState(() {
        _spotlightRect = newRect;
      });
    }
  }

  GlobalKey _getCardKey(SpanishCard card) {
    final id = '${card.number}_${card.suit.name}';
    return _cardKeys.putIfAbsent(id, () => GlobalKey());
  }

  void _showGraduationDialog() {
    TutorialCompletionDialog.show(
      context,
      onGoToLobby: () {
        Navigator.of(context).pop(); // Cierra el diálogo
        Navigator.of(context).pop(); // Sale del Tutorial al Lobby
      },
    );
  }

  void _onCardTapped(SpanishCard card) {
    if (_engine.showingFeedbackModal) return;

    final played = _engine.playUserCard(card);
    if (!played) {
      // Feedback táctil si intenta jugar una carta errónea
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Para esta lección, debes jugar el ${_engine.currentStep.targetCard?.displayName ?? "naipe indicado"}!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onCantoTapped(String cantoName) {
    if (_engine.showingFeedbackModal) return;
    _engine.callUserCanto(cantoName);
  }

  @override
  Widget build(BuildContext context) {
    final step = _engine.currentStep;

    return Scaffold(
      appBar: GameTableHeader(
        title: 'Entrenamiento: La Caída',
        onBack: () => Navigator.of(context).pop(),
        trophies: _engine.userScore,
        playerLevel: 1,
        isMuted: AudioService().isMuted,
        onToggleMute: () => setState(() => AudioService().toggleMute()),
      ),
      body: WoodTableBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Tablero principal de juego
              Column(
                children: [
                  // Marcador de puntos didáctico y barra de lección
                  _buildLessonProgressHeader(step),

                  // Área del Bot Rival
                  _buildBotRivalArea(step),

                  // Tapete central de cartas en mesa
                  Expanded(
                    child: Center(
                      child: _buildTableArea(),
                    ),
                  ),

                  // Botón de canto (si el paso actual lo requiere)
                  if (step.actionType == TutorialActionType.callCanto && !_engine.showingFeedbackModal)
                    _buildCantoActionArea(step),

                  // Mano del usuario (con keys para el foco)
                  _buildUserHandArea(),
                  const SizedBox(height: 12),
                ],
              ),

              // 2. Capa oscura Spotlight bloqueante
              if (!_engine.showingFeedbackModal && !_engine.isCompleted)
                TutorialSpotlightOverlay(
                  spotlightTarget: _spotlightRect,
                  title: step.title,
                  instruction: step.instruction,
                  currentStep: step.stepNumber,
                  totalSteps: _engine.totalSteps,
                  onSkip: () => Navigator.of(context).pop(),
                ),

              // 3. Modal / Banner de Feedback explicativo tras realizar la acción
              if (_engine.showingFeedbackModal)
                _buildFeedbackOverlay(step),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonProgressHeader(TutorialStep step) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
      ),
      child: Row(
        children: [
          // Píldora de paso
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${step.stepNumber}/8',
              style: const TextStyle(
                color: Color(0xFF1E1B4B),
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Título abreviado
          Expanded(
            child: Text(
              step.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          // Puntos acumulados en el tutorial
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF38BDF8), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFFDE047), size: 14),
                const SizedBox(width: 4),
                Text(
                  '${_engine.userScore} pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotRivalArea(TutorialStep step) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF475569),
            child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Rival de Entrenamiento',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              if (step.botCallout != null)
                Text(
                  step.botCallout!,
                  style: const TextStyle(
                    color: Color(0xFFFDE047),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                )
              else if (step.botCard != null)
                Text(
                  'Jugó: ${step.botCard!.displayName}',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                const Text(
                  'Esperando tu jugada...',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableArea() {
    final cards = _engine.tableCards;

    if (cards.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: const Text(
          'Mesa despejada',
          style: TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: cards.map((c) {
        return SpanishCardView(
          card: c,
          width: 72,
        );
      }).toList(),
    );
  }

  Widget _buildCantoActionArea(TutorialStep step) {
    final cantoName = step.targetCantoName ?? 'CANTAR';
    final isTrivilin = step.isTrivilinFinale;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: AnimatedBuilder(
          animation: _trivilinPulse,
          builder: (ctx, child) {
            final scale = isTrivilin ? 1.0 + (_trivilinPulse.value * 0.08) : 1.0;

            return Transform.scale(
              scale: scale,
              child: GestureDetector(
                key: _cantoButtonKey,
                onTap: () => _onCantoTapped(cantoName),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTrivilin ? 32 : 24,
                    vertical: isTrivilin ? 16 : 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isTrivilin
                          ? [const Color(0xFFF59E0B), const Color(0xFFDC2626), const Color(0xFF7C3AED)]
                          : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFDE68A),
                      width: isTrivilin ? 2.8 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isTrivilin ? const Color(0xFFF59E0B) : const Color(0xFFD97706))
                            .withValues(alpha: 0.6),
                        blurRadius: isTrivilin ? 22 : 12,
                        spreadRadius: isTrivilin ? 3 : 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTrivilin ? Icons.auto_awesome_rounded : Icons.campaign_rounded,
                        color: Colors.white,
                        size: isTrivilin ? 26 : 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        cantoName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: isTrivilin ? 20 : 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserHandArea() {
    final hand = _engine.userHand;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: hand.map((card) {
          final key = _getCardKey(card);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SpanishCardView(
              key: key,
              card: card,
              width: 78,
              onTap: () => _onCardTapped(card),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeedbackOverlay(TutorialStep step) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFF10B981), width: 2.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de acierto
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFF065F46),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF34D399), size: 38),
            ),
            const SizedBox(height: 14),

            // Título feedback
            Text(
              step.feedbackTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF34D399),
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),

            // Detalle de la regla
            Text(
              step.feedbackDetail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),

            // Botón Siguiente Lección
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: const Color(0xFF064E3B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  if (step.isTrivilinFinale) {
                    _engine.advanceToNextStep();
                    _showGraduationDialog();
                  } else {
                    _engine.advanceToNextStep();
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      step.isTrivilinFinale ? '¡GRADUARME!' : 'SIGUIENTE LECCIÓN',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
