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
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTareas,
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
                      Text('Error al cargar tareas', style: theme.textTheme.titleLarge),
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
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFiltroChip('Todas', 'todas', colorScheme),
                            const SizedBox(width: 8),
                            _buildFiltroChip('Pendientes', 'pendiente', colorScheme),
                            const SizedBox(width: 8),
                            _buildFiltroChip('En Progreso', 'en_progreso', colorScheme),
                            const SizedBox(width: 8),
                            _buildFiltroChip('Completadas', 'completada', colorScheme),
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
                                  Icon(Icons.inbox_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(height: 16),
                                  Text('No tienes tareas', style: theme.textTheme.titleLarge),
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
                                padding: const EdgeInsets.all(16),
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
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroEstado = valor;
        });
      },
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
    final titulo = tarea['titulo']?.toString() ?? 'Sin título';
    final descripcion = tarea['descripcion']?.toString();
    final fechaVencimiento = tarea['fechaVencimiento'] != null
        ? DateTime.tryParse(tarea['fechaVencimiento'].toString())
        : null;
    final proyecto = tarea['proyecto'] as Map<String, dynamic>?;
    final tareaId = tarea['id'] ?? tarea['tarea_id'] ?? tarea['tareaId'];

    print('🔍 Tarea card: id=$tareaId, titulo=$titulo, keys=${tarea.keys.toList()}');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
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
          padding: const EdgeInsets.all(16),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(estado.toUpperCase()),
                    backgroundColor: _getEstadoColor(estado, colorScheme),
                    labelStyle: TextStyle(
                      color: _getEstadoTextColor(estado, colorScheme),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              if (descripcion != null && descripcion.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  descripcion,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Footer: Proyecto, prioridad y fecha
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (proyecto != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_outlined, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            proyecto['nombre']?.toString() ?? 'Proyecto',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
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
                              ? Icons.priority_high
                              : prioridad.toLowerCase() == 'media'
                                  ? Icons.remove
                                  : Icons.arrow_downward,
                          size: 16,
                          color: prioridad.toLowerCase() == 'alta'
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          prioridad,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  if (fechaVencimiento != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${fechaVencimiento.day}/${fechaVencimiento.month}/${fechaVencimiento.year}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
