import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/presentation/widgets/app_3d_button.dart';
import '../../economy/player_session.dart';

/// Modal para personalizar los nombres de los 3 bots (IA) rivales y compañeros en La Caída.
/// Permite escribir nombres personalizados, elegir de una lista de apodos criollos o generar al azar.
class BotCustomizationModal extends StatefulWidget {
  final PlayerSession? session;
  final List<String>? initialBotNames;
  final ValueChanged<List<String>>? onSaved;

  const BotCustomizationModal({
    super.key,
    this.session,
    this.initialBotNames,
    this.onSaved,
  });

  /// Muestra el modal de personalización de bots.
  static Future<List<String>?> show(
    BuildContext context, {
    PlayerSession? session,
    List<String>? initialBotNames,
    ValueChanged<List<String>>? onSaved,
  }) {
    return showDialog<List<String>>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (_) => BotCustomizationModal(
        session: session,
        initialBotNames: initialBotNames,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<BotCustomizationModal> createState() => _BotCustomizationModalState();
}

class _BotCustomizationModalState extends State<BotCustomizationModal> {
  late PlayerSession _session;
  late List<TextEditingController> _controllers;

  static const List<String> _presetsBot1 = [
    'Alejandro',
    'El Chamo',
    'Pancho',
    'El Brujo',
    'Tiburón',
    'El Catire',
    'El Llanero',
  ];

  static const List<String> _presetsBot2 = [
    'Carl',
    'La Catira',
    'Don José',
    'El Gocho',
    'La Doña',
    'El Tigre',
    'El Compadre',
  ];

  static const List<String> _presetsBot3 = [
    'Jhonny',
    'El Guaro',
    'El Chigüire',
    'El Socio',
    'Mano Tengo Fe',
    'El Maracucho',
    'El Capo',
  ];

  static const List<String> _allRandomPresets = [
    'Alejandro',
    'Carl',
    'Jhonny',
    'El Chamo',
    'La Catira',
    'Pancho',
    'Don José',
    'El Brujo',
    'Tiburón',
    'El Catire',
    'El Llanero',
    'El Gocho',
    'La Doña',
    'El Tigre',
    'El Compadre',
    'El Guaro',
    'El Chigüire',
    'El Socio',
    'Mano Tengo Fe',
    'El Maracucho',
    'El Capo',
    'El Cacique',
    'El Morocho',
    'Doña Rosa',
    'El Cuatro',
  ];

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? PlayerSession.shared;
    final currentNames = widget.initialBotNames ?? _session.botNames;
    _controllers = [
      TextEditingController(text: currentNames.isNotEmpty ? currentNames[0] : 'Alejandro'),
      TextEditingController(text: currentNames.length > 1 ? currentNames[1] : 'Carl'),
      TextEditingController(text: currentNames.length > 2 ? currentNames[2] : 'Jhonny'),
    ];
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _randomizeNames() {
    HapticFeedback.mediumImpact();
    final random = Random();
    final shuffled = List<String>.from(_allRandomPresets)..shuffle(random);
    setState(() {
      for (int i = 0; i < 3; i++) {
        _controllers[i].text = shuffled[i];
      }
    });
  }

  void _resetToDefault() {
    HapticFeedback.lightImpact();
    setState(() {
      _controllers[0].text = 'Alejandro';
      _controllers[1].text = 'Carl';
      _controllers[2].text = 'Jhonny';
    });
  }

  void _save() {
    HapticFeedback.mediumImpact();
    final newNames = [
      _controllers[0].text.trim().isNotEmpty ? _controllers[0].text.trim() : 'Alejandro',
      _controllers[1].text.trim().isNotEmpty ? _controllers[1].text.trim() : 'Carl',
      _controllers[2].text.trim().isNotEmpty ? _controllers[2].text.trim() : 'Jhonny',
    ];

    _session.updateBotNames(newNames);
    widget.onSaved?.call(newNames);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
              const SizedBox(width: 10),
              Text(
                'Bots guardados: ${newNames.join(", ")}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop(newNames);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1A1528),
                Color(0xFF0F172A),
                Color(0xFF0B0F19),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    children: [
                      // Bot 1 - Oeste
                      _buildBotCard(
                        botIndex: 0,
                        positionTitle: 'Bot 1 • Rival Oeste (Izquierda)',
                        positionSubtitle: 'Rival principal en 1v1 y partidas individuales',
                        accentColor: const Color(0xFFF43F5E),
                        avatarIndex: 1,
                        presets: _presetsBot1,
                      ),
                      const SizedBox(height: 14),

                      // Bot 2 - Norte
                      _buildBotCard(
                        botIndex: 1,
                        positionTitle: 'Bot 2 • Norte (Frente)',
                        positionSubtitle: 'Tu compañero en 2v2 o rival en partidas de 4',
                        accentColor: const Color(0xFF10B981),
                        avatarIndex: 14,
                        presets: _presetsBot2,
                      ),
                      const SizedBox(height: 14),

                      // Bot 3 - Este
                      _buildBotCard(
                        botIndex: 2,
                        positionTitle: 'Bot 3 • Rival Este (Derecha)',
                        positionSubtitle: 'Rival en partidas de 3 y 4 jugadores',
                        accentColor: const Color(0xFFA855F7),
                        avatarIndex: 5,
                        presets: _presetsBot3,
                      ),
                      const SizedBox(height: 16),

                      // Botón para aleatorizar apodos criollos
                      App3dButton.icon(
                        onPressed: _randomizeNames,
                        icon: Icons.casino_rounded,
                        iconColor: const Color(0xFFFDE68A),
                        iconSize: 18,
                        label: '🎲 Aleatorio Criollo',
                        variant: App3dButtonVariant.dark,
                        depth: 4,
                        borderRadius: 12,
                        textStyle: const TextStyle(
                          color: Color(0xFFFDE68A),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personalizar Bots (IA)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Nombres de tus rivales y compañeros',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildBotCard({
    required int botIndex,
    required String positionTitle,
    required String positionSubtitle,
    required Color accentColor,
    required int avatarIndex,
    required List<String> presets,
  }) {
    final controller = _controllers[botIndex];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del Bot
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 1.5),
                ),
                child: Center(
                  child: Icon(
                    Icons.smart_toy_rounded,
                    color: accentColor,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      positionTitle,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      positionSubtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Campo de texto editable
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLength: 14,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Nombre del bot',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      border: InputBorder.none,
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      controller.clear();
                      setState(() {});
                    },
                    child: const Icon(Icons.clear_rounded, color: Colors.white38, size: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Chips de sugerencias rápidas
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: presets.map((preset) {
              final isSelected = controller.text.trim().toLowerCase() == preset.toLowerCase();
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.text = preset;
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white12,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    preset,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Botón Restablecer
          Expanded(
            flex: 2,
            child: App3dButton(
              onPressed: _resetToDefault,
              variant: App3dButtonVariant.dark,
              depth: 4,
              borderRadius: 14,
              label: 'Restablecer',
              textStyle: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Botón Guardar Cambios
          Expanded(
            flex: 3,
            child: App3dButton(
              onPressed: _save,
              variant: App3dButtonVariant.cyan,
              depth: 5,
              borderRadius: 14,
              label: 'Guardar Cambios',
              textStyle: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
