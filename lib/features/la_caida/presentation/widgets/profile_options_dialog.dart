import 'package:flutter/material.dart';
import '../../../../core/services/user_profile_service.dart';
import '../../economy/player_session.dart';
import 'avatar_view.dart';

/// Modal para editar el perfil del jugador y seleccionar entre 20 avatares
/// en pestañas "Estilo A" y "Estilo B", inspirado en la captura de referencia.
class ProfileOptionsDialog extends StatefulWidget {
  const ProfileOptionsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ProfileOptionsDialog(),
    );
  }

  @override
  State<ProfileOptionsDialog> createState() => _ProfileOptionsDialogState();
}

class _ProfileOptionsDialogState extends State<ProfileOptionsDialog> {
  final _profileService = UserProfileService();
  late TextEditingController _nameController;
  late int _selectedAvatarId;
  bool _isStyleB = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _profileService.name);
    _selectedAvatarId = _profileService.avatarId;
    _isStyleB = _selectedAvatarId >= 10;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveAndClose() {
    final finalName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Jugador';
    _profileService.updateProfile(
      name: finalName,
      avatarId: _selectedAvatarId,
    );
    PlayerSession.shared.updateProfile(
      name: finalName,
      avatarIndex: _selectedAvatarId,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentPresets = AvatarPreset.allPresets.where((p) => p.isStyleB == _isStyleB).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera superior redondeada "Opciones del perfil"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Opciones del perfil',
                style: TextStyle(
                  color: Color(0xFF1E1B4B),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Contenedor principal con fondo azul celeste pastel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF67A4CA), // Azul cielo suave de la captura
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFBAE6FD), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Previsualización del Avatar Seleccionado con Lápiz
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      AvatarView(
                        avatarId: _selectedAvatarId,
                        size: 88,
                        showBorder: true,
                        isSelected: true,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Campo de texto editable para el nombre
                  Container(
                    width: 220,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                    ),
                    child: TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      maxLength: 14,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Tu nombre',
                        border: InputBorder.none,
                        counterText: '',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sub-contenedor con la cuadrícula de avatares
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF93C5FD), // Azul más claro para la bandeja
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white70, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Píldora "Seleccionar"
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Seleccionar',
                            style: TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Cuadrícula de 10 avatares (5 columnas x 2 filas por estilo)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: currentPresets.map((preset) {
                            final isSel = preset.id == _selectedAvatarId;
                            return AvatarView(
                              avatarId: preset.id,
                              size: 48,
                              isSelected: isSel,
                              onTap: () {
                                setState(() {
                                  _selectedAvatarId = preset.id;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        // Botones de acción: Estilo A | Estilo B | Ok
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildTabButton(
                              label: 'Estilo A',
                              isActive: !_isStyleB,
                              onTap: () => setState(() => _isStyleB = false),
                            ),
                            _buildTabButton(
                              label: 'Estilo B',
                              isActive: _isStyleB,
                              onTap: () => setState(() => _isStyleB = true),
                            ),
                            _buildOkButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : const Color(0xFF60A5FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF2563EB) : Colors.white60,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF1E3A8A) : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildOkButton() {
    return GestureDetector(
      onTap: _saveAndClose,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E), // Verde vibrante
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF15803D).withValues(alpha: 0.5),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Text(
          'Ok',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
