import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/models/usuario.dart';
import '../../../core/models/rol.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_widgets.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class UsuariosManagementPage extends StatefulWidget {
  const UsuariosManagementPage({super.key});

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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Modular.to.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
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
            children: [
              // Barra de búsqueda y filtros
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingMedium),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar por email o nombre...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppStyles.borderRadiusMedium,
                          ),
                        ),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: AppStyles.spacingSmall),
                    Row(
                      children: [
                        const Text('Filtrar por rol:'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<int?>(
                            value: _selectedRolFilter,
                            isExpanded: true,
                            hint: const Text('Todos los roles'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Todos'),
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
                      ],
                    ),
                  ],
                ),
              ),

              // Lista de usuarios
              Expanded(
                child: filteredUsuarios.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: Colors.blue.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No se encontraron usuarios',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadData(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppStyles.spacingMedium),
                          itemCount: filteredUsuarios.length,
                          itemBuilder: (context, index) {
                            final usuario = filteredUsuarios[index];
                            return _buildUsuarioCard(usuario);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        icon: const Icon(Icons.add),
        label: const Text('Crear Usuario'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildUsuarioCard(Usuario usuario) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingMedium),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            usuario.nombres[0].toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text('${usuario.nombres} ${usuario.apellidos}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(usuario.email),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRolColor(usuario.rol?.nombre ?? 'Sin rol'),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                usuario.rol?.nombre ?? 'Sin rol',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
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
            const PopupMenuItem<String>(
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
        ),
      ),
    );
  }

  Color _getRolColor(String rolNombre) {
    switch (rolNombre.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'funcionario':
        return Colors.blue;
      case 'voluntario':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
