import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/models/inscripcion.dart';
import '../../../core/models/participacion.dart';
import '../../../core/models/dto/voluntario_responses.dart';
import '../../../core/repositories/voluntario_repository.dart';

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
  Map<int, ProyectoVoluntario> _proyectosCache = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Obtener el perfil del usuario para filtrar participaciones e inscripciones
      final perfil = await _repository.getStoredPerfil();
      
      final inscripciones = await _repository.getInscripciones();
      final participaciones = await _repository.getParticipaciones();
      final proyectos = await _repository.getMyProyectos();
      final tareas = await _repository.getMyTasks();

      // Filtrar solo las inscripciones del usuario actual
      final inscripcionesUsuario = perfil != null
          ? inscripciones.where((ins) {
              return ins.perfilVolId == perfil.idPerfilVoluntario;
            }).toList()
          : <Inscripcion>[];

      // Filtrar solo las participaciones del usuario actual
      final participacionesUsuario = perfil != null
          ? participaciones.where((part) {
              // Coincidir por usuario_id o por perfil_vol_id como respaldo
              final byUsuario = part.usuarioId != null && part.usuarioId == perfil.usuarioId;
              final byPerfilVol = part.perfilVolId != null && part.perfilVolId == perfil.idPerfilVoluntario;
              return byUsuario || byPerfilVol;
            }).toList()
          : <Participacion>[];

      if (!mounted) return;
      setState(() {
        _misInscripciones = inscripcionesUsuario;
        _misParticipaciones = participacionesUsuario;
        _misTareas = tareas;
        _proyectosCache = {
          for (final p in proyectos) p.idProyecto: p,
        };
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
          colors: [Color(0xFFF5F7FA), Color(0xFFFFFFFF)],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SafeArea(
          top: true,
          bottom: false,
          child: CustomScrollView(
            slivers: [
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
                        'Tu participación y proyectos',
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

              SliverToBoxAdapter(child: _buildQuickStats(theme)),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              if (_misTareas.isNotEmpty)
                _buildTasksSection(theme),

              if (_misParticipaciones.isNotEmpty)
                _buildProjectsSection(theme),

              if (_misInscripciones.isNotEmpty)
                _buildOrganizationsSection(theme),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    final participacionesActivas = _misParticipaciones
        .where((p) => _estadoCategoriaParticipacion(p) != 'completado')
        .length;

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

  SliverToBoxAdapter _buildProjectsSection(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    List<Participacion> byEstado(String categoria) => _misParticipaciones
        .where((p) => _estadoCategoriaParticipacion(p) == categoria)
        .toList();

    final proyectosActivos = byEstado('en_progreso');
    final proyectosPendientes = byEstado('pendiente');
    final proyectosCompletados = byEstado('completado');

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mis Proyectos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            if (proyectosActivos.isNotEmpty) ...[
              _buildProjectStatusSection('En Progreso', proyectosActivos, theme, colorScheme, const Color(0xFF1976D2)),
              const SizedBox(height: 16),
            ],
            if (proyectosPendientes.isNotEmpty) ...[
              _buildProjectStatusSection('Pendientes', proyectosPendientes, theme, colorScheme, const Color(0xFFFF9800)),
              const SizedBox(height: 16),
            ],
            if (proyectosCompletados.isNotEmpty) ...[
              _buildProjectStatusSection('Completados', proyectosCompletados, theme, colorScheme, const Color(0xFF4CAF50)),
              const SizedBox(height: 16),
            ],
            if (proyectosActivos.isEmpty && proyectosPendientes.isEmpty && proyectosCompletados.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.volunteer_activism_outlined, size: 48, color: colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        'Sin participaciones activas',
                        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectStatusSection(
    String title,
    List<Participacion> participaciones,
    ThemeData theme,
    ColorScheme colorScheme,
    Color statusColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(
                participaciones.length.toString(),
                style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: participaciones.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _buildProjectParticipationCard(participaciones[index], theme, statusColor);
          },
        ),
      ],
    );
  }

  Widget _buildProjectParticipationCard(Participacion participacion, ThemeData theme, Color statusColor) {
    final proyectoId = participacion.proyecto?['id_proyecto'] ?? participacion.proyectoId;
    final proyectoNombre = participacion.proyecto?['nombre']
        ?.toString()
      ?? _proyectosCache[proyectoId]?.nombre
      ?? 'Proyecto desconocido';

    final orgNombre = participacion.proyecto?['organizacion'] != null
      ? (participacion.proyecto!['organizacion']['nombre'] ??
          participacion.proyecto!['organizacion']['nombre_corto'] ??
          participacion.proyecto!['organizacion']['nombre_legal'] ??
          'Organización')
        .toString()
      : _proyectosCache[proyectoId]?.organizacion.nombreLegal ?? 'Organización desconocida';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (proyectoId != null) {
              Modular.to.pushNamed('/voluntario/proyectos/$proyectoId');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Icon(_getStatusIcon(participacion.estado), color: statusColor, size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proyectoNombre,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.business_rounded, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              orgNombre,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(
                            _estadoEtiquetaParticipacion(participacion.estado),
                            style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildOrganizationsSection(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    final organizacionesAprobadas = _misInscripciones.where((i) => i.estado.toLowerCase() == 'aprobado').toList();
    final organizacionesPendientes = _misInscripciones.where((i) => i.estado.toLowerCase() == 'pendiente').toList();
    final organizacionesRechazadas = _misInscripciones
        .where((i) => i.estado.toLowerCase() == 'rechazado' || i.estado.toLowerCase() == 'rechazada')
        .toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mis Organizaciones',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            if (organizacionesAprobadas.isNotEmpty) ...[
              _buildOrganizationStatusSection('Aprobadas', organizacionesAprobadas, theme, colorScheme, const Color(0xFF4CAF50)),
              const SizedBox(height: 16),
            ],
            if (organizacionesPendientes.isNotEmpty) ...[
              _buildOrganizationStatusSection('Pendientes', organizacionesPendientes, theme, colorScheme, const Color(0xFFFF9800)),
              const SizedBox(height: 16),
            ],
            if (organizacionesRechazadas.isNotEmpty) ...[
              _buildOrganizationStatusSection('Rechazadas', organizacionesRechazadas, theme, colorScheme, const Color(0xFFF44336)),
              const SizedBox(height: 16),
            ],
            if (organizacionesAprobadas.isEmpty && organizacionesPendientes.isEmpty && organizacionesRechazadas.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.business_outlined, size: 48, color: colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        'Sin inscripciones a organizaciones',
                        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildTasksSection(ThemeData theme) {
    List<Map<String, dynamic>> byEstado(String categoria) {
      return _misTareas.where((t) {
        final estado = t['estado']?.toString().toUpperCase() ?? '';
        switch (categoria) {
          case 'en_progreso':
            return estado.contains('PROGRES') || estado == 'EN_PROGRESO';
          case 'pendiente':
            return estado.contains('PEND') || estado.contains('ASIGN');
          case 'completado':
            return estado.contains('COMPLET');
          default:
            return false;
        }
      }).toList();
    }

    final pendientes = byEstado('pendiente');
    final enProgreso = byEstado('en_progreso');
    final completadas = byEstado('completado');

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mis Tareas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            _buildTaskGroup('En progreso', enProgreso, theme, const Color(0xFF1976D2)),
            const SizedBox(height: 12),
            _buildTaskGroup('Pendientes', pendientes, theme, const Color(0xFFFF9800)),
            const SizedBox(height: 12),
            _buildTaskGroup('Completadas', completadas, theme, const Color(0xFF4CAF50)),
            if (pendientes.isEmpty && enProgreso.isEmpty && completadas.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Sin tareas asignadas',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskGroup(
    String title,
    List<Map<String, dynamic>> tareas,
    ThemeData theme,
    Color statusColor,
  ) {
    if (tareas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 18, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Text('${tareas.length}', style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tareas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return _buildTaskCard(tareas[index], theme, statusColor);
          },
        ),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> tarea, ThemeData theme, Color statusColor) {
    final titulo = (tarea['nombre'] ?? tarea['titulo'] ?? 'Tarea').toString();
    final proyectoId = tarea['proyecto_id'] ?? tarea['proyectoId'];
    final proyectoNombre = tarea['proyecto'] is Map
        ? (tarea['proyecto']['nombre'] ?? tarea['proyecto']['titulo'] ?? '').toString()
        : _proyectosCache[proyectoId]?.nombre ?? '';
    final estado = tarea['estado']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          if (proyectoNombre.isNotEmpty)
            Row(
              children: [
                Icon(Icons.work_outline_rounded, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    proyectoNombre,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _taskStatusColor(estado).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _taskStatusLabel(estado),
              style: theme.textTheme.labelSmall?.copyWith(
                color: _taskStatusColor(estado),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationStatusSection(
    String title,
    List<Inscripcion> inscripciones,
    ThemeData theme,
    ColorScheme colorScheme,
    Color statusColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(
                inscripciones.length.toString(),
                style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: inscripciones.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _buildOrganizationInscriptionCard(inscripciones[index], theme, statusColor);
          },
        ),
      ],
    );
  }

  Widget _buildOrganizationInscriptionCard(Inscripcion inscripcion, ThemeData theme, Color statusColor) {
    final orgNombre = inscripcion.organizacion != null
        ? (inscripcion.organizacion!['nombre'] ??
                inscripcion.organizacion!['nombre_legal'] ??
                inscripcion.organizacion!['nombre_corto'] ??
                'Organización desconocida')
            .toString()
        : 'Organización desconocida';
    final orgId = inscripcion.organizacion?['id_organizacion'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (orgId != null) {
              Modular.to.pushNamed('/voluntario/organizaciones/$orgId');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [statusColor.withOpacity(0.8), statusColor.withOpacity(0.5)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(_getEnrollmentStatusIcon(inscripcion.estado), color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orgNombre,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(
                            _getEnrollmentStatusLabel(inscripcion.estado),
                            style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: Colors.grey[400], size: 20),
              ],
            ),
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
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [bgColor, bgColor.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: iconColor.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
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
              boxShadow: [BoxShadow(color: iconColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
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

  IconData _getStatusIcon(String estado) {
    final s = estado.toLowerCase();
    if (s == 'activo') return Icons.play_circle_rounded;
    if (s == 'pendiente') return Icons.schedule_rounded;
    if (s == 'completado') return Icons.check_circle_rounded;
    return Icons.info_rounded;
  }

  IconData _getEnrollmentStatusIcon(String estado) {
    final s = estado.toLowerCase();
    if (s == 'aprobado') return Icons.check_circle_rounded;
    if (s == 'pendiente') return Icons.schedule_rounded;
    if (s == 'rechazado' || s == 'rechazada') return Icons.cancel_rounded;
    return Icons.info_rounded;
  }

  String _getEnrollmentStatusLabel(String estado) {
    final s = estado.toLowerCase();
    if (s == 'aprobado') return 'Aprobado';
    if (s == 'pendiente') return 'Pendiente de revisión';
    if (s == 'rechazado' || s == 'rechazada') return 'Rechazado';
    return estado;
  }

  String _estadoCategoriaParticipacion(Participacion p) {
    final e = p.estado.toUpperCase();
    if (e.contains('COMPLET')) return 'completado';
    if (e.contains('PROGRES') || e.contains('ACTIVO')) return 'en_progreso';
    if (e.contains('PROGRAM') || e.contains('PEND')) return 'pendiente';
    return 'pendiente';
  }

  String _estadoEtiquetaParticipacion(String estado) {
    final e = estado.toUpperCase();
    if (e.contains('COMPLET')) return 'Completado';
    if (e.contains('PROGRES') || e.contains('ACTIVO')) return 'En progreso';
    if (e.contains('PROGRAM') || e.contains('PEND')) return 'Pendiente';
    return estado;
  }

  Color _taskStatusColor(String estado) {
    final e = estado.toUpperCase();
    if (e.contains('COMPLET')) return const Color(0xFF4CAF50);
    if (e.contains('PROGRES') || e.contains('INICI')) return const Color(0xFF1976D2);
    if (e.contains('PEND') || e.contains('ASIGN')) return const Color(0xFFFF9800);
    return Colors.grey;
  }

  String _taskStatusLabel(String estado) {
    final e = estado.toUpperCase();
    if (e.contains('COMPLET')) return 'Completada';
    if (e.contains('PROGRES') || e.contains('INICI')) return 'En progreso';
    if (e.contains('PEND') || e.contains('ASIGN')) return 'Pendiente';
    return estado;
  }
}
