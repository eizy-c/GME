import 'package:flutter/material.dart';
import '../../economy/player_session.dart';
import '../../economy/user_progress.dart';
import 'avatar_view.dart';
import 'user_frame_view.dart';

/// Definición de paletas de fondo temáticas seleccionables por el usuario.
class LobbyThemeOption {
  final String id;
  final String name;
  final List<Color> backgroundGradient;
  final Color accentColor;
  final IconData icon;

  const LobbyThemeOption({
    required this.id,
    required this.name,
    required this.backgroundGradient,
    required this.accentColor,
    required this.icon,
  });

  static const List<LobbyThemeOption> allThemes = [
    LobbyThemeOption(
      id: 'royal_blue',
      name: 'Azul Royale',
      backgroundGradient: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
      accentColor: Color(0xFF38BDF8),
      icon: Icons.brightness_3_rounded,
    ),
    LobbyThemeOption(
      id: 'casino_green',
      name: 'Tapete Clásico',
      backgroundGradient: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF047857)],
      accentColor: Color(0xFF4ADE80),
      icon: Icons.table_restaurant_rounded,
    ),
    LobbyThemeOption(
      id: 'purple_night',
      name: 'Púrpura Imperial',
      backgroundGradient: [Color(0xFF2E1065), Color(0xFF4C1D95), Color(0xFF581C87)],
      accentColor: Color(0xFFC084FC),
      icon: Icons.auto_awesome_rounded,
    ),
    LobbyThemeOption(
      id: 'wood_classic',
      name: 'Madera Noble',
      backgroundGradient: [Color(0xFF29150B), Color(0xFF451A03), Color(0xFF78350F)],
      accentColor: Color(0xFFFDE047),
      icon: Icons.nature_rounded,
    ),
    LobbyThemeOption(
      id: 'crimson_gold',
      name: 'Carmesí Real',
      backgroundGradient: [Color(0xFF450A0A), Color(0xFF7F1D1D), Color(0xFF991B1B)],
      accentColor: Color(0xFFFBBF24),
      icon: Icons.shield_moon_rounded,
    ),
  ];

  static LobbyThemeOption getById(String id) {
    return allThemes.firstWhere((t) => t.id == id, orElse: () => allThemes.first);
  }
}

/// Modal integrado de Resumen de Nivel, Progreso de XP y Personalización completa
/// (Fondos de color/tema, Avatares, Marcos y Nombre de Usuario).
class ProfileAndLevelModal extends StatefulWidget {
  final PlayerSession session;
  final int initialTabIndex;

  const ProfileAndLevelModal({
    super.key,
    required this.session,
    this.initialTabIndex = 0,
  });

  static Future<void> show(BuildContext context, {required PlayerSession session, int initialTabIndex = 0}) {
    return showDialog(
      context: context,
      builder: (_) => ProfileAndLevelModal(
        session: session,
        initialTabIndex: initialTabIndex,
      ),
    );
  }

  @override
  State<ProfileAndLevelModal> createState() => _ProfileAndLevelModalState();
}

class _ProfileAndLevelModalState extends State<ProfileAndLevelModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;
  late int _tempAvatarIndex;
  late String _tempFrameId;
  late String _tempThemeId;
  bool _isAvatarStyleB = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTabIndex);
    _nameController = TextEditingController(text: widget.session.name);
    _tempAvatarIndex = widget.session.avatarIndex;
    _tempFrameId = widget.session.selectedFrameId;
    _tempThemeId = widget.session.selectedThemeId;
    _isAvatarStyleB = _tempAvatarIndex >= 10;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _saveCustomization() {
    final finalName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Eizy';
    widget.session.updateCustomization(
      name: finalName,
      avatarIndex: _tempAvatarIndex,
      frameId: _tempFrameId,
      themeId: _tempThemeId,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final progress = UserProgress(totalXp: widget.session.xp);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFCA8A04), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black87, blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              // 1. Cabecera superior con botón de cerrar
              _buildHeader(progress),

              // 2. Barra de Pestañas
              Container(
                color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFFDE047),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFFFDE047),
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  tabs: const [
                    Tab(icon: Icon(Icons.military_tech_rounded, size: 18), text: 'Nivel & XP'),
                    Tab(icon: Icon(Icons.filter_frames_rounded, size: 18), text: 'Marcos'),
                    Tab(icon: Icon(Icons.palette_rounded, size: 18), text: 'Fondos'),
                    Tab(icon: Icon(Icons.person_rounded, size: 18), text: 'Avatar'),
                  ],
                ),
              ),

              // 3. Contenido de las pestañas
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLevelTab(progress),
                    _buildFramesTab(progress),
                    _buildThemesTab(),
                    _buildAvatarTab(),
                  ],
                ),
              ),

              // 4. Botón inferior de Guardar / Listo
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _saveCustomization,
                    child: const Text(
                      'GUARDAR CAMBIOS',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserProgress progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      child: Row(
        children: [
          UserFrameView(
            avatarIndex: _tempAvatarIndex,
            frameId: _tempFrameId,
            level: progress.currentLevel,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isNotEmpty ? _nameController.text : 'Eizy',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Nivel ${progress.currentLevel} • ${progress.rankTitle}',
                  style: const TextStyle(
                    color: Color(0xFFFDE047),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // --- PESTAÑA 1: RESUMEN DE NIVEL & XP ---
  Widget _buildLevelTab(UserProgress progress) {
    final currentLevel = progress.currentLevel;
    final nextLevel = currentLevel + 1;
    final xpInTier = progress.currentTierXp;
    final neededInTier = progress.neededInCurrentTier;
    final percent = (progress.levelProgressPercentage * 100).toInt();
    final remaining = progress.xpRemainingToNextLevel;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta Principal de Progreso
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF6366F1), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NIVEL $currentLevel',
                      style: const TextStyle(
                        color: Color(0xFFFDE047),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Nivel $nextLevel',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Barra de progreso de XP
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.levelProgressPercentage,
                    minHeight: 14,
                    backgroundColor: const Color(0xFF0F172A),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$xpInTier / $neededInTier XP ($percent%)',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total: ${widget.session.xp} XP',
                      style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Banner de "¿Qué falta para subir?"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEAB308), width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Color(0xFFFDE047), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'Te faltan ',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      children: [
                        TextSpan(
                          text: '$remaining XP',
                          style: const TextStyle(color: Color(0xFFFDE047), fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: ' para alcanzar el Nivel $nextLevel.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Recompensas y Desbloqueos por Nivel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Lista de metas
          _buildMilestone(0, 'Nivel 0: Pichón', '10 Tickets de cortesía, Modo Normal, Marco Madera Rústica', currentLevel >= 0),
          _buildMilestone(1, 'Nivel 1: Caimanero', '+150 Monedas, Escuela de Novatos completada', currentLevel >= 1),
          _buildMilestone(2, 'Nivel 2: El Avillao', 'Desbloqueo de Marco Plata Pulida 🥈', currentLevel >= 2),
          _buildMilestone(3, 'Nivel 3: Arrastrador', '+250 Monedas, Desbloqueo Mesa VIP Bronce', currentLevel >= 3),
          _buildMilestone(4, 'Nivel 4: Gallo Fino', 'Desbloqueo de Marco Oro Imperial 🥇', currentLevel >= 4),
          _buildMilestone(5, 'Nivel 5: El Tigre', '+500 Monedas, Desbloqueo Mesa VIP Plata', currentLevel >= 5),
          _buildMilestone(6, 'Nivel 6: El Baquiano', 'Desbloqueo de Marco Neón Cibernético ⚡', currentLevel >= 6),
          _buildMilestone(7, 'Nivel 7: Pana Bravo', '+750 Monedas, Desbloqueo Mesa VIP Oro', currentLevel >= 7),
          _buildMilestone(8, 'Nivel 8: El Caballo', 'Desbloqueo de Marco Llama Ardiente 🔥', currentLevel >= 8),
          _buildMilestone(9, 'Nivel 9: El Papá de los Helados', '+1,000 Monedas de bonificación', currentLevel >= 9),
          _buildMilestone(10, 'Nivel 10: Cacique del Trivilín', 'Desbloqueo Marco Diamante Real 💎 y Mesa Diamante', currentLevel >= 10),
        ],
      ),
    );
  }

  Widget _buildMilestone(int lvl, String title, String reward, bool isUnlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFF1E293B) : const Color(0xFF0F172A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? const Color(0xFF22C55E) : Colors.white12,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isUnlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            color: isUnlocked ? const Color(0xFF22C55E) : Colors.white30,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isUnlocked ? Colors.white : Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  reward,
                  style: TextStyle(
                    color: isUnlocked ? const Color(0xFF93C5FD) : Colors.white30,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- PESTAÑA 2: MARCOS DE USUARIO ---
  Widget _buildFramesTab(UserProgress progress) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: UserFrameItem.allFrames.length,
      itemBuilder: (context, i) {
        final frame = UserFrameItem.allFrames[i];
        final isUnlocked = progress.currentLevel >= frame.minLevel;
        final isSelected = _tempFrameId == frame.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1E1B4B)
                : const Color(0xFF1E293B).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFFFDE047) : Colors.white12,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              UserFrameView(
                avatarIndex: _tempAvatarIndex,
                frameId: frame.id,
                level: progress.currentLevel,
                size: 46,
                showLevelBadge: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      frame.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      frame.description,
                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUnlocked ? 'Desbloqueado' : 'Requiere Nivel ${frame.minLevel}',
                      style: TextStyle(
                        color: isUnlocked ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? const Color(0xFF22C55E)
                      : (isUnlocked ? const Color(0xFF38BDF8) : Colors.white12),
                  foregroundColor: isSelected ? Colors.white : (isUnlocked ? const Color(0xFF0F172A) : Colors.white38),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isUnlocked
                    ? () {
                        setState(() {
                          _tempFrameId = frame.id;
                        });
                      }
                    : null,
                child: Text(
                  isSelected ? 'ACTIVO' : (isUnlocked ? 'EQUIPAR' : 'BLOQUEADO'),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- PESTAÑA 3: FONDOS / TEMAS DE COLOR ---
  Widget _buildThemesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: LobbyThemeOption.allThemes.length,
      itemBuilder: (context, i) {
        final theme = LobbyThemeOption.allThemes[i];
        final isSelected = _tempThemeId == theme.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFFFDE047) : Colors.white12,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Muestra visual del gradiente
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: theme.backgroundGradient),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white30, width: 1),
                ),
                child: Center(
                  child: Icon(theme.icon, color: theme.accentColor, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Fondo de interfaz y tapete para el Lobby',
                      style: TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? const Color(0xFF22C55E) : const Color(0xFF38BDF8),
                  foregroundColor: isSelected ? Colors.white : const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  setState(() {
                    _tempThemeId = theme.id;
                  });
                },
                child: Text(
                  isSelected ? 'APLICADO' : 'APLICAR',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- PESTAÑA 4: AVATAR & NOMBRE ---
  Widget _buildAvatarTab() {
    final currentPresets = AvatarPreset.allPresets.where((p) => p.isStyleB == _isAvatarStyleB).toList();

    return Column(
      children: [
        // Campo de edición de nombre
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _nameController,
            maxLength: 14,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Nombre de Jugador',
              labelStyle: const TextStyle(color: Color(0xFFFDE047)),
              prefixIcon: const Icon(Icons.edit, color: Color(0xFFFDE047), size: 18),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFFDE047), width: 1.5),
              ),
              counterStyle: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),

        // Selector Estilo A / Estilo B
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isAvatarStyleB = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isAvatarStyleB ? const Color(0xFF38BDF8) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Estilo A',
                      style: TextStyle(
                        color: !_isAvatarStyleB ? const Color(0xFF0F172A) : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isAvatarStyleB = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _isAvatarStyleB ? const Color(0xFF38BDF8) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Estilo B',
                      style: TextStyle(
                        color: _isAvatarStyleB ? const Color(0xFF0F172A) : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grid de Avatares
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: currentPresets.length,
            itemBuilder: (context, i) {
              final preset = currentPresets[i];
              final isSelected = _tempAvatarIndex == preset.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _tempAvatarIndex = preset.id;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFDE047) : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: ClipOval(
                    child: AvatarView(
                      avatarId: preset.id,
                      size: 46,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
