import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/usuario.dart';
import '../../../core/models/rol.dart';
import '../../../core/theme/app_widgets.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class UsuariosManagementPage extends StatefulWidget {
  final bool embedded;
  
  const UsuariosManagementPage({super.key, this.embedded = false});

  @override
  State<UsuariosManagementPage> createState() => _UsuariosManagementPageState();
}

class _UsuariosManagementPageState extends State<UsuariosManagementPage> {
  final _searchController = TextEditingController();
  int? _selectedRolFilter;
  List<Usuario> _usuarios = [];
  List<Rol> _roles = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    BlocProvider.of<AdminBloc>(context).add(LoadUsuariosRequested());
    BlocProvider.of<AdminBloc>(context).add(LoadRolesRequested());
  }

  void _showCreateUserDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nombreController = TextEditingController();
    final apellidoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Crear Nuevo Usuario'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email requerido';
                    }
                    if (!value.contains('@')) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Contraseña requerida';
                    }
                    if (value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombres',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nombres requeridos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: apellidoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellidos',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Apellidos requeridos';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                // TODO: Implementar creación de usuario
                Navigator.pop(dialogContext);
                AppWidgets.showStyledSnackBar(
                  context: context,
                  message: 'Funcionalidad en desarrollo',
                  isError: false,
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(Usuario usuario) {
    final nombreController = TextEditingController(text: usuario.nombres);
    final apellidoController = TextEditingController(text: usuario.apellidos);
    final telefonoController = TextEditingController(
      text: usuario.telefono?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Usuario'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombres',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nombres requeridos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: apellidoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellidos',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Apellidos requeridos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                // TODO: Implementar actualización
                Navigator.pop(dialogContext);
                AppWidgets.showStyledSnackBar(
                  context: context,
                  message: 'Funcionalidad en desarrollo',
                  isError: false,
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showAssignRoleDialog(Usuario usuario) {
    int? selectedRolId = usuario.idRol;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Asignar Rol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usuario: ${usuario.nombres} ${usuario.apellidos}'),
            const SizedBox(height: 16),
            const Text('Selecciona un rol:'),
            const SizedBox(height: 8),
            ..._roles.map((rol) {
              return RadioListTile<int>(
                title: Text(rol.nombre),
                subtitle: Text(rol.descripcion ?? ''),
                value: rol.idRol,
                groupValue: selectedRolId,
                onChanged: (value) {
                  selectedRolId = value;
                  (dialogContext as Element).markNeedsBuild();
                },
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedRolId != null) {
                BlocProvider.of<AdminBloc>(context).add(
                  AsignarRolRequested(
                    idUsuario: usuario.idUsuario,
                    idRol: selectedRolId!,
                  ),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Asignar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Usuario usuario) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de eliminar al usuario ${usuario.nombres} ${usuario.apellidos}?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar eliminación
              Navigator.pop(dialogContext);
              AppWidgets.showStyledSnackBar(
                context: context,
                message: 'Funcionalidad en desarrollo',
                isError: false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  List<Usuario> _getFilteredUsuarios() {
    var filtered = _usuarios;

    // Filtro por texto de búsqueda
    if (_searchController.text.isNotEmpty) {
      final searchLower = _searchController.text.toLowerCase();
      filtered = filtered.where((u) {
        return u.email.toLowerCase().contains(searchLower) ||
            u.nombres.toLowerCase().contains(searchLower) ||
            u.apellidos.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Filtro por rol
    if (_selectedRolFilter != null) {
      filtered = filtered.where((u) => u.idRol == _selectedRolFilter).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        backgroundColor: const Color(0xFF007AFF),
        elevation: 2,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: BlocConsumer<AdminBloc, AdminState>(
          listener: (context, state) {
            if (state is RolAsignado) {
              AppWidgets.showStyledSnackBar(
                context: context,
                message: 'Rol asignado exitosamente',
                isError: false,
              );
              _loadData();
            } else if (state is AdminError) {
              AppWidgets.showStyledSnackBar(
                context: context,
                message: state.message,
                isError: true,
              );
            }
          },
          builder: (context, state) {
            if (state is AdminLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is UsuariosLoaded) {
              _usuarios = state.usuarios;
            }

            if (state is RolesLoaded) {
              _roles = state.roles;
            }

            final filteredUsuarios = _getFilteredUsuarios();

            return Column(
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
                            'Usuarios',
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

                // Barra de búsqueda limpia
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE5E5EA),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar usuarios...',
                        hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF8E8E93),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: Color(0xFF8E8E93),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                ),

                // Filtro por rol
                if (_roles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E5EA),
                          width: 1,
                        ),
                      ),
                      child: DropdownButton<int?>(
                        value: _selectedRolFilter,
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: const Text(
                          'Todos los roles',
                          style: TextStyle(
                            color: Color(0xFF1D1D1F),
                            fontSize: 15,
                          ),
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Color(0xFF8E8E93),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todos los roles'),
                          ),
                          ..._roles.map((rol) {
                            return DropdownMenuItem(
                              value: rol.idRol,
                              child: Text(rol.nombre),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRolFilter = value;
                          });
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Lista de usuarios
                if (filteredUsuarios.isEmpty)
                  Expanded(
                    child: Center(
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
                              Icons.people_rounded,
                              size: 64,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No hay usuarios',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Presiona + para crear el primero',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF86868B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: filteredUsuarios.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final usuario = filteredUsuarios[index];
                        return _buildUsuarioCard(usuario);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUsuarioCard(Usuario usuario) {
    final rol = _getUsuarioRol(usuario);
    final rolNombre = rol?.nombre ?? 'Sin rol';
    final rolColor = _getRolColor(rolNombre);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showEditUserDialog(usuario),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar circular
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    usuario.nombres[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF007AFF),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${usuario.nombres} ${usuario.apellidos}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      usuario.email,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF86868B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Badge de rol
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: rolColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rolNombre,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: rolColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Menú
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: Color(0xFF8E8E93),
                  size: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditUserDialog(usuario);
                      break;
                    case 'role':
                      _showAssignRoleDialog(usuario);
                      break;
                    case 'delete':
                      _confirmDelete(usuario);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'role',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, size: 20),
                        SizedBox(width: 8),
                        Text('Asignar Rol'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
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

  Rol? _getUsuarioRol(Usuario usuario) {
    if (usuario.rol != null) return usuario.rol;
    final idRol = usuario.idRol;
    if (idRol == null) return null;
    try {
      return _roles.firstWhere((rol) => rol.idRol == idRol);
    } catch (_) {
      return null;
    }
  }

  Color _getRolColor(String rolNombre) {
    switch (rolNombre.toLowerCase()) {
      case 'admin':
        return const Color(0xFFFF2D55); // Rosa Apple
      case 'funcionario':
        return const Color(0xFF007AFF); // Azul Apple
      case 'voluntario':
        return const Color(0xFF34C759); // Verde Apple
      default:
        return const Color(0xFF8E8E93); // Gris Apple
    }
  }
}
