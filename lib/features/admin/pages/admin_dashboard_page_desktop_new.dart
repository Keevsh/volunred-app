import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/theme/dashboard_theme.dart';
import '../bloc/admin_bloc.dart';
import 'bitacoras_management_page.dart';
import 'usuarios_management_page.dart';
import 'roles_management_page.dart';
import 'permisos_management_page.dart';
import 'programas_management_page.dart';
import 'aptitudes_management_page.dart';
import 'organizaciones_management_page.dart';
import 'proyectos_management_page.dart';
import 'tareas_management_page.dart';

/// Panel de administración con diseño moderno tipo Sitemark
class AdminDashboardPageDesktopNew extends StatefulWidget {
  const AdminDashboardPageDesktopNew({super.key});

  @override
  State<AdminDashboardPageDesktopNew> createState() => _AdminDashboardPageDesktopNewState();
}

class _AdminDashboardPageDesktopNewState extends State<AdminDashboardPageDesktopNew> {
  late AdminRepository _adminRepository;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  int _selectedMenuIndex = 0;
  bool _isSidebarCollapsed = false;
  String _userName = 'Administrador';
  String _userEmail = 'admin@volunred.com';

  final List<_MenuItem> _menuItems = [
    _MenuItem(icon: Icons.dashboard_rounded, title: 'Dashboard'),
    _MenuItem(icon: Icons.people_rounded, title: 'Usuarios'),
    _MenuItem(icon: Icons.admin_panel_settings_rounded, title: 'Roles'),
    _MenuItem(icon: Icons.security_rounded, title: 'Permisos'),
    _MenuItem(icon: Icons.apps_rounded, title: 'Programas'),
    _MenuItem(icon: Icons.emoji_events_rounded, title: 'Aptitudes'),
    _MenuItem(icon: Icons.business_rounded, title: 'Organizaciones'),
    _MenuItem(icon: Icons.folder_special_rounded, title: 'Proyectos'),
    _MenuItem(icon: Icons.task_rounded, title: 'Tareas'),
    _MenuItem(icon: Icons.history_rounded, title: 'Bitácoras'),
  ];

  @override
  void initState() {
    super.initState();
    _adminRepository = Modular.get<AdminRepository>();
    _verificarAcceso();
    _loadStats();
    _loadUserInfo();
  }

  Future<void> _verificarAcceso() async {
    final authRepo = Modular.get<AuthRepository>();
    final usuario = await authRepo.getStoredUser();

    if (usuario == null || !usuario.isAdmin) {
      if (mounted) {
        Modular.to.navigate('/home');
      }
    }
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

  Future<void> _loadStats() async {
    try {
      final stats = await _adminRepository.getSystemStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _stats['error'] = e.toString();
        });
      }
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
                  color: DashboardTheme.primary,
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
                        'Panel Admin',
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
          // Botón de colapsar/expandir
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: DashboardTheme.sidebarHover.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: _isSidebarCollapsed 
                      ? MainAxisAlignment.center 
                      : MainAxisAlignment.start,
                  children: [
                    AnimatedRotation(
                      turns: _isSidebarCollapsed ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_double_arrow_left_rounded,
                        color: DashboardTheme.textMuted,
                        size: 18,
                      ),
                    ),
                    if (!_isSidebarCollapsed) ...[
                      const SizedBox(width: 10),
                      const Text(
                        'Ocultar menú',
                        style: TextStyle(
                          color: DashboardTheme.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
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
        );
      },
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
        // Botón de cerrar sesión
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
                'Dashboard',
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
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar datos',
            style: IconButton.styleFrom(
              backgroundColor: DashboardTheme.background,
              foregroundColor: DashboardTheme.textSecondary,
            ),
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
    switch (_selectedMenuIndex) {
      case 0:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _buildDashboardContent(),
        );
      case 1:
        return BlocProvider(
          create: (context) => AdminBloc(Modular.get<AdminRepository>()),
          child: const UsuariosManagementPage(embedded: true),
        );
      case 2:
        return BlocProvider(
          create: (context) => AdminBloc(Modular.get<AdminRepository>()),
          child: const RolesManagementPage(embedded: true),
        );
      case 3:
        return BlocProvider(
          create: (context) => AdminBloc(Modular.get<AdminRepository>()),
          child: const PermisosManagementPage(embedded: true),
        );
      case 4:
        return BlocProvider(
          create: (context) => AdminBloc(Modular.get<AdminRepository>()),
          child: const ProgramasManagementPage(embedded: true),
        );
      case 5:
        return BlocProvider(
          create: (context) => AdminBloc(Modular.get<AdminRepository>()),
          child: const AptitudesManagementPage(embedded: true),
        );
      case 6:
        return BlocProvider(
          create: (context) => AdminBloc(Modular.get<AdminRepository>()),
          child: const OrganizacionesManagementPage(embedded: true),
        );
      case 7:
        return BlocProvider(
          create: (context) => AdminBloc(Modular.get<AdminRepository>()),
          child: const ProyectosManagementPage(embedded: true),
        );
      case 8:
        return BlocProvider(
          create: (context) => AdminBloc(Modular.get<AdminRepository>()),
          child: const TareasManagementPage(embedded: true),
        );
      case 9:
        return BlocProvider(
          create: (context) => AdminBloc(Modular.get<AdminRepository>()),
          child: const BitacorasManagementPage(embedded: true),
        );
      default:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _buildDashboardContent(),
        );
    }
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de sección
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: DashboardTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        
        // Grid de estadísticas principales
        _buildStatsGrid(),
        const SizedBox(height: 32),
        
        // Sección de gráficos
        _buildChartsSection(),
        const SizedBox(height: 32),
        
        // Accesos rápidos
        _buildQuickAccessSection(),
      ],
    );
  }

  Widget _buildStatsGrid() {
    if (_isLoading) {
      return _buildStatsLoading();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1400
            ? 4
            : constraints.maxWidth > 1000
                ? 3
                : 2;
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.3,
          children: [
            StatCard(
              title: 'Usuarios Totales',
              value: _stats['totalUsuarios']?.toString() ?? '0',
              subtitle: '${_stats['voluntarios'] ?? 0} voluntarios, ${_stats['funcionarios'] ?? 0} funcionarios',
              icon: Icons.people_rounded,
              color: DashboardTheme.chartBlue,
            ),
            StatCard(
              title: 'Proyectos Activos',
              value: _stats['proyectosActivos']?.toString() ?? '0',
              subtitle: 'de ${_stats['totalProyectos'] ?? 0} totales',
              icon: Icons.folder_special_rounded,
              color: DashboardTheme.chartGreen,
            ),
            StatCard(
              title: 'Organizaciones',
              value: _stats['totalOrganizaciones']?.toString() ?? '0',
              subtitle: 'Organizaciones registradas',
              icon: Icons.business_rounded,
              color: DashboardTheme.chartOrange,
            ),
            StatCard(
              title: 'Administradores',
              value: _stats['admins']?.toString() ?? '0',
              subtitle: 'Usuarios con rol admin',
              icon: Icons.admin_panel_settings_rounded,
              color: DashboardTheme.chartPurple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsLoading() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: List.generate(4, (index) => _buildStatCardSkeleton()),
    );
  }

  Widget _buildStatCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardTheme.cardBg,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusLarge),
        border: Border.all(color: DashboardTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 100,
                height: 14,
                decoration: BoxDecoration(
                  color: DashboardTheme.borderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: DashboardTheme.borderColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 80,
            height: 28,
            decoration: BoxDecoration(
              color: DashboardTheme.borderColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 120,
            height: 12,
            decoration: BoxDecoration(
              color: DashboardTheme.borderColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gráfico de sesiones/actividad
        Expanded(
          flex: 3,
          child: _buildSessionsChart(),
        ),
        const SizedBox(width: 24),
        // Gráfico de distribución
        Expanded(
          flex: 2,
          child: _buildDistributionChart(),
        ),
      ],
    );
  }

  Widget _buildSessionsChart() {
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
                    'Actividad del Sistema',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DashboardTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Usuarios activos por día en los últimos 30 días',
                    style: TextStyle(
                      fontSize: 13,
                      color: DashboardTheme.textMuted,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildChartLegendItem('Voluntarios', DashboardTheme.chartBlue),
                  const SizedBox(width: 16),
                  _buildChartLegendItem('Funcionarios', DashboardTheme.chartGreen),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Mensaje informativo
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: DashboardTheme.background,
              borderRadius: BorderRadius.circular(DashboardTheme.radiusMedium),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 48,
                    color: DashboardTheme.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Gráfico de actividad disponible próximamente',
                    style: TextStyle(
                      fontSize: 14,
                      color: DashboardTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: DashboardTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionChart() {
    final totalUsuarios = (_stats['totalUsuarios'] ?? 0) as int;
    final voluntarios = (_stats['voluntarios'] ?? 0) as int;
    final funcionarios = (_stats['funcionarios'] ?? 0) as int;
    final admins = (_stats['admins'] ?? 0) as int;

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
            'Distribución de Usuarios',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DashboardTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Por tipo de rol',
            style: TextStyle(
              fontSize: 13,
              color: DashboardTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          // Barras de distribución
          _buildDistributionBar(
            'Voluntarios',
            voluntarios,
            totalUsuarios,
            DashboardTheme.chartBlue,
          ),
          const SizedBox(height: 16),
          _buildDistributionBar(
            'Funcionarios',
            funcionarios,
            totalUsuarios,
            DashboardTheme.chartGreen,
          ),
          const SizedBox(height: 16),
          _buildDistributionBar(
            'Administradores',
            admins,
            totalUsuarios,
            DashboardTheme.chartPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBar(String label, int value, int total, Color color) {
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
              '$value (${percentage.toStringAsFixed(0)}%)',
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

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accesos Rápidos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DashboardTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1200
                ? 4
                : constraints.maxWidth > 800
                    ? 3
                    : 2;
            
            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.8,
              children: _menuItems.skip(1).toList().asMap().entries.map((entry) {
                final menuIndex = entry.key + 1;
                final item = entry.value;
                return _buildQuickAccessCard(item, menuIndex);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(_MenuItem item, int menuIndex) {
    return Material(
      color: DashboardTheme.cardBg,
      borderRadius: BorderRadius.circular(DashboardTheme.radiusMedium),
      child: InkWell(
        onTap: () => setState(() => _selectedMenuIndex = menuIndex),
        borderRadius: BorderRadius.circular(DashboardTheme.radiusMedium),
        hoverColor: DashboardTheme.primary.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DashboardTheme.radiusMedium),
            border: Border.all(color: DashboardTheme.borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DashboardTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  color: DashboardTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DashboardTheme.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: DashboardTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;

  _MenuItem({required this.icon, required this.title});
}
