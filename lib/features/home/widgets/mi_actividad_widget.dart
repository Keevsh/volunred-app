import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/models/inscripcion.dart';
import '../../../core/models/participacion.dart';

class MiActividadWidget extends StatefulWidget {
  const MiActividadWidget({super.key});

  @override
  State<MiActividadWidget> createState() => _MiActividadWidgetState();
}

class _MiActividadWidgetState extends State<MiActividadWidget> {
  final VoluntarioRepository _repository = Modular.get<VoluntarioRepository>();

  List<Inscripcion> _misInscripciones = [];
  List<Participacion> _misParticipaciones = [];
  List<Map<String, dynamic>> _misTareas = [];
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
      final inscripciones = await _repository.getInscripciones();
      final participaciones = await _repository.getParticipaciones();
      final tareas = await _repository.getMyTasks();

      setState(() {
        _misInscripciones = inscripciones;
        _misParticipaciones = participaciones;
        _misTareas = tareas;
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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF5F7FA),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SafeArea(
          top: true,
          bottom: false,
          child: CustomScrollView(
            slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mi Actividad',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Resumen de tu participación',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Estadísticas rápidas
            SliverToBoxAdapter(
              child: _buildQuickStats(theme),
            ),

            // Resumen de mis tareas
            if (_misTareas.isNotEmpty) _buildMyTasksSummary(theme),

            // Participaciones activas
            if (_misParticipaciones.isNotEmpty) _buildMyParticipations(theme),

            // Inscripciones pendientes
            if (_misInscripciones.where((i) => i.estado == 'pendiente').isNotEmpty)
              _buildPendingInscriptions(theme),

            // Inscripciones procesadas
            if (_misInscripciones.where((i) => i.estado != 'pendiente').isNotEmpty)
              _buildProcessedInscriptions(theme),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    )
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    final participacionesActivas =
        _misParticipaciones.where((p) => p.estado == 'activo').length;
    final tareasPendientes = _misTareas.where((t) {
      final estado = t['estado']?.toString().toLowerCase();
      return estado == 'pendiente' || estado == 'en_progreso' || estado == 'en progreso';
    }).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Proyectos',
              participacionesActivas.toString(),
              Icons.volunteer_activism_rounded,
              const Color(0xFF1976D2),
              const Color(0xFFE3F2FD),
              theme,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'Tareas',
              tareasPendientes > 0 ? tareasPendientes.toString() : _misTareas.length.toString(),
              Icons.assignment_rounded,
              tareasPendientes > 0 ? const Color(0xFFFF9800) : const Color(0xFF4CAF50),
              tareasPendientes > 0 ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTasksSummary(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final tareasOrdenadas = List<Map<String, dynamic>>.from(_misTareas);
    tareasOrdenadas.sort((a, b) {
      final estadoA = a['estado']?.toString().toLowerCase() ?? '';
      final estadoB = b['estado']?.toString().toLowerCase() ?? '';
      return estadoA.compareTo(estadoB);
    });
    final tareasMostrar = tareasOrdenadas.take(3).toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1976D2),
                Color(0xFF42A5F5),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1976D2).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mis Tareas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Revisa rápido lo pendiente y en progreso',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Modular.to.pushNamed('/voluntario/tareas');
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Text(
                            'Ver todas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (tareasMostrar.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Aún no tienes tareas asignadas.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: tareasMostrar.map((tarea) {
                    final titulo = tarea['titulo']?.toString() ?? 'Tarea sin título';
                    final estado = tarea['estado']?.toString() ?? 'pendiente';
                    final proyectoNombre =
                        tarea['proyecto_nombre']?.toString() ?? tarea['proyecto']?.toString();
                    final fechaLimite =
                        tarea['fecha_limite']?.toString() ?? tarea['fechaLimite']?.toString();

                    Color chipColor;
                    Color chipTextColor;
                    String estadoLabel;
                    IconData? estadoIcon;

                    switch (estado.toLowerCase()) {
                      case 'pendiente':
                        chipColor = colorScheme.errorContainer;
                        chipTextColor = colorScheme.onErrorContainer;
                        estadoLabel = 'Pendiente';
                        estadoIcon = Icons.schedule;
                        break;
                      case 'en_progreso':
                      case 'en progreso':
                        chipColor = colorScheme.tertiaryContainer;
                        chipTextColor = colorScheme.onTertiaryContainer;
                        estadoLabel = 'En progreso';
                        estadoIcon = Icons.timelapse;
                        break;
                      case 'completada':
                      case 'completado':
                        chipColor = colorScheme.primaryContainer;
                        chipTextColor = colorScheme.onPrimaryContainer;
                        estadoLabel = 'Completada';
                        estadoIcon = Icons.check_circle;
                        break;
                      default:
                        chipColor = colorScheme.surfaceVariant;
                        chipTextColor = colorScheme.onSurfaceVariant;
                        estadoLabel = estado;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titulo,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (proyectoNombre != null && proyectoNombre.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.volunteer_activism,
                                        size: 14,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          proyectoNombre,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (fechaLimite != null && fechaLimite.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.event,
                                        size: 14,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Entrega: $fechaLimite',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: chipColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (estadoIcon != null) ...[
                                  Icon(
                                    estadoIcon,
                                    size: 14,
                                    color: chipTextColor,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  estadoLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: chipTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color bgColor,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            bgColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyParticipations(ThemeData theme) {
    final participacionesActivas = _misParticipaciones
        .where((p) => p.estado == 'activo')
        .toList();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                const Text(
                  'Participando Actualmente',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    participacionesActivas.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: participacionesActivas
                  .map((participacion) => _buildParticipacionCard(participacion, theme))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipacionCard(Participacion participacion, ThemeData theme) {
    final proyectoNombre = participacion.proyecto != null
        ? (participacion.proyecto!['nombre'] ?? 'Proyecto').toString()
        : 'Proyecto';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.volunteer_activism_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proyectoNombre,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Participación activa',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF1976D2),
              ),
              iconSize: 20,
              onPressed: () {
                if (participacion.proyecto != null) {
                  final proyectoId = participacion.proyecto!['id_proyecto'];
                  if (proyectoId != null) {
                    Modular.to.pushNamed('/voluntario/proyectos/$proyectoId');
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInscriptions(ThemeData theme) {
    final pendientes = _misInscripciones
        .where((i) => i.estado == 'pendiente')
        .toList();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Text(
                  'Inscripciones Pendientes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pendientes.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: pendientes
                  .map((inscripcion) => _buildInscripcionCard(inscripcion, theme, true))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessedInscriptions(ThemeData theme) {
    final procesadas = _misInscripciones
        .where((i) => i.estado != 'pendiente')
        .toList();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Text(
              'Historial',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: procesadas
                  .map((inscripcion) => _buildInscripcionCard(inscripcion, theme, false))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInscripcionCard(Inscripcion inscripcion, ThemeData theme, bool isPending) {
    final organizacionNombre = inscripcion.organizacion != null
        ? (inscripcion.organizacion!['nombre'] ?? inscripcion.organizacion!['nombre_legal'] ?? 'Organización').toString()
        : 'Organización';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (inscripcion.estado) {
      case 'pendiente':
        statusColor = const Color(0xFFFF9800);
        statusText = 'Pendiente';
        statusIcon = Icons.pending_rounded;
        break;
      case 'aprobada':
        statusColor = const Color(0xFF4CAF50);
        statusText = 'Aprobada';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rechazada':
        statusColor = const Color(0xFFF44336);
        statusText = 'Rechazada';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = const Color(0xFF9E9E9E);
        statusText = inscripcion.estado;
        statusIcon = Icons.info_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
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
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  organizacionNombre,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF757575),
              ),
              iconSize: 20,
              onPressed: () {
                if (inscripcion.organizacion != null) {
                  final orgId = inscripcion.organizacion!['id_organizacion'];
                  if (orgId != null) {
                    Modular.to.pushNamed('/voluntario/organizaciones/$orgId');
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
