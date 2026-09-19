import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'debug_logger.dart';

/// Servicio singleton para reproducción de efectos de sonido (SFX) y cantos tradicionales.
/// Utiliza BytesSource cargado en memoria desde rootBundle para evitar descargas en navegadores web.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  final Map<String, Uint8List> _audioCache = {};
  bool _isMuted = false;
  bool _isPreloading = false;

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

  /// Pre-carga todos los audios en memoria para reproducción instantánea sin descargas ni retardos.
  Future<void> preloadAudios() async {
    if (_isPreloading) return;
    _isPreloading = true;
    final soundPaths = [
      'assets/sfx/cantos/sfx_caida.mp3',
      'assets/sfx/cantos/sfx_mesa-limpia.mp3',
      'assets/sfx/cantos/sfx_patrulla.mp3',
      'assets/sfx/cantos/sfx_registro.mp3',
      'assets/sfx/cantos/sfx_ronda.mp3',
      'assets/sfx/cantos/sfx_vigia.mp3',
    ];

    for (final path in soundPaths) {
      try {
        if (!_audioCache.containsKey(path)) {
          final data = await rootBundle.load(path);
          _audioCache[path] = data.buffer.asUint8List();
        }
      } catch (e) {
        if (kDebugMode) {
          print('AudioService preload error for $path: $e');
        }
      }
    }
  }

  /// Reproduce el efecto de sonido según el nombre del canto o evento de juego.
  Future<void> playCanto(String name) async {
    if (_isMuted) return;

    final lower = name.toLowerCase();
    String? assetPath;

    if (lower.contains('ronda')) {
      assetPath = 'assets/sfx/cantos/sfx_ronda.mp3';
    } else if (lower.contains('patrulla')) {
      assetPath = 'assets/sfx/cantos/sfx_patrulla.mp3';
    } else if (lower.contains('vigi') || lower.contains('vigí')) {
      assetPath = 'assets/sfx/cantos/sfx_vigia.mp3';
    } else if (lower.contains('registro')) {
      assetPath = 'assets/sfx/cantos/sfx_registro.mp3';
    } else if (lower.contains('limpia')) {
      assetPath = 'assets/sfx/cantos/sfx_mesa-limpia.mp3';
    } else if (lower.contains('caida') || lower.contains('caída')) {
      assetPath = 'assets/sfx/cantos/sfx_caida.mp3';
    }

    if (assetPath != null) {
      try {
        Uint8List? bytes = _audioCache[assetPath];
        if (bytes == null) {
          final data = await rootBundle.load(assetPath);
          bytes = data.buffer.asUint8List();
          _audioCache[assetPath] = bytes;
        }

        await _player.stop();
        await _player.play(BytesSource(bytes));
        DebugLogger.instance.logAudio('SFX reproducido: $name');
      } catch (e) {
        DebugLogger.instance.log(
          'Error al reproducir audio ($assetPath): $e',
          category: 'Audio',
          level: LogLevel.warning,
        );
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
