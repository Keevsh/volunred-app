import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../../core/models/proyecto.dart';
import '../../../core/models/organizacion.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/image_base64_widget.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class ProyectosManagementPage extends StatefulWidget {
  final bool embedded;
  
  const ProyectosManagementPage({super.key, this.embedded = false});

  @override
  State<ProyectosManagementPage> createState() =>
      _ProyectosManagementPageState();
}

class _ProyectosManagementPageState extends State<ProyectosManagementPage> {
  bool? _esAdmin;
  int? _userId;
  List<Proyecto> _proyectos = [];
  List<Organizacion> _organizaciones = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarAcceso();
    });
  }

  Future<void> _verificarAcceso() async {
    final authRepo = Modular.get<AuthRepository>();
    final usuario = await authRepo.getStoredUser();

    if (usuario == null) {
      // Si está embebido, no redirigir, solo cargar como admin
      if (widget.embedded) {
        _loadData(true, 0);
        return;
      }
      // No autenticado, redirigir al login o home
      if (mounted) {
        Modular.to.navigate('/home');
      }
    } else {
      // Determinar si es admin
      final esAdmin = usuario.isAdmin;

      // Cargar datos apropiados
      _loadData(esAdmin, usuario.idUsuario);
    }
  }

  void _loadData([bool? esAdmin, int? userId]) {
    if (esAdmin != null) _esAdmin = esAdmin;
    if (userId != null) _userId = userId;

    // Usar los valores guardados
    final admin = _esAdmin ?? true;
    final uid = _userId ?? 0;

    BlocProvider.of<AdminBloc>(context).add(LoadProyectosRequested());

    if (admin) {
      BlocProvider.of<AdminBloc>(context).add(LoadOrganizacionesRequested());
    } else {
      BlocProvider.of<AdminBloc>(
        context,
      ).add(LoadOrganizacionesByUsuarioRequested(uid));
    }

    BlocProvider.of<AdminBloc>(context).add(LoadCategoriasProyectosRequested());
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
          // Guardar proyectos cuando lleguen
          if (state is ProyectosLoaded) {
            setState(() {
              _proyectos = state.proyectos;
            });
          }
          // Guardar organizaciones cuando lleguen
          if (state is OrganizacionesLoaded) {
            setState(() {
              _organizaciones = state.organizaciones;
            });
          }
          
          if (state is ProyectoCreated ||
              state is ProyectoUpdated ||
              state is ProyectoDeleted) {
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
                    // Mostrar skeleton solo si está cargando Y no hay datos previos
                    if (state is AdminLoading && _proyectos.isEmpty) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 2;
                          double childAspectRatio = 1.3;
                          
                          if (constraints.maxWidth > 1200) {
                            crossAxisCount = 4;
                            childAspectRatio = 1.4;
                          } else if (constraints.maxWidth > 900) {
                            crossAxisCount = 3;
                            childAspectRatio = 1.35;
                          } else if (constraints.maxWidth > 600) {
                            crossAxisCount = 2;
                            childAspectRatio = 1.3;
                          }
                          
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: childAspectRatio,
                            ),
                            itemCount: 6,
                            itemBuilder: (context, index) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              height: 14,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              height: 10,
                                              width: 100,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    }
                    
                    // Usar datos locales guardados
                    if (_proyectos.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildProyectosList(_proyectos);
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calcular columnas según el ancho disponible
          // Aspect ratio > 1 = más ancho que alto
          int crossAxisCount = 2;
          double childAspectRatio = 1.3; // Más ancho que alto
          
          if (constraints.maxWidth > 1200) {
            crossAxisCount = 4;
            childAspectRatio = 1.4;
          } else if (constraints.maxWidth > 900) {
            crossAxisCount = 3;
            childAspectRatio = 1.35;
          } else if (constraints.maxWidth > 600) {
            crossAxisCount = 2;
            childAspectRatio = 1.3;
          }
          
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: proyectos.length,
            itemBuilder: (context, index) {
              final proyecto = proyectos[index];
              return _buildProyectoGridCard(proyecto);
            },
          );
        },
      ),
    );
  }

  Widget _buildProyectoGridCard(Proyecto proyecto) {
    final estado = proyecto.estado.toLowerCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEditDialog(proyecto),
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con imagen - más grande
                  Expanded(
                    flex: 5,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: estado == 'activo'
                              ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                              : [
                                  const Color(0xFF90A4AE),
                                  const Color(0xFFB0BEC5),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (proyecto.imagen != null &&
                            proyecto.imagen!.isNotEmpty)
                          Positioned.fill(
                            child: proyecto.imagen!.startsWith('http')
                                ? Image.network(
                                    proyecto.imagen!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF1976D2),
                                              const Color(0xFF42A5F5),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Image.memory(
                                    base64Decode(
                                      proyecto.imagen!.split(',').last,
                                    ),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF1976D2),
                                              const Color(0xFF42A5F5),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        // Overlay oscuro
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.2),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        // Icono
                        const Icon(
                          Icons.folder_special_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ],
                    ),
                    ),
                  ),
                  // Contenido - más compacto
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                proyecto.nombre,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1D1D1F),
                                  letterSpacing: -0.2,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (proyecto.objetivo != null &&
                                  proyecto.objetivo!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  proyecto.objetivo!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF86868B),
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          if (proyecto.ubicacion != null &&
                              proyecto.ubicacion!.isNotEmpty)
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: Color(0xFF86868B),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    proyecto.ubicacion!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF86868B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Menu button
              Positioned(
                top: 8,
                right: 8,
                child: PopupMenuButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFF86868B),
                      size: 18,
                    ),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18),
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
                            size: 18,
                            color: Colors.red,
                          ),
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
              ),
            ],
          ),
        ),
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
                        if (proyecto.objetivo != null &&
                            proyecto.objetivo!.isNotEmpty)
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
                  if (proyecto.ubicacion != null &&
                      proyecto.ubicacion!.isNotEmpty)
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
                            Icons.location_on_rounded,
                            size: 14,
                            color: Color(0xFF86868B),
                          ),
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
            style: TextStyle(fontSize: 15, color: Color(0xFF86868B)),
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
    bool participacionPublica = false;
    String? imagenBase64;
    final ImagePicker _imagePicker = ImagePicker();

    final bloc = BlocProvider.of<AdminBloc>(context);
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
                BlocProvider.of<AdminBloc>(
                  dialogContext,
                ).add(LoadOrganizacionesRequested());
              }

              if (state is CategoriasProyectosLoaded) {
                categorias = state.categorias;
              } else {
                BlocProvider.of<AdminBloc>(
                  dialogContext,
                ).add(LoadCategoriasProyectosRequested());
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
                            onChanged: (value) => setDialogState(
                              () => selectedCategoriaId = value,
                            ),
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
                            onChanged: (value) => setDialogState(
                              () => selectedOrganizacionId = value,
                            ),
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
                                      initialDate:
                                          fechaInicio ?? DateTime.now(),
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
                                value: 'inactivo',
                                child: Text('Inactivo'),
                              ),
                              DropdownMenuItem(
                                value: 'completado',
                                child: Text('Completado'),
                              ),
                              DropdownMenuItem(
                                value: 'cancelado',
                                child: Text('Cancelado'),
                              ),
                            ],
                            onChanged: (value) =>
                                setDialogState(() => selectedEstado = value),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Participación Pública'),
                            subtitle: const Text(
                              'Permitir que cualquier voluntario se una sin inscripción previa en la organización',
                            ),
                            value: participacionPublica,
                            onChanged: (value) => setDialogState(
                              () => participacionPublica = value,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFFE5E5EA)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildImageSelector(
                            context,
                            imagenBase64,
                            (image) =>
                                setDialogState(() => imagenBase64 = image),
                            _imagePicker,
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
                            BlocProvider.of<AdminBloc>(dialogContext).add(
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
                                participacionPublica: participacionPublica,
                                imagen: imagenBase64,
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
    final ubicacionController = TextEditingController(
      text: proyecto.ubicacion ?? '',
    );
    DateTime? fechaInicio = proyecto.fechaInicio;
    DateTime? fechaFin = proyecto.fechaFin;
    int? selectedCategoriaId = proyecto.categoriaProyectoId;
    int? selectedOrganizacionId = proyecto.organizacionId;
    String? selectedEstado = proyecto.estado;
    bool participacionPublica = proyecto.participacionPublica;

    // Usar datos locales ya cargados
    final organizaciones = _organizaciones;
    // Lista vacía para categorías (se puede cargar después si es necesario)
    final List<dynamic> categorias = [];

    showDialog(
      context: context,
      builder: (dialogContext) {
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
                            onChanged: (value) => setDialogState(
                              () => selectedCategoriaId = value,
                            ),
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
                            onChanged: (value) => setDialogState(
                              () => selectedOrganizacionId = value,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          fechaInicio ?? DateTime.now(),
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
                                value: 'inactivo',
                                child: Text('Inactivo'),
                              ),
                              DropdownMenuItem(
                                value: 'completado',
                                child: Text('Completado'),
                              ),
                              DropdownMenuItem(
                                value: 'cancelado',
                                child: Text('Cancelado'),
                              ),
                            ],
                            onChanged: (value) =>
                                setDialogState(() => selectedEstado = value),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Participación Pública'),
                            subtitle: const Text(
                              'Permitir que cualquier voluntario se una sin inscripción previa en la organización',
                            ),
                            value: participacionPublica,
                            onChanged: (value) => setDialogState(
                              () => participacionPublica = value,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFFE5E5EA)),
                            ),
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
                            BlocProvider.of<AdminBloc>(dialogContext).add(
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
                                participacionPublica: participacionPublica,
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
          );
    }
  

  Widget _buildImageSelector(
    BuildContext context,
    String? imagenBase64,
    Function(String?) onImageSelected,
    ImagePicker imagePicker,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imagen del Proyecto (opcional)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            try {
              final XFile? image = await imagePicker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1024,
                maxHeight: 1024,
                imageQuality: 85,
              );

              if (image != null) {
                try {
                  final base64 = await ImageUtils.convertXFileToBase64(image);
                  onImageSelected(base64);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al procesar la imagen: $e'),
                      ),
                    );
                  }
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al seleccionar imagen: $e')),
                );
              }
            }
          },
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
            ),
            child: imagenBase64 != null && imagenBase64.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: ImageBase64Widget(
                      base64String: imagenBase64,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agregar imagen',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
          ),
        ),
        if (imagenBase64 != null && imagenBase64.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () => onImageSelected(null),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Eliminar imagen'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
      ],
    );
  }

  void _confirmDelete(Proyecto proyecto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Proyecto'),
        content: Text(
          '¿Está seguro que desea eliminar el proyecto "${proyecto.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              BlocProvider.of<AdminBloc>(
                context,
              ).add(DeleteProyectoRequested(proyecto.idProyecto));
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
