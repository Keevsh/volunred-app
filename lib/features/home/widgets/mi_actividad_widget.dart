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

      setState(() {
        _misInscripciones = inscripciones;
        _misParticipaciones = participaciones;
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
      color: const Color(0xFFF8F9FA),
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Text(
                  'Mi Actividad',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),

            // Estadísticas rápidas
            SliverToBoxAdapter(
              child: _buildQuickStats(theme),
            ),

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
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    final participacionesActivas = _misParticipaciones.where((p) => p.estado == 'activo').length;
    final inscripcionesPendientes = _misInscripciones.where((i) => i.estado == 'pendiente').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Participando',
              participacionesActivas.toString(),
              Icons.handshake_rounded,
              const Color(0xFF1976D2),
              const Color(0xFFE3F2FD),
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Pendientes',
              inscripcionesPendientes.toString(),
              Icons.pending_actions_rounded,
              inscripcionesPendientes > 0 ? const Color(0xFFFF9800) : const Color(0xFF4CAF50),
              inscripcionesPendientes > 0 ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
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
    Color iconColor,
    Color bgColor,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF757575),
              fontWeight: FontWeight.w500,
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
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Text(
                  'Participando Actualmente',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3F2FD), width: 1.5),
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
