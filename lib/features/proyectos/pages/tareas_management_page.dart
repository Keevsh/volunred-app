import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/models/tarea.dart';
import '../../../core/models/proyecto.dart';
import 'package:intl/intl.dart';

class TareasManagementPage extends StatefulWidget {
  final int proyectoId;

  const TareasManagementPage({super.key, required this.proyectoId});

  @override
  State<TareasManagementPage> createState() => _TareasManagementPageState();
}

class _TareasManagementPageState extends State<TareasManagementPage> {
  final FuncionarioRepository _repository =
      Modular.get<FuncionarioRepository>();

  List<Tarea> _tareas = [];
  Proyecto? _proyecto;
  bool _isLoading = true;
  String? _error;
  String _filtroEstado = 'todos';
  String? _filtroPrioridad;
  String _ordenarPor = 'fecha_creacion';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final proyecto = await _repository.getProyectoById(widget.proyectoId);
      final tareas = await _repository.getTareasByProyecto(widget.proyectoId);

      setState(() {
        _proyecto = proyecto;
        _tareas = tareas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Tarea> get _tareasFiltradas {
    var tareas = List<Tarea>.from(_tareas);

    // Filtrar por estado
    if (_filtroEstado != 'todos') {
      tareas = tareas.where((t) => t.estado == _filtroEstado).toList();
    }

    // Filtrar por prioridad
    if (_filtroPrioridad != null) {
      tareas = tareas.where((t) => t.prioridad == _filtroPrioridad).toList();
    }

    // Ordenar
    switch (_ordenarPor) {
      case 'nombre':
        tareas.sort((a, b) => a.nombre.compareTo(b.nombre));
        break;
      case 'prioridad':
        tareas.sort((a, b) {
          final prioridadOrder = {'alta': 0, 'media': 1, 'baja': 2};
          final prioA = prioridadOrder[a.prioridad?.toLowerCase()] ?? 3;
          final prioB = prioridadOrder[b.prioridad?.toLowerCase()] ?? 3;
          return prioA.compareTo(prioB);
        });
        break;
      case 'fecha_inicio':
        tareas.sort((a, b) {
          if (a.fechaInicio == null) return 1;
          if (b.fechaInicio == null) return -1;
          return a.fechaInicio!.compareTo(b.fechaInicio!);
        });
        break;
      case 'fecha_creacion':
      default:
        tareas.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
        break;
    }

    return tareas;
  }

  Color _getPrioridadColor(String? prioridad) {
    switch (prioridad?.toLowerCase()) {
      case 'alta':
        return const Color(0xFFF44336);
      case 'media':
        return const Color(0xFFFF9800);
      case 'baja':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return const Color(0xFFFF9800);
      case 'en_progreso':
        return const Color(0xFF2196F3);
      case 'completada':
        return const Color(0xFF4CAF50);
      case 'cancelada':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Color _getEstadoBgColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return const Color(0xFFFFF3E0);
      case 'en_progreso':
        return const Color(0xFFE3F2FD);
      case 'completada':
        return const Color(0xFFE8F5E9);
      case 'cancelada':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.schedule_rounded;
      case 'en_progreso':
        return Icons.pending_rounded;
      case 'completada':
        return Icons.check_circle_rounded;
      case 'cancelada':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Future<void> _showCreateEditDialog({Tarea? tarea}) async {
    final isEdit = tarea != null;
    final nombreController = TextEditingController(text: tarea?.nombre ?? '');
    final descripcionController = TextEditingController(
      text: tarea?.descripcion ?? '',
    );
    String? prioridad = tarea?.prioridad;
    String estado = tarea?.estado ?? 'pendiente';
    DateTime? fechaInicio = tarea?.fechaInicio;
    DateTime? fechaFin = tarea?.fechaFin;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Editar Tarea' : 'Nueva Tarea'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la tarea *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.task),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descripcionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Prioridad',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.flag),
                              ),
                              value: prioridad,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Alta',
                                  child: Text('🔴 Alta'),
                                ),
                                DropdownMenuItem(
                                  value: 'Media',
                                  child: Text('🟠 Media'),
                                ),
                                DropdownMenuItem(
                                  value: 'Baja',
                                  child: Text('🔵 Baja'),
                                ),
                              ],
                              onChanged: (value) {
                                setDialogState(() {
                                  prioridad = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Estado',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.info),
                              ),
                              value: estado,
                              items: const [
                                DropdownMenuItem(
                                  value: 'pendiente',
                                  child: Text('⚪ Pendiente'),
                                ),
                                DropdownMenuItem(
                                  value: 'en_progreso',
                                  child: Text('🔵 En Progreso'),
                                ),
                                DropdownMenuItem(
                                  value: 'completada',
                                  child: Text('🟢 Completada'),
                                ),
                                DropdownMenuItem(
                                  value: 'cancelada',
                                  child: Text('🔴 Cancelada'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    estado = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: fechaInicio ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setDialogState(() {
                                    fechaInicio = date;
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                fechaInicio != null
                                    ? DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(fechaInicio!)
                                    : 'Fecha Inicio',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      fechaFin ?? fechaInicio ?? DateTime.now(),
                                  firstDate: fechaInicio ?? DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setDialogState(() {
                                    fechaFin = date;
                                  });
                                }
                              },
                              icon: const Icon(Icons.event),
                              label: Text(
                                fechaFin != null
                                    ? DateFormat('dd/MM/yyyy').format(fechaFin!)
                                    : 'Fecha Fin',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    if (nombreController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('El nombre es requerido')),
                      );
                      return;
                    }

                    final data = <String, dynamic>{
                      'proyecto_id': widget.proyectoId,
                      'nombre': nombreController.text.trim(),
                      'descripcion': descripcionController.text.trim().isEmpty
                          ? null
                          : descripcionController.text.trim(),
                      'prioridad': prioridad?.toLowerCase(),
                      'estado': estado.toLowerCase(),
                    };

                    if (fechaInicio != null) {
                      data['fecha_inicio'] =
                          '${fechaInicio!.year}-${fechaInicio!.month.toString().padLeft(2, '0')}-${fechaInicio!.day.toString().padLeft(2, '0')}';
                    }
                    if (fechaFin != null) {
                      data['fecha_fin'] =
                          '${fechaFin!.year}-${fechaFin!.month.toString().padLeft(2, '0')}-${fechaFin!.day.toString().padLeft(2, '0')}';
                    }

                    try {
                      if (isEdit) {
                        await _repository.updateTarea(tarea.idTarea, data);
                      } else {
                        await _repository.createTarea(widget.proyectoId, data);
                      }
                      Navigator.of(dialogContext).pop(true);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  icon: Icon(isEdit ? Icons.save : Icons.add),
                  label: Text(isEdit ? 'Guardar' : 'Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteTarea(Tarea tarea) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text('¿Cancelar la tarea "${tarea.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.deleteTarea(tarea.idTarea);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Tarea cancelada')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestión de Tareas',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            if (_proyecto != null)
              Text(
                _proyecto!.nombre,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.view_column_rounded,
                color: Color(0xFF1976D2),
              ),
              onPressed: () {
                Modular.to.pushNamed(
                  '/proyectos/${widget.proyectoId}/tareas-kanban?role=funcionario',
                );
              },
              tooltip: 'Vista Kanban',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1976D2)),
              onPressed: _loadData,
              tooltip: 'Actualizar',
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEditDialog(),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text(
          'Nueva Tarea',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
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
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Barra de filtros y controles
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            color: Color(0xFF1976D2),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Filtros y Ordenamiento',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Filtro de estado con chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip(
                            'Todos',
                            'todos',
                            Icons.list_rounded,
                            null,
                          ),
                          _buildFilterChip(
                            'Pendiente',
                            'pendiente',
                            Icons.schedule_rounded,
                            const Color(0xFFFF9800),
                          ),
                          _buildFilterChip(
                            'En Progreso',
                            'en_progreso',
                            Icons.pending_rounded,
                            const Color(0xFF2196F3),
                          ),
                          _buildFilterChip(
                            'Completada',
                            'completada',
                            Icons.check_circle_rounded,
                            const Color(0xFF4CAF50),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Filtro de prioridad
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonFormField<String?>(
                                decoration: const InputDecoration(
                                  labelText: 'Prioridad',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.flag_rounded,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                                value: _filtroPrioridad,
                                items: const [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text('Todas'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'alta',
                                    child: Text('🔴 Alta'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'media',
                                    child: Text('🟠 Media'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'baja',
                                    child: Text('🟢 Baja'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _filtroPrioridad = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Ordenar por
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Ordenar por',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.sort_rounded,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                                value: _ordenarPor,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'fecha_creacion',
                                    child: Text('Fecha de creación'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'nombre',
                                    child: Text('Nombre'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'prioridad',
                                    child: Text('Prioridad'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'fecha_inicio',
                                    child: Text('Fecha de inicio'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _ordenarPor = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tabla de tareas
                Expanded(
                  child: _tareasFiltradas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.task_alt,
                                size: 80,
                                color: colorScheme.outlineVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay tareas',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Crea tu primera tarea para comenzar',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                colorScheme.surfaceContainerHighest,
                              ),
                              columns: const [
                                DataColumn(label: Text('Estado')),
                                DataColumn(label: Text('Nombre')),
                                DataColumn(label: Text('Prioridad')),
                                DataColumn(label: Text('Fecha Inicio')),
                                DataColumn(label: Text('Fecha Fin')),
                                DataColumn(label: Text('Creada')),
                                DataColumn(label: Text('Acciones')),
                              ],
                              rows: _tareasFiltradas.map((tarea) {
                                return DataRow(
                                  onSelectChanged: (_) {
                                    Modular.to.pushNamed(
                                      '/proyectos/tarea/${tarea.idTarea}?role=funcionario',
                                    );
                                  },
                                  cells: [
                                    // Estado
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getEstadoColor(
                                            tarea.estado,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _getEstadoColor(
                                              tarea.estado,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getEstadoIcon(tarea.estado),
                                              size: 16,
                                              color: _getEstadoColor(
                                                tarea.estado,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              tarea.estado,
                                              style: TextStyle(
                                                color: _getEstadoColor(
                                                  tarea.estado,
                                                ),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Nombre
                                    DataCell(
                                      SizedBox(
                                        width: 250,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              tarea.nombre,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (tarea.descripcion != null &&
                                                tarea.descripcion!.isNotEmpty)
                                              Text(
                                                tarea.descripcion!,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Prioridad
                                    DataCell(
                                      tarea.prioridad != null
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getPrioridadColor(
                                                  tarea.prioridad,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.flag,
                                                    size: 14,
                                                    color: _getPrioridadColor(
                                                      tarea.prioridad,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    tarea.prioridad!,
                                                    style: TextStyle(
                                                      color: _getPrioridadColor(
                                                        tarea.prioridad,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const Text('-'),
                                    ),
                                    // Fecha Inicio
                                    DataCell(
                                      Text(
                                        tarea.fechaInicio != null
                                            ? DateFormat(
                                                'dd/MM/yyyy',
                                              ).format(tarea.fechaInicio!)
                                            : '-',
                                      ),
                                    ),
                                    // Fecha Fin
                                    DataCell(
                                      Text(
                                        tarea.fechaFin != null
                                            ? DateFormat(
                                                'dd/MM/yyyy',
                                              ).format(tarea.fechaFin!)
                                            : '-',
                                      ),
                                    ),
                                    // Creada
                                    DataCell(
                                      Text(
                                        DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(tarea.creadoEn),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                    // Acciones
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _showCreateEditDialog(
                                                  tarea: tarea,
                                                ),
                                            tooltip: 'Editar',
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 20,
                                            ),
                                            color: Colors.red,
                                            onPressed: () =>
                                                _deleteTarea(tarea),
                                            tooltip: 'Cancelar',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),

                // Footer con estadísticas
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    border: Border(
                      top: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildStatChip(
                        'Total',
                        _tareas.length.toString(),
                        Icons.task_alt,
                        colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        'Pendientes',
                        _tareas
                            .where((t) => t.estado == 'pendiente')
                            .length
                            .toString(),
                        Icons.radio_button_unchecked,
                        Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        'En Progreso',
                        _tareas
                            .where((t) => t.estado == 'en_progreso')
                            .length
                            .toString(),
                        Icons.pending,
                        Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _buildStatChip(
                        'Completadas',
                        _tareas
                            .where((t) => t.estado == 'completada')
                            .length
                            .toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    IconData icon,
    Color? color,
  ) {
    final isSelected = _filtroEstado == value;
    final chipColor = color ?? const Color(0xFF1976D2);

    return Material(
      color: isSelected ? chipColor : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          setState(() {
            _filtroEstado = value;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? chipColor : const Color(0xFFE0E0E0),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : chipColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF424242),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
