import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/models/organizacion.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/inscripcion.dart';
import '../../../core/models/tarea.dart';
import '../../../core/widgets/image_base64_widget.dart';
import 'package:intl/intl.dart';

class FuncionarioDashboard extends StatefulWidget {
  const FuncionarioDashboard({super.key});

  @override
  State<FuncionarioDashboard> createState() => _FuncionarioDashboardState();
}

class _FuncionarioDashboardState extends State<FuncionarioDashboard> {
  final FuncionarioRepository _repository = Modular.get<FuncionarioRepository>();
  
  Organizacion? _organizacion;
  List<Proyecto> _proyectos = [];
  List<Inscripcion> _inscripciones = [];
  List<Tarea> _tareasPendientes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final org = await _repository.getMiOrganizacion();
      final proyectos = await _repository.getProyectos();
      final inscripciones = await _repository.getInscripcionesPendientes();
      
      // Cargar tareas pendientes de todos los proyectos
      List<Tarea> todasTareas = [];
      for (var proyecto in proyectos) {
        try {
          final tareas = await _repository.getTareasByProyecto(proyecto.idProyecto);
          todasTareas.addAll(tareas.where((t) => t.estado == 'pendiente' || t.estado == 'en_progreso'));
        } catch (e) {
          // Continuar si falla algún proyecto
        }
      }

      setState(() {
        _organizacion = org;
        _proyectos = proyectos;
        _inscripciones = inscripciones;
        _tareasPendientes = todasTareas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Header con información de la organización
          SliverToBoxAdapter(
            child: _buildOrganizacionHeader(theme, colorScheme),
          ),

          // Estadísticas rápidas
          SliverToBoxAdapter(
            child: _buildQuickStats(theme, colorScheme),
          ),

          // Sección de acciones rápidas
          SliverToBoxAdapter(
            child: _buildQuickActions(theme, colorScheme),
          ),

          // Proyectos activos
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Proyectos Activos',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // Ver todos los proyectos
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Ver todos'),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final proyecto = _proyectos[index];
                  return _buildProyectoCard(proyecto, theme, colorScheme);
                },
                childCount: _proyectos.length > 6 ? 6 : _proyectos.length,
              ),
            ),
          ),

          // Tareas pendientes
          if (_tareasPendientes.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text(
                  'Tareas Pendientes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tarea = _tareasPendientes[index];
                    return _buildTareaCard(tarea, theme, colorScheme);
                  },
                  childCount: _tareasPendientes.length > 5 ? 5 : _tareasPendientes.length,
                ),
              ),
            ),
          ],

          // Inscripciones pendientes
          if (_inscripciones.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Row(
                  children: [
                    Text(
                      'Solicitudes Pendientes',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _inscripciones.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final inscripcion = _inscripciones[index];
                    return _buildInscripcionCard(inscripcion, theme, colorScheme);
                  },
                  childCount: _inscripciones.length > 3 ? 3 : _inscripciones.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildOrganizacionHeader(ThemeData theme, ColorScheme colorScheme) {
    if (_organizacion == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withOpacity(0.06),
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: (_organizacion!.logo != null && _organizacion!.logo!.isNotEmpty)
                      ? ImageBase64Widget(
                          base64String: _organizacion!.logo!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(72),
                          ),
                          child: Icon(
                            Icons.apartment_rounded,
                            size: 38,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _organizacion!.nombre,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (_organizacion!.descripcion != null && _organizacion!.descripcion!.isNotEmpty)
                              Text(
                                _organizacion!.descripcion!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield_rounded,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Organización activa',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              // Navegar al perfil completo de la organización (si existe ruta)
                            },
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('Ver organización'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        Icons.location_on,
                        _organizacion!.direccion ?? 'Sin dirección',
                        colorScheme,
                      ),
                      if (_organizacion!.categoriaOrganizacion != null)
                        _buildInfoChip(
                          Icons.category,
                          _organizacion!.categoriaOrganizacion!['nombre']?.toString() ?? 'General',
                          colorScheme,
                        ),
                      if (_organizacion!.email != null && _organizacion!.email!.isNotEmpty)
                        _buildInfoChip(
                          Icons.email_outlined,
                          _organizacion!.email,
                          colorScheme,
                        ),
                      if (_organizacion!.telefono != null && _organizacion!.telefono!.isNotEmpty)
                        _buildInfoChip(
                          Icons.phone,
                          _organizacion!.telefono!,
                          colorScheme,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme, ColorScheme colorScheme) {
    final proyectosActivos = _proyectos.where((p) => p.estado == 'activo').length;
    // Contar participaciones activas (esto requeriría una consulta adicional)
    final totalVoluntarios = 0; // Placeholder

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Proyectos Activos',
              proyectosActivos.toString(),
              Icons.folder_open,
              Colors.blue,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Voluntarios',
              totalVoluntarios.toString(),
              Icons.people,
              Colors.green,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Tareas',
              _tareasPendientes.length.toString(),
              Icons.task,
              Colors.orange,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Solicitudes',
              _inscripciones.length.toString(),
              Icons.notifications,
              Colors.red,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildActionButton(
            'Nuevo Proyecto',
            Icons.add_circle,
            colorScheme.primary,
            () => Modular.to.pushNamed('/proyectos/create'),
          ),
          _buildActionButton(
            'Ver Solicitudes',
            Icons.inbox,
            Colors.orange,
            () {
              // Navegar a solicitudes
            },
          ),
          _buildActionButton(
            'Gestionar Equipo',
            Icons.groups,
            Colors.blue,
            () {
              // Navegar a equipo
            },
          ),
          _buildActionButton(
            'Reportes',
            Icons.analytics,
            Colors.purple,
            () {
              // Navegar a reportes
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProyectoCard(Proyecto proyecto, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Modular.to.pushNamed('/proyectos/${proyecto.idProyecto}'),
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 230,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (proyecto.imagen != null && proyecto.imagen!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: ImageBase64Widget(
                    base64String: proyecto.imagen!,
                    width: double.infinity,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primaryContainer, colorScheme.secondaryContainer],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Icon(Icons.folder, size: 40, color: colorScheme.primary),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              proyecto.nombre,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: proyecto.estado == 'activo' ? Colors.green : Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              proyecto.estado.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.people, size: 16, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'Ver voluntarios',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (proyecto.fechaFin != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(proyecto.fechaFin!),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTareaCard(Tarea tarea, ThemeData theme, ColorScheme colorScheme) {
    final estadoColor = tarea.estado == 'pendiente' ? Colors.grey : Colors.blue;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: estadoColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            tarea.estado == 'pendiente' ? Icons.radio_button_unchecked : Icons.pending,
            color: estadoColor,
          ),
        ),
        title: Text(
          tarea.nombre,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: tarea.proyecto != null
            ? Text(tarea.proyecto!['nombre']?.toString() ?? '')
            : null,
        trailing: tarea.prioridad != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPrioridadColor(tarea.prioridad).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tarea.prioridad!.toUpperCase(),
                  style: TextStyle(
                    color: _getPrioridadColor(tarea.prioridad),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () {
          Modular.to.pushNamed('/proyectos/tarea/${tarea.idTarea}?role=funcionario');
        },
      ),
    );
  }

  Widget _buildInscripcionCard(Inscripcion inscripcion, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            'V',
            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          'Solicitud de inscripción #${inscripcion.idInscripcion}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('Solicitud de inscripción'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () async {
                // Aprobar inscripción
                try {
                  await _repository.aprobarInscripcion(inscripcion.idInscripcion);
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inscripción aprobada')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () async {
                // Rechazar inscripción
                try {
                  await _repository.rechazarInscripcion(inscripcion.idInscripcion, 'Rechazado desde dashboard');
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inscripción rechazada')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
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
}
