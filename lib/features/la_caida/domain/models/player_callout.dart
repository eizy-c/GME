import 'dart:async';

/// Representa un mensaje o canto emergente ("bocadillo de pensamiento/diálogo")
/// que nace de la estación o avatar de un jugador en la mesa.
class PlayerCallout {
  final String text;
  final Duration duration;
  Timer? timer;

  PlayerCallout({
    required this.text,
    this.duration = const Duration(milliseconds: 2200),
    this.timer,
  });

  void cancel() {
    timer?.cancel();
    timer = null;
  }
}
