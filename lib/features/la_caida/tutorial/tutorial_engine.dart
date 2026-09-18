import 'package:flutter/foundation.dart';
import '../../../../core/models/cards/spanish_card.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/user_profile_service.dart';
import '../economy/player_session.dart';
import 'tutorial_step.dart';

/// Motor controlador reactivo para el tour guiado de entrenamiento de La Caída.
class TutorialEngine extends ChangeNotifier {
  final List<TutorialStep> _steps = TutorialStep.officialSteps;
  int _currentStepIndex = 0;
  int _userScore = 0;
  int _botScore = 0;
  bool _showingFeedbackModal = false;
  bool _isCompleted = false;
  bool _rewardAwarded = false;

  late List<SpanishCard> _currentUserHand;
  late List<SpanishCard> _currentTableCards;

  TutorialEngine() {
    _loadStep(0);
  }

  // Getters
  List<TutorialStep> get steps => _steps;
  int get currentStepIndex => _currentStepIndex;
  TutorialStep get currentStep => _steps[_currentStepIndex];
  int get totalSteps => _steps.length;
  int get userScore => _userScore;
  int get botScore => _botScore;
  bool get showingFeedbackModal => _showingFeedbackModal;
  bool get isCompleted => _isCompleted;
  List<SpanishCard> get userHand => List.unmodifiable(_currentUserHand);
  List<SpanishCard> get tableCards => List.unmodifiable(_currentTableCards);

  void _loadStep(int index) {
    final step = _steps[index];
    _currentUserHand = List.from(step.playerCards);
    _currentTableCards = List.from(step.initialTableCards);
    _showingFeedbackModal = false;

    // En la etapa 4, el bot canta primero Ronda de 5 (+1 pt)
    if (step.stepNumber == 4) {
      _botScore += 1;
    }
  }

  /// Verifica si la carta seleccionada es la acción forzada del paso activo.
  bool canPlayCard(SpanishCard card) {
    if (currentStep.actionType != TutorialActionType.playCard) return false;
    final target = currentStep.targetCard;
    if (target == null) return false;
    return card.number == target.number && card.suit == target.suit;
  }

  /// Verifica si el canto activado es el correspondiente a la lección.
  bool canCallCanto(String cantoName) {
    if (currentStep.actionType != TutorialActionType.callCanto) return false;
    final target = currentStep.targetCantoName;
    if (target == null) return false;
    return target.toUpperCase().contains(cantoName.toUpperCase()) ||
        cantoName.toUpperCase().contains(target.toUpperCase());
  }

  /// Intenta jugar una carta. Retorna false si no es la carta forzada por la lección.
  bool playUserCard(SpanishCard card) {
    if (!canPlayCard(card)) return false;

    _currentUserHand.removeWhere((c) => c.number == card.number && c.suit == card.suit);

    if (currentStep.stepNumber == 1) {
      // Caída básica: levanta el 6
      _currentTableCards.clear();
      AudioService().playCaida();
    } else if (currentStep.stepNumber == 2) {
      // Arrastre: levanta 6, 7 y 10
      _currentTableCards.clear();
      AudioService().playCaida();
    } else if (currentStep.stepNumber == 3) {
      // Mesa Limpia: levanta el Caballo y deja la mesa vacía
      _currentTableCards.clear();
      AudioService().playCaida();
      Future.delayed(const Duration(milliseconds: 700), () {
        AudioService().playMesaLimpia();
      });
    }

    _userScore += currentStep.pointsAwarded;
    _showingFeedbackModal = true;
    notifyListeners();
    return true;
  }

  /// Activa un canto guiado. Retorna false si no coincide con la lección.
  bool callUserCanto(String cantoName) {
    if (!canCallCanto(cantoName)) return false;

    switch (currentStep.stepNumber) {
      case 4:
        AudioService().playRonda();
        break;
      case 5:
        AudioService().playPatrulla();
        break;
      case 6:
        AudioService().playVigia();
        break;
      case 7:
        AudioService().playRegistro();
        break;
      case 8:
        AudioService().playCanto('trivilin');
        break;
    }

    _userScore += currentStep.pointsAwarded;

    // Etapa 8: ¡Trivilín y Finalización!
    if (currentStep.isTrivilinFinale) {
      _isCompleted = true;
      if (!_rewardAwarded) {
        _rewardAwarded = true;
        PlayerSession.shared.completeTutorialReward(coinReward: 1000);
        UserProfileService().markNotFirstTime();
      }
    }

    _showingFeedbackModal = true;
    notifyListeners();
    return true;
  }

  /// Avanza a la siguiente lección tras cerrar el feedback explicativo.
  void advanceToNextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      _currentStepIndex++;
      _loadStep(_currentStepIndex);
    } else {
      _isCompleted = true;
      _showingFeedbackModal = false;
    }
    notifyListeners();
  }

  /// Cierra el modal de feedback sin avanzar aún si fuera necesario.
  void dismissFeedback() {
    _showingFeedbackModal = false;
    notifyListeners();
  }

  /// Reinicia el tour de entrenamiento desde la etapa 1.
  void reset() {
    _currentStepIndex = 0;
    _userScore = 0;
    _botScore = 0;
    _isCompleted = false;
    _loadStep(0);
    notifyListeners();
  }
}
