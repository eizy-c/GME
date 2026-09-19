import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_palette.dart';

/// Variantes de color predefinidas para los botones 3D basados en la paleta oficial y modos de juego.
enum App3dButtonVariant {
  cyan, // #8BDCD7 (Acción principal)
  olive, // #999966 (Acciones secundarias)
  dark, // #232323 (Charcoal / Contraste)
  sand, // #D5D4BC (Pergamino Claro)
  gold, // Dorado / Ámbar (JUGAR, VIP, Premios)
  emerald, // Verde Esmeralda (Tutorial, Éxito)
  crimson, // Rojo Carmesí (Abandonar, Peligro)
  custom, // Colores personalizados pasados por parámetro
}

/// Botón 3D táctil animado inspirado fielmente en las mecánicas de `.btn-177`:
/// - Cara superior redondeada con contraste nítido.
/// - Base lateral extruida 3D inferior (`:before`) con tono oscurecido.
/// - Sombra difusa inferior (`:after`) que da sensación de elevación física.
/// - Animación de presión física en el eje Y (`translateY: +depth`) con curva suave y respuesta háptica.
class App3dButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? label;
  final IconData? icon;
  final double? iconSize;
  final App3dButtonVariant variant;
  final Color? backgroundColor;
  final Color? edgeColor;
  final Color? textColor;
  final Color? iconColor;
  final double depth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final TextStyle? textStyle;
  final bool expand;
  final bool enableHaptics;

  const App3dButton({
    super.key,
    required this.onPressed,
    this.child,
    this.label,
    this.icon,
    this.iconSize,
    this.variant = App3dButtonVariant.cyan,
    this.backgroundColor,
    this.edgeColor,
    this.textColor,
    this.iconColor,
    this.depth = 5.0,
    this.borderRadius = 14.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.width,
    this.height,
    this.textStyle,
    this.expand = false,
    this.enableHaptics = true,
  }) : assert(child != null || label != null, 'Debe especificarse child o label');

  /// Constructor alternativo con Icono y Texto
  factory App3dButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    App3dButtonVariant variant = App3dButtonVariant.cyan,
    Color? backgroundColor,
    Color? edgeColor,
    Color? textColor,
    Color? iconColor,
    double? iconSize,
    double depth = 5.0,
    double borderRadius = 14.0,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    double? width,
    double? height,
    TextStyle? textStyle,
    bool expand = false,
    bool enableHaptics = true,
  }) {
    return App3dButton(
      key: key,
      onPressed: onPressed,
      label: label,
      icon: icon,
      iconSize: iconSize,
      variant: variant,
      backgroundColor: backgroundColor,
      edgeColor: edgeColor,
      textColor: textColor,
      iconColor: iconColor,
      depth: depth,
      borderRadius: borderRadius,
      padding: padding,
      width: width,
      height: height,
      textStyle: textStyle,
      expand: expand,
      enableHaptics: enableHaptics,
    );
  }

  @override
  State<App3dButton> createState() => _App3dButtonState();
}

class _App3dButtonState extends State<App3dButton> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null;

  Color get _resolvedBgColor {
    if (!_isEnabled) return const Color(0xFFDCDCDC);
    if (widget.backgroundColor != null) return widget.backgroundColor!;

    switch (widget.variant) {
      case App3dButtonVariant.cyan:
        return AppPalette.cyan;
      case App3dButtonVariant.olive:
        return AppPalette.olive;
      case App3dButtonVariant.dark:
        return AppPalette.darkSlate;
      case App3dButtonVariant.sand:
        return AppPalette.sand;
      case App3dButtonVariant.gold:
        return const Color(0xFFFBBF24);
      case App3dButtonVariant.emerald:
        return const Color(0xFF10B981);
      case App3dButtonVariant.crimson:
        return const Color(0xFFEF4444);
      case App3dButtonVariant.custom:
        return AppPalette.cyan;
    }
  }

  Color get _resolvedEdgeColor {
    if (!_isEnabled) return Colors.transparent;
    if (widget.edgeColor != null) return widget.edgeColor!;

    switch (widget.variant) {
      case App3dButtonVariant.cyan:
        return AppPalette.get3dEdgeColor(AppPalette.cyan, 0.22);
      case App3dButtonVariant.olive:
        return AppPalette.get3dEdgeColor(AppPalette.olive, 0.25);
      case App3dButtonVariant.dark:
        return const Color(0xFF0F0F0F);
      case App3dButtonVariant.sand:
        return AppPalette.get3dEdgeColor(AppPalette.sand, 0.22);
      case App3dButtonVariant.gold:
        return const Color(0xFFB45309);
      case App3dButtonVariant.emerald:
        return const Color(0xFF047857);
      case App3dButtonVariant.crimson:
        return const Color(0xFFB91C1C);
      case App3dButtonVariant.custom:
        return AppPalette.get3dEdgeColor(_resolvedBgColor);
    }
  }

  Color get _resolvedTextColor {
    if (!_isEnabled) return const Color(0xFF7E7E7E);
    if (widget.textColor != null) return widget.textColor!;

    switch (widget.variant) {
      case App3dButtonVariant.cyan:
        return const Color(0xFF0F172A);
      case App3dButtonVariant.olive:
        return Colors.white;
      case App3dButtonVariant.dark:
        return Colors.white;
      case App3dButtonVariant.sand:
        return const Color(0xFF1E1E1E);
      case App3dButtonVariant.gold:
        return const Color(0xFF1E1B4B);
      case App3dButtonVariant.emerald:
        return Colors.white;
      case App3dButtonVariant.crimson:
        return Colors.white;
      case App3dButtonVariant.custom:
        return Colors.white;
    }
  }

  void _handleTapDown(TapDownDetails _) {
    if (!_isEnabled) return;
    setState(() => _isPressed = true);
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (!_isEnabled) return;
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (!_isEnabled) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDepth = _isEnabled ? widget.depth : 0.0;
    final currentTranslation = (_isPressed && _isEnabled) ? effectiveDepth : 0.0;
    final r = Radius.circular(widget.borderRadius);

    Widget content;
    if (widget.child != null) {
      content = widget.child!;
    } else {
      final style = widget.textStyle ??
          TextStyle(
            color: _resolvedTextColor,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 0.5,
          );

      if (widget.icon != null) {
        content = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: widget.iconSize ?? 18,
              color: widget.iconColor ?? _resolvedTextColor,
            ),
            const SizedBox(width: 8),
            Text(widget.label!, style: style),
          ],
        );
      } else {
        content = Text(widget.label!, style: style, textAlign: TextAlign.center);
      }
    }

    final buttonCore = SizedBox(
      width: widget.expand ? double.infinity : widget.width,
      height: widget.height != null ? (widget.height! + effectiveDepth) : null,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // 1. Sombra Difusa Inferior (:after en CSS)
            if (_isEnabled)
              Positioned(
                top: _isPressed ? (effectiveDepth + 2) : (effectiveDepth + 4),
                left: 2,
                right: 2,
                bottom: _isPressed ? 0 : 0,
                child: Container(
                  height: widget.height ?? 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: _isPressed ? 0.15 : 0.32),
                        blurRadius: _isPressed ? 3 : 8,
                        offset: Offset(0, _isPressed ? 2 : 4),
                      ),
                    ],
                  ),
                ),
              ),

            // 2. Base Extruida 3D (:before en CSS)
            if (_isEnabled)
              Positioned(
                top: effectiveDepth,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: widget.height,
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: _resolvedEdgeColor,
                    borderRadius: BorderRadius.all(r),
                  ),
                ),
              ),

            // 3. Cara Superior Interactiva con Desplazamiento Y
            AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.only(
                top: currentTranslation,
                bottom: effectiveDepth - currentTranslation,
              ),
              width: widget.expand ? double.infinity : widget.width,
              height: widget.height,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: _resolvedBgColor,
                borderRadius: BorderRadius.all(r),
                border: _isEnabled
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.2,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: content,
            ),
          ],
        ),
      ),
    );

    return buttonCore;
  }
}
