import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Servicio singleton para reproducción de efectos de sonido (SFX) y cantos tradicionales.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isMuted = false;

  bool get isMuted => _isMuted;
  set isMuted(bool val) {
    _isMuted = val;
    if (_isMuted) {
      _player.stop().catchError((_) {});
    }
  }

  void toggleMute() {
    isMuted = !isMuted;
  }

  /// Reproduce el efecto de sonido según el nombre del canto o evento de juego.
  Future<void> playCanto(String name) async {
    if (_isMuted) return;

    final lower = name.toLowerCase();
    String? assetSubpath;

    if (lower.contains('ronda')) {
      assetSubpath = 'sfx/cantos/sfx_ronda.mp3';
    } else if (lower.contains('patrulla')) {
      assetSubpath = 'sfx/cantos/sfx_patrulla.mp3';
    } else if (lower.contains('vigi') || lower.contains('vigí')) {
      assetSubpath = 'sfx/cantos/sfx_vigia.mp3';
    } else if (lower.contains('registro')) {
      assetSubpath = 'sfx/cantos/sfx_registro.mp3';
    } else if (lower.contains('limpia')) {
      assetSubpath = 'sfx/cantos/sfx_mesa-limpia.mp3';
    } else if (lower.contains('caida') || lower.contains('caída')) {
      assetSubpath = 'sfx/cantos/sfx_caida.mp3';
    }

    if (assetSubpath != null) {
      try {
        await _player.stop();
        await _player.play(AssetSource(assetSubpath), mode: PlayerMode.lowLatency);
      } catch (e) {
        if (kDebugMode) {
          print('AudioService info (ignorable en pruebas): $e');
        }
      }
    }
  }

  Future<void> playCaida() => playCanto('caida');
  Future<void> playMesaLimpia() => playCanto('limpia');
  Future<void> playRonda() => playCanto('ronda');
  Future<void> playPatrulla() => playCanto('patrulla');
  Future<void> playVigia() => playCanto('vigia');
  Future<void> playRegistro() => playCanto('registro');

  void dispose() {
    _player.dispose();
  }
}
