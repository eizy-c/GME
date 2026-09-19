import 'package:flutter/material.dart';

/// Paleta de colores oficial de CaidaGO y GME basada en la especificación de diseño:
/// - Cyan / Turquesa: #8BDCD7 (Acción principal, destacados vivos)
/// - Olive / Verde Salvia: #999966 (Acciones secundarias, tutoriales, equilibrio)
/// - Dark Slate / Charcoal: #232323 (Fondo profundo, contraste de texto oscuro, bases 3D)
/// - Sand / Pergamino Claro: #D5D4BC (Fondos claros, superficies neutras, textos contrastados)
class AppPalette {
  AppPalette._();

  /// #8BDCD7 - Turquesa / Cian Suave
  static const Color cyan = Color(0xFF8BDCD7);

  /// #999966 - Oliva / Verde Salvia
  static const Color olive = Color(0xFF999966);

  /// #232323 - Pizarra Oscura / Charcoal
  static const Color darkSlate = Color(0xFF232323);

  /// #D5D4BC - Arena / Pergamino Claro
  static const Color sand = Color(0xFFD5D4BC);

  // Variantes tradicionales de acento para modos y recompensas
  static const Color gold = Color(0xFFFBBF24);
  static const Color goldDark = Color(0xFFD97706);
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF047857);
  static const Color crimson = Color(0xFFEF4444);
  static const Color crimsonDark = Color(0xFFB91C1C);

  /// Genera una tonalidad más oscura para la base extruida 3D (:before en CSS).
  static Color get3dEdgeColor(Color baseColor, [double factor = 0.28]) {
    final hsl = HSLColor.fromColor(baseColor);
    final darkerLightness = (hsl.lightness - factor).clamp(0.0, 1.0);
    return hsl.withLightness(darkerLightness).toColor();
  }

  /// Genera una tonalidad más clara para el brillo superior / borde.
  static Color getHighlightColor(Color baseColor, [double factor = 0.15]) {
    final hsl = HSLColor.fromColor(baseColor);
    final lighterLightness = (hsl.lightness + factor).clamp(0.0, 1.0);
    return hsl.withLightness(lighterLightness).toColor();
  }
}
