import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/models/organizacion.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/inscripcion.dart';
import '../../../core/models/participacion.dart';
import '../../../core/widgets/skeleton_widget.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/utils/participation_logger.dart';
import 'funcionario_dashboard_desktop.dart';

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
  List<Participacion> _participaciones = [];
  bool _isLoading = true;
  String? _error;
  String _selectedMenuItem = 'Dashboard';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Widget _buildOrganizacionSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mi organización',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_organizacion == null)
            _buildEmptyState(
              icon: Icons.business,
              message: 'No se encontró información de la organización',
              theme: theme,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _organizacion!.nombre,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (_organizacion!.descripcion != null)
                  Text(
                    _organizacion!.descripcion!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReportesSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reportes y métricas',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard(
                icon: Icons.folder_rounded,
                label: 'Proyectos activos',
                value: '${_proyectos.length}',
                color: theme.colorScheme.primary,
                theme: theme,
              ),
              _buildStatCard(
                icon: Icons.people_rounded,
                label: 'Voluntarios',
                value: '${_participaciones.length}',
                color: Colors.green,
                theme: theme,
              ),
              _buildStatCard(
                icon: Icons.assignment_rounded,
                label: 'Solicitudes pendientes',
                value: '${_inscripciones.length}',
                color: Colors.orange,
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTareasSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tareas',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildEmptyState(
            icon: Icons.task_alt,
            message: 'Aún no hay tareas configuradas para mostrar aquí',
            theme: theme,
          ),
        ],
      ),
    );
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
      final participaciones = await _repository.getParticipaciones();

      // Imprimir datos de participaciones para debugging
      ParticipationLogger.printParticipacionesResumen(participaciones);
      ParticipationLogger.printParticipaciones(participaciones);

      setState(() {
        _organizacion = org;
        _proyectos = proyectos;
        _inscripciones = inscripciones;
        _participaciones = participaciones;
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
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Solo en desktop/tablet con pantalla grande usar el nuevo diseño
    // En móvil (incluso web móvil) usar el diseño original
    if ((isDesktop || isTablet) && screenWidth >= 900) {
      return const FuncionarioDashboardDesktop();
    }

    // En mobile, usar layout móvil original
    return _buildMobileLayout(theme);
  }

  Widget _buildDesktopLayout(ThemeData theme) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(theme),
          // Contenido principal
          Expanded(child: _buildMainContent(theme)),
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con logo
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VolunRed',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Funcionario',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Menú de navegación
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  selected: _selectedMenuItem == 'Dashboard',
                  onTap: () => setState(() => _selectedMenuItem = 'Dashboard'),
                ),
                _buildMenuItem(
                  icon: Icons.folder_rounded,
                  label: 'Proyectos',
                  selected: _selectedMenuItem == 'Proyectos',
                  onTap: () => setState(() => _selectedMenuItem = 'Proyectos'),
                ),
                _buildMenuItem(
                  icon: Icons.task_rounded,
                  label: 'Tareas',
                  selected: _selectedMenuItem == 'Tareas',
                  onTap: () => setState(() => _selectedMenuItem = 'Tareas'),
                ),
                _buildMenuItem(
                  icon: Icons.people_rounded,
                  label: 'Voluntarios',
                  selected: _selectedMenuItem == 'Voluntarios',
                  onTap: () =>
                      setState(() => _selectedMenuItem = 'Voluntarios'),
                ),
                _buildMenuItem(
                  icon: Icons.assignment_rounded,
                  label: 'Inscripciones',
                  selected: _selectedMenuItem == 'Inscripciones',
                  onTap: () =>
                      setState(() => _selectedMenuItem = 'Inscripciones'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(),
                ),
                _buildMenuItem(
                  icon: Icons.business_rounded,
                  label: 'Mi Organización',
                  selected: _selectedMenuItem == 'Organización',
                  onTap: () =>
                      setState(() => _selectedMenuItem = 'Organización'),
                ),
                _buildMenuItem(
                  icon: Icons.analytics_rounded,
                  label: 'Reportes',
                  selected: _selectedMenuItem == 'Reportes',
                  onTap: () => setState(() => _selectedMenuItem = 'Reportes'),
                ),
              ],
            ),
          ),

          // Footer con info de usuario
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.person_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _organizacion?.nombre ?? 'Funcionario',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Administrador',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () {
                    // TODO: Implementar logout
                  },
                  tooltip: 'Cerrar sesión',
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? colorScheme.primary : Colors.grey.shade600,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selected
                          ? colorScheme.primary
                          : Colors.grey.shade800,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_error != null) {
      return _buildErrorState(theme);
    }

    // En desktop solo mostrar Dashboard content sin headers internos
    return Container(
      color: const Color(0xFFF8F9FA),
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(32),
              sliver: SliverToBoxAdapter(
                child: _buildDashboardContent(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent(ThemeData theme) {
    switch (_selectedMenuItem) {
      case 'Proyectos':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDesktopProjectsSection(theme),
          ],
        );
      case 'Inscripciones':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDesktopInscripcionesSection(theme),
          ],
        );
      case 'Voluntarios':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDesktopParticipacionesSection(theme),
          ],
        );
      case 'Mi Organización':
      case 'Organización':
        return _buildOrganizacionSection(theme);
      case 'Reportes':
        return _buildReportesSection(theme);
      case 'Tareas':
        return _buildTareasSection(theme);
      case 'Dashboard':
      default:
        return _buildDashboardContent(theme);
    }
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
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

  Widget _buildDashboardContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjetas de estadísticas
        _buildDesktopStatsGrid(theme),
        const SizedBox(height: 32),

        // Proyectos recientes
        _buildDesktopProjectsSection(theme),
        const SizedBox(height: 32),

        // Otras secciones
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildDesktopParticipacionesSection(theme)),
            const SizedBox(width: 24),
            Expanded(child: _buildDesktopInscripcionesSection(theme)),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopStatsGrid(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 24,
      crossAxisSpacing: 24,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.folder_rounded,
          label: 'Proyectos Activos',
          value: '${_proyectos.length}',
          color: colorScheme.primary,
          theme: theme,
        ),
        _buildStatCard(
          icon: Icons.people_rounded,
          label: 'Voluntarios',
          value: '${_participaciones.length}',
          color: Colors.green,
          theme: theme,
        ),
        _buildStatCard(
          icon: Icons.assignment_rounded,
          label: 'Solicitudes',
          value: '${_inscripciones.length}',
          color: Colors.orange,
          theme: theme,
        ),
        _buildStatCard(
          icon: Icons.check_circle_rounded,
          label: 'Completadas',
          value: '0',
          color: Colors.teal,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Icon(Icons.trending_up, color: Colors.green, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color bgColor,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconColor, iconColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  size: 14,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1A1A),
              fontSize: 26,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF757575),
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopProjectsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Proyectos Recientes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _selectedMenuItem = 'Proyectos'),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_proyectos.isEmpty)
          _buildEmptyState(
            icon: Icons.folder_open,
            message: 'No hay proyectos registrados',
            theme: theme,
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _proyectos.take(3).length,
            itemBuilder: (context, index) {
              final proyecto = _proyectos[index];
              return _buildDesktopProjectCard(proyecto, theme);
            },
          ),
      ],
    );
  }

  Widget _buildDesktopProjectCard(Proyecto proyecto, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.folder_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proyecto.nombre,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  proyecto.objetivo ?? 'Sin objetivo definido',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: () {
              Modular.to.pushNamed('/home/proyecto/${proyecto.idProyecto}');
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Ver detalles'),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopParticipacionesSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividad Reciente',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_participaciones.isEmpty)
            _buildEmptyState(
              icon: Icons.timeline,
              message: 'No hay actividad reciente',
              theme: theme,
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _participaciones.take(5).length,
              itemBuilder: (context, index) {
                final participacion = _participaciones[index];
                return _buildActivityItem(participacion, theme);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopInscripcionesSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solicitudes Pendientes',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_inscripciones.isEmpty)
            _buildEmptyState(
              icon: Icons.inbox,
              message: 'No hay solicitudes pendientes',
              theme: theme,
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _inscripciones.take(5).length,
              itemBuilder: (context, index) {
                final inscripcion = _inscripciones[index];
                return _buildInscripcionItem(inscripcion, theme);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Participacion participacion, ThemeData theme) {
    String nombre = 'Voluntario desconocido';

    try {
      // 1. Intentar desde usuario_completo (campo directo en participacion)
      if (participacion.usuarioCompleto != null) {
        final nombres = participacion.usuarioCompleto!['nombres']?.toString() ?? '';
        final apellidos = participacion.usuarioCompleto!['apellidos']?.toString() ?? '';
        nombre = '$nombres $apellidos'.trim();
      }
      // 2. Intentar desde usuario (campo directo en participacion)
      else if (participacion.usuario != null) {
        final nombres = participacion.usuario!['nombres']?.toString() ?? '';
        final apellidos = participacion.usuario!['apellidos']?.toString() ?? '';
        nombre = '$nombres $apellidos'.trim();
      }
      // 3. Intentar desde perfil_voluntario.usuario
      else if (participacion.perfilVoluntario != null) {
        final usuario = participacion.perfilVoluntario!['usuario'];
        if (usuario != null && usuario is Map) {
          final nombres = usuario['nombres']?.toString() ?? '';
          final apellidos = usuario['apellidos']?.toString() ?? '';
          nombre = '$nombres $apellidos'.trim();
        }
      }
      // 4. Fallback: buscar en inscripcion
      else if (participacion.inscripcion != null) {
        var usuario = participacion.inscripcion!['usuario'];
        if (usuario == null && participacion.inscripcion!['perfil_voluntario'] != null) {
          final perfilVol = participacion.inscripcion!['perfil_voluntario'];
          if (perfilVol is Map) {
            usuario = perfilVol['usuario'];
          }
        }
        if (usuario != null && usuario is Map) {
          final nombres = usuario['nombres']?.toString() ?? '';
          final apellidos = usuario['apellidos']?.toString() ?? '';
          nombre = '$nombres $apellidos'.trim();
        }
      }
      
      if (nombre.isEmpty) nombre = 'Voluntario desconocido';
    } catch (e) {
      // Keep default name
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _buildUserAvatar(participacion),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Se unió al proyecto',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInscripcionItem(Inscripcion inscripcion, ThemeData theme) {
    final nombre = _extractNombreVoluntario(inscripcion);

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.person,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nombre,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, size: 20),
            onPressed: () {},
            tooltip: 'Aprobar',
            color: Colors.green,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {},
            tooltip: 'Rechazar',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required ThemeData theme,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    if (_isLoading) {
      return SafeArea(
        child: Container(
          color: const Color(0xFFF8F9FA),
          child: CustomScrollView(
            slivers: [
              // Header skeleton
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SkeletonWidget(
                            width: 100,
                            height: 20,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const Spacer(),
                          const SkeletonWidget(width: 40, height: 30),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SkeletonWidget(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: 32,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 8),
                      const SkeletonWidget(width: 120, height: 20),
                    ],
                  ),
                ),
              ),
              // Stats skeleton
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonWidget(width: 80, height: 18),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(child: SkeletonCard(height: 100)),
                          const SizedBox(width: 12),
                          const Expanded(child: SkeletonCard(height: 100)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Expanded(child: SkeletonCard(height: 100)),
                          const SizedBox(width: 12),
                          const Expanded(child: SkeletonCard(height: 100)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Projects skeleton con header mejorado
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header skeleton tipo card gradiente
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SkeletonWidget(
                                        width: 150,
                                        height: 24,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      const SizedBox(height: 8),
                                      SkeletonWidget(
                                        width: 100,
                                        height: 20,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SkeletonWidget(
                              width: double.infinity,
                              height: 44,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Project cards skeleton
                      const SkeletonList(itemCount: 3, itemHeight: 140),
                    ],
                  ),
                ),
              ),
              // Participaciones skeleton
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SkeletonWidget(width: 250, height: 24),
                          const SizedBox(width: 8),
                          SkeletonWidget(
                            width: 40,
                            height: 24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const SkeletonList(itemCount: 3, itemHeight: 80),
                    ],
                  ),
                ),
              ),
              // Solicitudes pendientes skeleton
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SkeletonWidget(width: 200, height: 24),
                          const SizedBox(width: 8),
                          SkeletonWidget(
                            width: 40,
                            height: 24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const SkeletonList(itemCount: 3, itemHeight: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      final colorScheme = theme.colorScheme;
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

    return SafeArea(
      child: Container(
        color: const Color(0xFFF8F9FA),
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // Header con saludo y perfil
              _buildWelcomeHeader(theme),

              // Estadísticas rápidas
              SliverToBoxAdapter(child: _buildQuickStats(theme)),

              // Proyectos destacados
              _buildFeaturedProjects(theme),

              if (_participaciones.isNotEmpty)
                _buildParticipacionesResumen(theme),

              // Solicitudes pendientes
              if (_inscripciones.isNotEmpty) _buildPendingRequests(theme),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipacionesResumen(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    // Filtrar solo las participaciones en estado pendiente (solicitudes)
    final participacionesPendientes = _participaciones
        .where((p) => p.estado.toLowerCase() == 'pendiente')
        .toList();

    if (participacionesPendientes.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final participacionesMostrar = participacionesPendientes.take(3).toList();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Text(
                  'Solicitudes de participación pendientes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    participacionesPendientes.length.toString(),
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
              children: participacionesMostrar.map((participacion) {
                final proyecto = participacion.proyecto;
                final proyectoNombre = proyecto != null
                    ? (proyecto['nombre'] ?? 'Proyecto').toString()
                    : 'Proyecto';

                Color chipColor;
                Color chipTextColor;

                switch (participacion.estado.toLowerCase()) {
                  case 'pendiente':
                    chipColor = Colors.amber.withOpacity(0.2);
                    chipTextColor =
                        Colors.amber[800] ?? colorScheme.onSurfaceVariant;
                    break;
                  case 'programada':
                    chipColor = colorScheme.primaryContainer;
                    chipTextColor = colorScheme.onPrimaryContainer;
                    break;
                  case 'en_progreso':
                    chipColor = colorScheme.tertiaryContainer;
                    chipTextColor = colorScheme.onTertiaryContainer;
                    break;
                  case 'completado':
                    chipColor = colorScheme.secondaryContainer;
                    chipTextColor = colorScheme.onSecondaryContainer;
                    break;
                  case 'ausente':
                    chipColor = colorScheme.errorContainer;
                    chipTextColor = colorScheme.onErrorContainer;
                    break;
                  default:
                    chipColor = colorScheme.surfaceVariant;
                    chipTextColor = colorScheme.onSurfaceVariant;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                      // Avatar del usuario
                      _buildUserAvatar(participacion),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nombre del voluntario
                            Text(
                              _extractNombrePostulante(participacion),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Email del usuario
                            if (participacion.inscripcion != null)
                              Builder(
                                builder: (context) {
                                  var usuario =
                                      participacion.inscripcion!['usuario'];
                                  // Si no está directamente, buscar en perfil_voluntario
                                  if (usuario == null &&
                                      participacion
                                              .inscripcion!['perfil_voluntario'] !=
                                          null) {
                                    final perfilVol = participacion
                                        .inscripcion!['perfil_voluntario'];
                                    if (perfilVol is Map) {
                                      usuario = perfilVol['usuario'];
                                    }
                                  }

                                  if (usuario == null)
                                    return const SizedBox.shrink();

                                  final email = usuario['email']?.toString();
                                  if (email == null || email.isEmpty)
                                    return const SizedBox.shrink();

                                  return Row(
                                    children: [
                                      Icon(
                                        Icons.email_outlined,
                                        size: 14,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          email,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            const SizedBox(height: 4),
                            // Teléfono del usuario
                            if (participacion.inscripcion != null)
                              Builder(
                                builder: (context) {
                                  var usuario =
                                      participacion.inscripcion!['usuario'];
                                  // Si no está directamente, buscar en perfil_voluntario
                                  if (usuario == null &&
                                      participacion
                                              .inscripcion!['perfil_voluntario'] !=
                                          null) {
                                    final perfilVol = participacion
                                        .inscripcion!['perfil_voluntario'];
                                    if (perfilVol is Map) {
                                      usuario = perfilVol['usuario'];
                                    }
                                  }

                                  if (usuario == null)
                                    return const SizedBox.shrink();

                                  final telefono = usuario['telefono'];
                                  if (telefono == null)
                                    return const SizedBox.shrink();

                                  return Row(
                                    children: [
                                      Icon(
                                        Icons.phone_outlined,
                                        size: 14,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        telefono.toString(),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            const SizedBox(height: 8),
                            // Proyecto
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withOpacity(
                                  0.3,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.folder_outlined,
                                    size: 14,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      proyectoNombre,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: chipColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              participacion.estado.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: chipTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF4CAF50),
                                  ),
                                  iconSize: 24,
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Aprobar',
                                  onPressed: () async {
                                    try {
                                      await _repository.updateParticipacion(
                                        participacion.idParticipacion,
                                        {'estado': 'APROBADA'},
                                      );
                                      // Actualizar solo la lista de participaciones localmente
                                      if (mounted) {
                                        setState(() {
                                          _participaciones = _participaciones
                                              .where(
                                                (p) =>
                                                    p.idParticipacion !=
                                                    participacion
                                                        .idParticipacion,
                                              )
                                              .toList();
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Participación aprobada exitosamente',
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.cancel_rounded,
                                    color: Color(0xFFFF5252),
                                  ),
                                  iconSize: 24,
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Rechazar',
                                  onPressed: () async {
                                    try {
                                      await _repository.deleteParticipacion(
                                        participacion.idParticipacion,
                                      );
                                      // Actualizar solo la lista de participaciones localmente
                                      if (mounted) {
                                        setState(() {
                                          _participaciones = _participaciones
                                              .where(
                                                (p) =>
                                                    p.idParticipacion !=
                                                    participacion
                                                        .idParticipacion,
                                              )
                                              .toList();
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Solicitud de participación rechazada',
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(ThemeData theme) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Buenos días';
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour < 18) {
      greeting = 'Buenas tardes';
      greetingIcon = Icons.wb_twilight_rounded;
    } else {
      greeting = 'Buenas noches';
      greetingIcon = Icons.nightlight_rounded;
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF1565C0), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1976D2).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  greetingIcon,
                  color: Colors.white.withOpacity(0.9),
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    greeting,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ),
                if (_inscripciones.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _inscripciones.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _organizacion?.nombre ?? 'Organización',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Organización activa',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    final proyectosActivos = _proyectos
        .where((p) => p.estado == 'activo')
        .length;
    final participacionesActivas = _participaciones
        .where(
          (p) =>
              p.estado.toLowerCase() == 'programada' ||
              p.estado.toLowerCase() == 'en_progreso',
        )
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMobileStatCard(
                  'Proyectos\nActivos',
                  proyectosActivos.toString(),
                  Icons.rocket_launch_rounded,
                  const Color(0xFF1976D2),
                  const Color(0xFFE3F2FD),
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMobileStatCard(
                  'Solicitudes\nNuevas',
                  _inscripciones.length.toString(),
                  Icons.notification_important_rounded,
                  _inscripciones.isNotEmpty
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF4CAF50),
                  _inscripciones.isNotEmpty
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFE8F5E9),
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMobileStatCard(
                  'Participantes\nActivos',
                  participacionesActivas.toString(),
                  Icons.groups_rounded,
                  const Color(0xFF9C27B0),
                  const Color(0xFFF3E5F5),
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMobileStatCard(
                  'Total\nProyectos',
                  _proyectos.length.toString(),
                  Icons.folder_special_rounded,
                  const Color(0xFFFF9800),
                  const Color(0xFFFFF3E0),
                  theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProjects(ThemeData theme) {
    if (_proyectos.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.rocket_launch_rounded,
                        size: 48,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No hay proyectos',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crea tu primer proyecto para comenzar',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF757575),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mejorado con gradiente y diseño moderno
          Container(
            margin: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1976D2), const Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1976D2).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icono decorativo
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.folder_special,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Título y contador
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mis Proyectos',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${_proyectos.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _proyectos.length == 1
                                          ? 'proyecto'
                                          : 'proyectos',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Badge de proyectos activos
                              if (_proyectos
                                  .where(
                                    (p) => p.estado.toLowerCase() == 'activo',
                                  )
                                  .isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_proyectos.where((p) => p.estado.toLowerCase() == 'activo').length} activos',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Botón de crear proyecto mejorado
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Modular.to.pushNamed('/proyectos/create');
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text(
                      'Crear Nuevo Proyecto',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1976D2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_proyectos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 48,
                      color: const Color(0xFF9E9E9E),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sin proyectos aún',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF616161),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crea tu primer proyecto para comenzar a gestionar voluntarios',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () {
                        Modular.to.pushNamed('/proyectos/create');
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 18),
                          SizedBox(width: 8),
                          Text('Crear Proyecto'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _proyectos.length > 6 ? 6 : _proyectos.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildProyectoListCard(_proyectos[index], theme);
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildProyectoListCard(Proyecto proyecto, ThemeData theme) {
    final isActivo = proyecto.estado.toLowerCase() == 'activo';
    final hasImage = proyecto.imagen != null && proyecto.imagen!.isNotEmpty;

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Imagen lateral
              Container(
                width: 140,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasImage)
                        Image.memory(
                          base64Decode(proyecto.imagen!.split(',').last),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildGradientBackground(isActivo);
                          },
                        )
                      else
                        _buildGradientBackground(isActivo),
                      // Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.2),
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header con título y badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              proyecto.nombre,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                                height: 1.2,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActivo
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              proyecto.estado.toUpperCase(),
                              style: TextStyle(
                                color: isActivo
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFFF9800),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Ubicación
                      if (proyecto.ubicacion != null &&
                          proyecto.ubicacion!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Color(0xFF757575),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                proyecto.ubicacion!,
                                style: const TextStyle(
                                  color: Color(0xFF757575),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      // Footer con botón
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.people_rounded,
                                  size: 16,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Ver equipo',
                                style: TextStyle(
                                  color: Color(0xFF757575),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Color(0xFF9E9E9E),
                          ),
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

  Widget _buildGradientBackground(bool isActivo) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActivo
              ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
              : [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.folder_special_rounded,
          size: 50,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildPendingRequests(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Text(
                  'Solicitudes Pendientes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _inscripciones.length.toString(),
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
              children: _inscripciones
                  .take(3)
                  .map(
                    (inscripcion) => _buildInscripcionCard(inscripcion, theme),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInscripcionCard(Inscripcion inscripcion, ThemeData theme) {
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
              child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del voluntario
                Text(
                  _extractNombreVoluntario(inscripcion),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Estado de la solicitud
                Text(
                  'Solicitud #${inscripcion.idInscripcion} • ${_formatFecha(inscripcion.fechaRecepcion)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF757575),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF4CAF50),
              ),
              iconSize: 24,
              onPressed: () async {
                try {
                  await _repository.aprobarInscripcion(
                    inscripcion.idInscripcion,
                  );
                  // Actualizar solo la lista de inscripciones localmente
                  if (mounted) {
                    setState(() {
                      _inscripciones = _inscripciones
                          .where(
                            (i) => i.idInscripcion != inscripcion.idInscripcion,
                          )
                          .toList();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Solicitud aprobada'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.cancel_rounded, color: Color(0xFFFF5252)),
              iconSize: 24,
              onPressed: () async {
                try {
                  await _repository.rechazarInscripcion(
                    inscripcion.idInscripcion,
                    'Rechazado desde dashboard',
                  );
                  // Actualizar solo la lista de inscripciones localmente
                  if (mounted) {
                    setState(() {
                      _inscripciones = _inscripciones
                          .where(
                            (i) => i.idInscripcion != inscripcion.idInscripcion,
                          )
                          .toList();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Solicitud rechazada'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Extrae el nombre completo del postulante desde una participación
  String _extractNombrePostulante(Participacion participacion) {
    try {
      print('🔍 DEBUG _extractNombrePostulante:');
      final inscripcion = participacion.inscripcion;
      print('   inscripcion existe: ${inscripcion != null}');

      if (inscripcion == null) {
        print('   ❌ inscripcion es null');
        return 'Voluntario desconocido';
      }

      print('   Keys en inscripcion: ${inscripcion.keys.toList()}');

      // Opción 1: Buscar usuario_completo directamente en inscripcion
      if (inscripcion['usuario_completo'] != null) {
        final nombreCompleto = inscripcion['usuario_completo']
            .toString()
            .trim();
        if (nombreCompleto.isNotEmpty) {
          print('   ✅ Encontrado en usuario_completo: "$nombreCompleto"');
          return nombreCompleto;
        }
      }

      // Opción 2: Buscar usuario directamente en inscripcion
      var usuario = inscripcion['usuario'];
      print('   usuario directo existe: ${usuario != null}');

      if (usuario != null && usuario is Map) {
        final nombres = usuario['nombres']?.toString() ?? '';
        final apellidos = usuario['apellidos']?.toString() ?? '';
        final nombreCompleto = '$nombres $apellidos'.trim();
        if (nombreCompleto.isNotEmpty) {
          print('   ✅ Encontrado en usuario directo: "$nombreCompleto"');
          return nombreCompleto;
        }
      }

      // Opción 3: Buscar en perfil_voluntario
      if (inscripcion['perfil_voluntario'] != null) {
        final perfilVol = inscripcion['perfil_voluntario'];
        print('   perfil_voluntario existe: ${perfilVol != null}');
        if (perfilVol is Map) {
          usuario = perfilVol['usuario'];
          if (usuario != null && usuario is Map) {
            final nombres = usuario['nombres']?.toString() ?? '';
            final apellidos = usuario['apellidos']?.toString() ?? '';
            final nombreCompleto = '$nombres $apellidos'.trim();
            if (nombreCompleto.isNotEmpty) {
              print(
                '   ✅ Encontrado en perfil_voluntario/usuario: "$nombreCompleto"',
              );
              return nombreCompleto;
            }
          }
        }
      }

      print('   ❌ No se encontró nombre en ningún lugar');
      return 'Voluntario desconocido';
    } catch (e) {
      print('   ❌ ERROR en _extractNombrePostulante: $e');
      return 'Voluntario desconocido';
    }
  }

  /// Construye el avatar del usuario desde una participación
  Widget _buildUserAvatar(Participacion participacion) {
    try {
      final inscripcion = participacion.inscripcion;
      if (inscripcion == null) {
        return _buildDefaultAvatar();
      }

      // Obtener usuario de cualquier ubicación
      var usuario = inscripcion['usuario'];
      if (usuario == null && inscripcion['perfil_voluntario'] != null) {
        final perfilVol = inscripcion['perfil_voluntario'];
        if (perfilVol is Map) {
          usuario = perfilVol['usuario'];
        }
      }

      if (usuario == null) {
        return _buildDefaultAvatar();
      }

      // Obtener iniciales
      final nombres = usuario['nombres']?.toString() ?? '';
      final apellidos = usuario['apellidos']?.toString() ?? '';
      final iniciales = _getIniciales(nombres, apellidos);

      // Obtener foto de perfil (buscar en múltiples ubicaciones)
      var fotoPerfil = inscripcion['foto_perfil'];
      if (fotoPerfil == null && usuario is Map) {
        fotoPerfil = usuario['foto_perfil'];
      }
      if (fotoPerfil == null && inscripcion['perfil_voluntario'] is Map) {
        final perfilVol = inscripcion['perfil_voluntario'];
        fotoPerfil = perfilVol['foto_perfil'];
      }

      if (fotoPerfil != null && fotoPerfil is String && fotoPerfil.isNotEmpty) {
        // Si hay foto base64
        try {
          // Manejar base64 con o sin prefijo data:
          String base64String = fotoPerfil;
          if (fotoPerfil.contains('base64,')) {
            base64String = fotoPerfil.split('base64,').last;
          }

          final bytes = base64Decode(base64String);
          return CircleAvatar(
            radius: 24,
            backgroundImage: MemoryImage(bytes),
            backgroundColor: Colors.transparent,
          );
        } catch (e) {
          print('Error al decodificar foto: $e');
          // Si falla decodificar, usar iniciales
          return CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF1976D2),
            child: Text(
              iniciales,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          );
        }
      }

      // Si no hay foto, usar iniciales
      return CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF1976D2),
        child: Text(
          iniciales,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      );
    } catch (e) {
      print('Error en _buildUserAvatar: $e');
      return _buildDefaultAvatar();
    }
  }

  /// Construye un avatar por defecto
  Widget _buildDefaultAvatar() {
    return const CircleAvatar(
      radius: 24,
      backgroundColor: Color(0xFF1976D2),
      child: Icon(Icons.person, color: Colors.white, size: 24),
    );
  }

  /// Obtiene las iniciales de nombres y apellidos
  String _getIniciales(String nombres, String apellidos) {
    String inicialNombre = nombres.isNotEmpty ? nombres[0].toUpperCase() : '';
    String inicialApellido = apellidos.isNotEmpty
        ? apellidos[0].toUpperCase()
        : '';

    if (inicialNombre.isEmpty && inicialApellido.isEmpty) {
      return 'V';
    }

    return '$inicialNombre$inicialApellido';
  }

  /// Extrae el nombre completo del voluntario desde una inscripción
  String _extractNombreVoluntario(Inscripcion inscripcion) {
    try {
      final perfilVoluntario = inscripcion.perfilVoluntario;
      if (perfilVoluntario == null) return 'Voluntario desconocido';

      final usuario = perfilVoluntario['usuario'];
      if (usuario == null) return 'Voluntario desconocido';

      final nombres = usuario['nombres']?.toString() ?? '';
      final apellidos = usuario['apellidos']?.toString() ?? '';
      final nombreCompleto = '$nombres $apellidos'.trim();

      return nombreCompleto.isNotEmpty
          ? nombreCompleto
          : 'Voluntario desconocido';
    } catch (e) {
      return 'Voluntario desconocido';
    }
  }

  /// Formatea una fecha al formato dd/MM/yyyy
  String _formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }
}
