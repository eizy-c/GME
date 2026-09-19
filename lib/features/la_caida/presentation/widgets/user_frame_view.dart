import 'package:flutter/material.dart';
import 'avatar_view.dart';

/// Definición de un marco cosmético para el avatar del usuario.
class UserFrameItem {
  final String id;
  final String name;
  final int minLevel;
  final List<Color> borderGradient;
  final Color shadowColor;
  final double borderWidth;
  final IconData? crownIcon;
  final String description;

  const UserFrameItem({
    required this.id,
    required this.name,
    required this.minLevel,
    required this.borderGradient,
    required this.shadowColor,
    this.borderWidth = 3.5,
    this.crownIcon,
    required this.description,
  });

  static const List<UserFrameItem> allFrames = [
    UserFrameItem(
      id: 'wood',
      name: 'Madera Clásica',
      minLevel: 0,
      borderGradient: [Color(0xFF854D0E), Color(0xFFD97706), Color(0xFF78350F)],
      shadowColor: Color(0xFF451A03),
      borderWidth: 3.5,
      description: 'Marco tradicional de madera caoba pulida.',
    ),
    UserFrameItem(
      id: 'silver',
      name: 'Plata Pulida',
      minLevel: 1,
      borderGradient: [Color(0xFFE2E8F0), Color(0xFF94A3B8), Color(0xFFF8FAFC)],
      shadowColor: Color(0xFF64748B),
      borderWidth: 4.0,
      description: 'Marco de plata brillante para aprendices destacados.',
    ),
    UserFrameItem(
      id: 'gold',
      name: 'Oro Imperial',
      minLevel: 3,
      borderGradient: [Color(0xFFFDE047), Color(0xFFEAB308), Color(0xFFCA8A04)],
      shadowColor: Color(0xFFCA8A04),
      borderWidth: 4.5,
      crownIcon: Icons.military_tech_rounded,
      description: 'Bisel forjado en oro puro con insignias reales.',
    ),
    UserFrameItem(
      id: 'neon',
      name: 'Neón Cian',
      minLevel: 5,
      borderGradient: [Color(0xFF38BDF8), Color(0xFF06B6D4), Color(0xFF0284C7)],
      shadowColor: Color(0xFF0284C7),
      borderWidth: 4.5,
      crownIcon: Icons.bolt_rounded,
      description: 'Resplandor futurista de energía electro-cian.',
    ),
    UserFrameItem(
      id: 'fire',
      name: 'Fuego Carmesí',
      minLevel: 7,
      borderGradient: [Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFB91C1C)],
      shadowColor: Color(0xFFDC2626),
      borderWidth: 4.8,
      crownIcon: Icons.local_fire_department_rounded,
      description: 'Llamas vivas para jugadores agresivos de Caída.',
    ),
    UserFrameItem(
      id: 'diamond',
      name: 'Diamante Mítico',
      minLevel: 10,
      borderGradient: [Color(0xFFA855F7), Color(0xFFEC4899), Color(0xFF60A5FA)],
      shadowColor: Color(0xFF9333EA),
      borderWidth: 5.0,
      crownIcon: Icons.auto_awesome_rounded,
      description: 'Marco prismático exclusivo para leyendas criollas.',
    ),
  ];

  static UserFrameItem getById(String id) {
    return allFrames.firstWhere((f) => f.id == id, orElse: () => allFrames.first);
  }
}

/// Widget visual para renderizar el Avatar del usuario contenido en su Marco seleccionado
/// e insignia de Nivel en forma de escudo.
class UserFrameView extends StatelessWidget {
  final int avatarIndex;
  final String frameId;
  final int level;
  final double size;
  final bool showLevelBadge;
  final VoidCallback? onTap;

  const UserFrameView({
    super.key,
    required this.avatarIndex,
    this.frameId = 'wood',
    this.level = 0,
    this.size = 64,
    this.showLevelBadge = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final frame = UserFrameItem.getById(frameId);
    final badgeSize = size * 0.38;

    Widget content = SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Resplandor / Sombra exterior del marco
          Container(
            width: size + 4,
            height: size + 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: frame.shadowColor.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // 2. Marco Ornamental con Gradiente
          Container(
            width: size + 4,
            height: size + 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: frame.borderGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.0,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(frame.borderWidth),
              child: ClipOval(
                child: AvatarView(
                  avatarId: avatarIndex,
                  size: size - (frame.borderWidth * 2),
                ),
              ),
            ),
          ),

          // 3. Ícono de Corona / Joya superior si tiene
          if (frame.crownIcon != null)
            Positioned(
              top: -6,
              child: Icon(
                frame.crownIcon,
                size: size * 0.32,
                color: const Color(0xFFFDE047),
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
            ),

          // 4. Insignia de Nivel en forma de escudo en la esquina superior derecha
          if (showLevelBadge)
            Positioned(
              top: -2,
              right: -2,
              child: _buildLevelShield(badgeSize),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }

  Widget _buildLevelShield(double badgeSize) {
    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFDE047), width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            color: const Color(0xFFFDE047),
            fontWeight: FontWeight.w900,
            fontSize: badgeSize * 0.52,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
