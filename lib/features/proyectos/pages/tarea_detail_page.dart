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

class _TareaDetailPageState extends State<TareaDetailPage>
    with SingleTickerProviderStateMixin {
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
          final asignaciones = await funcionarioRepo.getAsignacionesByTarea(
            widget.tareaId,
          );
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
                  leading: const Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.grey,
                  ),
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
        data[field] =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } else {
        data[field] = value;
      }

      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      await funcionarioRepo.updateTarea(widget.tareaId, data);

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tarea actualizada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detalles de Tarea',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (widget.isFuncionario)
            Container(
              margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: FilledButton.icon(
                onPressed: () {
                  Modular.to
                      .pushNamed(
                        '/proyectos/tarea/${widget.tareaId}/asignar-voluntarios?nombre=${Uri.encodeComponent(_tarea?.nombre ?? 'Tarea')}',
                      )
                      .then((_) => _loadData());
                },
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Asignar'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Error al cargar la tarea',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _tarea == null
          ? const Center(child: Text('Tarea no encontrada'))
          : _buildDetailsTab(),
    );
  }

  Widget _buildDetailsTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card con nombre y badges
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre de la tarea
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _tarea!.nombre,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (widget.isFuncionario)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => _editField('nombre', _tarea!.nombre),
                          tooltip: 'Editar nombre',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Badges: Estado y Prioridad
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // Estado Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: widget.isFuncionario
                            ? () => _editField('estado', _tarea!.estado)
                            : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getEstadoIcon(_tarea!.estado),
                              color: _getEstadoColor(_tarea!.estado),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _tarea!.estado.toUpperCase(),
                              style: TextStyle(
                                color: _getEstadoColor(_tarea!.estado),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (widget.isFuncionario) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.edit,
                                size: 14,
                                color: _getEstadoColor(_tarea!.estado),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Prioridad Badge
                    if (_tarea!.prioridad != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: widget.isFuncionario
                              ? () => _editField('prioridad', _tarea!.prioridad)
                              : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flag,
                                color: _getPrioridadColor(_tarea!.prioridad),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Prioridad ${_tarea!.prioridad!.toUpperCase()}',
                                style: TextStyle(
                                  color: _getPrioridadColor(_tarea!.prioridad),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              if (widget.isFuncionario) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: _getPrioridadColor(_tarea!.prioridad),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Fechas en cards horizontales
          Row(
            children: [
              Expanded(
                child: _buildDateCard(
                  icon: Icons.calendar_today,
                  label: 'Inicio',
                  date: _tarea!.fechaInicio,
                  color: colorScheme.primary,
                  onEdit: widget.isFuncionario
                      ? () => _editField('fecha_inicio', _tarea!.fechaInicio)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateCard(
                  icon: Icons.event,
                  label: 'Fin',
                  date: _tarea!.fechaFin,
                  color: colorScheme.secondary,
                  onEdit: widget.isFuncionario
                      ? () => _editField('fecha_fin', _tarea!.fechaFin)
                      : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Descripción
          _buildModernSection(
            icon: Icons.description,
            title: 'Descripción',
            child: Text(
              _tarea!.descripcion?.isNotEmpty == true
                  ? _tarea!.descripcion!
                  : 'Sin descripción',
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: _tarea!.descripcion?.isNotEmpty == true
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            onEdit: widget.isFuncionario
                ? () => _editField('descripcion', _tarea!.descripcion ?? '')
                : null,
          ),

          const SizedBox(height: 16),

          // Proyecto
          if (_tarea!.proyecto != null)
            _buildModernSection(
              icon: Icons.folder_special,
              title: 'Proyecto',
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.folder,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _tarea!.proyecto!['nombre']?.toString() ?? 'Sin nombre',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Asignaciones (solo para funcionarios)
          if (widget.isFuncionario) ...[
            _buildModernSection(
              icon: Icons.people,
              title: 'Voluntarios Asignados (${_asignaciones.length})',
              child: _asignaciones.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                          style: BorderStyle.solid,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_add_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'No hay voluntarios asignados',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: _asignaciones.asMap().entries.map((entry) {
                        final asignacion = entry.value;
                        final isLast = entry.key == _asignaciones.length - 1;

                        return Container(
                          margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary.withOpacity(0.8),
                                      colorScheme.primary,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    asignacion
                                            .perfilVoluntario?['usuario']?['nombres']
                                            ?.toString()
                                            .substring(0, 1)
                                            .toUpperCase() ??
                                        'V',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${asignacion.perfilVoluntario?['usuario']?['nombres'] ?? ''} ${asignacion.perfilVoluntario?['usuario']?['apellidos'] ?? ''}',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      asignacion
                                              .perfilVoluntario?['usuario']?['email'] ??
                                          '',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getEstadoColor(
                                    asignacion.estado,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  asignacion.estado,
                                  style: TextStyle(
                                    color: _getEstadoColor(asignacion.estado),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),
          ],

          // Metadatos
          _buildModernSection(
            icon: Icons.info_outline,
            title: 'Información',
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.add_circle_outline,
                  label: 'Creada',
                  value: DateFormat(
                    'dd MMM yyyy, HH:mm',
                  ).format(_tarea!.creadoEn),
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.update,
                  label: 'Última actualización',
                  value: _tarea!.actualizadoEn != null
                      ? DateFormat(
                          'dd MMM yyyy, HH:mm',
                        ).format(_tarea!.actualizadoEn!)
                      : 'N/A',
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDateCard({
    required IconData icon,
    required String label,
    required DateTime? date,
    required Color color,
    VoidCallback? onEdit,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (onEdit != null)
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.edit, size: 16, color: color),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date != null
                ? DateFormat('dd MMM yyyy').format(date)
                : 'No establecida',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: date != null
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection({
    required IconData icon,
    required String title,
    required Widget child,
    VoidCallback? onEdit,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onEdit != null)
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
