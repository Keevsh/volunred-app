import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/aptitud.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_widgets.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AptitudesManagementPage extends StatefulWidget {
  const AptitudesManagementPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Gestión de Aptitudes'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAptitudes,
            tooltip: 'Recargar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAptitudDialog(),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Aptitud'),
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is AptitudCreated) {
            AppWidgets.showStyledSnackBar(
              context: context,
              message: 'Aptitud "${state.aptitud.nombre}" creada exitosamente',
              isError: false,
            );
            _loadAptitudes();
          } else if (state is AptitudUpdated) {
            AppWidgets.showStyledSnackBar(
              context: context,
              message: 'Aptitud "${state.aptitud.nombre}" actualizada',
              isError: false,
            );
            _loadAptitudes();
          } else if (state is AptitudDeleted) {
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
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is AptitudesLoaded) {
            if (state.aptitudes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: AppStyles.spacingMedium),
                    Text(
                      'No hay aptitudes registradas',
                      style: TextStyle(
                        fontSize: AppStyles.fontSizeBody,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacingMedium),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateAptitudDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear Primera Aptitud'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadAptitudes(),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppStyles.spacingMedium),
                itemCount: state.aptitudes.length,
                itemBuilder: (context, index) {
                  final aptitud = state.aptitudes[index];
                  return _buildAptitudCard(aptitud);
                },
              ),
            );
          }

          return const Center(
            child: Text('Cargando aptitudes...'),
          );
        },
      ),
    );
  }

  Widget _buildAptitudCard(Aptitud aptitud) {
    final isActivo = aptitud.estado == 'activo';

    return Card(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingMedium),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
        side: BorderSide(
          color: isActivo ? Colors.teal.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacingMedium,
          vertical: AppStyles.spacingSmall,
        ),
        leading: Container(
          padding: const EdgeInsets.all(AppStyles.spacingSmall),
          decoration: BoxDecoration(
            color: isActivo ? Colors.teal.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusSmall),
          ),
          child: Icon(
            Icons.emoji_events,
            color: isActivo ? Colors.teal : Colors.grey,
            size: 24,
          ),
        ),
        title: Text(
          aptitud.nombre,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: AppStyles.fontSizeBody,
            color: isActivo ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (aptitud.descripcion != null &&
                aptitud.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                aptitud.descripcion!,
                style: TextStyle(
                  fontSize: AppStyles.fontSizeSmall,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isActivo
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActivo ? 'Activo' : 'Inactivo',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isActivo ? Colors.green.shade700 : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditAptitudDialog(aptitud);
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
      ),
    );
  }

  void _showCreateAptitudDialog() {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nueva Aptitud'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej: Trabajo en equipo',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppStyles.spacingMedium),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Describe la aptitud',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nombre = nombreController.text.trim();
              if (nombre.isEmpty) {
                AppWidgets.showStyledSnackBar(
                  context: context,
                  message: 'El nombre es obligatorio',
                  isError: true,
                );
                return;
              }

              BlocProvider.of<AdminBloc>(context).add(
                    CreateAptitudRequested(
                      nombre: nombre,
                      descripcion: descripcionController.text.trim().isEmpty
                          ? null
                          : descripcionController.text.trim(),
                    ),
                  );

              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showEditAptitudDialog(Aptitud aptitud) {
    final nombreController = TextEditingController(text: aptitud.nombre);
    final descripcionController =
        TextEditingController(text: aptitud.descripcion ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Aptitud'),
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
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppStyles.spacingMedium),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nombre = nombreController.text.trim();
              if (nombre.isEmpty) {
                AppWidgets.showStyledSnackBar(
                  context: context,
                  message: 'El nombre es obligatorio',
                  isError: true,
                );
                return;
              }

              BlocProvider.of<AdminBloc>(context).add(
                    UpdateAptitudRequested(
                      id: aptitud.idAptitud,
                      nombre: nombre,
                      descripcion: descripcionController.text.trim().isEmpty
                          ? null
                          : descripcionController.text.trim(),
                    ),
                  );

              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _toggleAptitudEstado(Aptitud aptitud) {
    final nuevoEstado = aptitud.estado == 'activo' ? 'inactivo' : 'activo';

    BlocProvider.of<AdminBloc>(context).add(
          UpdateAptitudRequested(
            id: aptitud.idAptitud,
            estado: nuevoEstado,
          ),
        );
  }

  void _confirmDelete(Aptitud aptitud) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de eliminar la aptitud "${aptitud.nombre}"?\n\n'
          'Esta acción no se puede deshacer y afectará a todos los voluntarios que tengan esta aptitud asignada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              BlocProvider.of<AdminBloc>(context).add(
                    DeleteAptitudRequested(aptitud.idAptitud),
                  );
              Navigator.of(dialogContext).pop();
            },
            style: ElevatedButton.styleFrom(
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
