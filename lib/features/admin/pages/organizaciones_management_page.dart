import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/organizacion.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class OrganizacionesManagementPage extends StatefulWidget {
  final bool embedded;
  
  const OrganizacionesManagementPage({super.key, this.embedded = false});

  @override
  State<OrganizacionesManagementPage> createState() =>
      _OrganizacionesManagementPageState();
}

class _OrganizacionesManagementPageState
    extends State<OrganizacionesManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<AdminBloc>().add(LoadOrganizacionesRequested());
    context.read<AdminBloc>().add(LoadCategoriasOrganizacionesRequested());
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
          if (state is OrganizacionCreated ||
              state is OrganizacionUpdated ||
              state is OrganizacionDeleted) {
            _loadData();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state is OrganizacionCreated
                      ? 'Organización creada'
                      : state is OrganizacionUpdated
                      ? 'Organización actualizada'
                      : 'Organización eliminada',
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
              // Header - ocultar si está embebido
              if (!widget.embedded)
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
                          'Organizaciones',
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

              // Lista de organizaciones
              Expanded(
                child: BlocBuilder<AdminBloc, AdminState>(
                  builder: (context, state) {
                    if (state is AdminLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is OrganizacionesLoaded) {
                      if (state.organizaciones.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildOrganizacionesList(state.organizaciones);
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

  Widget _buildOrganizacionesList(List<Organizacion> organizaciones) {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: organizaciones.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final organizacion = organizaciones[index];
          return _buildOrganizacionCard(organizacion);
        },
      ),
    );
  }

  Widget _buildOrganizacionCard(Organizacion organizacion) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showEditDialog(organizacion),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Color(0xFF007AFF),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      organizacion.nombre,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (organizacion.email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        organizacion.email,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF86868B),
                        ),
                      ),
                    ],
                    if (organizacion.direccion != null &&
                        organizacion.direccion!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        organizacion.direccion!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF86868B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: organizacion.estado == 'activo'
                      ? const Color(0xFF34C759).withOpacity(0.1)
                      : const Color(0xFF8E8E93).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  organizacion.estado == 'activo' ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: organizacion.estado == 'activo'
                        ? const Color(0xFF34C759)
                        : const Color(0xFF8E8E93),
                  ),
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
                        Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditDialog(organizacion);
                  } else if (value == 'delete') {
                    _confirmDelete(organizacion);
                  }
                },
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
              Icons.business_rounded,
              size: 64,
              color: Color(0xFF007AFF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay organizaciones',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Las organizaciones aparecerán aquí',
            style: TextStyle(fontSize: 15, color: Color(0xFF86868B)),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final nombreController = TextEditingController();
    final nombreCortoController = TextEditingController();
    final correoController = TextEditingController();
    final telefonoController = TextEditingController();
    final direccionController = TextEditingController();
    int? selectedCategoriaId;

    final bloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: BlocBuilder<AdminBloc, AdminState>(
            builder: (dialogContext, state) {
              List<dynamic> categorias = [];
              if (state is CategoriasOrganizacionesLoaded) {
                categorias = state.categorias;
              } else {
                dialogContext.read<AdminBloc>().add(
                  LoadCategoriasOrganizacionesRequested(),
                );
              }

              return AlertDialog(
                title: const Text('Nueva Organización'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Legal *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nombreCortoController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Corto (opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: correoController,
                        decoration: const InputDecoration(
                          labelText: 'Correo *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Categoría (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        items: categorias.map((cat) {
                          final id =
                              cat['id_categoria'] ??
                              cat['idCategoria'] ??
                              cat['id'];
                          final nombre = cat['nombre'] ?? '';
                          return DropdownMenuItem<int>(
                            value: id as int?,
                            child: Text(nombre),
                          );
                        }).toList(),
                        onChanged: (value) => selectedCategoriaId = value,
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
                          correoController.text.isNotEmpty) {
                        dialogContext.read<AdminBloc>().add(
                          CreateOrganizacionRequested(
                            nombreLegal: nombreController.text,
                            nombreCorto: nombreCortoController.text.isEmpty
                                ? null
                                : nombreCortoController.text,
                            correo: correoController.text,
                            telefono: telefonoController.text.isEmpty
                                ? null
                                : telefonoController.text,
                            direccion: direccionController.text.isEmpty
                                ? null
                                : direccionController.text,
                            idCategoria: selectedCategoriaId,
                            estado: 'activo',
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
          ),
        );
      },
    );
  }

  void _showEditDialog(Organizacion organizacion) {
    final nombreController = TextEditingController(text: organizacion.nombre);
    final correoController = TextEditingController(text: organizacion.email);
    final telefonoController = TextEditingController(
      text: organizacion.telefono ?? '',
    );
    final direccionController = TextEditingController(
      text: organizacion.direccion ?? '',
    );
    final ciudadController = TextEditingController();
    int? selectedCategoriaId = organizacion.idCategoriaOrganizacion;
    String? selectedEstado = organizacion.estado;

    final bloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: BlocBuilder<AdminBloc, AdminState>(
            builder: (dialogContext, state) {
              List<dynamic> categorias = [];
              if (state is CategoriasOrganizacionesLoaded) {
                categorias = state.categorias;
              } else {
                dialogContext.read<AdminBloc>().add(
                  LoadCategoriasOrganizacionesRequested(),
                );
              }

              return AlertDialog(
                title: const Text('Editar Organización'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Legal *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: correoController,
                        decoration: const InputDecoration(
                          labelText: 'Correo *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedCategoriaId,
                        items: categorias.map((cat) {
                          final id =
                              cat['id_categoria'] ??
                              cat['idCategoria'] ??
                              cat['id'];
                          final nombre = cat['nombre'] ?? '';
                          return DropdownMenuItem<int>(
                            value: id as int?,
                            child: Text(nombre),
                          );
                        }).toList(),
                        onChanged: (value) => selectedCategoriaId = value,
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
                            value: 'inactivo',
                            child: Text('Inactivo'),
                          ),
                        ],
                        onChanged: (value) => selectedEstado = value,
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
                          correoController.text.isNotEmpty) {
                        dialogContext.read<AdminBloc>().add(
                          UpdateOrganizacionRequested(
                            id: organizacion.idOrganizacion,
                            nombreLegal: nombreController.text,
                            correo: correoController.text,
                            telefono: telefonoController.text.isEmpty
                                ? null
                                : telefonoController.text,
                            direccion: direccionController.text.isEmpty
                                ? null
                                : direccionController.text,
                            idCategoria: selectedCategoriaId,
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
          ),
        );
      },
    );
  }

  void _confirmDelete(Organizacion organizacion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Organización'),
        content: Text(
          '¿Está seguro que desea eliminar la organización "${organizacion.nombre}"?',
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
                DeleteOrganizacionRequested(organizacion.idOrganizacion),
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
