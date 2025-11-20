import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/models/tarea.dart';
import '../../../core/models/asignacion_tarea.dart';
import 'package:intl/intl.dart';

class TareaDetailPage extends StatefulWidget {
  final int tareaId;
  final bool isFuncionario;

  const TareaDetailPage({
    super.key,
    required this.tareaId,
    this.isFuncionario = false,
  });

  @override
  State<TareaDetailPage> createState() => _TareaDetailPageState();
}

class _TareaDetailPageState extends State<TareaDetailPage> with SingleTickerProviderStateMixin {
  Tarea? _tarea;
  List<AsignacionTarea> _asignaciones = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.isFuncionario) {
        final funcionarioRepo = Modular.get<FuncionarioRepository>();
        final tarea = await funcionarioRepo.getTareaById(widget.tareaId);
        // Cargar asignaciones si es funcionario
        try {
          final asignaciones = await funcionarioRepo.getAsignacionesByTarea(widget.tareaId);
          setState(() {
            _asignaciones = asignaciones;
          });
        } catch (e) {
          // Si falla, continuar sin asignaciones
        }
        setState(() {
          _tarea = tarea;
          _isLoading = false;
        });
      } else {
        final voluntarioRepo = Modular.get<VoluntarioRepository>();
        final tarea = await voluntarioRepo.getTareaById(widget.tareaId);
        setState(() {
          _tarea = tarea;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getPrioridadColor(String? prioridad) {
    switch (prioridad?.toLowerCase()) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baja':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.grey;
      case 'en_progreso':
        return Colors.blue;
      case 'completada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Icons.radio_button_unchecked;
      case 'en_progreso':
        return Icons.pending;
      case 'completada':
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _editField(String field, dynamic currentValue) async {
    if (!widget.isFuncionario) return;

    dynamic newValue;

    switch (field) {
      case 'nombre':
        final controller = TextEditingController(text: currentValue as String?);
        newValue = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Editar Nombre'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
        break;

      case 'descripcion':
        final controller = TextEditingController(text: currentValue as String?);
        newValue = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Editar Descripción'),
            content: TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
        break;

      case 'prioridad':
        newValue = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cambiar Prioridad'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.red),
                  title: const Text('Alta'),
                  onTap: () => Navigator.pop(context, 'alta'),
                ),
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.orange),
                  title: const Text('Media'),
                  onTap: () => Navigator.pop(context, 'media'),
                ),
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.blue),
                  title: const Text('Baja'),
                  onTap: () => Navigator.pop(context, 'baja'),
                ),
              ],
            ),
          ),
        );
        break;

      case 'estado':
        newValue = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cambiar Estado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                  title: const Text('Pendiente'),
                  onTap: () => Navigator.pop(context, 'pendiente'),
                ),
                ListTile(
                  leading: const Icon(Icons.pending, color: Colors.blue),
                  title: const Text('En Progreso'),
                  onTap: () => Navigator.pop(context, 'en_progreso'),
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Completada'),
                  onTap: () => Navigator.pop(context, 'completada'),
                ),
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.red),
                  title: const Text('Cancelada'),
                  onTap: () => Navigator.pop(context, 'cancelada'),
                ),
              ],
            ),
          ),
        );
        break;

      case 'fecha_inicio':
      case 'fecha_fin':
        final initialDate = currentValue as DateTime?;
        newValue = await showDatePicker(
          context: context,
          initialDate: initialDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        break;
    }

    if (newValue != null && newValue != currentValue) {
      await _updateTarea(field, newValue);
    }
  }

  Future<void> _updateTarea(String field, dynamic value) async {
    try {
      final data = <String, dynamic>{};
      
      if (field == 'fecha_inicio' || field == 'fecha_fin') {
        final date = value as DateTime;
        data[field] = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } else {
        data[field] = value;
      }

      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      await funcionarioRepo.updateTarea(widget.tareaId, data);
      
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Tarea'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Detalles'),
            Tab(icon: Icon(Icons.timeline), text: 'Actividad'),
          ],
        ),
        actions: [
          if (widget.isFuncionario)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Menú de opciones
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _tarea == null
                  ? const Center(child: Text('Tarea no encontrada'))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDetailsTab(),
                        _buildActivityTab(),
                      ],
                    ),
    );
  }

  Widget _buildDetailsTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre de la tarea
          _buildEditableSection(
            icon: Icons.task,
            title: 'Nombre',
            child: Text(
              _tarea!.nombre,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            onEdit: widget.isFuncionario
                ? () => _editField('nombre', _tarea!.nombre)
                : null,
          ),

          const SizedBox(height: 24),

          // Estado
          _buildEditableSection(
            icon: Icons.info_outline,
            title: 'Estado',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _getEstadoColor(_tarea!.estado).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getEstadoColor(_tarea!.estado),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getEstadoIcon(_tarea!.estado),
                    color: _getEstadoColor(_tarea!.estado),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _tarea!.estado.toUpperCase(),
                    style: TextStyle(
                      color: _getEstadoColor(_tarea!.estado),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            onEdit: widget.isFuncionario
                ? () => _editField('estado', _tarea!.estado)
                : null,
          ),

          const SizedBox(height: 24),

          // Prioridad
          if (_tarea!.prioridad != null)
            _buildEditableSection(
              icon: Icons.flag,
              title: 'Prioridad',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _getPrioridadColor(_tarea!.prioridad).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag,
                      color: _getPrioridadColor(_tarea!.prioridad),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _tarea!.prioridad!.toUpperCase(),
                      style: TextStyle(
                        color: _getPrioridadColor(_tarea!.prioridad),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              onEdit: widget.isFuncionario
                  ? () => _editField('prioridad', _tarea!.prioridad)
                  : null,
            ),

          const SizedBox(height: 24),

          // Fechas
          Row(
            children: [
              Expanded(
                child: _buildEditableSection(
                  icon: Icons.calendar_today,
                  title: 'Fecha Inicio',
                  child: Text(
                    _tarea!.fechaInicio != null
                        ? DateFormat('dd MMM yyyy').format(_tarea!.fechaInicio!)
                        : 'No establecida',
                    style: theme.textTheme.bodyLarge,
                  ),
                  onEdit: widget.isFuncionario
                      ? () => _editField('fecha_inicio', _tarea!.fechaInicio)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEditableSection(
                  icon: Icons.event,
                  title: 'Fecha Fin',
                  child: Text(
                    _tarea!.fechaFin != null
                        ? DateFormat('dd MMM yyyy').format(_tarea!.fechaFin!)
                        : 'No establecida',
                    style: theme.textTheme.bodyLarge,
                  ),
                  onEdit: widget.isFuncionario
                      ? () => _editField('fecha_fin', _tarea!.fechaFin)
                      : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Descripción
          _buildEditableSection(
            icon: Icons.description,
            title: 'Descripción',
            child: Text(
              _tarea!.descripcion?.isNotEmpty == true
                  ? _tarea!.descripcion!
                  : 'Sin descripción',
              style: theme.textTheme.bodyLarge,
            ),
            onEdit: widget.isFuncionario
                ? () => _editField('descripcion', _tarea!.descripcion ?? '')
                : null,
          ),

          const SizedBox(height: 24),

          // Proyecto
          if (_tarea!.proyecto != null)
            _buildInfoSection(
              icon: Icons.folder,
              title: 'Proyecto',
              child: Text(
                _tarea!.proyecto!['nombre']?.toString() ?? 'Sin nombre',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Asignaciones (solo para funcionarios)
          if (widget.isFuncionario) ...[
            _buildInfoSection(
              icon: Icons.people,
              title: 'Voluntarios Asignados',
              child: _asignaciones.isEmpty
                  ? Text(
                      'No hay voluntarios asignados',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Column(
                      children: _asignaciones.map((asignacion) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                asignacion.perfilVoluntario?['usuario']?['nombres']
                                        ?.toString()
                                        .substring(0, 1)
                                        .toUpperCase() ??
                                    'V',
                              ),
                            ),
                            title: Text(
                              '${asignacion.perfilVoluntario?['usuario']?['nombres'] ?? ''} ${asignacion.perfilVoluntario?['usuario']?['apellidos'] ?? ''}',
                            ),
                            subtitle: Text(asignacion.estado),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getEstadoColor(asignacion.estado)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                asignacion.estado,
                                style: TextStyle(
                                  color: _getEstadoColor(asignacion.estado),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 24),
          ],

          // Metadatos
          _buildInfoSection(
            icon: Icons.access_time,
            title: 'Información',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_circle_outline, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Creada: ${DateFormat('dd MMM yyyy, HH:mm').format(_tarea!.creadoEn)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.update, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Actualizada: ${_tarea!.actualizadoEn != null ? DateFormat('dd MMM yyyy, HH:mm').format(_tarea!.actualizadoEn!) : 'N/A'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Historial de Actividad',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Próximamente',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableSection({
    required IconData icon,
    required String title,
    required Widget child,
    VoidCallback? onEdit,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: onEdit,
                  tooltip: 'Editar',
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
