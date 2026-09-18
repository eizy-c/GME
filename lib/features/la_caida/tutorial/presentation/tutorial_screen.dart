import 'package:flutter/material.dart';
import '../../../../core/models/cards/spanish_card.dart';
import '../../../../core/presentation/widgets/game_table_header.dart';
import '../../../../core/presentation/widgets/spanish_card_view.dart';
import '../../../../core/presentation/widgets/table_player_badge.dart';
import '../../../../core/presentation/widgets/wood_table_background.dart';
import '../../../../core/services/audio_service.dart';
import '../../economy/player_session.dart';
import '../tutorial_engine.dart';
import '../tutorial_step.dart';
import 'tutorial_completion_dialog.dart';
import '../../presentation/widgets/deck_stack_view.dart';

/// Pantalla interactiva guiada para el Tour de Novatos (Tutorial Paso a Paso) de La Caída.
/// Diseñada para sentirse exactamente como una partida real, dinámica y fluida:
/// - Tapete de madera idéntico al de las partidas oficiales.
/// - Estación del bot rival arriba y estación del jugador abajo a la izquierda.
/// - Guía pedagógica flotante (El Maestro) sin oscurecer ni bloquear la mesa.
/// - Resaltado sutil en dorado y animación de flotación sobre la carta/canto objetivo.
/// - Diálogo de graduación con protección estricta contra duplicaciones de apertura y monedas.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> with TickerProviderStateMixin {
  late final TutorialEngine _engine;
  late AnimationController _targetPulse;
  late AnimationController _cantoPulse;

  String? _botCalloutMessage;
  String? _userCalloutMessage;
  String? _pointEventBanner;
  bool _hasShownGraduationDialog = false;

  @override
  void initState() {
    super.initState();
    _engine = TutorialEngine();
    _engine.addListener(_onEngineChanged);

    _targetPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _cantoPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    _syncStepState();
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineChanged);
    _engine.dispose();
    _targetPulse.dispose();
    _cantoPulse.dispose();
    super.dispose();
  }

  void _syncStepState() {
    final step = _engine.currentStep;
    setState(() {
      _botCalloutMessage = step.botCallout ??
          (step.botCard != null ? '¡Juego mi ${step.botCard!.displayName}!' : null);
      _userCalloutMessage = null;
      _pointEventBanner = null;
    });
  }

  void _onEngineChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _showGraduationDialog() {
    if (_hasShownGraduationDialog || !mounted) return;
    _hasShownGraduationDialog = true;

    TutorialCompletionDialog.show(
      context,
      onGoToLobby: () {
        Navigator.of(context).pop(); // Cierra el modal de graduación
        Navigator.of(context).pop(); // Retorna al Lobby
      },
    );
  }

  void _onCardTapped(SpanishCard card) {
    if (_engine.showingFeedbackModal) return;

    final step = _engine.currentStep;
    final isTarget = step.targetCard == card;

    if (!isTarget) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.touch_app_rounded, color: Color(0xFFFDE047), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '¡Para esta lección, toca la carta resaltada: ${step.targetCard?.displayName ?? "el naipe indicado"}!',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF1E1B4B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFF59E0B), width: 1.2),
          ),
        ),
      );
      return;
    }

    // Efectos según la etapa
    if (step.stepNumber == 1) {
      _pointEventBanner = '¡CAÍDA! +1 pt';
      _userCalloutMessage = '¡Caída!';
    } else if (step.stepNumber == 2) {
      _pointEventBanner = '¡ARRASTRE EN SEGUIDILLA! +3 cartas';
      _userCalloutMessage = '¡Arrastre!';
    } else if (step.stepNumber == 3) {
      _pointEventBanner = '¡MESA LIMPIA! +4 pts';
      _userCalloutMessage = '¡Mesa Limpia!';
    }

    _engine.playUserCard(card);
  }

  void _onCantoTapped(String cantoName) {
    if (_engine.showingFeedbackModal) return;

    final step = _engine.currentStep;

    if (step.stepNumber == 4) {
      _pointEventBanner = '¡RONDA DE REYES! +4 pts (Rival anulado)';
      _userCalloutMessage = '¡Ronda de Reyes!';
      _botCalloutMessage = '¡Me mataste el canto!';
    } else if (step.stepNumber == 5) {
      _pointEventBanner = '¡PATRULLA! +6 pts';
      _userCalloutMessage = '¡Patrulla!';
    } else if (step.stepNumber == 6) {
      _pointEventBanner = '¡VIGÍA! +7 pts';
      _userCalloutMessage = '¡Vigía!';
    } else if (step.stepNumber == 7) {
      _pointEventBanner = '¡REGISTRO! +8 pts';
      _userCalloutMessage = '¡Registro!';
    } else if (step.stepNumber == 8) {
      _pointEventBanner = '¡¡¡TRIVILÍN VICTORIA FULMINANTE!!!';
      _userCalloutMessage = '¡¡¡TRIVILÍN GANAMOS TODO!!!';
      _botCalloutMessage = '¡No puede ser, Knock-out!';
    }

    _engine.callUserCanto(cantoName);
  }

  void _onAdvanceStep() {
    final step = _engine.currentStep;
    if (step.isTrivilinFinale) {
      _showGraduationDialog();
    } else {
      _engine.advanceToNextStep();
      _syncStepState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _engine.currentStep;
    final session = PlayerSession.shared;

    return Scaffold(
      appBar: GameTableHeader(
        title: 'Tutorial: La Caída',
        onBack: () => Navigator.of(context).pop(),
        trophies: _engine.userScore,
        playerLevel: session.level,
        isMuted: AudioService().isMuted,
        onToggleMute: () => setState(() => AudioService().toggleMute()),
      ),
      body: WoodTableBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Mazo físico en la esquina superior izquierda
              const Positioned(
                left: 14,
                top: 12,
                child: DeckStackView(
                  remainingCards: 28,
                ),
              ),

              // 2. Estación del Bot Rival (Arriba al centro)
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: TablePlayerBadge(
                    name: 'Pedro (Rival)',
                    score: _engine.botScore,
                    cardsWon: 0,
                    isBot: true,
                    isCurrentTurn: false,
                    position: PlayerPositionOnTable.top,
                    avatarId: 1,
                    avatarColor: const Color(0xFFEF4444),
                    calloutMessage: _botCalloutMessage,
                    cardsInHandCount: 3,
                  ),
                ),
              ),

              // 3. Tarjeta flotante de Guía / El Maestro (Debajo del bot)
              Positioned(
                top: 92,
                left: 16,
                right: 16,
                child: _buildTeacherBar(step),
              ),

              // 4. Cartas sobre el tapete central de madera
              Positioned.fill(
                top: 180,
                bottom: 170,
                child: Center(
                  child: _buildTableCardsArea(),
                ),
              ),

              // 5. Banner animado de evento / jugada realizada
              if (_pointEventBanner != null)
                Positioned(
                  top: 200,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: _buildPointEventBanner(),
                  ),
                ),

              // 6. Estación del Usuario (Abajo a la izquierda)
              Positioned(
                left: 14,
                bottom: 12,
                child: TablePlayerBadge(
                  name: session.name,
                  score: _engine.userScore,
                  cardsWon: 0,
                  isBot: false,
                  isCurrentTurn: !_engine.showingFeedbackModal,
                  position: PlayerPositionOnTable.bottom,
                  avatarId: session.avatarIndex,
                  avatarColor: const Color(0xFF10B981),
                  calloutMessage: _userCalloutMessage,
                  cardsInHandCount: _engine.userHand.length,
                ),
              ),

              // 7. Botón de Canto destacado sobre la mano (si la etapa lo requiere)
              if (step.actionType == TutorialActionType.callCanto && !_engine.showingFeedbackModal)
                Positioned(
                  bottom: 135,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildCantoActionButton(step),
                  ),
                ),

              // 8. Mano interactiva de cartas del jugador (Abajo a la derecha)
              Positioned(
                right: 12,
                bottom: 10,
                child: _buildUserHandFan(step),
              ),

              // 9. Lámina explicativa fluida al completar la acción pedagógica
              if (_engine.showingFeedbackModal)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: _buildFeedbackExplanationSheet(step),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Barra de guía didáctica del Maestro de Caída (sin tapar la mesa)
  Widget _buildTeacherBar(TutorialStep step) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_rounded, color: Color(0xFF1E1B4B), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'LECCIÓN ${step.stepNumber} DE 8',
                      style: const TextStyle(
                        color: Color(0xFF1E1B4B),
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.title.replaceAll(RegExp(r'Etapa \d+: '), ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFDE68A),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Salir',
                    style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            step.instruction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  /// Tapete central con las cartas sobre la madera
  Widget _buildTableCardsArea() {
    final cards = _engine.tableCards;

    if (cards.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text(
          'Mesa despejada',
          style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
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
          width: 74,
        );
      }).toList(),
    );
  }

  /// Banner animado que anuncia jugadas clave (Caída, Mesa Limpia, Cantos)
  Widget _buildPointEventBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        _pointEventBanner!,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFFDE047),
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  /// Botón de canto resaltado y pulsante
  Widget _buildCantoActionButton(TutorialStep step) {
    final isTrivilin = step.isTrivilinFinale;
    final cantoName = step.targetCantoName ?? 'CANTAR';

    return AnimatedBuilder(
      animation: _cantoPulse,
      builder: (context, child) {
        final scale = 1.0 + (_cantoPulse.value * (isTrivilin ? 0.08 : 0.04));

        return Transform.scale(
          scale: scale,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isTrivilin ? 28 : 22,
                vertical: isTrivilin ? 14 : 11,
              ),
              backgroundColor: isTrivilin ? const Color(0xFFDC2626) : const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isTrivilin ? const Color(0xFFFDE047) : Colors.white,
                  width: 2.0,
                ),
              ),
              shadowColor: (isTrivilin ? const Color(0xFFDC2626) : const Color(0xFFF59E0B))
                  .withValues(alpha: 0.6),
            ),
            onPressed: () => _onCantoTapped(cantoName),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isTrivilin ? Icons.auto_awesome_rounded : Icons.campaign_rounded,
                  color: const Color(0xFFFDE047),
                  size: isTrivilin ? 22 : 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isTrivilin ? '¡TRIVILÍN! (KNOCK-OUT)' : 'CANTAR $cantoName (+${step.pointsAwarded} pts)',
                  style: TextStyle(
                    fontSize: isTrivilin ? 15 : 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Mano del usuario con efecto dorado y sutil elevación en la carta objetivo
  Widget _buildUserHandFan(TutorialStep step) {
    final hand = _engine.userHand;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: hand.map((card) {
        final isTarget = step.actionType == TutorialActionType.playCard && step.targetCard == card;

        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: AnimatedBuilder(
            animation: _targetPulse,
            builder: (context, child) {
              final lift = isTarget ? -10.0 - (4.0 * _targetPulse.value) : 0.0;

              return Transform.translate(
                offset: Offset(0, lift),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isTarget && !_engine.showingFeedbackModal)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 4),
                          ],
                        ),
                        child: const Text(
                          'TOCA AQUÍ 👆',
                          style: TextStyle(
                            color: Color(0xFF1E1B4B),
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    Container(
                      decoration: isTarget
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
                                  blurRadius: 14 + (6 * _targetPulse.value),
                                  spreadRadius: 2,
                                ),
                              ],
                            )
                          : null,
                      child: SpanishCardView(
                        card: card,
                        width: 78,
                        onTap: () => _onCardTapped(card),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  /// Tarjeta de explicación pedagógica y avance tras ejecutar la jugada
  Widget _buildFeedbackExplanationSheet(TutorialStep step) {
    final isLast = step.isTrivilinFinale;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLast ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLast ? const Color(0xFFF59E0B) : const Color(0xFF10B981))
                .withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isLast ? const Color(0xFF78350F) : const Color(0xFF065F46),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLast ? Icons.emoji_events_rounded : Icons.check_rounded,
                  color: isLast ? const Color(0xFFFDE047) : const Color(0xFF34D399),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step.feedbackTitle,
                  style: TextStyle(
                    color: isLast ? const Color(0xFFFDE047) : const Color(0xFF34D399),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            step.feedbackDetail,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                foregroundColor: isLast ? const Color(0xFF1E1B4B) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              onPressed: _onAdvanceStep,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLast ? '¡GRADUARME Y COBRAR RECOMPENSA! 🪙' : 'SIGUIENTE LECCIÓN',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
