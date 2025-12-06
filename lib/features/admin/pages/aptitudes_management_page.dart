import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/aptitud.dart';
import '../../../core/theme/app_widgets.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';
import 'create_aptitud_page.dart';
import 'edit_aptitud_page.dart';

class AptitudesManagementPage extends StatefulWidget {
  final bool embedded;
  
  const AptitudesManagementPage({super.key, this.embedded = false});

  @override
  State<AptitudesManagementPage> createState() =>
      _AptitudesManagementPageState();
}

class _AptitudesManagementPageState extends State<AptitudesManagementPage> {
  @override
  void initState() {
    super.initState();
    _loadAptitudes();
  }

  void _loadAptitudes() {
    BlocProvider.of<AdminBloc>(context).add(LoadAptitudesRequested());
  }

  Future<void> _navigateToCreatePage() async {
    final adminBloc = context.read<AdminBloc>();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: adminBloc,
          child: const CreateAptitudPage(),
        ),
      ),
    );

    if (result == true) {
      _loadAptitudes();
    }
  }

  Future<void> _navigateToEditPage(Aptitud aptitud) async {
    final adminBloc = context.read<AdminBloc>();
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: adminBloc,
          child: EditAptitudPage(aptitud: aptitud),
        ),
      ),
    );

    if (result == true) {
      _loadAptitudes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePage,
        backgroundColor: const Color(0xFF007AFF),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: BlocConsumer<AdminBloc, AdminState>(
          listener: (context, state) {
            if (state is AptitudDeleted) {
              AppWidgets.showStyledSnackBar(
                context: context,
                message: state.message,
                isError: false,
              );
              _loadAptitudes();
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

            if (state is AptitudesLoaded) {
              return Column(
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
                              'Aptitudes',
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
                              onTap: _loadAptitudes,
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

                  if (state.aptitudes.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                size: 64,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No hay aptitudes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D1D1F),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Presiona + para crear la primera',
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
                        itemCount: state.aptitudes.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final aptitud = state.aptitudes[index];
                          return _buildAptitudCard(aptitud);
                        },
                      ),
                    ),
                ],
              );
            }

            return const Center(child: Text('Cargando aptitudes...'));
          },
        ),
      ),
    );
  }

  Widget _buildAptitudCard(Aptitud aptitud) {
    final isActivo = aptitud.estado == 'activo';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _navigateToEditPage(aptitud),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono circular
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: isActivo
                      ? const Color(0xFF1D1D1F)
                      : const Color(0xFF8E8E93),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aptitud.nombre,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (aptitud.descripcion != null &&
                        aptitud.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        aptitud.descripcion!,
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
              // Badge de estado
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActivo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActivo
                        ? const Color(0xFF1D1D1F)
                        : const Color(0xFF8E8E93),
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
                      _navigateToEditPage(aptitud);
                      break;
                    case 'toggle':
                      _toggleAptitudEstado(aptitud);
                      break;
                    case 'delete':
                      _confirmDelete(aptitud);
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
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          isActivo ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(isActivo ? 'Desactivar' : 'Activar'),
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

  void _toggleAptitudEstado(Aptitud aptitud) {
    final nuevoEstado = aptitud.estado == 'activo' ? 'inactivo' : 'activo';
    final accion = nuevoEstado == 'activo' ? 'activar' : 'desactivar';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${accion.substring(0, 1).toUpperCase()}${accion.substring(1)} Aptitud',
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Color(0xFF1D1D1F)),
            children: [
              TextSpan(text: '¿Está seguro que desea $accion la aptitud '),
              TextSpan(
                text: '"${aptitud.nombre}"',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
            ),
            onPressed: () {
              BlocProvider.of<AdminBloc>(context).add(
                UpdateAptitudRequested(
                  id: aptitud.idAptitud,
                  estado: nuevoEstado,
                ),
              );
              Navigator.pop(context);
            },
            child: Text(
              accion.substring(0, 1).toUpperCase() + accion.substring(1),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Aptitud aptitud) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Aptitud'),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Color(0xFF1D1D1F)),
            children: [
              const TextSpan(
                text: '¿Está seguro que desea eliminar la aptitud ',
              ),
              TextSpan(
                text: '"${aptitud.nombre}"',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: '?\n\n'),
              const TextSpan(
                text:
                    'Esta acción no se puede deshacer y afectará a todos los voluntarios que tengan esta aptitud asignada.',
                style: TextStyle(color: Color(0xFF86868B), fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              BlocProvider.of<AdminBloc>(
                context,
              ).add(DeleteAptitudRequested(aptitud.idAptitud));
              Navigator.of(dialogContext).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
