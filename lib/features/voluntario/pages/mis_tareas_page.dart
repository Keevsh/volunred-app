import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/voluntario_repository.dart';

class MisTareasPage extends StatefulWidget {
  const MisTareasPage({super.key});

  @override
  State<MisTareasPage> createState() => _MisTareasPageState();
}

class _MisTareasPageState extends State<MisTareasPage> {
  final VoluntarioRepository _repository = Modular.get<VoluntarioRepository>();
  List<Map<String, dynamic>> _tareas = [];
  bool _isLoading = true;
  String? _error;
  String _filtroEstado = 'todas';

  @override
  void initState() {
    super.initState();
    _loadTareas();
  }

  Future<void> _loadTareas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔍 Cargando tareas del voluntario...');
      final tareas = await _repository.getMyTasks();
      print('✅ Tareas cargadas: ${tareas.length} tareas');
      if (tareas.isNotEmpty) {
        print('📋 Primera tarea: ${tareas.first}');
        print('📋 Keys de primera tarea: ${tareas.first.keys.toList()}');
      }
      setState(() {
        _tareas = tareas;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error cargando tareas: $e');
      print('❌ StackTrace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _tareasFiltradas {
    if (_filtroEstado == 'todas') return _tareas;
    return _tareas.where((t) {
      final estado = t['estado']?.toString().toLowerCase();
      if (_filtroEstado == 'en_progreso') {
        return estado == 'en_progreso' || estado == 'en progreso';
      }
      if (_filtroEstado == 'completada') {
        return estado == 'completada' || estado == 'completado';
      }
      return estado == _filtroEstado;
    }).toList();
  }

  Color _getEstadoColor(String estado, ColorScheme colorScheme) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return colorScheme.errorContainer;
      case 'en_progreso':
      case 'en progreso':
        return colorScheme.tertiaryContainer;
      case 'completada':
      case 'completado':
        return colorScheme.primaryContainer;
      default:
        return colorScheme.surfaceVariant;
    }
  }

  Color _getEstadoTextColor(String estado, ColorScheme colorScheme) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return colorScheme.onErrorContainer;
      case 'en_progreso':
      case 'en progreso':
        return colorScheme.onTertiaryContainer;
      case 'completada':
      case 'completado':
        return colorScheme.onPrimaryContainer;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Mis Tareas',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFF5F7FA),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1976D2)),
              onPressed: _loadTareas,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar tareas',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadTareas,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Filtros
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFiltroChip('Todas', 'todas', colorScheme),
                        const SizedBox(width: 10),
                        _buildFiltroChip(
                          'Pendientes',
                          'pendiente',
                          colorScheme,
                        ),
                        const SizedBox(width: 10),
                        _buildFiltroChip(
                          'En Progreso',
                          'en_progreso',
                          colorScheme,
                        ),
                        const SizedBox(width: 10),
                        _buildFiltroChip(
                          'Completadas',
                          'completada',
                          colorScheme,
                        ),
                      ],
                    ),
                  ),
                ),

                // Lista de tareas
                Expanded(
                  child: _tareasFiltradas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tienes tareas',
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _filtroEstado == 'todas'
                                    ? 'Aún no tienes tareas asignadas'
                                    : 'No tienes tareas $_filtroEstado',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTareas,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                            itemCount: _tareasFiltradas.length,
                            itemBuilder: (context, index) {
                              final tarea = _tareasFiltradas[index];
                              return _buildTareaCard(tarea, theme, colorScheme);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFiltroChip(String label, String valor, ColorScheme colorScheme) {
    final isSelected = _filtroEstado == valor;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroEstado = valor;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1976D2).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF616161),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTareaCard(
    Map<String, dynamic> tarea,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final estado = tarea['estado']?.toString() ?? 'pendiente';
    final prioridad = tarea['prioridad']?.toString();
    final titulo =
        tarea['titulo']?.toString() ??
        tarea['nombre']?.toString() ??
        'Sin título';
    final descripcion = tarea['descripcion']?.toString();
    final fechaVencimiento = tarea['fechaVencimiento'] != null
        ? DateTime.tryParse(tarea['fechaVencimiento'].toString())
        : null;

    // Soportar distintas formas de venir los datos del proyecto
    Map<String, dynamic>? proyecto;
    if (tarea['proyecto'] is Map) {
      proyecto = Map<String, dynamic>.from(tarea['proyecto'] as Map);
    } else if (tarea['tarea'] is Map &&
        (tarea['tarea'] as Map)['proyecto'] is Map) {
      final nested = (tarea['tarea'] as Map)['proyecto'] as Map;
      proyecto = Map<String, dynamic>.from(nested);
    }

    // Nombre del proyecto con varios fallbacks
    final nombreProyecto = proyecto != null
        ? (proyecto['nombre']?.toString() ??
              proyecto['titulo']?.toString() ??
              'Proyecto')
        : (tarea['proyecto_nombre']?.toString() ??
              tarea['nombre_proyecto']?.toString());
    final tareaId = tarea['id'] ?? tarea['tarea_id'] ?? tarea['tareaId'];

    print(
      '🔍 Tarea card: id=$tareaId, titulo=$titulo, keys=${tarea.keys.toList()}',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            print('👆 Click en tarea card: id=$tareaId');
            if (tareaId != null) {
              print('✅ Navegando a /voluntario/tareas/$tareaId');
              Modular.to.pushNamed('/voluntario/tareas/$tareaId');
            } else {
              print('❌ tareaId es null en card');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Error: ID de tarea no disponible'),
                  backgroundColor: colorScheme.error,
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Título y estado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(estado, colorScheme),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        estado.toUpperCase(),
                        style: TextStyle(
                          color: _getEstadoTextColor(estado, colorScheme),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                if (descripcion != null && descripcion.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 16),

                // Footer: Proyecto, prioridad y fecha
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      if (nombreProyecto != null && nombreProyecto.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.folder_rounded,
                              size: 16,
                              color: Color(0xFF1976D2),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                nombreProyecto,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1976D2),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (prioridad != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              prioridad.toLowerCase() == 'alta'
                                  ? Icons.flag_rounded
                                  : prioridad.toLowerCase() == 'media'
                                  ? Icons.flag_outlined
                                  : Icons.outlined_flag,
                              size: 16,
                              color: prioridad.toLowerCase() == 'alta'
                                  ? const Color(0xFFEF5350)
                                  : const Color(0xFF616161),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              prioridad,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      if (fechaVencimiento != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${fechaVencimiento.day}/${fechaVencimiento.month}/${fechaVencimiento.year}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
