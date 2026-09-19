import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/spanish_card_view.dart';
import '../../domain/models/spatial_card_state.dart';

/// Capa superior transparente que proyecta naipes en vuelo cinemático con arcos 3D,
/// rotación dinámica, sombras proyectadas y destellos de impacto en Caídas.
class CardFlightOverlay extends StatefulWidget {
  final List<CardFlightTrajectory> activeTrajectories;
  final VoidCallback onAllCompleted;

  const CardFlightOverlay({
    super.key,
    required this.activeTrajectories,
    required this.onAllCompleted,
  });

  @override
  State<CardFlightOverlay> createState() => _CardFlightOverlayState();
}

class _CardFlightOverlayState extends State<CardFlightOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..addListener(() {
        if (mounted) setState(() {});
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          for (final trajectory in widget.activeTrajectories) {
            trajectory.onCompleted?.call();
          }
          widget.onAllCompleted();
        }
      });

    if (widget.activeTrajectories.isNotEmpty) {
      _startFlight();
    }
  }

  void _startFlight() {
    if (widget.activeTrajectories.isEmpty) return;
    final maxDuration = widget.activeTrajectories
        .map((t) => t.duration)
        .reduce((a, b) => a > b ? a : b);

    _controller.duration = maxDuration;
    _controller.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(covariant CardFlightOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeTrajectories != oldWidget.activeTrajectories &&
        widget.activeTrajectories.isNotEmpty) {
      _startFlight();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activeTrajectories.isEmpty) {
      return const SizedBox.shrink();
    }

    final progress = _controller.value;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: widget.activeTrajectories.map((trajectory) {
          final pos = trajectory.positionAt(progress);
          final rot = trajectory.rotationAt(progress);
          final scale = trajectory.scaleAt(progress);

          // Cálculo de elevación y sombra dinámica 3D
          final heightFactor = math.sin(progress * math.pi);
          final shadowBlur = 4.0 + (heightFactor * 14.0);
          final shadowSpread = heightFactor * 3.0;
          final shadowOffset = Offset(0, 3.0 + (heightFactor * 10.0));

          final isImpactMoment = trajectory.isCaidaImpact && progress >= 0.85;

          return Transform.translate(
            offset: pos,
            child: Transform.rotate(
              angle: rot,
              child: Transform.scale(
                scale: scale,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Sombra proyectada dinámica
                    Container(
                      width: 58,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: (0.35 + (heightFactor * 0.25)).clamp(0.0, 0.6),
                            ),
                            blurRadius: shadowBlur,
                            spreadRadius: shadowSpread,
                            offset: shadowOffset,
                          ),
                        ],
                      ),
                    ),

                    // Naipe en vuelo
                    trajectory.isFaceUp
                        ? SpanishCardView(
                            card: trajectory.card,
                            width: 58,
                          )
                        : const SpanishCardView.back(
                            width: 58,
                          ),

                    // Destello de impacto dorado al colisionar en Caída
                    if (isImpactMoment)
                      Positioned.fill(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 200),
                          builder: (context, flashVal, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFDE047).withValues(alpha: 1.0 - flashVal),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEAB308).withValues(
                                      alpha: (1.0 - flashVal) * 0.8,
                                    ),
                                    blurRadius: 18,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
