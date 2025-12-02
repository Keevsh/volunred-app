import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/programa.dart';
import '../../../core/models/aplicacion.dart';
import '../../../core/models/modulo.dart';
import '../../../core/models/rol.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class PermisosManagementPage extends StatefulWidget {
  const PermisosManagementPage({super.key});

  @override
  State<PermisosManagementPage> createState() => _PermisosManagementPageState();
}

class _PermisosManagementPageState extends State<PermisosManagementPage> {
  Rol? _selectedRol;
  final Map<int, bool> _selectedProgramas = {};
  bool _isLoading = false;

  // Datos almacenados localmente
  List<Rol> _roles = [];
  List<Modulo> _modulos = [];
  List<Aplicacion> _aplicaciones = [];
  List<Programa> _programas = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<AdminBloc>().add(LoadRolesRequested());
    context.read<AdminBloc>().add(LoadModulosRequested());
    context.read<AdminBloc>().add(LoadAplicacionesRequested());
    context.read<AdminBloc>().add(LoadProgramasRequested());
  }

  void _selectRol(Rol rol) {
    setState(() {
      _selectedRol = rol;
      _selectedProgramas.clear();
    });
    // Cargar permisos del rol seleccionado
    context.read<AdminBloc>().add(LoadPermisosByRolRequested(rol.idRol));
  }

  void _togglePrograma(int programaId) {
    setState(() {
      _selectedProgramas[programaId] =
          !(_selectedProgramas[programaId] ?? false);
    });
  }

  Future<void> _asignarPermisos() async {
    if (_selectedRol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un rol primero')),
      );
      return;
    }

    final programasSeleccionados = _selectedProgramas.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (programasSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un programa')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    context.read<AdminBloc>().add(
      AsignarPermisosRequested(
        idRol: _selectedRol!.idRol,
        programas: programasSeleccionados,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: BlocListener<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is RolesLoaded) {
            setState(() {
              _roles = state.roles;
            });
          }
          if (state is ModulosLoaded) {
            setState(() {
              _modulos = state.modulos;
            });
          }
          if (state is AplicacionesLoaded) {
            setState(() {
              _aplicaciones = state.aplicaciones;
            });
          }
          if (state is ProgramasLoaded) {
            setState(() {
              _programas = state.programas;
            });
          }
          if (state is PermisosAsignados) {
            setState(() {
              _isLoading = false;
              _selectedProgramas.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            if (_selectedRol != null) {
              context.read<AdminBloc>().add(
                LoadPermisosByRolRequested(_selectedRol!.idRol),
              );
            }
          }
          if (state is PermisosByRolLoaded) {
            setState(() {
              _isLoading = false;
              // Marcar los programas que ya tienen permisos
              _selectedProgramas.clear();
              for (var permiso in state.permisos) {
                final programaId = permiso.programa?.idPrograma;
                if (programaId != null) {
                  _selectedProgramas[programaId] = true;
                }
              }
            });
          }
          if (state is AdminError) {
            setState(() {
              _isLoading = false;
            });
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
                        'Permisos',
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

              // Selector de Rol
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _roles.isEmpty
                    ? const SizedBox.shrink()
                    : _buildRolSelector(_roles),
              ),

              const SizedBox(height: 16),

              // Lista de Módulos > Aplicaciones > Programas
              Expanded(
                child: _selectedRol == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9500).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.security_rounded,
                                size: 64,
                                color: Color(0xFFFF9500),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Selecciona un rol',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D1D1F),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Elige un rol para asignar permisos',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF86868B),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildPermisosTree(),
              ),

              // Botón de asignar
              if (_selectedRol != null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _asignarPermisos,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Asignar Permisos',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRolSelector(List<Rol> roles) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rol',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Rol>(
            value: _selectedRol,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: roles.map((rol) {
              return DropdownMenuItem<Rol>(value: rol, child: Text(rol.nombre));
            }).toList(),
            onChanged: (rol) {
              if (rol != null) {
                _selectRol(rol);
              }
            },
            hint: const Text('Selecciona un rol'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermisosTree() {
    // Si no tenemos datos, cargar
    if (_modulos.isEmpty || _aplicaciones.isEmpty || _programas.isEmpty) {
      final bloc = context.read<AdminBloc>();
      if (_modulos.isEmpty) {
        bloc.add(LoadModulosRequested());
      }
      if (_aplicaciones.isEmpty) {
        bloc.add(LoadAplicacionesRequested());
      }
      if (_programas.isEmpty) {
        bloc.add(LoadProgramasRequested());
      }
      return const Center(child: CircularProgressIndicator());
    }

    // Agrupar aplicaciones por módulo
    final aplicacionesPorModulo = <int, List<Aplicacion>>{};
    for (var aplicacion in _aplicaciones) {
      final moduloId = aplicacion.idModulo;
      if (!aplicacionesPorModulo.containsKey(moduloId)) {
        aplicacionesPorModulo[moduloId] = [];
      }
      aplicacionesPorModulo[moduloId]!.add(aplicacion);
    }

    // Agrupar programas por aplicación
    final programasPorAplicacion = <int, List<Programa>>{};
    for (var programa in _programas) {
      final aplicacionId = programa.idAplicacion;
      if (!programasPorAplicacion.containsKey(aplicacionId)) {
        programasPorAplicacion[aplicacionId] = [];
      }
      programasPorAplicacion[aplicacionId]!.add(programa);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: _modulos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final modulo = _modulos[index];
        final aplicacionesDelModulo =
            aplicacionesPorModulo[modulo.idModulo] ?? [];

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.dashboard_rounded,
                  color: Color(0xFF34C759),
                  size: 24,
                ),
              ),
              title: Text(
                modulo.nombre,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              subtitle:
                  modulo.descripcion != null && modulo.descripcion!.isNotEmpty
                  ? Text(
                      modulo.descripcion!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF86868B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              children: aplicacionesDelModulo.map((aplicacion) {
                final programasDeAplicacion =
                    programasPorAplicacion[aplicacion.idAplicacion] ?? [];

                return Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    childrenPadding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      bottom: 8,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.widgets_rounded,
                        color: Color(0xFF007AFF),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      aplicacion.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    children: programasDeAplicacion.map((programa) {
                      final isSelected =
                          _selectedProgramas[programa.idPrograma] ?? false;

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) =>
                            _togglePrograma(programa.idPrograma),
                        title: Text(
                          programa.nombre,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                        subtitle: programa.descripcion != null
                            ? Text(
                                programa.descripcion!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF86868B),
                                ),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
