import 'package:flutter/material.dart';

class MatchSetupConfig {
  final int playerCount; // 1, 2, 3, 4
  final bool isTeams; // Para 4 jugadores: parejas 2v2 o individual
  final String playerName;

  const MatchSetupConfig({
    this.playerCount = 2,
    this.isTeams = false,
    this.playerName = 'Tú',
  });
}

/// Diálogo interactivo de configuración y Lobby previo a la partida.
/// Permite elegir entre 1, 2, 3 o 4 jugadores, modalidad individual o por parejas,
/// y previsualizar los asientos ocupados en la mesa.
class MatchSetupDialog extends StatefulWidget {
  final String gameTitle;
  final int initialPlayerCount;
  final bool supportTeams;
  final ValueChanged<MatchSetupConfig> onStartMatch;

  const MatchSetupDialog({
    super.key,
    required this.gameTitle,
    this.initialPlayerCount = 2,
    this.supportTeams = true,
    required this.onStartMatch,
  });

  static Future<MatchSetupConfig?> show(
    BuildContext context, {
    required String gameTitle,
    int initialPlayerCount = 2,
    bool supportTeams = true,
  }) {
    return showDialog<MatchSetupConfig>(
      context: context,
      barrierDismissible: true,
      builder: (_) => MatchSetupDialog(
        gameTitle: gameTitle,
        initialPlayerCount: initialPlayerCount,
        supportTeams: supportTeams,
        onStartMatch: (config) => Navigator.pop(context, config),
      ),
    );
  }

  @override
  State<MatchSetupDialog> createState() => _MatchSetupDialogState();
}

class _MatchSetupDialogState extends State<MatchSetupDialog> {
  late int _selectedPlayers;
  late bool _isTeams;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _selectedPlayers = widget.initialPlayerCount.clamp(1, 4);
    _isTeams = false;
    _nameController = TextEditingController(text: 'Tú');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E1960), Color(0xFF160B33)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF7C4DFF), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera con icono y título
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C4DFF).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF9F75FF), width: 1),
                      ),
                      child: const Icon(Icons.groups_rounded, color: Color(0xFFFDE047), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CONFIGURAR SALA',
                          style: TextStyle(
                            color: Color(0xFFFDE047),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          widget.gameTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Selector de Jugadores (1, 2, 3, 4)
            const Text(
              'Número de Jugadores:',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [1, 2, 3, 4].map((count) {
                final isSelected = _selectedPlayers == count;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPlayers = count;
                          if (count != 4) _isTeams = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF1E143C),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2DD4BF) : const Color(0xFF4A347F),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF0D9488).withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              count == 1
                                  ? Icons.person_rounded
                                  : count == 2
                                      ? Icons.people_alt_rounded
                                      : count == 3
                                          ? Icons.diversity_3_rounded
                                          : Icons.groups_2_rounded,
                              color: isSelected ? Colors.white : Colors.white60,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$count Jug.',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // Si se eligen 4 jugadores, opción de Individual vs Parejas
            if (_selectedPlayers == 4 && widget.supportTeams) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E143C),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF4A347F)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.handshake_rounded, color: Color(0xFFFBBF24), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Modalidad:',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Individual', style: TextStyle(fontSize: 11)),
                          selected: !_isTeams,
                          onSelected: (val) => setState(() => _isTeams = !val),
                          selectedColor: const Color(0xFF0284C7),
                          backgroundColor: Colors.black26,
                          labelStyle: TextStyle(
                            color: !_isTeams ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('2 vs 2 (Parejas)', style: TextStyle(fontSize: 11)),
                          selected: _isTeams,
                          onSelected: (val) => setState(() => _isTeams = val),
                          selectedColor: const Color(0xFF10B981),
                          backgroundColor: Colors.black26,
                          labelStyle: TextStyle(
                            color: _isTeams ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Previsualización de asientos en mesa (Miniatura)
            _buildSeatsPreview(),

            const SizedBox(height: 20),

            // Botón Iniciar Partida
            ElevatedButton(
              onPressed: () {
                final name = _nameController.text.trim().isEmpty ? 'Tú' : _nameController.text.trim();
                widget.onStartMatch(
                  MatchSetupConfig(
                    playerCount: _selectedPlayers,
                    isTeams: _selectedPlayers == 4 && _isTeams,
                    playerName: name,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                shadowColor: const Color(0xFF16A34A).withValues(alpha: 0.6),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 24),
                  SizedBox(width: 8),
                  Text(
                    '¡INICIAR MESA DE JUEGO!',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatsPreview() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF261910), // Tono madera
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5A3D29), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centro de la mesa con logo sutil
          const Text(
            'MESA',
            style: TextStyle(
              color: Color(0xFF5A3D29),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),

          // Sur (Tú)
          Positioned(
            bottom: 6,
            child: _buildMiniSeat('Tú', isPlayer: true),
          ),

          // Norte (Rival 1 o Pareja)
          if (_selectedPlayers >= 2 && _selectedPlayers != 3)
            Positioned(
              top: 6,
              child: _buildMiniSeat(_isTeams ? 'Player 2 (Compañero)' : 'Player 1'),
            ),

          // Oeste (Rival en 3 y 4 jugadores)
          if (_selectedPlayers >= 3)
            Positioned(
              left: 12,
              child: _buildMiniSeat('Player 1'),
            ),

          // Este (Rival en 3 y 4 jugadores)
          if (_selectedPlayers >= 3)
            Positioned(
              right: 12,
              child: _buildMiniSeat(_selectedPlayers == 3 ? 'Player 2' : 'Player 3'),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniSeat(String label, {bool isPlayer = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPlayer ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPlayer ? const Color(0xFF38BDF8) : Colors.white24,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPlayer ? Icons.person_rounded : Icons.smart_toy_rounded,
            size: 11,
            color: isPlayer ? Colors.white : const Color(0xFF34D399),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
