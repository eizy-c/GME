import 'package:flutter/material.dart';

/// Modal festivo de graduación tras cantar Trivilín en la última lección del tutorial.
class TutorialCompletionDialog extends StatefulWidget {
  final VoidCallback onGoToLobby;

  const TutorialCompletionDialog({
    super.key,
    required this.onGoToLobby,
  });

  static Future<void> show(BuildContext context, {required VoidCallback onGoToLobby}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TutorialCompletionDialog(onGoToLobby: onGoToLobby),
    );
  }

  @override
  State<TutorialCompletionDialog> createState() => _TutorialCompletionDialogState();
}

class _TutorialCompletionDialogState extends State<TutorialCompletionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.bounceOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF59E0B), width: 2.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono animado de cofre del tesoro y monedas
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFDE047), Color(0xFFD97706)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.military_tech_rounded,
                    color: Color(0xFF78350F),
                    size: 56,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Plaqueta superior
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '¡GRADUADO DE CAIDAGO!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Título
              const Text(
                '¡Tutorial Completado con Trivilín!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFDE047),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),

              // Mensaje
              const Text(
                'Has dominado con maestría todas las mecánicas, arrastres, caídas y cantos tradicionales de CaidaGO.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),

              // Tarjeta de Recompensa
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (ctx, child) {
                  return Transform.scale(
                    scale: 0.9 + (0.1 * _bounceAnimation.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF065F46), Color(0xFF047857)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF34D399), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.monetization_on_rounded, color: Color(0xFFFDE047), size: 28),
                          SizedBox(width: 8),
                          Text(
                            '+1,000 Monedas',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              const Text(
                'Añadidas a tu saldo para mesas VIP y casuales',
                style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Créditos del desarrollador
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Desarrollada por: Eizy Systems (C)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Desarrollador: Yoangel Eizaga (Eizy-C en GitHub e Instagram)',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botón IR AL LOBBY
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF1E1B4B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                  ),
                  onPressed: widget.onGoToLobby,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'IR AL LOBBY',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
