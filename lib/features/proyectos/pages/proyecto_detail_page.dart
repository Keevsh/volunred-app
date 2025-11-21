import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/tarea.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/image_base64_widget.dart';

class ProyectoDetailPage extends StatefulWidget {
  final int proyectoId;

  const ProyectoDetailPage({
    super.key,
    required this.proyectoId,
  });

  @override
  State<ProyectoDetailPage> createState() => _ProyectoDetailPageState();
}

class _ProyectoDetailPageState extends State<ProyectoDetailPage> {
  Proyecto? _proyecto;
  bool _isLoading = true;
  String? _error;
  List<Tarea> _tareas = [];
  bool _isLoadingTareas = false;
  String? _tareasError;

  @override
  void initState() {
    super.initState();
    _loadProyecto();
    _loadTareas();
  }

  Future<void> _loadProyecto() async {
    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      final proyecto = await funcionarioRepo.getProyectoById(widget.proyectoId);
      setState(() {
        _proyecto = proyecto;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTareas() async {
    setState(() {
      _isLoadingTareas = true;
      _tareasError = null;
    });

    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      final tareas = await funcionarioRepo.getTareasByProyecto(widget.proyectoId);
      setState(() {
        _tareas = tareas;
        _isLoadingTareas = false;
      });
    } catch (e) {
      setState(() {
        _tareasError = e.toString();
        _isLoadingTareas = false;
      });
    }
  }

  Future<void> _showCreateTareaDialog() async {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    String? prioridad;
    String estado = 'PENDIENTE';
    DateTime? fechaInicio;
    DateTime? fechaFin;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva tarea'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descripcionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Prioridad',
                        border: OutlineInputBorder(),
                      ),
                      value: prioridad,
                      items: const [
                        DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                        DropdownMenuItem(value: 'Media', child: Text('Media')),
                        DropdownMenuItem(value: 'Baja', child: Text('Baja')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          prioridad = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                      ),
                      value: estado,
                      items: const [
                        DropdownMenuItem(value: 'PENDIENTE', child: Text('Pendiente')),
                        DropdownMenuItem(value: 'EN_PROGRESO', child: Text('En progreso')),
                        DropdownMenuItem(value: 'COMPLETADA', child: Text('Completada')),
                        DropdownMenuItem(value: 'CANCELADA', child: Text('Cancelada')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          estado = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                              );
                              if (date != null) {
                                setDialogState(() {
                                  fechaInicio = date;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    fechaInicio != null
                                        ? '${fechaInicio!.day}/${fechaInicio!.month}/${fechaInicio!.year}'
                                        : 'Fecha inicio',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: fechaInicio ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                              );
                              if (date != null) {
                                setDialogState(() {
                                  fechaFin = date;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    fechaFin != null
                                        ? '${fechaFin!.day}/${fechaFin!.month}/${fechaFin!.year}'
                                        : 'Fecha fin',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nombreController.text.trim().isEmpty) {
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
                      final funcionarioRepo = Modular.get<FuncionarioRepository>();
                      await funcionarioRepo.createTarea(widget.proyectoId, data);
                      if (mounted) {
                        Navigator.of(dialogContext).pop();
                        await _loadTareas();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tarea creada correctamente')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al crear tarea: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Proyecto'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTareaDialog,
        icon: const Icon(Icons.add_task),
        label: const Text('Nueva Tarea'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Error al cargar proyecto',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _loadProyecto,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _proyecto == null
                  ? const Center(child: Text('Proyecto no encontrado'))
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _loadProyecto();
                        await _loadTareas();
                      },
                      child: Column(
                        children: [
                          // Hero Image - Full width, square, no margins
                          if (_proyecto!.imagen != null && _proyecto!.imagen!.isNotEmpty)
                            AspectRatio(
                              aspectRatio: 1.0, // Square image
                              child: Stack(
                                children: [
                                  ImageBase64Widget(
                                    base64String: _proyecto!.imagen!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 24,
                                    left: 16,
                                    right: 16,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _proyecto!.estado == 'activo'
                                                ? Colors.green
                                                : Colors.red,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _proyecto!.estado.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _proyecto!.nombre,
                                          style: theme.textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primaryContainer,
                                    colorScheme.secondaryContainer,
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _proyecto!.estado == 'activo'
                                          ? Colors.green
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _proyecto!.estado.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _proyecto!.nombre,
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Scrollable content
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                          // Organización
                          if (_proyecto!.organizacion != null) ...[
                            Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerHighest,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Logo de la organización
                                    if (_proyecto!.organizacion!['logo'] != null && 
                                        _proyecto!.organizacion!['logo'].toString().isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: ImageBase64Widget(
                                          base64String: _proyecto!.organizacion!['logo'].toString(),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.business,
                                          size: 30,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    const SizedBox(width: 16),
                                    // Información de la organización
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Organización',
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _proyecto!.organizacion!['nombre']?.toString() ??
                                                _proyecto!.organizacion!['nombre_legal']?.toString() ??
                                                _proyecto!.organizacion!['nombre_corto']?.toString() ??
                                                'Organización',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Objetivo
                          if (_proyecto!.objetivo != null && _proyecto!.objetivo!.isNotEmpty) ...[
                            Text(
                              'Objetivo',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _proyecto!.objetivo!,
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Ubicación
                          if (_proyecto!.ubicacion != null && _proyecto!.ubicacion!.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 20, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  _proyecto!.ubicacion!,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Categorías
                          if (_proyecto!.categoriasProyectos != null && 
                              _proyecto!.categoriasProyectos!.isNotEmpty) ...[
                            Text(
                              'Categorías',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _proyecto!.categoriasProyectos!.map((catProy) {
                                String categoriaNombre = 'Categoría';
                                if (catProy is Map) {
                                  if (catProy['categoria'] is Map) {
                                    categoriaNombre = catProy['categoria']['nombre']?.toString() ?? 'Categoría';
                                  } else {
                                    categoriaNombre = catProy['nombre']?.toString() ?? 'Categoría';
                                  }
                                }
                                return Chip(
                                  label: Text(categoriaNombre),
                                  avatar: Icon(
                                    Icons.label,
                                    size: 18,
                                    color: colorScheme.primary,
                                  ),
                                  backgroundColor: colorScheme.primaryContainer,
                                  labelStyle: TextStyle(
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Fechas
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fecha de Inicio',
                                      style: theme.textTheme.labelMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _proyecto!.fechaInicio != null
                                          ? '${_proyecto!.fechaInicio!.day}/${_proyecto!.fechaInicio!.month}/${_proyecto!.fechaInicio!.year}'
                                          : 'No especificada',
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                              if (_proyecto!.fechaFin != null)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fecha de Fin',
                                        style: theme.textTheme.labelMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_proyecto!.fechaFin!.day}/${_proyecto!.fechaFin!.month}/${_proyecto!.fechaFin!.year}',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tareas del proyecto',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Modular.to.pushNamed('/proyectos/${widget.proyectoId}/tareas-kanban?role=funcionario');
                                    },
                                    icon: const Icon(Icons.view_column),
                                    label: const Text('Kanban'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    onPressed: () {
                                      Modular.to.pushNamed('/proyectos/${widget.proyectoId}/tareas');
                                    },
                                    icon: const Icon(Icons.table_chart),
                                    label: const Text('Tabla'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_isLoadingTareas)
                            const Center(child: CircularProgressIndicator())
                          else if (_tareasError != null)
                            Text(
                              'Error al cargar tareas: $_tareasError',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.error,
                              ),
                            )
                          else if (_tareas.isEmpty)
                            Text(
                              'No hay tareas creadas para este proyecto.',
                              style: theme.textTheme.bodyMedium,
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _tareas.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final tarea = _tareas[index];
                                final fechaInicioStr = tarea.fechaInicio != null
                                    ? '${tarea.fechaInicio!.day}/${tarea.fechaInicio!.month}/${tarea.fechaInicio!.year}'
                                    : null;
                                final fechaFinStr = tarea.fechaFin != null
                                    ? '${tarea.fechaFin!.day}/${tarea.fechaFin!.month}/${tarea.fechaFin!.year}'
                                    : null;

                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                tarea.nombre,
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Chip(
                                              label: Text(tarea.estado),
                                            ),
                                          ],
                                        ),
                                        if (tarea.descripcion != null && tarea.descripcion!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            tarea.descripcion!,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (tarea.prioridad != null && tarea.prioridad!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(right: 8),
                                                child: Chip(
                                                  label: Text('Prioridad: ${tarea.prioridad}'),
                                                ),
                                              ),
                                            if (fechaInicioStr != null)
                                              Row(
                                                children: [
                                                  const Icon(Icons.calendar_today_rounded, size: 14),
                                                  const SizedBox(width: 4),
                                                  Text(fechaInicioStr),
                                                ],
                                              ),
                                            if (fechaFinStr != null) ...[
                                              const SizedBox(width: 8),
                                              const Text('→'),
                                              const SizedBox(width: 4),
                                              Text(fechaFinStr),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

