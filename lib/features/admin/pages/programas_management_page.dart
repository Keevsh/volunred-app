import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/programa.dart';
import '../../../core/models/aplicacion.dart';
import '../../../core/models/modulo.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class ProgramasManagementPage extends StatefulWidget {
  const ProgramasManagementPage({super.key});

  @override
  State<ProgramasManagementPage> createState() =>
      _ProgramasManagementPageState();
}

class _ProgramasManagementPageState extends State<ProgramasManagementPage> {
  String _selectedView = 'programas'; // 'programas', 'aplicaciones', 'modulos'
  List<Programa> _programas = [];
  List<Aplicacion> _aplicaciones = [];
  List<Modulo> _modulos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final bloc = BlocProvider.of<AdminBloc>(context);
    // Cargar todos los datos siempre
    bloc.add(LoadProgramasRequested());
    bloc.add(LoadAplicacionesRequested());
    bloc.add(LoadModulosRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        // Guardar datos cuando lleguen
        if (state is ProgramasLoaded) {
          setState(() {
            _programas = state.programas;
          });
        }
        if (state is AplicacionesLoaded) {
          setState(() {
            _aplicaciones = state.aplicaciones;
          });
        }
        if (state is ModulosLoaded) {
          setState(() {
            _modulos = state.modulos;
          });
        }

        if (state is ProgramaCreated ||
            state is ProgramaUpdated ||
            state is ProgramaDeleted) {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state is ProgramaCreated
                    ? 'Programa creado'
                    : state is ProgramaUpdated
                    ? 'Programa actualizado'
                    : 'Programa eliminado',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (state is AplicacionCreated ||
            state is AplicacionUpdated ||
            state is AplicacionDeleted) {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state is AplicacionCreated
                    ? 'Aplicación creada'
                    : state is AplicacionUpdated
                    ? 'Aplicación actualizada'
                    : 'Aplicación eliminada',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (state is ModuloUpdated) {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Módulo actualizado'),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (state is AdminError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateDialog,
          backgroundColor: const Color(0xFF007AFF),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header simple estilo Apple
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
                        'Programas',
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

              // Tabs de selección
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton('Programas', 'programas'),
                      _buildTabButton('Aplicaciones', 'aplicaciones'),
                      _buildTabButton('Módulos', 'modulos'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Contenido dinámico según la pestaña
              Expanded(
                child: BlocBuilder<AdminBloc, AdminState>(
                  builder: (context, state) {
                    if (state is AdminLoading && _programas.isEmpty && _aplicaciones.isEmpty && _modulos.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (_selectedView == 'programas') {
                      if (_programas.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildProgramasList(_programas);
                    }

                    if (_selectedView == 'aplicaciones') {
                      if (_aplicaciones.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildAplicacionesList(_aplicaciones);
                    }

                    if (_selectedView == 'modulos') {
                      if (_modulos.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildModulosList(_modulos);
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

  void _showCreateDialog() {
    if (_selectedView == 'programas') {
      _showCreateProgramaDialog();
    } else if (_selectedView == 'aplicaciones') {
      _showCreateAplicacionDialog();
    }
    // Los módulos no se pueden crear desde aquí según la API
  }

  void _showCreateProgramaDialog() {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    int? selectedAplicacionId;
    final bloc = context.read<AdminBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: BlocBuilder<AdminBloc, AdminState>(
            builder: (dialogContext, state) {
              List<Aplicacion> aplicaciones = [];
              if (state is AplicacionesLoaded) {
                aplicaciones = state.aplicaciones;
              } else {
                dialogContext.read<AdminBloc>().add(
                  LoadAplicacionesRequested(),
                );
              }

              return AlertDialog(
                title: const Text('Nuevo Programa'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
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
                          labelText: 'Aplicación',
                          border: OutlineInputBorder(),
                        ),
                        items: aplicaciones.map((a) {
                          return DropdownMenuItem<int>(
                            value: a.idAplicacion,
                            child: Text(a.nombre),
                          );
                        }).toList(),
                        onChanged: (value) => selectedAplicacionId = value,
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
                          selectedAplicacionId != null) {
                        dialogContext.read<AdminBloc>().add(
                          CreateProgramaRequested(
                            nombre: nombreController.text,
                            descripcion: descripcionController.text.isEmpty
                                ? null
                                : descripcionController.text,
                            idAplicacion: selectedAplicacionId!,
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

  void _showCreateAplicacionDialog() {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    int? selectedModuloId;
    final bloc = context.read<AdminBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: BlocBuilder<AdminBloc, AdminState>(
            builder: (dialogContext, state) {
              List<Modulo> modulos = [];
              if (state is ModulosLoaded) {
                modulos = state.modulos;
              } else {
                dialogContext.read<AdminBloc>().add(LoadModulosRequested());
              }

              return AlertDialog(
                title: const Text('Nueva Aplicación'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
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
                          labelText: 'Módulo',
                          border: OutlineInputBorder(),
                        ),
                        items: modulos.map((m) {
                          return DropdownMenuItem<int>(
                            value: m.idModulo,
                            child: Text(m.nombre),
                          );
                        }).toList(),
                        onChanged: (value) => selectedModuloId = value,
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
                          selectedModuloId != null) {
                        dialogContext.read<AdminBloc>().add(
                          CreateAplicacionRequested(
                            nombre: nombreController.text,
                            idModulo: selectedModuloId!,
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

  Widget _buildTabButton(String label, String value) {
    final isSelected = _selectedView == value;
    return Expanded(
      child: Material(
        color: isSelected ? const Color(0xFF5856D6) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedView = value;
            });
            _loadData();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF86868B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgramasList(List<Programa> programas) {
    if (programas.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: programas.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final programa = programas[index];
        return _buildProgramaCard(programa);
      },
    );
  }

  Widget _buildProgramaCard(Programa programa) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showEditProgramaDialog(programa),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF5856D6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.extension_rounded,
                  color: Color(0xFF5856D6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      programa.nombre,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (programa.descripcion != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        programa.descripcion!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF86868B),
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
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
                        Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditProgramaDialog(programa);
                  } else if (value == 'delete') {
                    _confirmDeletePrograma(programa);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProgramaDialog(Programa programa) {
    final nombreController = TextEditingController(text: programa.nombre);
    final descripcionController = TextEditingController(
      text: programa.descripcion ?? '',
    );
    int? selectedAplicacionId = programa.idAplicacion;

    final bloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: BlocBuilder<AdminBloc, AdminState>(
            builder: (dialogContext, state) {
              List<Aplicacion> aplicaciones = [];
              if (state is AplicacionesLoaded) {
                aplicaciones = state.aplicaciones;
              } else {
                dialogContext.read<AdminBloc>().add(
                  LoadAplicacionesRequested(),
                );
              }

              return AlertDialog(
                title: const Text('Editar Programa'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
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
                          labelText: 'Aplicación',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedAplicacionId,
                        items: aplicaciones.map((a) {
                          return DropdownMenuItem<int>(
                            value: a.idAplicacion,
                            child: Text(a.nombre),
                          );
                        }).toList(),
                        onChanged: (value) => selectedAplicacionId = value,
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
                          selectedAplicacionId != null) {
                        dialogContext.read<AdminBloc>().add(
                          UpdateProgramaRequested(
                            id: programa.idPrograma,
                            nombre: nombreController.text,
                            descripcion: descripcionController.text.isEmpty
                                ? null
                                : descripcionController.text,
                            idAplicacion: selectedAplicacionId!,
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

  void _confirmDeletePrograma(Programa programa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Programa'),
        content: Text(
          '¿Está seguro que desea eliminar el programa "${programa.nombre}"?',
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
                DeleteProgramaRequested(programa.idPrograma),
              );
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAplicacionesList(List<Aplicacion> aplicaciones) {
    if (aplicaciones.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: aplicaciones.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final aplicacion = aplicaciones[index];
        return _buildAplicacionCard(aplicacion);
      },
    );
  }

  Widget _buildAplicacionCard(Aplicacion aplicacion) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showEditAplicacionDialog(aplicacion),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.widgets_rounded,
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
                      aplicacion.nombre,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      aplicacion.modulo?.nombre ?? 'Sin módulo',
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: aplicacion.estado == 'activo'
                      ? const Color(0xFF34C759).withOpacity(0.1)
                      : const Color(0xFF8E8E93).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  aplicacion.estado == 'activo' ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: aplicacion.estado == 'activo'
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
                    _showEditAplicacionDialog(aplicacion);
                  } else if (value == 'delete') {
                    _confirmDeleteAplicacion(aplicacion);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditAplicacionDialog(Aplicacion aplicacion) {
    final nombreController = TextEditingController(text: aplicacion.nombre);
    final descripcionController = TextEditingController(
      text: aplicacion.descripcion ?? '',
    );
    int? selectedModuloId = aplicacion.idModulo;

    final bloc = context.read<AdminBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: bloc,
          child: BlocBuilder<AdminBloc, AdminState>(
            builder: (dialogContext, state) {
              List<Modulo> modulos = [];
              if (state is ModulosLoaded) {
                modulos = state.modulos;
              } else {
                dialogContext.read<AdminBloc>().add(LoadModulosRequested());
              }

              return AlertDialog(
                title: const Text('Editar Aplicación'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
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
                          labelText: 'Módulo',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedModuloId,
                        items: modulos.map((m) {
                          return DropdownMenuItem<int>(
                            value: m.idModulo,
                            child: Text(m.nombre),
                          );
                        }).toList(),
                        onChanged: (value) => selectedModuloId = value,
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
                          selectedModuloId != null) {
                        context.read<AdminBloc>().add(
                          UpdateAplicacionRequested(
                            id: aplicacion.idAplicacion,
                            nombre: nombreController.text,
                            descripcion: descripcionController.text.isEmpty
                                ? null
                                : descripcionController.text,
                            idModulo: selectedModuloId!,
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
          ),
        );
      },
    );
  }

  void _confirmDeleteAplicacion(Aplicacion aplicacion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Aplicación'),
        content: Text(
          '¿Está seguro que desea eliminar la aplicación "${aplicacion.nombre}"?',
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
                DeleteAplicacionRequested(aplicacion.idAplicacion),
              );
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildModulosList(List<Modulo> modulos) {
    if (modulos.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: modulos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final modulo = modulos[index];
        return _buildModuloCard(modulo);
      },
    );
  }

  Widget _buildModuloCard(Modulo modulo) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showEditModuloDialog(modulo),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modulo.nombre,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (modulo.descripcion != null &&
                        modulo.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        modulo.descripcion!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF86868B),
                          fontWeight: FontWeight.w400,
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
                  color: modulo.estado == 'activo'
                      ? const Color(0xFF34C759).withOpacity(0.1)
                      : const Color(0xFF8E8E93).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  modulo.estado == 'activo' ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: modulo.estado == 'activo'
                        ? const Color(0xFF34C759)
                        : const Color(0xFF8E8E93),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Color(0xFF86868B)),
                onPressed: () => _showEditModuloDialog(modulo),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditModuloDialog(Modulo modulo) {
    final nombreController = TextEditingController(text: modulo.nombre);
    final descripcionController = TextEditingController(
      text: modulo.descripcion ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Módulo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
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
              if (nombreController.text.isNotEmpty) {
                context.read<AdminBloc>().add(
                  UpdateModuloRequested(
                    id: modulo.idModulo,
                    nombre: nombreController.text,
                    descripcion: descripcionController.text.isEmpty
                        ? null
                        : descripcionController.text,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
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
              Icons.apps_rounded,
              size: 64,
              color: Color(0xFF5856D6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay elementos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los elementos aparecerán aquí',
            style: TextStyle(fontSize: 15, color: Color(0xFF86868B)),
          ),
        ],
      ),
    );
  }
}
