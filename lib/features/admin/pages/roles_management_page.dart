import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/rol.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';
import 'create_rol_page.dart';
import 'edit_rol_page.dart';

class RolesManagementPage extends StatefulWidget {
  final bool embedded;
  
  const RolesManagementPage({super.key, this.embedded = false});

  @override
  State<RolesManagementPage> createState() => _RolesManagementPageState();
}

class _RolesManagementPageState extends State<RolesManagementPage> {
  List<Rol> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() => _isLoading = true);
    context.read<AdminBloc>().add(LoadRolesRequested());
  }

  Future<void> _navigateToCreatePage() async {
    final adminBloc = context.read<AdminBloc>();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            BlocProvider.value(value: adminBloc, child: const CreateRolPage()),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _navigateToEditPage(Rol rol) async {
    final adminBloc = context.read<AdminBloc>();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: adminBloc,
          child: EditRolPage(rol: rol),
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _confirmDelete(Rol rol) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Rol'),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Color(0xFF1D1D1F)),
            children: [
              const TextSpan(text: '¿Está seguro que desea eliminar el rol '),
              TextSpan(
                text: '"${rol.nombre}"',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: '?\n\n'),
              const TextSpan(
                text: 'Esta acción no se puede deshacer.',
                style: TextStyle(color: Color(0xFF86868B), fontSize: 14),
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<AdminBloc>().add(DeleteRolRequested(rol.idRol));
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePage,
        backgroundColor: const Color(0xFF007AFF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocListener<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is RolDeleted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Rol eliminado')));
            _loadData();
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
                          'Roles',
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
              Expanded(
                child: BlocConsumer<AdminBloc, AdminState>(
                  listener: (context, state) {
                    if (state is RolesLoaded) {
                      setState(() {
                        _roles = state.roles;
                        _isLoading = false;
                      });
                    }
                  },
                  builder: (context, state) {
                    if (_isLoading && _roles.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (_roles.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildRolesList(_roles);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRolesList(List<Rol> roles) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: roles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildRolCard(roles[index]),
    );
  }

  Widget _buildRolCard(Rol rol) {
    final permisosCount = rol.permisos?.length ?? rol.cantidadPermisos ?? 0;

    // Agrupar permisos por módulo
    Map<String, List<Map<String, dynamic>>> permisosPorModulo = {};
    if (rol.permisos != null) {
      for (var permiso in rol.permisos!) {
        final modulo =
            permiso['programa']?['aplicacion']?['modulo']?['nombre'] ??
            'Sin módulo';
        if (!permisosPorModulo.containsKey(modulo)) {
          permisosPorModulo[modulo] = [];
        }
        permisosPorModulo[modulo]!.add(permiso);
      }
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Color(0xFF8E8E93),
              size: 24,
            ),
          ),
          title: Text(
            rol.nombre,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (rol.descripcion != null && rol.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  rol.descripcion!,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF86868B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$permisosCount permisos',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF86868B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton(
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
              switch (value) {
                case 'edit':
                  _navigateToEditPage(rol);
                  break;
                case 'delete':
                  _confirmDelete(rol);
                  break;
              }
            },
          ),
          children: [
            if (rol.permisos != null && rol.permisos!.isNotEmpty) ...[
              const Divider(height: 1),
              const SizedBox(height: 12),
              ...permisosPorModulo.entries.map((entry) {
                final moduloNombre = entry.key;
                final permisosDelModulo = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 8,
                        bottom: 8,
                        top: 8,
                      ),
                      child: Text(
                        moduloNombre.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF86868B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...permisosDelModulo.map((permiso) {
                      final programa = permiso['programa'];
                      final programaNombre =
                          programa?['nombre'] ?? 'Sin nombre';
                      final programaDescripcion =
                          programa?['descripcion'] ?? '';
                      final aplicacionNombre =
                          programa?['aplicacion']?['nombre'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 8,
                              color: Color(0xFF8E8E93),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    programaNombre,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1D1D1F),
                                    ),
                                  ),
                                  if (programaDescripcion.isNotEmpty)
                                    Text(
                                      programaDescripcion,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF86868B),
                                      ),
                                    ),
                                  if (aplicacionNombre.isNotEmpty)
                                    Text(
                                      aplicacionNombre,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFAAAAAA),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                );
              }).toList(),
            ] else ...[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No hay permisos asignados',
                    style: TextStyle(color: Color(0xFF86868B), fontSize: 14),
                  ),
                ),
              ),
            ],
          ],
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Color(0xFF8E8E93),
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay roles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los roles aparecerán aquí',
            style: TextStyle(fontSize: 15, color: Color(0xFF86868B)),
          ),
        ],
      ),
    );
  }
}
