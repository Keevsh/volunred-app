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
  final FuncionarioRepository _repository =
      Modular.get<FuncionarioRepository>();

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
          final tareas = await _repository.getTareasByProyecto(
            proyecto.idProyecto,
          );
          todasTareas.addAll(
            tareas.where(
              (t) => t.estado == 'pendiente' || t.estado == 'en_progreso',
            ),
          );
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

    return Container(
      color: const Color(0xFFF5F7FA), // Fondo gris muy claro
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Header con información de la organización
            SliverToBoxAdapter(
              child: _buildOrganizacionHeader(theme, colorScheme),
            ),

            // Estadísticas rápidas
            SliverToBoxAdapter(child: _buildQuickStats(theme, colorScheme)),

            // Sección de acciones rápidas
            SliverToBoxAdapter(child: _buildQuickActions(theme, colorScheme)),

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
                delegate: SliverChildBuilderDelegate((context, index) {
                  final proyecto = _proyectos[index];
                  return _buildProyectoCard(proyecto, theme, colorScheme);
                }, childCount: _proyectos.length > 6 ? 6 : _proyectos.length),
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
                    childCount: _tareasPendientes.length > 5
                        ? 5
                        : _tareasPendientes.length,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                      return _buildInscripcionCard(
                        inscripcion,
                        theme,
                        colorScheme,
                      );
                    },
                    childCount: _inscripciones.length > 3
                        ? 3
                        : _inscripciones.length,
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizacionHeader(ThemeData theme, ColorScheme colorScheme) {
    if (_organizacion == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cover Image / Banner
          Container(
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Stack(
              children: [
                // Pattern overlay
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: CustomPaint(painter: _DotPatternPainter()),
                  ),
                ),
                // Edit button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Navegar al perfil completo
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 20),
                      color: Colors.white,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Profile section
          Transform.translate(
            offset: const Offset(0, -40),
            child: Column(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child:
                          (_organizacion!.logo != null &&
                              _organizacion!.logo!.isNotEmpty)
                          ? ImageBase64Widget(
                              base64String: _organizacion!.logo!,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1976D2),
                                    Color(0xFF42A5F5),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.apartment_rounded,
                                size: 45,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Organization name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _organizacion!.nombre,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                // Active badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Organización activa',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Info chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      if (_organizacion!.direccion != null &&
                          _organizacion!.direccion!.isNotEmpty)
                        _buildInfoChipSocial(
                          Icons.location_on_rounded,
                          _organizacion!.direccion!,
                        ),
                      if (_organizacion!.email != null &&
                          _organizacion!.email!.isNotEmpty)
                        _buildInfoChipSocial(
                          Icons.email_outlined,
                          _organizacion!.email!,
                        ),
                      if (_organizacion!.telefono != null &&
                          _organizacion!.telefono!.isNotEmpty)
                        _buildInfoChipSocial(
                          Icons.phone_outlined,
                          _organizacion!.telefono!,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme, ColorScheme colorScheme) {
    final proyectosActivos = _proyectos
        .where((p) => p.estado == 'activo')
        .length;
    // Contar participaciones activas (esto requeriría una consulta adicional)
    final totalVoluntarios = 0; // Placeholder

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Proyectos\nActivos',
              proyectosActivos.toString(),
              Icons.folder_open_rounded,
              const Color(0xFF1976D2),
              const Color(0xFFE3F2FD),
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Voluntarios',
              totalVoluntarios.toString(),
              Icons.people_rounded,
              const Color(0xFF1976D2),
              const Color(0xFFE3F2FD),
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Tareas',
              _tareasPendientes.length.toString(),
              Icons.assignment_rounded,
              const Color(0xFFFF9800),
              const Color(0xFFFFF3E0),
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Solicitudes',
              _inscripciones.length.toString(),
              Icons.notifications_active_rounded,
              const Color(0xFFF44336),
              const Color(0xFFFFEBEE),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _buildActionButton(
            'Nuevo Proyecto',
            Icons.add_circle_rounded,
            const Color(0xFF1976D2),
            const Color(0xFFE3F2FD),
            () => Modular.to.pushNamed('/proyectos/create'),
          ),
          _buildActionButton(
            'Ver Solicitudes',
            Icons.inbox_rounded,
            const Color(0xFFFF9800),
            const Color(0xFFFFF3E0),
            () {
              // Navegar a solicitudes
            },
          ),
          _buildActionButton(
            'Gestionar Equipo',
            Icons.groups_rounded,
            const Color(0xFF1976D2),
            const Color(0xFFE3F2FD),
            () {
              // Navegar a equipo
            },
          ),
          _buildActionButton(
            'Reportes',
            Icons.analytics_rounded,
            const Color(0xFF9C27B0),
            const Color(0xFFF3E5F5),
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
    Color iconColor,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProyectoCard(
    Proyecto proyecto,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              Modular.to.pushNamed('/proyectos/${proyecto.idProyecto}'),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen con badge de estado
              Stack(
                children: [
                  if (proyecto.imagen != null && proyecto.imagen!.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: ImageBase64Widget(
                        base64String: proyecto.imagen!,
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 140,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.folder_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  // Badge de estado
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: proyecto.estado == 'activo'
                            ? const Color(0xFF4CAF50)
                            : Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        proyecto.estado.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        proyecto.nombre,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.people_rounded,
                                  size: 16,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ver voluntarios',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF757575),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (proyecto.fechaFin != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(proyecto.fechaFin!),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF757575),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
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

  Widget _buildTareaCard(
    Tarea tarea,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final estadoColor = tarea.estado == 'pendiente'
        ? const Color(0xFFFF9800)
        : const Color(0xFF1976D2);
    final estadoBgColor = tarea.estado == 'pendiente'
        ? const Color(0xFFFFF3E0)
        : const Color(0xFFE3F2FD);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Modular.to.pushNamed(
              '/proyectos/tarea/${tarea.idTarea}?role=funcionario',
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: estadoBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    tarea.estado == 'pendiente'
                        ? Icons.radio_button_unchecked_rounded
                        : Icons.pending_rounded,
                    color: estadoColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tarea.nombre,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tarea.proyecto != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          tarea.proyecto!['nombre']?.toString() ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF757575),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (tarea.prioridad != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getPrioridadColor(tarea.prioridad),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tarea.prioridad!.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInscripcionCard(
    Inscripcion inscripcion,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3F2FD), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                child: Text(
                  'V',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solicitud de inscripción #${inscripcion.idInscripcion}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Solicitud de inscripción',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50),
                ),
                iconSize: 28,
                onPressed: () async {
                  try {
                    await _repository.aprobarInscripcion(
                      inscripcion.idInscripcion,
                    );
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Inscripción aprobada')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF44336).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.cancel_rounded,
                  color: Color(0xFFF44336),
                ),
                iconSize: 28,
                onPressed: () async {
                  try {
                    await _repository.rechazarInscripcion(
                      inscripcion.idInscripcion,
                      'Rechazado desde dashboard',
                    );
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Inscripción rechazada')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChipWhite(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChipSocial(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1976D2)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF424242),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

// Custom painter para el patrón de puntos en el banner
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    const dotRadius = 2.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
