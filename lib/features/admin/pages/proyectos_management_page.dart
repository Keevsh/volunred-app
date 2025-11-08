import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/organizacion.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class ProyectosManagementPage extends StatefulWidget {
  const ProyectosManagementPage({super.key});

  @override
  State<ProyectosManagementPage> createState() => _ProyectosManagementPageState();
}

class _ProyectosManagementPageState extends State<ProyectosManagementPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<AdminBloc>().add(LoadProyectosRequested());
    context.read<AdminBloc>().add(LoadOrganizacionesRequested());
    context.read<AdminBloc>().add(LoadCategoriasProyectosRequested());
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
          if (state is ProyectoCreated || state is ProyectoUpdated || state is ProyectoDeleted) {
            _loadData();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state is ProyectoCreated
                      ? 'Proyecto creado'
                      : state is ProyectoUpdated
                          ? 'Proyecto actualizado'
                          : 'Proyecto eliminado',
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
                        'Proyectos',
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

              // Lista de proyectos
              Expanded(
                child: BlocBuilder<AdminBloc, AdminState>(
                  builder: (context, state) {
                    if (state is AdminLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is ProyectosLoaded) {
                      if (state.proyectos.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildProyectosList(state.proyectos);
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

  Widget _buildProyectosList(List<Proyecto> proyectos) {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: proyectos.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final proyecto = proyectos[index];
          return _buildProyectoCard(proyecto);
        },
      ),
    );
  }

  Widget _buildProyectoCard(Proyecto proyecto) {
    final fechaInicioStr = proyecto.fechaInicio != null
        ? '${proyecto.fechaInicio!.day}/${proyecto.fechaInicio!.month}/${proyecto.fechaInicio!.year}'
        : 'No definida';
    final fechaFinStr = proyecto.fechaFin != null
        ? '${proyecto.fechaFin!.day}/${proyecto.fechaFin!.month}/${proyecto.fechaFin!.year}'
        : 'No definida';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showEditDialog(proyecto),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5856D6).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.folder_special_rounded,
                      color: Color(0xFF5856D6),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proyecto.nombre,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D1D1F),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (proyecto.objetivo != null && proyecto.objetivo!.isNotEmpty)
                          Text(
                            proyecto.objetivo!,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF86868B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF86868B)),
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
                            Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditDialog(proyecto);
                      } else if (value == 'delete') {
                        _confirmDelete(proyecto);
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
                  if (proyecto.ubicacion != null && proyecto.ubicacion!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF86868B)),
                          const SizedBox(width: 4),
                          Text(
                            proyecto.ubicacion!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF86868B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF86868B)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: proyecto.estado == 'activo'
                          ? const Color(0xFF34C759).withOpacity(0.1)
                          : const Color(0xFF8E8E93).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      proyecto.estado == 'activo' ? 'Activo' : proyecto.estado,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: proyecto.estado == 'activo'
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
              color: const Color(0xFF5856D6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_special_rounded,
              size: 64,
              color: Color(0xFF5856D6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay proyectos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los proyectos aparecerán aquí',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final nombreController = TextEditingController();
    final objetivoController = TextEditingController();
    final ubicacionController = TextEditingController();
    DateTime? fechaInicio;
    DateTime? fechaFin;
    int? selectedCategoriaId;
    int? selectedOrganizacionId;
    String? selectedEstado = 'activo';

    final bloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: BlocBuilder<AdminBloc, AdminState>(
            builder: (dialogContext, state) {
              List<Organizacion> organizaciones = [];
              List<dynamic> categorias = [];

              if (state is OrganizacionesLoaded) {
                organizaciones = state.organizaciones;
              } else {
                dialogContext.read<AdminBloc>().add(LoadOrganizacionesRequested());
              }

              if (state is CategoriasProyectosLoaded) {
                categorias = state.categorias;
              } else {
                dialogContext.read<AdminBloc>().add(LoadCategoriasProyectosRequested());
              }

              return StatefulBuilder(
                builder: (context, setDialogState) {
                  return AlertDialog(
                    title: const Text('Nuevo Proyecto'),
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
                          controller: objetivoController,
                          decoration: const InputDecoration(
                            labelText: 'Objetivo *',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: ubicacionController,
                          decoration: const InputDecoration(
                            labelText: 'Ubicación (opcional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Categoría *',
                            border: OutlineInputBorder(),
                          ),
                          items: categorias.map((cat) {
                            final id = cat['id_categoria'] ?? cat['idCategoria'] ?? cat['id'];
                            final nombre = cat['nombre'] ?? '';
                            return DropdownMenuItem<int>(
                              value: id as int?,
                              child: Text(nombre),
                            );
                          }).toList(),
                          onChanged: (value) => setDialogState(() => selectedCategoriaId = value),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Organización *',
                            border: OutlineInputBorder(),
                          ),
                          items: organizaciones.map((org) {
                            return DropdownMenuItem<int>(
                              value: org.idOrganizacion,
                              child: Text(org.nombre),
                            );
                          }).toList(),
                          onChanged: (value) => setDialogState(() => selectedOrganizacionId = value),
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
                                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                  );
                                  if (date != null) {
                                    setDialogState(() => fechaInicio = date);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE5E5EA)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF86868B)),
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
                                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                  );
                                  if (date != null) {
                                    setDialogState(() => fechaFin = date);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE5E5EA)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF86868B)),
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
                            DropdownMenuItem(value: 'activo', child: Text('Activo')),
                            DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                            DropdownMenuItem(value: 'completado', child: Text('Completado')),
                            DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
                          ],
                          onChanged: (value) => setDialogState(() => selectedEstado = value),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (nombreController.text.isNotEmpty &&
                            objetivoController.text.isNotEmpty &&
                            selectedCategoriaId != null &&
                            selectedOrganizacionId != null) {
                          dialogContext.read<AdminBloc>().add(
                                CreateProyectoRequested(
                                  categoriaProyectoId: selectedCategoriaId!,
                                  organizacionId: selectedOrganizacionId!,
                                  nombre: nombreController.text,
                                  objetivo: objetivoController.text,
                                  ubicacion: ubicacionController.text.isEmpty
                                      ? null
                                      : ubicacionController.text,
                                  fechaInicio: fechaInicio,
                                  fechaFin: fechaFin,
                                  estado: selectedEstado,
                                ),
                              );
                          Navigator.pop(dialogContext);
                        }
                      },
                      child: const Text('Crear'),
                    ),
                  ],
                );
              },
            );
            },
          ),
        );
      },
    );
  }

  void _showEditDialog(Proyecto proyecto) {
    final nombreController = TextEditingController(text: proyecto.nombre);
    final objetivoController = TextEditingController(text: proyecto.objetivo);
    final ubicacionController = TextEditingController(text: proyecto.ubicacion ?? '');
    DateTime? fechaInicio = proyecto.fechaInicio;
    DateTime? fechaFin = proyecto.fechaFin;
    int? selectedCategoriaId = proyecto.categoriaProyectoId;
    int? selectedOrganizacionId = proyecto.organizacionId;
    String? selectedEstado = proyecto.estado;

    final bloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: BlocBuilder<AdminBloc, AdminState>(
            builder: (dialogContext, state) {
              List<Organizacion> organizaciones = [];
              List<dynamic> categorias = [];

              if (state is OrganizacionesLoaded) {
                organizaciones = state.organizaciones;
              } else {
                dialogContext.read<AdminBloc>().add(LoadOrganizacionesRequested());
              }

              if (state is CategoriasProyectosLoaded) {
                categorias = state.categorias;
              } else {
                dialogContext.read<AdminBloc>().add(LoadCategoriasProyectosRequested());
              }

              return StatefulBuilder(
                builder: (context, setDialogState) {
                  return AlertDialog(
                    title: const Text('Editar Proyecto'),
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
                          controller: objetivoController,
                          decoration: const InputDecoration(
                            labelText: 'Objetivo *',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: ubicacionController,
                          decoration: const InputDecoration(
                            labelText: 'Ubicación',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedCategoriaId,
                          items: categorias.map((cat) {
                            final id = cat['id_categoria'] ?? cat['idCategoria'] ?? cat['id'];
                            final nombre = cat['nombre'] ?? '';
                            return DropdownMenuItem<int>(
                              value: id as int?,
                              child: Text(nombre),
                            );
                          }).toList(),
                          onChanged: (value) => setDialogState(() => selectedCategoriaId = value),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Organización',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedOrganizacionId,
                          items: organizaciones.map((org) {
                            return DropdownMenuItem<int>(
                              value: org.idOrganizacion,
                              child: Text(org.nombre),
                            );
                          }).toList(),
                          onChanged: (value) => setDialogState(() => selectedOrganizacionId = value),
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
                                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                  );
                                  if (date != null) {
                                    setDialogState(() => fechaInicio = date);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE5E5EA)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF86868B)),
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
                                    initialDate: fechaFin ?? fechaInicio ?? DateTime.now(),
                                    firstDate: fechaInicio ?? DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                  );
                                  if (date != null) {
                                    setDialogState(() => fechaFin = date);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE5E5EA)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF86868B)),
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
                            DropdownMenuItem(value: 'activo', child: Text('Activo')),
                            DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                            DropdownMenuItem(value: 'completado', child: Text('Completado')),
                            DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
                          ],
                          onChanged: (value) => setDialogState(() => selectedEstado = value),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (nombreController.text.isNotEmpty &&
                            objetivoController.text.isNotEmpty &&
                            selectedCategoriaId != null &&
                            selectedOrganizacionId != null) {
                          dialogContext.read<AdminBloc>().add(
                                UpdateProyectoRequested(
                                  id: proyecto.idProyecto,
                                  categoriaProyectoId: selectedCategoriaId,
                                  organizacionId: selectedOrganizacionId,
                                  nombre: nombreController.text,
                                  objetivo: objetivoController.text,
                                  ubicacion: ubicacionController.text.isEmpty
                                      ? null
                                      : ubicacionController.text,
                                  fechaInicio: fechaInicio,
                                  fechaFin: fechaFin,
                                  estado: selectedEstado,
                                ),
                              );
                          Navigator.pop(dialogContext);
                        }
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                );
              },
            );
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(Proyecto proyecto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Proyecto'),
        content: Text('¿Está seguro que desea eliminar el proyecto "${proyecto.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<AdminBloc>().add(DeleteProyectoRequested(proyecto.idProyecto));
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

