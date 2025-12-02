import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/tarea.dart';
import '../../../core/models/proyecto.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class TareasManagementPage extends StatefulWidget {
  const TareasManagementPage({super.key});

  @override
  State<TareasManagementPage> createState() => _TareasManagementPageState();
}

class _TareasManagementPageState extends State<TareasManagementPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<AdminBloc>().add(LoadTareasRequested());
    context.read<AdminBloc>().add(LoadProyectosRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: const Color(0xFF007AFF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocListener<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is TareaCreated ||
              state is TareaUpdated ||
              state is TareaDeleted) {
            _loadData();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state is TareaCreated
                      ? 'Tarea creada'
                      : state is TareaUpdated
                      ? 'Tarea actualizada'
                      : 'Tarea eliminada',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF1D1D1F),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Tareas',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1F),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: _loadData,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: Color(0xFF1D1D1F),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de tareas
              Expanded(
                child: BlocBuilder<AdminBloc, AdminState>(
                  builder: (context, state) {
                    if (state is AdminLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is TareasLoaded) {
                      if (state.tareas.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildTareasList(state.tareas);
                    }
                    return _buildEmptyState();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTareasList(List<Tarea> tareas) {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: tareas.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tarea = tareas[index];
          return _buildTareaCard(tarea);
        },
      ),
    );
  }

  Widget _buildTareaCard(Tarea tarea) {
    final fechaInicioStr = tarea.fechaInicio != null
        ? '${tarea.fechaInicio!.day}/${tarea.fechaInicio!.month}/${tarea.fechaInicio!.year}'
        : 'No definida';
    final fechaFinStr = tarea.fechaFin != null
        ? '${tarea.fechaFin!.day}/${tarea.fechaFin!.month}/${tarea.fechaFin!.year}'
        : 'No definida';

    Color prioridadColor = const Color(0xFF86868B);
    if (tarea.prioridad == 'Alta') {
      prioridadColor = Colors.red;
    } else if (tarea.prioridad == 'Media') {
      prioridadColor = Colors.orange;
    } else if (tarea.prioridad == 'Baja') {
      prioridadColor = Colors.green;
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showEditDialog(tarea),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.task_rounded,
                      color: Color(0xFF007AFF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tarea.nombre,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D1D1F),
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (tarea.descripcion != null &&
                            tarea.descripcion!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            tarea.descripcion!,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF86868B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFF86868B),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_rounded,
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditDialog(tarea);
                      } else if (value == 'delete') {
                        _confirmDelete(tarea);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (tarea.prioridad != null && tarea.prioridad!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: prioridadColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Prioridad: ${tarea.prioridad}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: prioridadColor,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Color(0xFF86868B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$fechaInicioStr - $fechaFinStr',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF86868B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          tarea.estado == 'activo' ||
                              tarea.estado == 'completada'
                          ? const Color(0xFF34C759).withOpacity(0.1)
                          : const Color(0xFF8E8E93).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tarea.estado,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            tarea.estado == 'activo' ||
                                tarea.estado == 'completada'
                            ? const Color(0xFF34C759)
                            : const Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_rounded,
              size: 64,
              color: Color(0xFF007AFF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay tareas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Las tareas aparecerán aquí',
            style: TextStyle(fontSize: 15, color: Color(0xFF86868B)),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    DateTime? fechaInicio;
    DateTime? fechaFin;
    int? selectedProyectoId;
    String? selectedPrioridad;
    String? selectedEstado = 'activo';

    showDialog(
      context: context,
      builder: (context) {
        return BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            List<Proyecto> proyectos = [];
            if (state is ProyectosLoaded) {
              proyectos = state.proyectos;
            } else {
              context.read<AdminBloc>().add(LoadProyectosRequested());
            }

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text('Nueva Tarea'),
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
                          decoration: const InputDecoration(
                            labelText: 'Descripción (opcional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Proyecto *',
                            border: OutlineInputBorder(),
                          ),
                          items: proyectos.map((proy) {
                            return DropdownMenuItem<int>(
                              value: proy.idProyecto,
                              child: Text(proy.nombre),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setDialogState(() => selectedProyectoId = value),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Prioridad (opcional)',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedPrioridad,
                          items: const [
                            DropdownMenuItem(
                              value: 'Alta',
                              child: Text('Alta'),
                            ),
                            DropdownMenuItem(
                              value: 'Media',
                              child: Text('Media'),
                            ),
                            DropdownMenuItem(
                              value: 'Baja',
                              child: Text('Baja'),
                            ),
                          ],
                          onChanged: (value) =>
                              setDialogState(() => selectedPrioridad = value),
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
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365 * 5),
                                    ),
                                  );
                                  if (date != null) {
                                    setDialogState(() => fechaInicio = date);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE5E5EA),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 20,
                                        color: Color(0xFF86868B),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        fechaInicio != null
                                            ? '${fechaInicio!.day}/${fechaInicio!.month}/${fechaInicio!.year}'
                                            : 'Fecha Inicio',
                                        style: TextStyle(
                                          color: fechaInicio != null
                                              ? const Color(0xFF1D1D1F)
                                              : const Color(0xFF86868B),
                                        ),
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
                                    firstDate: fechaInicio ?? DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365 * 5),
                                    ),
                                  );
                                  if (date != null) {
                                    setDialogState(() => fechaFin = date);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE5E5EA),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 20,
                                        color: Color(0xFF86868B),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        fechaFin != null
                                            ? '${fechaFin!.day}/${fechaFin!.month}/${fechaFin!.year}'
                                            : 'Fecha Fin',
                                        style: TextStyle(
                                          color: fechaFin != null
                                              ? const Color(0xFF1D1D1F)
                                              : const Color(0xFF86868B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedEstado,
                          items: const [
                            DropdownMenuItem(
                              value: 'activo',
                              child: Text('Activo'),
                            ),
                            DropdownMenuItem(
                              value: 'pendiente',
                              child: Text('Pendiente'),
                            ),
                            DropdownMenuItem(
                              value: 'en_progreso',
                              child: Text('En Progreso'),
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
                          onChanged: (value) =>
                              setDialogState(() => selectedEstado = value),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (nombreController.text.isNotEmpty &&
                            selectedProyectoId != null) {
                          context.read<AdminBloc>().add(
                            CreateTareaRequested(
                              proyectoId: selectedProyectoId!,
                              nombre: nombreController.text,
                              descripcion: descripcionController.text.isEmpty
                                  ? null
                                  : descripcionController.text,
                              prioridad: selectedPrioridad,
                              fechaInicio: fechaInicio,
                              fechaFin: fechaFin,
                              estado: selectedEstado,
                            ),
                          );
                          Navigator.pop(context);
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
      },
    );
  }

  void _showEditDialog(Tarea tarea) {
    final nombreController = TextEditingController(text: tarea.nombre);
    final descripcionController = TextEditingController(
      text: tarea.descripcion ?? '',
    );
    DateTime? fechaInicio = tarea.fechaInicio;
    DateTime? fechaFin = tarea.fechaFin;
    int? selectedProyectoId = tarea.proyectoId;
    String? selectedPrioridad = tarea.prioridad;
    String? selectedEstado = tarea.estado;

    showDialog(
      context: context,
      builder: (context) {
        return BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            List<Proyecto> proyectos = [];
            if (state is ProyectosLoaded) {
              proyectos = state.proyectos;
            } else {
              context.read<AdminBloc>().add(LoadProyectosRequested());
            }

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text('Editar Tarea'),
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
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Proyecto',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedProyectoId,
                          items: proyectos.map((proy) {
                            return DropdownMenuItem<int>(
                              value: proy.idProyecto,
                              child: Text(proy.nombre),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setDialogState(() => selectedProyectoId = value),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Prioridad',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedPrioridad,
                          items: const [
                            DropdownMenuItem(
                              value: 'Alta',
                              child: Text('Alta'),
                            ),
                            DropdownMenuItem(
                              value: 'Media',
                              child: Text('Media'),
                            ),
                            DropdownMenuItem(
                              value: 'Baja',
                              child: Text('Baja'),
                            ),
                          ],
                          onChanged: (value) =>
                              setDialogState(() => selectedPrioridad = value),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: fechaInicio ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365 * 5),
                                    ),
                                  );
                                  if (date != null) {
                                    setDialogState(() => fechaInicio = date);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE5E5EA),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 20,
                                        color: Color(0xFF86868B),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        fechaInicio != null
                                            ? '${fechaInicio!.day}/${fechaInicio!.month}/${fechaInicio!.year}'
                                            : 'Fecha Inicio',
                                        style: TextStyle(
                                          color: fechaInicio != null
                                              ? const Color(0xFF1D1D1F)
                                              : const Color(0xFF86868B),
                                        ),
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
                                    initialDate:
                                        fechaFin ??
                                        fechaInicio ??
                                        DateTime.now(),
                                    firstDate: fechaInicio ?? DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365 * 5),
                                    ),
                                  );
                                  if (date != null) {
                                    setDialogState(() => fechaFin = date);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE5E5EA),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 20,
                                        color: Color(0xFF86868B),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        fechaFin != null
                                            ? '${fechaFin!.day}/${fechaFin!.month}/${fechaFin!.year}'
                                            : 'Fecha Fin',
                                        style: TextStyle(
                                          color: fechaFin != null
                                              ? const Color(0xFF1D1D1F)
                                              : const Color(0xFF86868B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedEstado,
                          items: const [
                            DropdownMenuItem(
                              value: 'activo',
                              child: Text('Activo'),
                            ),
                            DropdownMenuItem(
                              value: 'pendiente',
                              child: Text('Pendiente'),
                            ),
                            DropdownMenuItem(
                              value: 'en_progreso',
                              child: Text('En Progreso'),
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
                          onChanged: (value) =>
                              setDialogState(() => selectedEstado = value),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (nombreController.text.isNotEmpty &&
                            selectedProyectoId != null) {
                          context.read<AdminBloc>().add(
                            UpdateTareaRequested(
                              id: tarea.idTarea,
                              proyectoId: selectedProyectoId,
                              nombre: nombreController.text,
                              descripcion: descripcionController.text.isEmpty
                                  ? null
                                  : descripcionController.text,
                              prioridad: selectedPrioridad,
                              fechaInicio: fechaInicio,
                              fechaFin: fechaFin,
                              estado: selectedEstado,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Tarea tarea) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Tarea'),
        content: Text(
          '¿Está seguro que desea eliminar la tarea "${tarea.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<AdminBloc>().add(
                DeleteTareaRequested(tarea.idTarea),
              );
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
