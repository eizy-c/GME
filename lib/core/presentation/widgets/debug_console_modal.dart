import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/debug_logger.dart';
import '../../../features/la_caida/economy/player_session.dart';

/// Modal interactivo de consola de diagnóstico, visor de bugs y eventos del juego.
class DebugConsoleModal extends StatefulWidget {
  const DebugConsoleModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DebugConsoleModal(),
    );
  }

  @override
  State<DebugConsoleModal> createState() => _DebugConsoleModalState();
}

class _DebugConsoleModalState extends State<DebugConsoleModal> {
  String _selectedFilter = 'TODOS';
  final Set<int> _expandedLogIds = {};

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final logger = DebugLogger.instance;

    return AnimatedBuilder(
      animation: logger,
      builder: (context, _) {
        final allLogs = logger.logs;
        final filteredLogs = _applyFilter(allLogs);
        final errorCount = logger.errorCount;

        return Container(
          height: media.size.height * 0.88,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A), // Slate 900
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0xFF38BDF8), width: 2),
              left: BorderSide(color: Color(0xFF1E293B), width: 1),
              right: BorderSide(color: Color(0xFF1E293B), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black87,
                blurRadius: 30,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Barra de arrastre superior
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Cabecera con título, insignias y botón cerrar
              _buildHeader(context, allLogs.length, errorCount),

              // Panel de Diagnóstico Rápido de Sesión / Dispositivo
              _buildQuickDiagnostics(context),

              // Filtros de categoría
              _buildFilterChips(allLogs),

              const Divider(color: Colors.white12, height: 1),

              // Lista de logs
              Expanded(
                child: filteredLogs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final entry = filteredLogs[index];
                          final isExpanded = _expandedLogIds.contains(entry.id);
                          return _buildLogCard(entry, isExpanded);
                        },
                      ),
              ),

              // Barra de acciones inferior
              _buildBottomActions(context, logger),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int totalLogs, int errorCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: errorCount > 0
                  ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                  : const Color(0xFF0284C7).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: errorCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.bug_report_rounded,
              color: errorCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CONSOLA DE BUGS Y REGISTROS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '$totalLogs registros | $errorCount ${errorCount == 1 ? "error" : "errores"}',
                  style: TextStyle(
                    color: errorCount > 0 ? const Color(0xFFF87171) : Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Cerrar consola',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDiagnostics(BuildContext context) {
    final session = PlayerSession.shared;
    final media = MediaQuery.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _diagItem('👤 Jugador', session.name),
          _diagItem('⭐ Nivel', '${session.userProgress.level} (XP: ${session.userProgress.experience})'),
          _diagItem('🪙 Monedas', '${session.coins}'),
          _diagItem('🎫 Tickets', '${session.tickets}/10'),
          _diagItem('📱 Pantalla', '${media.size.width.toInt()}x${media.size.height.toInt()}'),
        ],
      ),
    );
  }

  Widget _diagItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF38BDF8),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(List<DebugLogEntry> logs) {
    final filters = [
      'TODOS',
      'ERRORES',
      'CAÍDA',
      'AUDIO',
      'SISTEMA',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          final count = _getFilterCount(logs, filter);

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text('$filter ($count)'),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              selectedColor: const Color(0xFF0284C7),
              backgroundColor: const Color(0xFF1E293B),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF38BDF8) : Colors.white12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  int _getFilterCount(List<DebugLogEntry> logs, String filter) {
    switch (filter) {
      case 'ERRORES':
        return logs.where((e) => e.level == LogLevel.error).length;
      case 'CAÍDA':
        return logs.where((e) => e.category.toLowerCase().contains('caída')).length;
      case 'AUDIO':
        return logs.where((e) => e.category.toLowerCase().contains('audio')).length;
      case 'SISTEMA':
        return logs.where((e) => e.category.toLowerCase().contains('sistema') || e.category.toLowerCase().contains('general')).length;
      default:
        return logs.length;
    }
  }

  List<DebugLogEntry> _applyFilter(List<DebugLogEntry> logs) {
    switch (_selectedFilter) {
      case 'ERRORES':
        return logs.where((e) => e.level == LogLevel.error).toList();
      case 'CAÍDA':
        return logs.where((e) => e.category.toLowerCase().contains('caída')).toList();
      case 'AUDIO':
        return logs.where((e) => e.category.toLowerCase().contains('audio')).toList();
      case 'SISTEMA':
        return logs.where((e) => e.category.toLowerCase().contains('sistema') || e.category.toLowerCase().contains('general')).toList();
      default:
        return logs;
    }
  }

  Widget _buildLogCard(DebugLogEntry entry, bool isExpanded) {
    final isError = entry.level == LogLevel.error;
    final isWarning = entry.level == LogLevel.warning;

    final borderColor = isError
        ? const Color(0xFFEF4444)
        : isWarning
            ? const Color(0xFFF59E0B)
            : Colors.white10;

    final bgColor = isError
        ? const Color(0xFF450A0A).withValues(alpha: 0.4)
        : const Color(0xFF1E293B);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isError ? 1.5 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedLogIds.remove(entry.id);
              } else {
                _expandedLogIds.add(entry.id);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.level.icon,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.category,
                        style: TextStyle(
                          color: isError ? const Color(0xFFFCA5A5) : const Color(0xFF38BDF8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.timeFormatted,
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                    const Spacer(),
                    if (entry.stackTrace != null || entry.extraData != null)
                      Icon(
                        isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: Colors.white54,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  entry.message,
                  style: TextStyle(
                    color: isError ? const Color(0xFFFECACA) : Colors.white,
                    fontSize: 12,
                    fontWeight: isError ? FontWeight.w600 : FontWeight.normal,
                    height: 1.3,
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 8),
                  if (entry.extraData != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SelectableText(
                        'Datos extra: ${entry.extraData}',
                        style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                  if (entry.stackTrace != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: SelectableText(
                        'Traza de pila:\n${entry.stackTrace}',
                        style: const TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 10,
                          fontFamily: 'monospace',
                          height: 1.3,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 48),
          SizedBox(height: 12),
          Text(
            'Sin registros en esta categoría',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'Todos los sistemas funcionando con normalidad',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, DebugLogger logger) {
    return Container(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      color: const Color(0xFF0B132B),
      child: Row(
        children: [
          // Botón: Copiar todo
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copiar Logs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final report = logger.exportLogsAsText();
                Clipboard.setData(ClipboardData(text: report));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📋 Reporte de logs copiado al portapapeles'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Color(0xFF0284C7),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),

          // Botón: Error de prueba
          OutlinedButton.icon(
            icon: const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFF59E0B)),
            label: const Text('Simular Error', style: TextStyle(fontSize: 11, color: Color(0xFFF59E0B))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFF59E0B)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              try {
                throw StateError('Simulación manual de error de prueba en CaidaGO');
              } catch (e, st) {
                logger.logError(e, st, category: 'Simulación', message: '¡Error de prueba provocado manualmente!');
              }
            },
          ),
          const SizedBox(width: 8),

          // Botón: Limpiar
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white60),
            tooltip: 'Limpiar historial',
            onPressed: () => logger.clear(),
          ),
        ],
      ),
    );
  }
}
