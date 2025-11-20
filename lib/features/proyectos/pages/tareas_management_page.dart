import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/models/tarea.dart';
import '../../../core/models/proyecto.dart';
import 'package:intl/intl.dart';

class TareasManagementPage extends StatefulWidget {
  final int proyectoId;

  const TareasManagementPage({
    super.key,
    required this.proyectoId,
  });

  @override
  State<TareasManagementPage> createState() => _TareasManagementPageState();
}

class _TareasManagementPageState extends State<TareasManagementPage> {
  final FuncionarioRepository _repository = Modular.get<FuncionarioRepository>();
  
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
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.grey;
      case 'en_progreso':
        return Colors.blue;
      case 'completada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.radio_button_unchecked;
      case 'en_progreso':
        return Icons.pending;
      case 'completada':
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _showCreateEditDialog({Tarea? tarea}) async {
    final isEdit = tarea != null;
    final nombreController = TextEditingController(text: tarea?.nombre ?? '');
    final descripcionController = TextEditingController(text: tarea?.descripcion ?? '');
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
                                DropdownMenuItem(value: 'Alta', child: Text('🔴 Alta')),
                                DropdownMenuItem(value: 'Media', child: Text('🟠 Media')),
                                DropdownMenuItem(value: 'Baja', child: Text('🔵 Baja')),
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
                                DropdownMenuItem(value: 'pendiente', child: Text('⚪ Pendiente')),
                                DropdownMenuItem(value: 'en_progreso', child: Text('🔵 En Progreso')),
                                DropdownMenuItem(value: 'completada', child: Text('🟢 Completada')),
                                DropdownMenuItem(value: 'cancelada', child: Text('🔴 Cancelada')),
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
                                    ? DateFormat('dd/MM/yyyy').format(fechaInicio!)
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
                                  initialDate: fechaFin ?? fechaInicio ?? DateTime.now(),
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
                      data['fecha_inicio'] = '${fechaInicio!.year}-${fechaInicio!.month.toString().padLeft(2, '0')}-${fechaInicio!.day.toString().padLeft(2, '0')}';
                    }
                    if (fechaFin != null) {
                      data['fecha_fin'] = '${fechaFin!.year}-${fechaFin!.month.toString().padLeft(2, '0')}-${fechaFin!.day.toString().padLeft(2, '0')}';
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tarea cancelada')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gestión de Tareas'),
            if (_proyecto != null)
              Text(
                _proyecto!.nombre,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Tarea'),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Filtro de estado
                              Expanded(
                                child: SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(
                                      value: 'todos',
                                      label: Text('Todos'),
                                      icon: Icon(Icons.list, size: 16),
                                    ),
                                    ButtonSegment(
                                      value: 'pendiente',
                                      label: Text('Pendiente'),
                                      icon: Icon(Icons.radio_button_unchecked, size: 16),
                                    ),
                                    ButtonSegment(
                                      value: 'en_progreso',
                                      label: Text('En Progreso'),
                                      icon: Icon(Icons.pending, size: 16),
                                    ),
                                    ButtonSegment(
                                      value: 'completada',
                                      label: Text('Completada'),
                                      icon: Icon(Icons.check_circle, size: 16),
                                    ),
                                  ],
                                  selected: {_filtroEstado},
                                  onSelectionChanged: (Set<String> newSelection) {
                                    setState(() {
                                      _filtroEstado = newSelection.first;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Filtro de prioridad
                              Expanded(
                                child: DropdownButtonFormField<String?>(
                                  decoration: const InputDecoration(
                                    labelText: 'Filtrar por prioridad',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.filter_list),
                                    isDense: true,
                                  ),
                                  value: _filtroPrioridad,
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('Todas')),
                                    DropdownMenuItem(value: 'alta', child: Text('🔴 Alta')),
                                    DropdownMenuItem(value: 'media', child: Text('🟠 Media')),
                                    DropdownMenuItem(value: 'baja', child: Text('🔵 Baja')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _filtroPrioridad = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Ordenar por
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Ordenar por',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.sort),
                                    isDense: true,
                                  ),
                                  value: _ordenarPor,
                                  items: const [
                                    DropdownMenuItem(value: 'fecha_creacion', child: Text('Fecha de creación')),
                                    DropdownMenuItem(value: 'nombre', child: Text('Nombre')),
                                    DropdownMenuItem(value: 'prioridad', child: Text('Prioridad')),
                                    DropdownMenuItem(value: 'fecha_inicio', child: Text('Fecha de inicio')),
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
                                              color: _getEstadoColor(tarea.estado).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _getEstadoColor(tarea.estado),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getEstadoIcon(tarea.estado),
                                                  size: 16,
                                                  color: _getEstadoColor(tarea.estado),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  tarea.estado,
                                                  style: TextStyle(
                                                    color: _getEstadoColor(tarea.estado),
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
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  tarea.nombre,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (tarea.descripcion != null && tarea.descripcion!.isNotEmpty)
                                                  Text(
                                                    tarea.descripcion!,
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: colorScheme.onSurfaceVariant,
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
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _getPrioridadColor(tarea.prioridad).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.flag,
                                                        size: 14,
                                                        color: _getPrioridadColor(tarea.prioridad),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        tarea.prioridad!,
                                                        style: TextStyle(
                                                          color: _getPrioridadColor(tarea.prioridad),
                                                          fontWeight: FontWeight.bold,
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
                                                ? DateFormat('dd/MM/yyyy').format(tarea.fechaInicio!)
                                                : '-',
                                          ),
                                        ),
                                        // Fecha Fin
                                        DataCell(
                                          Text(
                                            tarea.fechaFin != null
                                                ? DateFormat('dd/MM/yyyy').format(tarea.fechaFin!)
                                                : '-',
                                          ),
                                        ),
                                        // Creada
                                        DataCell(
                                          Text(
                                            DateFormat('dd/MM/yyyy').format(tarea.creadoEn),
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ),
                                        // Acciones
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 20),
                                                onPressed: () => _showCreateEditDialog(tarea: tarea),
                                                tooltip: 'Editar',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 20),
                                                color: Colors.red,
                                                onPressed: () => _deleteTarea(tarea),
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
                          top: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
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
                            _tareas.where((t) => t.estado == 'pendiente').length.toString(),
                            Icons.radio_button_unchecked,
                            Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          _buildStatChip(
                            'En Progreso',
                            _tareas.where((t) => t.estado == 'en_progreso').length.toString(),
                            Icons.pending,
                            Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          _buildStatChip(
                            'Completadas',
                            _tareas.where((t) => t.estado == 'completada').length.toString(),
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

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
