import 'dart:async';
import 'package:flutter/foundation.dart';

/// Niveles de severidad de log
enum LogLevel {
  info('INFO', 'ℹ️'),
  game('JUEGO', '🃏'),
  audio('AUDIO', '🔊'),
  warning('ADVERTENCIA', '⚠️'),
  error('ERROR', '❌');

  final String label;
  final String icon;
  const LogLevel(this.label, this.icon);
}

/// Entrada individual en el registro de depuración
class DebugLogEntry {
  final int id;
  final DateTime timestamp;
  final LogLevel level;
  final String category;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? extraData;

  const DebugLogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.error,
    this.stackTrace,
    this.extraData,
  });

  String get timeFormatted {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  @override
  String toString() {
    final base = '[$timeFormatted] [${level.label}] [$category] $message';
    if (error != null) {
      return '$base\nDetalles: $error\n${stackTrace ?? ''}';
    }
    return base;
  }
}

/// Servicio centralizado de captura de errores, diagnósticos y logs del juego en vivo.
class DebugLogger extends ChangeNotifier {
  static final DebugLogger instance = DebugLogger._internal();
  factory DebugLogger() => instance;
  DebugLogger._internal();

  final List<DebugLogEntry> _logs = [];
  int _nextId = 1;
  static const int _maxLogs = 300;

  List<DebugLogEntry> get logs => List.unmodifiable(_logs);
  int get errorCount => _logs.where((e) => e.level == LogLevel.error).length;
  int get totalCount => _logs.length;

  /// Inicializa los interceptores globales de errores de Flutter y plataforma
  static void initialize() {
    final logger = DebugLogger.instance;

    // Capturar errores no controlados en widgets / layout
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      logger.logError(
        details.exceptionAsString(),
        details.stack,
        category: 'FlutterError',
        extraData: {
          'library': details.library ?? 'desconocida',
          'context': details.context?.toStringShort(),
        },
      );
      if (originalOnError != null) {
        originalOnError(details);
      }
    };

    // Capturar errores asíncronos en la zona raíz
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      logger.logError(error, stack, category: 'PlatformDispatcher');
      return true;
    };

    logger.log(
      'Sistema de diagnóstico y depuración inicializado correctamente.',
      category: 'Sistema',
      level: LogLevel.info,
    );
  }

  /// Registra un mensaje general
  void log(
    String message, {
    String category = 'General',
    LogLevel level = LogLevel.info,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extraData,
  }) {
    final entry = DebugLogEntry(
      id: _nextId++,
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      error: error,
      stackTrace: stackTrace,
      extraData: extraData,
    );

    _logs.insert(0, entry);
    if (_logs.length > _maxLogs) {
      _logs.removeLast();
    }
    notifyListeners();

    if (kDebugMode) {
      // ignore: avoid_print
      print('[DebugLogger] ${entry.level.icon} [${entry.category}] $message');
    }
  }

  /// Registra una acción de partida de La Caída
  void logGame(String message, {Map<String, dynamic>? extraData}) {
    log(message, category: 'Caída', level: LogLevel.game, extraData: extraData);
  }

  /// Registra un evento de audio
  void logAudio(String message) {
    log(message, category: 'Audio', level: LogLevel.audio);
  }

  /// Registra un error o excepción
  void logError(
    dynamic error, [
    StackTrace? stackTrace,
    {String category = 'Error',
    String? message,
    Map<String, dynamic>? extraData}
  ]) {
    log(
      message ?? (error?.toString() ?? 'Error sin descripción'),
      category: category,
      level: LogLevel.error,
      error: error,
      stackTrace: stackTrace ?? StackTrace.current,
      extraData: extraData,
    );
  }

  /// Limpia todo el historial de logs
  void clear() {
    _logs.clear();
    _nextId = 1;
    notifyListeners();
  }

  /// Exporta todos los registros en formato texto plano
  String exportLogsAsText() {
    final buffer = StringBuffer();
    buffer.writeln('=== REPORTE DE DIAGNÓSTICO Y ERRORES CAIDAGO ===');
    buffer.writeln('Generado: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total eventos: ${_logs.length} | Errores: $errorCount');
    buffer.writeln('==============================================\n');

    for (final entry in _logs.reversed) {
      buffer.writeln(entry.toString());
      if (entry.extraData != null && entry.extraData!.isNotEmpty) {
        buffer.writeln('  Meta: ${entry.extraData}');
      }
      buffer.writeln('----------------------------------------------');
    }
    return buffer.toString();
  }
}
