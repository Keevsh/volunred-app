import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/models/tarea.dart';
import '../../../core/models/proyecto.dart';
import 'package:intl/intl.dart';

class TareasKanbanPage extends StatefulWidget {
  final int proyectoId;
  final bool isFuncionario;

  const TareasKanbanPage({
    super.key,
    required this.proyectoId,
    this.isFuncionario = false,
  });

  @override
  State<TareasKanbanPage> createState() => _TareasKanbanPageState();
}

class _TareasKanbanPageState extends State<TareasKanbanPage> {
  List<Tarea> _tareas = [];
  Proyecto? _proyecto;
  bool _isLoading = true;
  String? _error;

  final List<Map<String, dynamic>> _estados = [
    {
      'key': 'pendiente',
      'label': 'PENDIENTE',
      'color': const Color(0xFFFF9800),
      'bgColor': const Color(0xFFFFF3E0),
      'icon': Icons.schedule_rounded,
    },
    {
      'key': 'en_progreso',
      'label': 'EN PROGRESO',
      'color': const Color(0xFF2196F3),
      'bgColor': const Color(0xFFE3F2FD),
      'icon': Icons.pending_rounded,
    },
    {
      'key': 'completada',
      'label': 'COMPLETADA',
      'color': const Color(0xFF4CAF50),
      'bgColor': const Color(0xFFE8F5E9),
      'icon': Icons.check_circle_rounded,
    },
  ];

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
      if (widget.isFuncionario) {
        final funcionarioRepo = Modular.get<FuncionarioRepository>();
        final proyecto = await funcionarioRepo.getProyectoById(
          widget.proyectoId,
        );
        final tareas = await funcionarioRepo.getTareasByProyecto(
          widget.proyectoId,
        );
        setState(() {
          _proyecto = proyecto;
          _tareas = tareas.where((t) => t.estado != 'cancelada').toList();
          _isLoading = false;
        });
      } else {
        final voluntarioRepo = Modular.get<VoluntarioRepository>();
        final tareas = await voluntarioRepo.getTareas();
        setState(() {
          _tareas = tareas
              .where(
                (t) =>
                    t.proyectoId == widget.proyectoId &&
                    t.estado != 'cancelada',
              )
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Tarea> _getTareasPorEstado(String estado) {
    return _tareas.where((t) => t.estado == estado).toList();
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

  Future<void> _cambiarEstado(Tarea tarea, String nuevoEstado) async {
    if (!widget.isFuncionario) return;

    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      await funcionarioRepo.updateTarea(tarea.idTarea, {'estado': nuevoEstado});
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a ${nuevoEstado.toUpperCase()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _mostrarMenuEstado(Tarea tarea) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Cambiar estado',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ..._estados.map((estado) {
              final isSelected = tarea.estado == estado['key'];
              return ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? estado['color'] : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: estado['color'], width: 2),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                title: Text(estado['label']),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  if (!isSelected) {
                    _cambiarEstado(tarea, estado['key']);
                  }
                },
              );
            }),
            ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: tarea.estado == 'cancelada'
                      ? Colors.red
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: tarea.estado == 'cancelada'
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              title: const Text('CANCELADA'),
              trailing: tarea.estado == 'cancelada'
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.pop(context);
                if (tarea.estado != 'cancelada') {
                  _cambiarEstado(tarea, 'cancelada');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateTareaDialog() async {
    if (!widget.isFuncionario) return;

    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    String? prioridad;
    String estado = 'pendiente';
    DateTime? fechaInicio;
    DateTime? fechaFin;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva Tarea'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
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
                      DropdownButtonFormField<String>(
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
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
                          const SizedBox(width: 8),
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
                  onPressed: () => Navigator.pop(dialogContext, false),
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
                      'estado': estado,
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
                      final funcionarioRepo =
                          Modular.get<FuncionarioRepository>();
                      await funcionarioRepo.createTarea(
                        widget.proyectoId,
                        data,
                      );
                      Navigator.pop(dialogContext, true);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Crear'),
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
              'Vista Kanban',
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
                Icons.table_chart_rounded,
                color: Color(0xFF1976D2),
              ),
              onPressed: () {
                Modular.to.pushNamed('/proyectos/${widget.proyectoId}/tareas');
              },
              tooltip: 'Vista de tabla',
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
      floatingActionButton: widget.isFuncionario
          ? FloatingActionButton.extended(
              onPressed: _showCreateTareaDialog,
              icon: const Icon(Icons.add_task_rounded),
              label: const Text(
                'Nueva Tarea',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              elevation: 4,
            )
          : null,
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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _estados.map((estadoInfo) {
                final tareas = _getTareasPorEstado(estadoInfo['key']);
                return _buildEstadoSection(
                  estadoInfo['label'],
                  estadoInfo['color'],
                  estadoInfo['icon'],
                  tareas,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildEstadoSection(
    String label,
    Color color,
    IconData icon,
    List<Tarea> tareas,
  ) {
    final theme = Theme.of(context);
    final estadoInfo = _estados.firstWhere((e) => e['label'] == label);
    final bgColor = estadoInfo['bgColor'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          // Header de la sección
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    tareas.length.toString(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenido
          if (tareas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay tareas aquí',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: tareas
                    .map((tarea) => _buildTareaCard(tarea, color, bgColor))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTareaCard(Tarea tarea, Color estadoColor, Color bgColor) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: estadoColor.withOpacity(0.3), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Modular.to.pushNamed(
              '/proyectos/tarea/${tarea.idTarea}?role=${widget.isFuncionario ? 'funcionario' : 'voluntario'}',
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Círculo de estado (clickeable para cambiar)
                GestureDetector(
                  onTap: widget.isFuncionario
                      ? () => _mostrarMenuEstado(tarea)
                      : null,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: estadoColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: estadoColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: tarea.estado == 'completada'
                        ? const Icon(
                            Icons.check_rounded,
                            size: 20,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                // Contenido de la tarea
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tarea.nombre,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                          decoration: tarea.estado == 'completada'
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tarea.descripcion != null &&
                          tarea.descripcion!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          tarea.descripcion!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF616161),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (tarea.fechaInicio != null ||
                          tarea.fechaFin != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: estadoColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tarea.fechaFin != null
                                    ? DateFormat(
                                        'dd MMM',
                                      ).format(tarea.fechaFin!)
                                    : DateFormat(
                                        'dd MMM',
                                      ).format(tarea.fechaInicio!),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: estadoColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Prioridad
                if (tarea.prioridad != null)
                  Container(
                    width: 5,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getPrioridadColor(tarea.prioridad),
                      borderRadius: BorderRadius.circular(3),
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
