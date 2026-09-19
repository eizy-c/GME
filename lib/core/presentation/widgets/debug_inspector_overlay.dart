import 'package:flutter/material.dart';
import '../../services/debug_logger.dart';
import 'debug_console_modal.dart';

/// Overlay global con botón flotante discreto y arrastrable para abrir la consola de bugs y diagnóstico.
class DebugInspectorOverlay extends StatefulWidget {
  final Widget child;

  const DebugInspectorOverlay({super.key, required this.child});

  @override
  State<DebugInspectorOverlay> createState() => _DebugInspectorOverlayState();
}

class _DebugInspectorOverlayState extends State<DebugInspectorOverlay> {
  Offset _position = const Offset(16, 120);
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final size = MediaQuery.of(context).size;
      // Posición inicial: esquina derecha a media altura
      _position = Offset(size.width - 54, size.height * 0.35);
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final logger = DebugLogger.instance;

    return Stack(
      children: [
        // La pantalla o widget principal
        widget.child,

        // Botón flotante discreto de bugs y diagnóstico
        Positioned(
          left: _position.dx.clamp(0.0, (media.size.width - 48).clamp(0.0, double.infinity)),
          top: _position.dy.clamp(media.padding.top, (media.size.height - media.padding.bottom - 48).clamp(0.0, double.infinity)),
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _position += details.delta;
              });
            },
            child: AnimatedBuilder(
              animation: logger,
              builder: (context, _) {
                final errorCount = logger.errorCount;
                final hasErrors = errorCount > 0;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => DebugConsoleModal.show(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(
                          color: hasErrors
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF38BDF8).withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: hasErrors
                                ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.bug_report_rounded,
                            size: 22,
                            color: hasErrors ? const Color(0xFFF87171) : const Color(0xFF7DD3FC),
                          ),
                          if (hasErrors)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                child: Text(
                                  '$errorCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
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
        ),
      ],
    );
  }
}
