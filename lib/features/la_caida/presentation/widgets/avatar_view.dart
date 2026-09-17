import 'package:flutter/material.dart';

/// Definición de estilo y accesorios para cada uno de los 20 avatares disponibles.
class AvatarPreset {
  final int id;
  final Color bgColor;
  final Color skinColor;
  final Color hairColor;
  final Color shirtColor;
  final String hairType; // 'curly', 'short', 'medium', 'long', 'spiky', 'cowboy', 'bald'
  final bool hasGlasses;
  final bool hasMustache;
  final bool hasBeard;
  final bool hasBowtie;
  final bool isStyleB;

  const AvatarPreset({
    required this.id,
    required this.bgColor,
    required this.skinColor,
    required this.hairColor,
    required this.shirtColor,
    required this.hairType,
    this.hasGlasses = false,
    this.hasMustache = false,
    this.hasBeard = false,
    this.hasBowtie = false,
    required this.isStyleB,
  });

  static const List<AvatarPreset> allPresets = [
    // --- ESTILO A (0 a 9) ---
    AvatarPreset(
      id: 0,
      bgColor: Color(0xFF7C3AED), // Púrpura
      skinColor: Color(0xFFFFDBAC),
      hairColor: Color(0xFF1E293B),
      shirtColor: Color(0xFF93C5FD),
      hairType: 'short',
      isStyleB: false,
    ),
    AvatarPreset(
      id: 1,
      bgColor: Color(0xFFEA580C), // Naranja
      skinColor: Color(0xFFFFE0BD),
      hairColor: Color(0xFF292524),
      shirtColor: Color(0xFF15803D),
      hairType: 'medium',
      hasMustache: true,
      hasBowtie: true,
      isStyleB: false,
    ),
    AvatarPreset(
      id: 2, // Avatar principal "Eizy"
      bgColor: Color(0xFF0D9488), // Turquesa
      skinColor: Color(0xFF8D5524), // Moreno
      hairColor: Color(0xFF0F172A),
      shirtColor: Colors.white,
      hairType: 'curly',
      hasGlasses: true,
      isStyleB: false,
    ),
    AvatarPreset(
      id: 3,
      bgColor: Color(0xFF16A34A), // Verde
      skinColor: Color(0xFFFFDBAC),
      hairColor: Color(0xFF78350F),
      shirtColor: Color(0xFF475569),
      hairType: 'short',
      hasBeard: true,
      isStyleB: false,
    ),
    AvatarPreset(
      id: 4,
      bgColor: Color(0xFF475569), // Gris
      skinColor: Color(0xFF5A3825), // Afro
      hairColor: Color(0xFF18181B),
      shirtColor: Color(0xFF0F172A),
      hairType: 'short',
      hasBeard: true,
      isStyleB: false,
    ),
    AvatarPreset(
      id: 5,
      bgColor: Color(0xFF3B82F6), // Azul
      skinColor: Color(0xFF8D5524),
      hairColor: Color(0xFF18181B),
      shirtColor: Color(0xFFCBD5E1),
      hairType: 'curly',
      hasGlasses: true,
      isStyleB: false,
    ),
    AvatarPreset(
      id: 6,
      bgColor: Color(0xFF0284C7), // Cian
      skinColor: Color(0xFFFFDBAC),
      hairColor: Color(0xFF451A03),
      shirtColor: Color(0xFF334155),
      hairType: 'short',
      hasGlasses: true,
      hasBeard: true,
      isStyleB: false,
    ),
    AvatarPreset(
      id: 7,
      bgColor: Color(0xFF64748B), // Pizarra
      skinColor: Color(0xFFFFDBAC),
      hairColor: Color(0xFF92400E),
      shirtColor: Color(0xFF475569),
      hairType: 'spiky',
      isStyleB: false,
    ),
    AvatarPreset(
      id: 8,
      bgColor: Color(0xFF047857), // Esmeralda
      skinColor: Color(0xFFFFE0BD),
      hairColor: Color(0xFF292524),
      shirtColor: Color(0xFF334155),
      hairType: 'medium',
      hasGlasses: true,
      hasBeard: true,
      isStyleB: false,
    ),
    AvatarPreset(
      id: 9,
      bgColor: Color(0xFF4338CA), // Índigo
      skinColor: Color(0xFF704214),
      hairColor: Color(0xFF18181B),
      shirtColor: Color(0xFF1E293B),
      hairType: 'curly',
      isStyleB: false,
    ),

    // --- ESTILO B (10 a 19) ---
    AvatarPreset(
      id: 10,
      bgColor: Color(0xFF0284C7), // Sombrero vaquero
      skinColor: Color(0xFFC68642),
      hairColor: Color(0xFF1E293B),
      shirtColor: Colors.white,
      hairType: 'cowboy',
      isStyleB: true,
    ),
    AvatarPreset(
      id: 11,
      bgColor: Color(0xFF059669),
      skinColor: Color(0xFF8D5524),
      hairColor: Color(0xFF18181B),
      shirtColor: Color(0xFF334155),
      hairType: 'short',
      hasBeard: true,
      isStyleB: true,
    ),
    AvatarPreset(
      id: 12,
      bgColor: Color(0xFFD97706),
      skinColor: Color(0xFFFFDBAC),
      hairColor: Color(0xFF18181B),
      shirtColor: Color(0xFF94A3B8),
      hairType: 'curly',
      hasBeard: true,
      isStyleB: true,
    ),
    AvatarPreset(
      id: 13,
      bgColor: Color(0xFF0284C7),
      skinColor: Color(0xFFFFE0BD),
      hairColor: Color(0xFF451A03),
      shirtColor: Color(0xFF475569),
      hairType: 'spiky',
      hasBeard: true,
      isStyleB: true,
    ),
    AvatarPreset(
      id: 14,
      bgColor: Color(0xFF4B5563),
      skinColor: Color(0xFFFFDBAC),
      hairColor: Color(0xFF1E293B),
      shirtColor: Color(0xFF94A3B8),
      hairType: 'long',
      isStyleB: true,
    ),
    AvatarPreset(
      id: 15,
      bgColor: Color(0xFF78350F),
      skinColor: Color(0xFFFFDBAC),
      hairColor: Color(0xFF292524),
      shirtColor: Color(0xFF334155),
      hairType: 'short',
      hasGlasses: true,
      isStyleB: true,
    ),
    AvatarPreset(
      id: 16,
      bgColor: Color(0xFF0F766E),
      skinColor: Color(0xFFFFDBAC),
      hairColor: Color(0xFF18181B),
      shirtColor: Color(0xFF94A3B8),
      hairType: 'short',
      hasBeard: true,
      isStyleB: true,
    ),
    AvatarPreset(
      id: 17,
      bgColor: Color(0xFF15803D),
      skinColor: Color(0xFF5A3825),
      hairColor: Color(0xFF18181B),
      shirtColor: Color(0xFF1E293B),
      hairType: 'short',
      hasBeard: true,
      isStyleB: true,
    ),
    AvatarPreset(
      id: 18,
      bgColor: Color(0xFF0369A1),
      skinColor: Color(0xFFFFDBAC),
      hairColor: Color(0xFF292524),
      shirtColor: Color(0xFF475569),
      hairType: 'short',
      hasBeard: true,
      isStyleB: true,
    ),
    AvatarPreset(
      id: 19,
      bgColor: Color(0xFFB45309),
      skinColor: Color(0xFFFFE0BD),
      hairColor: Color(0xFF18181B),
      shirtColor: Color(0xFF1E293B),
      hairType: 'medium',
      hasMustache: true,
      isStyleB: true,
    ),
  ];

  static AvatarPreset getById(int id) {
    return allPresets.firstWhere(
      (p) => p.id == id,
      orElse: () => allPresets[2],
    );
  }
}

/// Widget ilustrado para renderizar cualquier avatar seleccionado.
class AvatarView extends StatelessWidget {
  final int avatarId;
  final double size;
  final bool showBorder;
  final bool isSelected;
  final VoidCallback? onTap;

  const AvatarView({
    super.key,
    required this.avatarId,
    this.size = 54,
    this.showBorder = true,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preset = AvatarPreset.getById(avatarId);

    Widget avatarContent = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: preset.bgColor,
        borderRadius: BorderRadius.circular(size * 0.18),
        border: showBorder
            ? Border.all(
                color: isSelected ? const Color(0xFFFDE047) : Colors.white.withValues(alpha: 0.9),
                width: isSelected ? 2.5 : 1.5,
              )
            : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFFEAB308).withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.18 - 1),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Cuerpo / Camisa (abajo)
            Positioned(
              bottom: 0,
              child: Container(
                width: size * 0.72,
                height: size * 0.38,
                decoration: BoxDecoration(
                  color: preset.shirtColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(size * 0.25)),
                ),
              ),
            ),

            // Cuello
            Positioned(
              bottom: size * 0.28,
              child: Container(
                width: size * 0.22,
                height: size * 0.16,
                color: preset.skinColor.withValues(alpha: 0.9),
              ),
            ),

            // Pajarita (si tiene)
            if (preset.hasBowtie)
              Positioned(
                bottom: size * 0.26,
                child: Icon(Icons.change_history_rounded, size: size * 0.16, color: Colors.amber),
              ),

            // 2. Cabeza / Rostro
            Positioned(
              top: size * 0.22,
              child: Container(
                width: size * 0.44,
                height: size * 0.50,
                decoration: BoxDecoration(
                  color: preset.skinColor,
                  borderRadius: BorderRadius.circular(size * 0.22),
                ),
              ),
            ),

            // Cabello
            _buildHair(preset),

            // Barba o Bigote
            if (preset.hasBeard)
              Positioned(
                bottom: size * 0.28,
                child: Container(
                  width: size * 0.32,
                  height: size * 0.22,
                  decoration: BoxDecoration(
                    color: preset.hairColor,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(size * 0.16)),
                  ),
                ),
              ),
            if (preset.hasMustache)
              Positioned(
                bottom: size * 0.38,
                child: Container(
                  width: size * 0.24,
                  height: size * 0.08,
                  decoration: BoxDecoration(
                    color: preset.hairColor,
                    borderRadius: BorderRadius.circular(size * 0.04),
                  ),
                ),
              ),

            // Ojos
            Positioned(
              top: size * 0.44,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: size * 0.06,
                    height: size * 0.06,
                    decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
                  ),
                  SizedBox(width: size * 0.14),
                  Container(
                    width: size * 0.06,
                    height: size * 0.06,
                    decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
                  ),
                ],
              ),
            ),

            // Lentes (si tiene)
            if (preset.hasGlasses)
              Positioned(
                top: size * 0.38,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: size * 0.15,
                      height: size * 0.15,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF18181B), width: 1.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(width: size * 0.06, height: 1.5, color: const Color(0xFF18181B)),
                    Container(
                      width: size * 0.15,
                      height: size * 0.15,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF18181B), width: 1.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),

            // Sombrero Vaquero (si tiene)
            if (preset.hairType == 'cowboy')
              Positioned(
                top: size * 0.08,
                child: Container(
                  width: size * 0.72,
                  height: size * 0.26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE68A), // Paja clara
                    borderRadius: BorderRadius.circular(size * 0.08),
                    border: Border.all(color: const Color(0xFFD97706), width: 1),
                  ),
                  child: Center(
                    child: Container(
                      width: size * 0.38,
                      height: size * 0.18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(size * 0.04),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatarContent);
    }
    return avatarContent;
  }

  Widget _buildHair(AvatarPreset preset) {
    if (preset.hairType == 'cowboy') {
      return const SizedBox.shrink();
    }

    switch (preset.hairType) {
      case 'curly':
        return Positioned(
          top: size * 0.12,
          child: Container(
            width: size * 0.48,
            height: size * 0.26,
            decoration: BoxDecoration(
              color: preset.hairColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(size * 0.24)),
            ),
          ),
        );
      case 'spiky':
        return Positioned(
          top: size * 0.10,
          child: Container(
            width: size * 0.46,
            height: size * 0.24,
            decoration: BoxDecoration(
              color: preset.hairColor,
              borderRadius: BorderRadius.circular(size * 0.08),
            ),
          ),
        );
      case 'long':
        return Positioned(
          top: size * 0.14,
          child: Container(
            width: size * 0.52,
            height: size * 0.46,
            decoration: BoxDecoration(
              color: preset.hairColor,
              borderRadius: BorderRadius.circular(size * 0.14),
            ),
          ),
        );
      default:
        return Positioned(
          top: size * 0.14,
          child: Container(
            width: size * 0.46,
            height: size * 0.22,
            decoration: BoxDecoration(
              color: preset.hairColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(size * 0.22)),
            ),
          ),
        );
    }
  }
}
