import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'debug_logger.dart';

/// Servicio centralizado para gestionar el acceso al formulario oficial de sugerencias y comentarios.
class FeedbackService {
  FeedbackService._();

  /// Enlace oficial de Google Forms para recopilar sugerencias, ideas y reportes de los jugadores.
  static const String feedbackFormUrl = 'https://forms.gle/YDJAVHHS3rsA6o4w8';

  /// Abre el formulario de sugerencias en el navegador predeterminado del sistema o aplicación externa.
  static Future<bool> openFeedbackForm({BuildContext? context}) async {
    final uri = Uri.parse(feedbackFormUrl);
    try {
      DebugLogger.instance.log(
        'Abriendo formulario de sugerencias: $feedbackFormUrl',
        category: 'Sistema',
      );

      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }

      if (!launched && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir el navegador automáticamente.\nIngresa a: $feedbackFormUrl',
            ),
            backgroundColor: Color(0xFFE11D48),
            duration: Duration(seconds: 4),
          ),
        );
      }

      return launched;
    } catch (e) {
      DebugLogger.instance.log(
        'Error abriendo formulario de sugerencias ($e)',
        category: 'Sistema',
        level: LogLevel.warning,
      );
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error al abrir enlace. Ingresa directamente a: $feedbackFormUrl',
            ),
            backgroundColor: Color(0xFFE11D48),
            duration: Duration(seconds: 4),
          ),
        );
      }
      return false;
    }
  }
}
