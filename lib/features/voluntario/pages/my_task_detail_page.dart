import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/voluntario_repository.dart';

class MyTaskDetailPage extends StatefulWidget {
  final int tareaId;

  const MyTaskDetailPage({super.key, required this.tareaId});

  @override
  State<MyTaskDetailPage> createState() => _MyTaskDetailPageState();
}

class _MyTaskDetailPageState extends State<MyTaskDetailPage> {
  final VoluntarioRepository _repository = Modular.get<VoluntarioRepository>();
  late Future<Map<String, dynamic>> _futureDetail;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() {
    _futureDetail = _repository.getMyTaskDetail(widget.tareaId);
  }

  Future<void> _changeStatus(String estado) async {
    setState(() {
      _isUpdating = true;
    });
    try {
      await _repository.updateMyTaskStatus(widget.tareaId, estado);
      if (mounted) {
        _loadDetail();
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado actualizado a $estado')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar estado: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de tarea'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                    const SizedBox(height: 8),
                    Text('Error al cargar detalle de la tarea', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      snapshot.error.toString(),
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final tareaMap = data['tarea'] is Map ? Map<String, dynamic>.from(data['tarea'] as Map) : null;
          final evidencias = data['evidencias'] is List ? List.from(data['evidencias'] as List) : <dynamic>[];
          final estado = (data['estado'] ?? tareaMap?['estado'] ?? 'pendiente').toString();

          final nombre = tareaMap != null ? (tareaMap['nombre']?.toString() ?? 'Tarea') : 'Tarea';
          final descripcion = tareaMap != null ? tareaMap['descripcion']?.toString() : null;
          final prioridad = tareaMap != null ? tareaMap['prioridad']?.toString() : null;
          final proyectoMap = tareaMap != null && tareaMap['proyecto'] is Map
              ? Map<String, dynamic>.from(tareaMap['proyecto'] as Map)
              : null;
          final proyectoNombre = proyectoMap != null
              ? (proyectoMap['nombre']?.toString() ?? 'Proyecto')
              : 'Proyecto';

          int? proyectoId;
          if (tareaMap != null) {
            final rawProyectoId = tareaMap['proyecto_id'];
            if (rawProyectoId is int) {
              proyectoId = rawProyectoId;
            } else if (rawProyectoId is String) {
              proyectoId = int.tryParse(rawProyectoId);
            }
          }
          if (proyectoId == null && proyectoMap != null) {
            final rawProyectoId = proyectoMap['id_proyecto'] ?? proyectoMap['proyecto_id'];
            if (rawProyectoId is int) {
              proyectoId = rawProyectoId;
            } else if (rawProyectoId is String) {
              proyectoId = int.tryParse(rawProyectoId);
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  proyectoNombre,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Chip(
                      label: Text(estado.toUpperCase()),
                    ),
                    if (prioridad != null && prioridad.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('Prioridad: ${prioridad.toUpperCase()}'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if (descripcion != null && descripcion.isNotEmpty) ...[
                  Text('Descripción', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(descripcion, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                ],
                if (proyectoId != null) ...[
                  Text('Otras tareas de este proyecto', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _repository.getMyTasks(proyectoId: proyectoId),
                    builder: (context, tasksSnapshot) {
                      if (tasksSnapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(minHeight: 2),
                        );
                      }

                      if (tasksSnapshot.hasError) {
                        return Text(
                          'Error al cargar otras tareas del proyecto',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        );
                      }

                      final tasks = tasksSnapshot.data ?? [];
                      if (tasks.isEmpty) {
                        return Text(
                          'No tienes más tareas asignadas en este proyecto.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = tasks[index];
                          final otherTareaMap = item['tarea'] is Map
                              ? Map<String, dynamic>.from(item['tarea'] as Map)
                              : null;
                          final tareaNombre = otherTareaMap != null
                              ? (otherTareaMap['nombre']?.toString() ?? 'Tarea')
                              : 'Tarea';
                          final otherEstado = (item['estado'] ?? otherTareaMap?['estado'] ?? 'pendiente')
                              .toString();

                          int? otherTareaId;
                          if (otherTareaMap != null) {
                            final rawId = otherTareaMap['id_tarea'] ?? otherTareaMap['id'];
                            if (rawId is int) {
                              otherTareaId = rawId;
                            } else if (rawId is String) {
                              otherTareaId = int.tryParse(rawId);
                            }
                          }
                          otherTareaId ??= item['tarea_id'] is int ? item['tarea_id'] as int : null;

                          return ListTile(
                            title: Text(tareaNombre),
                            subtitle: Text('Estado: ${otherEstado.toUpperCase()}'),
                            onTap: otherTareaId == null
                                ? null
                                : () {
                                    if (otherTareaId == widget.tareaId) return;
                                    Modular.to.pushReplacementNamed('/voluntario/my-tasks/$otherTareaId');
                                  },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                Text('Evidencias (${evidencias.length})', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (evidencias.isEmpty)
                  Text(
                    'Aún no tienes evidencias registradas para esta tarea.',
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  Column(
                    children: evidencias.map((e) {
                      final tipo = e is Map && e['tipo'] != null ? e['tipo'].toString() : 'EVIDENCIA';
                      final desc = e is Map && e['descripcion'] != null ? e['descripcion'].toString() : '';
                      return ListTile(
                        leading: const Icon(Icons.insert_drive_file_outlined),
                        title: Text(tipo),
                        subtitle: desc.isNotEmpty ? Text(desc) : null,
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),
                Text('Acciones', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: _isUpdating || estado == 'en_progreso' ? null : () => _changeStatus('en_progreso'),
                      child: const Text('Marcar en progreso'),
                    ),
                    FilledButton(
                      onPressed: _isUpdating || estado == 'completada' ? null : () => _changeStatus('completada'),
                      child: const Text('Marcar completada'),
                    ),
                    OutlinedButton(
                      onPressed: _isUpdating || estado == 'pendiente' ? null : () => _changeStatus('pendiente'),
                      child: const Text('Volver a pendiente'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
