import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/tarea.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/image_base64_widget.dart';

class ProyectoDetailPage extends StatefulWidget {
  final int proyectoId;

  const ProyectoDetailPage({super.key, required this.proyectoId});

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
      final tareas = await funcionarioRepo.getTareasByProyecto(
        widget.proyectoId,
      );
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
                        DropdownMenuItem(
                          value: 'PENDIENTE',
                          child: Text('Pendiente'),
                        ),
                        DropdownMenuItem(
                          value: 'EN_PROGRESO',
                          child: Text('En progreso'),
                        ),
                        DropdownMenuItem(
                          value: 'COMPLETADA',
                          child: Text('Completada'),
                        ),
                        DropdownMenuItem(
                          value: 'CANCELADA',
                          child: Text('Cancelada'),
                        ),
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
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365 * 5),
                                ),
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
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                  ),
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
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365 * 5),
                                ),
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
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                  ),
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

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirmar creación'),
                        content: const Text('¿Estás seguro de que quieres crear esta tarea?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Confirmar'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;

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
                      final funcionarioRepo =
                          Modular.get<FuncionarioRepository>();
                      await funcionarioRepo.createTarea(
                        widget.proyectoId,
                        data,
                      );
                      if (mounted) {
                        Navigator.of(dialogContext).pop();
                        await _loadTareas();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tarea creada correctamente'),
                          ),
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Detalles del Proyecto',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTareaDialog,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text(
          'Nueva Tarea',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 4,
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
                  // Hero Image - Diseño moderno
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        if (_proyecto!.imagen != null &&
                            _proyecto!.imagen!.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                            child: Stack(
                              children: [
                                ImageBase64Widget(
                                  base64String: _proyecto!.imagen!,
                                  width: double.infinity,
                                  height: 280,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  width: double.infinity,
                                  height: 280,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.6),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _proyecto!.estado == 'activo'
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFFF44336),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _proyecto!.estado.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            height: 280,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(32),
                                bottomRight: Radius.circular(32),
                              ),
                            ),
                            child: Stack(
                              children: [
                                const Center(
                                  child: Icon(
                                    Icons.folder_rounded,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                ),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _proyecto!.estado == 'activo'
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFFF44336),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _proyecto!.estado.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Título del proyecto
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _proyecto!.nombre,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1A1A),
                              fontSize: 28,
                            ),
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
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      // Logo de la organización
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.08,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child:
                                              _proyecto!.organizacion!['logo'] !=
                                                      null &&
                                                  _proyecto!
                                                      .organizacion!['logo']
                                                      .toString()
                                                      .isNotEmpty
                                              ? ImageBase64Widget(
                                                  base64String: _proyecto!
                                                      .organizacion!['logo']
                                                      .toString(),
                                                  width: 70,
                                                  height: 70,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  width: 70,
                                                  height: 70,
                                                  decoration:
                                                      const BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                              colors: [
                                                                Color(
                                                                  0xFF1976D2,
                                                                ),
                                                                Color(
                                                                  0xFF42A5F5,
                                                                ),
                                                              ],
                                                            ),
                                                      ),
                                                  child: const Icon(
                                                    Icons.business_rounded,
                                                    size: 36,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Información de la organización
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'ORGANIZACIÓN',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: const Color(
                                                      0xFF757575,
                                                    ),
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 1.2,
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _proyecto!.organizacion!['nombre']
                                                      ?.toString() ??
                                                  _proyecto!
                                                      .organizacion!['nombre_legal']
                                                      ?.toString() ??
                                                  _proyecto!
                                                      .organizacion!['nombre_corto']
                                                      ?.toString() ??
                                                  'Organización',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(
                                                      0xFF1A1A1A,
                                                    ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Objetivo
                            if (_proyecto!.objetivo != null &&
                                _proyecto!.objetivo!.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE3F2FD),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.flag_rounded,
                                            color: Color(0xFF1976D2),
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'OBJETIVO',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1A1A1A),
                                                letterSpacing: 0.5,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _proyecto!.objetivo!,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: const Color(0xFF424242),
                                            height: 1.6,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Ubicación
                            if (_proyecto!.ubicacion != null &&
                                _proyecto!.ubicacion!.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE3F2FD),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: Color(0xFF1976D2),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _proyecto!.ubicacion!,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1A1A1A),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Categorías
                            if (_proyecto!.categoriasProyectos != null &&
                                _proyecto!.categoriasProyectos!.isNotEmpty) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CATEGORÍAS',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF757575),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: _proyecto!.categoriasProyectos!
                                        .map((catProy) {
                                          String categoriaNombre = 'Categoría';
                                          if (catProy is Map) {
                                            if (catProy['categoria'] is Map) {
                                              categoriaNombre =
                                                  catProy['categoria']['nombre']
                                                      ?.toString() ??
                                                  'Categoría';
                                            } else {
                                              categoriaNombre =
                                                  catProy['nombre']
                                                      ?.toString() ??
                                                  'Categoría';
                                            }
                                          }
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE3F2FD),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFF1976D2,
                                                ).withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.label_rounded,
                                                  size: 18,
                                                  color: Color(0xFF1976D2),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  categoriaNombre,
                                                  style: const TextStyle(
                                                    color: Color(0xFF1976D2),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Fechas
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE3F2FD),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.calendar_today_rounded,
                                                size: 18,
                                                color: Color(0xFF1976D2),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'INICIO',
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(
                                                      0xFF757575,
                                                    ),
                                                    letterSpacing: 1.0,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          _proyecto!.fechaInicio != null
                                              ? '${_proyecto!.fechaInicio!.day}/${_proyecto!.fechaInicio!.month}/${_proyecto!.fechaInicio!.year}'
                                              : 'No especificada',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1A1A1A),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_proyecto!.fechaFin != null) ...[
                                    Container(
                                      width: 1,
                                      height: 50,
                                      color: const Color(0xFFE0E0E0),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFFEBEE,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.event_rounded,
                                                  size: 18,
                                                  color: Color(0xFFF44336),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'FIN',
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: const Color(
                                                        0xFF757575,
                                                      ),
                                                      letterSpacing: 1.0,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '${_proyecto!.fechaFin!.day}/${_proyecto!.fechaFin!.month}/${_proyecto!.fechaFin!.year}',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(
                                                    0xFF1A1A1A,
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            // Header de tareas
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1976D2),
                                    Color(0xFF42A5F5),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF1976D2,
                                    ).withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.task_alt_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Tareas del Proyecto',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Material(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              Modular.to.pushNamed(
                                                '/proyectos/${widget.proyectoId}/tareas-kanban?role=funcionario',
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                    horizontal: 16,
                                                  ),
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.view_column_rounded,
                                                    color: Color(0xFF1976D2),
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Vista Kanban',
                                                    style: TextStyle(
                                                      color: Color(0xFF1976D2),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Material(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              Modular.to.pushNamed(
                                                '/proyectos/${widget.proyectoId}/tareas',
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                    horizontal: 16,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                  width: 1.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.table_chart_rounded,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Vista Tabla',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
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
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.task_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No hay tareas creadas',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Crea la primera tarea para este proyecto',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _tareas.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final tarea = _tareas[index];
                                  final fechaInicioStr =
                                      tarea.fechaInicio != null
                                      ? '${tarea.fechaInicio!.day}/${tarea.fechaInicio!.month}/${tarea.fechaInicio!.year}'
                                      : null;
                                  final fechaFinStr = tarea.fechaFin != null
                                      ? '${tarea.fechaFin!.day}/${tarea.fechaFin!.month}/${tarea.fechaFin!.year}'
                                      : null;

                                  // Colores según estado
                                  Color estadoColor;
                                  Color estadoBgColor;
                                  IconData estadoIcon;

                                  switch (tarea.estado.toLowerCase()) {
                                    case 'completada':
                                      estadoColor = const Color(0xFF4CAF50);
                                      estadoBgColor = const Color(0xFFE8F5E9);
                                      estadoIcon = Icons.check_circle_rounded;
                                      break;
                                    case 'en_progreso':
                                      estadoColor = const Color(0xFF2196F3);
                                      estadoBgColor = const Color(0xFFE3F2FD);
                                      estadoIcon = Icons.pending_rounded;
                                      break;
                                    case 'cancelada':
                                      estadoColor = const Color(0xFFF44336);
                                      estadoBgColor = const Color(0xFFFFEBEE);
                                      estadoIcon = Icons.cancel_rounded;
                                      break;
                                    default: // pendiente
                                      estadoColor = const Color(0xFFFF9800);
                                      estadoBgColor = const Color(0xFFFFF3E0);
                                      estadoIcon = Icons.schedule_rounded;
                                  }

                                  // Color según prioridad
                                  Color? prioridadColor;
                                  if (tarea.prioridad != null) {
                                    switch (tarea.prioridad!.toLowerCase()) {
                                      case 'alta':
                                        prioridadColor = const Color(
                                          0xFFF44336,
                                        );
                                        break;
                                      case 'media':
                                        prioridadColor = const Color(
                                          0xFFFF9800,
                                        );
                                        break;
                                      case 'baja':
                                        prioridadColor = const Color(
                                          0xFF4CAF50,
                                        );
                                        break;
                                    }
                                  }

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: estadoColor.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          // Navegar a detalles de tarea
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: estadoBgColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Icon(
                                                      estadoIcon,
                                                      color: estadoColor,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          tarea.nombre,
                                                          style: theme
                                                              .textTheme
                                                              .titleSmall
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color:
                                                                    const Color(
                                                                      0xFF1A1A1A,
                                                                    ),
                                                              ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                estadoBgColor,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            tarea.estado
                                                                .replaceAll(
                                                                  '_',
                                                                  ' ',
                                                                )
                                                                .toUpperCase(),
                                                            style: TextStyle(
                                                              color:
                                                                  estadoColor,
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              letterSpacing:
                                                                  0.5,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (prioridadColor != null)
                                                    Container(
                                                      width: 4,
                                                      height: 50,
                                                      decoration: BoxDecoration(
                                                        color: prioridadColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              2,
                                                            ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              if (tarea.descripcion != null &&
                                                  tarea
                                                      .descripcion!
                                                      .isNotEmpty) ...[
                                                const SizedBox(height: 12),
                                                Text(
                                                  tarea.descripcion!,
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: const Color(
                                                          0xFF616161,
                                                        ),
                                                        height: 1.4,
                                                      ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                              if (fechaInicioStr != null ||
                                                  fechaFinStr != null) ...[
                                                const SizedBox(height: 12),
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFF5F5F5,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .calendar_today_rounded,
                                                        size: 16,
                                                        color: Color(
                                                          0xFF757575,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      if (fechaInicioStr !=
                                                          null)
                                                        Text(
                                                          fechaInicioStr,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                color: Color(
                                                                  0xFF424242,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                      if (fechaFinStr !=
                                                          null) ...[
                                                        const Padding(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                              ),
                                                          child: Icon(
                                                            Icons
                                                                .arrow_forward_rounded,
                                                            size: 14,
                                                            color: Color(
                                                              0xFF757575,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          fechaFinStr,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                color: Color(
                                                                  0xFF424242,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
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
