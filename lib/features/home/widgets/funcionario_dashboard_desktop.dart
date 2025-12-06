import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/models/organizacion.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/inscripcion.dart';
import '../../../core/models/participacion.dart';
import '../../../core/theme/dashboard_theme.dart';

/// Dashboard de funcionario con diseño moderno tipo Sitemark
class FuncionarioDashboardDesktop extends StatefulWidget {
  const FuncionarioDashboardDesktop({super.key});

  @override
  State<FuncionarioDashboardDesktop> createState() => _FuncionarioDashboardDesktopState();
}

class _FuncionarioDashboardDesktopState extends State<FuncionarioDashboardDesktop> {
  final FuncionarioRepository _repository = Modular.get<FuncionarioRepository>();

  Organizacion? _organizacion;
  List<Proyecto> _proyectos = [];
  List<Inscripcion> _inscripciones = [];
  List<Participacion> _participaciones = [];
  bool _isLoading = true;
  String? _error;
  int _selectedMenuIndex = 0;
  bool _isSidebarCollapsed = false;
  String _userName = 'Funcionario';
  String _userEmail = 'funcionario@volunred.com';

  final List<_MenuItem> _menuItems = [
    _MenuItem(icon: Icons.dashboard_rounded, title: 'Dashboard'),
    _MenuItem(icon: Icons.folder_rounded, title: 'Proyectos'),
    _MenuItem(icon: Icons.task_rounded, title: 'Tareas'),
    _MenuItem(icon: Icons.people_rounded, title: 'Voluntarios'),
    _MenuItem(icon: Icons.assignment_rounded, title: 'Inscripciones'),
    _MenuItem(icon: Icons.business_rounded, title: 'Mi Organización'),
    _MenuItem(icon: Icons.analytics_rounded, title: 'Reportes'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final authRepo = Modular.get<AuthRepository>();
      final usuario = await authRepo.getStoredUser();
      if (usuario != null && mounted) {
        setState(() {
          _userName = usuario.nombreCompleto;
          _userEmail = usuario.email;
        });
      }
    } catch (e) {
      // Mantener valores por defecto
    }
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

  Future<void> _handleLogout() async {
    try {
      final authRepo = Modular.get<AuthRepository>();
      await authRepo.logout();
      if (mounted) {
        Modular.to.navigate('/auth/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardTheme.background,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final sidebarWidth = _isSidebarCollapsed ? 80.0 : 280.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: sidebarWidth,
      decoration: const BoxDecoration(
        gradient: DashboardTheme.sidebarGradient,
      ),
      child: Column(
        children: [
          _buildSidebarHeader(),
          const SizedBox(height: 8),
          Expanded(child: _buildSidebarMenu()),
          if (!_isSidebarCollapsed && _organizacion != null)
            _buildOrganizacionCard(),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: EdgeInsets.all(_isSidebarCollapsed ? 16 : 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: _isSidebarCollapsed 
                ? MainAxisAlignment.center 
                : MainAxisAlignment.start,
            children: [
              Container(
                width: _isSidebarCollapsed ? 40 : 44,
                height: _isSidebarCollapsed ? 40 : 44,
                decoration: BoxDecoration(
                  color: DashboardTheme.chartGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.volunteer_activism,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              if (!_isSidebarCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VolunRed',
                        style: TextStyle(
                          color: DashboardTheme.textLight,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Panel Funcionario',
                        style: TextStyle(
                          color: DashboardTheme.textMuted.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DashboardTheme.sidebarHover,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isSidebarCollapsed 
                    ? Icons.chevron_right_rounded 
                    : Icons.chevron_left_rounded,
                color: DashboardTheme.textMuted,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarMenu() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        return SidebarMenuItem(
          icon: item.icon,
          title: item.title,
          isSelected: _selectedMenuIndex == index,
          isCollapsed: _isSidebarCollapsed,
          onTap: () => setState(() => _selectedMenuIndex = index),
          badgeCount: index == 4 ? _inscripciones.length : null, // Badge para inscripciones
        );
      },
    );
  }

  Widget _buildOrganizacionCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardTheme.sidebarHover,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusMedium),
        border: Border.all(
          color: DashboardTheme.chartGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: DashboardTheme.chartGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.business,
                  color: DashboardTheme.chartGreen,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _organizacion!.nombre,
                  style: const TextStyle(
                    color: DashboardTheme.textLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (_organizacion!.descripcion != null) ...[
            const SizedBox(height: 8),
            Text(
              _organizacion!.descripcion!,
              style: TextStyle(
                color: DashboardTheme.textMuted.withOpacity(0.8),
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Column(
      children: [
        const Divider(color: DashboardTheme.sidebarHover, height: 1),
        SidebarUserProfile(
          name: _userName,
          email: _userEmail,
          isCollapsed: _isSidebarCollapsed,
        ),
        Padding(
          padding: EdgeInsets.all(_isSidebarCollapsed ? 8 : 12),
          child: _isSidebarCollapsed
              ? IconButton(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout, color: DashboardTheme.error),
                  tooltip: 'Cerrar Sesión',
                )
              : SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Cerrar Sesión'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DashboardTheme.error,
                      side: BorderSide(color: DashboardTheme.error.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(child: _buildSelectedContent()),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: DashboardTheme.cardBg,
        border: Border(
          bottom: BorderSide(color: DashboardTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumb
          Row(
            children: [
              Text(
                'Funcionario',
                style: TextStyle(
                  fontSize: 14,
                  color: DashboardTheme.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 18, color: DashboardTheme.textMuted),
              const SizedBox(width: 8),
              Text(
                _menuItems[_selectedMenuIndex].title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: DashboardTheme.textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Barra de búsqueda
          Container(
            width: 280,
            height: 40,
            decoration: BoxDecoration(
              color: DashboardTheme.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DashboardTheme.borderColor),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search, size: 20, color: DashboardTheme.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      hintStyle: TextStyle(
                        color: DashboardTheme.textMuted,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Fecha actual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: DashboardTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DashboardTheme.borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: DashboardTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  _formatDate(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 13,
                    color: DashboardTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Botón de refrescar
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar datos',
            style: IconButton.styleFrom(
              backgroundColor: DashboardTheme.background,
              foregroundColor: DashboardTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          // Notificaciones con badge
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: DashboardTheme.background,
                  foregroundColor: DashboardTheme.textSecondary,
                ),
              ),
              if (_inscripciones.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: DashboardTheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _inscripciones.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildSelectedContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    switch (_selectedMenuIndex) {
      case 0:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _buildDashboardContent(),
        );
      case 1:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _buildProyectosContent(),
        );
      case 2:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _buildTareasContent(),
        );
      case 3:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _buildVoluntariosContent(),
        );
      case 4:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _buildInscripcionesContent(),
        );
      case 5:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _buildOrganizacionContent(),
        );
      case 6:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _buildReportesContent(),
        );
      default:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _buildDashboardContent(),
        );
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: DashboardTheme.error),
          const SizedBox(height: 16),
          Text('Error: $_error', style: const TextStyle(color: DashboardTheme.textSecondary)),
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

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: DashboardTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        
        // Grid de estadísticas
        _buildStatsGrid(),
        const SizedBox(height: 32),
        
        // Sección de gráficos
        _buildChartsSection(),
        const SizedBox(height: 32),
        
        // Proyectos recientes e inscripciones
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildRecentProjectsCard()),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: _buildPendingInscripcionesCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final voluntariosSparkline = [3.0, 5.0, 7.0, 6.0, 9.0, 11.0, 13.0, 12.0, 15.0, 17.0];
    final proyectosSparkline = [2.0, 3.0, 4.0, 3.0, 5.0, 6.0, 7.0, 6.0, 8.0, 9.0];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : 2;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.3,
          children: [
            StatCard(
              title: 'Proyectos Activos',
              value: '${_proyectos.length}',
              subtitle: 'Proyectos en tu organización',
              icon: Icons.folder_rounded,
              color: DashboardTheme.chartBlue,
              trend: '+12%',
              trendUp: true,
              sparklineData: proyectosSparkline,
            ),
            StatCard(
              title: 'Voluntarios',
              value: '${_participaciones.length}',
              subtitle: 'Voluntarios activos',
              icon: Icons.people_rounded,
              color: DashboardTheme.chartGreen,
              trend: '+8%',
              trendUp: true,
              sparklineData: voluntariosSparkline,
            ),
            StatCard(
              title: 'Solicitudes Pendientes',
              value: '${_inscripciones.length}',
              subtitle: 'Esperando aprobación',
              icon: Icons.assignment_rounded,
              color: DashboardTheme.chartOrange,
              trend: _inscripciones.isNotEmpty ? '+${_inscripciones.length}' : '0',
              trendUp: false,
            ),
            StatCard(
              title: 'Tareas Completadas',
              value: '0',
              subtitle: 'Este mes',
              icon: Icons.check_circle_rounded,
              color: DashboardTheme.chartPurple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildActivityChart(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: _buildVoluntariosDistribution(),
        ),
      ],
    );
  }

  Widget _buildActivityChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DashboardTheme.cardBg,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusLarge),
        border: Border.all(color: DashboardTheme.borderColor),
        boxShadow: DashboardTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actividad de Voluntarios',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DashboardTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Participaciones por mes',
                    style: TextStyle(
                      fontSize: 13,
                      color: DashboardTheme.textMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: DashboardTheme.successLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, size: 16, color: DashboardTheme.success),
                    const SizedBox(width: 4),
                    Text(
                      '+35%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DashboardTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: BarChartPainter(
                data: [5, 8, 12, 15, 10, 18, 22, 20, 25, 28, 30, 27],
                color: DashboardTheme.chartGreen,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                       'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic']
                .map((m) => Text(
                  m,
                  style: TextStyle(
                    fontSize: 11,
                    color: DashboardTheme.textMuted,
                  ),
                ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVoluntariosDistribution() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DashboardTheme.cardBg,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusLarge),
        border: Border.all(color: DashboardTheme.borderColor),
        boxShadow: DashboardTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estado de Voluntarios',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DashboardTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Por estado de participación',
            style: TextStyle(
              fontSize: 13,
              color: DashboardTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatusBar('Activos', _participaciones.length, _participaciones.length + 5, DashboardTheme.chartGreen),
          const SizedBox(height: 16),
          _buildStatusBar('Pendientes', _inscripciones.length, _participaciones.length + 5, DashboardTheme.chartOrange),
          const SizedBox(height: 16),
          _buildStatusBar('Completados', 0, _participaciones.length + 5, DashboardTheme.chartBlue),
        ],
      ),
    );
  }

  Widget _buildStatusBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total * 100) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: DashboardTheme.textSecondary,
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: DashboardTheme.borderColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentProjectsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DashboardTheme.cardBg,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusLarge),
        border: Border.all(color: DashboardTheme.borderColor),
        boxShadow: DashboardTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Proyectos Recientes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DashboardTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedMenuIndex = 1),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_proyectos.isEmpty)
            _buildEmptyState('No hay proyectos', Icons.folder_open)
          else
            ...(_proyectos.take(3).map((p) => _buildProjectItem(p))),
        ],
      ),
    );
  }

  Widget _buildProjectItem(Proyecto proyecto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardTheme.background,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusMedium),
        border: Border.all(color: DashboardTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DashboardTheme.chartBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.folder_rounded,
              color: DashboardTheme.chartBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proyecto.nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DashboardTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  proyecto.objetivo ?? 'Sin objetivo definido',
                  style: TextStyle(
                    fontSize: 12,
                    color: DashboardTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: proyecto.estado == 'activo' 
                  ? DashboardTheme.successLight 
                  : DashboardTheme.warningLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              proyecto.estado,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: proyecto.estado == 'activo' 
                    ? DashboardTheme.success 
                    : DashboardTheme.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInscripcionesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DashboardTheme.cardBg,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusLarge),
        border: Border.all(color: DashboardTheme.borderColor),
        boxShadow: DashboardTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Solicitudes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DashboardTheme.textPrimary,
                    ),
                  ),
                  if (_inscripciones.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: DashboardTheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_inscripciones.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _selectedMenuIndex = 4),
                child: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_inscripciones.isEmpty)
            _buildEmptyState('No hay solicitudes pendientes', Icons.inbox)
          else
            ...(_inscripciones.take(4).map((i) => _buildInscripcionItem(i))),
        ],
      ),
    );
  }

  Widget _buildInscripcionItem(Inscripcion inscripcion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashboardTheme.background,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusSmall),
        border: Border.all(color: DashboardTheme.borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: DashboardTheme.chartOrange.withOpacity(0.1),
            child: const Icon(
              Icons.person,
              color: DashboardTheme.chartOrange,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solicitud #${inscripcion.idInscripcion}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DashboardTheme.textPrimary,
                  ),
                ),
                Text(
                  inscripcion.estado,
                  style: TextStyle(
                    fontSize: 11,
                    color: DashboardTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.check_circle_outline, size: 20),
            color: DashboardTheme.success,
            tooltip: 'Aprobar',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: DashboardTheme.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: DashboardTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // Contenido de otras secciones
  Widget _buildProyectosContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mis Proyectos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: DashboardTheme.textPrimary,
              ),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Proyecto'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_proyectos.isEmpty)
          _buildEmptyState('No hay proyectos', Icons.folder_open)
        else
          ...(_proyectos.map((p) => _buildProjectItem(p))),
      ],
    );
  }

  Widget _buildTareasContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tareas',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: DashboardTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        _buildEmptyState('No hay tareas configuradas', Icons.task_alt),
      ],
    );
  }

  Widget _buildVoluntariosContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Voluntarios',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: DashboardTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        if (_participaciones.isEmpty)
          _buildEmptyState('No hay voluntarios activos', Icons.people)
        else
          Text('${_participaciones.length} voluntarios activos'),
      ],
    );
  }

  Widget _buildInscripcionesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Solicitudes de Inscripción',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: DashboardTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        if (_inscripciones.isEmpty)
          _buildEmptyState('No hay solicitudes pendientes', Icons.inbox)
        else
          ...(_inscripciones.map((i) => _buildInscripcionItem(i))),
      ],
    );
  }

  Widget _buildOrganizacionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mi Organización',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: DashboardTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        if (_organizacion == null)
          _buildEmptyState('No hay información de organización', Icons.business)
        else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DashboardTheme.cardBg,
              borderRadius: BorderRadius.circular(DashboardTheme.radiusLarge),
              border: Border.all(color: DashboardTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _organizacion!.nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: DashboardTheme.textPrimary,
                  ),
                ),
                if (_organizacion!.descripcion != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _organizacion!.descripcion!,
                    style: TextStyle(
                      fontSize: 14,
                      color: DashboardTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReportesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reportes y Métricas',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: DashboardTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        _buildStatsGrid(),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;

  _MenuItem({required this.icon, required this.title});
}

/// Painter para gráfico de barras
class BarChartPainter extends CustomPainter {
  final List<int> data;
  final Color color;

  BarChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    final barWidth = (size.width / data.length) * 0.6;
    final spacing = (size.width / data.length) * 0.4;

    for (int i = 0; i < data.length; i++) {
      final barHeight = (data[i] / maxValue) * size.height * 0.85;
      final x = i * (barWidth + spacing) + spacing / 2;
      final y = size.height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [color, color.withOpacity(0.6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect.outerRect);

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
