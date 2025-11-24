import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/voluntario_repository.dart';

class MyTasksPage extends StatefulWidget {
  const MyTasksPage({super.key});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  final VoluntarioRepository _repository = Modular.get<VoluntarioRepository>();
  late Future<List<Map<String, dynamic>>> _futureTasks;
  String? _selectedEstado;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    _futureTasks = _repository.getMyTasks(estado: _selectedEstado);
  }

  Future<void> _refresh() async {
    setState(_loadTasks);
    await _futureTasks;
  }

  void _onEstadoChanged(String? value) {
    setState(() {
      _selectedEstado = value;
      _loadTasks();
    });
  }

  Color _estadoColor(String estado, ColorScheme colorScheme) {
    switch (estado.toLowerCase()) {
      case 'en_progreso':
        return colorScheme.primary;
      case 'completada':
        return colorScheme.secondary;
      case 'cancelada':
        return colorScheme.error;
      default:
        return colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis tareas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedEstado,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por estado',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('Todos'),
                      ),
                      DropdownMenuItem(
                        value: 'pendiente',
                        child: Text('Pendiente'),
                      ),
                      DropdownMenuItem(
                        value: 'en_progreso',
                        child: Text('En progreso'),
                      ),
                      DropdownMenuItem(
                        value: 'completada',
                        child: Text('Completada'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelada',
                        child: Text('Cancelada'),
                      ),
                    ],
                    onChanged: _onEstadoChanged,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureTasks,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                              const SizedBox(height: 8),
                              Text(
                                'Error al cargar tus tareas',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                snapshot.error.toString(),
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  final tasks = snapshot.data ?? [];

                  if (tasks.isEmpty) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline, size: 64, color: colorScheme.primary),
                              const SizedBox(height: 12),
                              Text(
                                'No tienes tareas asignadas todavía',
                                style: theme.textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = tasks[index];
                      final tareaMap = item['tarea'] is Map ? Map<String, dynamic>.from(item['tarea'] as Map) : null;
                      final tareaNombre = tareaMap != null ? (tareaMap['nombre']?.toString() ?? 'Tarea') : 'Tarea';
                      final proyectoMap = tareaMap != null && tareaMap['proyecto'] is Map
                          ? Map<String, dynamic>.from(tareaMap['proyecto'] as Map)
                          : null;
                      final proyectoNombre = proyectoMap != null
                          ? (proyectoMap['nombre']?.toString() ?? 'Proyecto')
                          : 'Proyecto';
                      final estado = (item['estado'] ?? tareaMap?['estado'] ?? 'pendiente').toString();

                      int? tareaId;
                      if (tareaMap != null) {
                        final rawId = tareaMap['id_tarea'] ?? tareaMap['id'];
                        if (rawId is int) {
                          tareaId = rawId;
                        } else if (rawId is String) {
                          tareaId = int.tryParse(rawId);
                        }
                      }
                      tareaId ??= item['tarea_id'] is int ? item['tarea_id'] as int : null;

                      return ListTile(
                        title: Text(tareaNombre),
                        subtitle: Text(proyectoNombre),
                        trailing: Chip(
                          label: Text(estado.toUpperCase()),
                          backgroundColor: _estadoColor(estado, colorScheme).withOpacity(0.1),
                          labelStyle: TextStyle(
                            color: _estadoColor(estado, colorScheme),
                          ),
                        ),
                        onTap: tareaId == null
                            ? null
                            : () {
                                Modular.to.pushNamed('/voluntario/my-tasks/$tareaId');
                              },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
