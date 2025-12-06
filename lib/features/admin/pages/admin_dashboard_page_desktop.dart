import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/widgets/skeleton_widget.dart';
import '../bloc/admin_bloc.dart';
import 'usuarios_management_page.dart';
import 'roles_management_page.dart';
import 'permisos_management_page.dart';
import 'programas_management_page.dart';
import 'aptitudes_management_page.dart';
import 'organizaciones_management_page.dart';
import 'proyectos_management_page.dart';
import 'tareas_management_page.dart';

/// Colores corporativos de VolunRed - Celeste y Blanco
class VolunRedColors {
  static const Color primary = Color(0xFF42A5F5); // Celeste principal
  static const Color primaryDark = Color(0xFF1E88E5); // Celeste oscuro
  static const Color primaryLight = Color(0xFF90CAF9); // Celeste claro
  static const Color accent = Color(0xFF64B5F6); // Celeste accent
  static const Color sidebarBg = Color(0xFF1565C0); // Azul oscuro para sidebar
  static const Color sidebarBgLight = Color(0xFF1976D2); // Azul medio
  static const Color textLight = Color(0xFFFFFFFF); // Blanco
  static const Color textMuted = Color(0xFFB0BEC5);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);
}

/// Panel de administración optimizado para desktop/web
/// Incluye sidebar con navegación y contenido embebido
class AdminDashboardPageDesktop extends StatefulWidget {
  const AdminDashboardPageDesktop({super.key});

  @override
  State<AdminDashboardPageDesktop> createState() => _AdminDashboardPageDesktopState();
}

class _AdminDashboardPageDesktopState extends State<AdminDashboardPageDesktop> {
  late AdminRepository _adminRepository;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  int _selectedMenuIndex = 0;
  bool _isSidebarCollapsed = false;

  // Lista de opciones del menú
  final List<_AdminMenuItem> _menuItems = [
    _AdminMenuItem(
      icon: Icons.dashboard_rounded,
      title: 'Dashboard',
      subtitle: 'Vista general',
    ),
    _AdminMenuItem(
      icon: Icons.people_rounded,
      title: 'Usuarios',
      subtitle: 'Gestionar usuarios',
    ),
    _AdminMenuItem(
      icon: Icons.admin_panel_settings_rounded,
      title: 'Roles',
      subtitle: 'Configurar roles',
    ),
    _AdminMenuItem(
      icon: Icons.security_rounded,
      title: 'Permisos',
      subtitle: 'Asignar permisos',
    ),
    _AdminMenuItem(
      icon: Icons.apps_rounded,
      title: 'Programas',
      subtitle: 'Gestionar programas',
    ),
    _AdminMenuItem(
      icon: Icons.emoji_events_rounded,
      title: 'Aptitudes',
      subtitle: 'Administrar habilidades',
    ),
    _AdminMenuItem(
      icon: Icons.business_rounded,
      title: 'Organizaciones',
      subtitle: 'Gestionar organizaciones',
    ),
    _AdminMenuItem(
      icon: Icons.folder_special_rounded,
      title: 'Proyectos',
      subtitle: 'Gestionar proyectos',
    ),
    _AdminMenuItem(
      icon: Icons.task_rounded,
      title: 'Tareas',
      subtitle: 'Gestionar tareas',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _adminRepository = Modular.get<AdminRepository>();
    _verificarAcceso();
    _loadStats();
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

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final authRepo = Modular.get<AuthRepository>();
      await authRepo.logout();

      if (!mounted) return;

      Modular.to.navigate('/auth/');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onMenuItemSelected(int index) {
    setState(() {
      _selectedMenuIndex = index;
    });
    // Ya no navegamos, el contenido se muestra embebido
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          // Contenido principal
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final sidebarWidth = _isSidebarCollapsed ? 80.0 : 280.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: sidebarWidth,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [VolunRedColors.sidebarBg, VolunRedColors.sidebarBgLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header del sidebar
            _buildSidebarHeader(),
            const SizedBox(height: 8),
            // Menú de navegación
            Expanded(
              child: _buildSidebarMenu(),
            ),
            // Footer con logout
            _buildSidebarFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: EdgeInsets.all(_isSidebarCollapsed ? 12 : 20),
      child: _isSidebarCollapsed
          ? Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism,
                    color: VolunRedColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSidebarCollapsed = false;
                    });
                  },
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: 'Expandir menú',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism,
                    color: VolunRedColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VolunRed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Panel Admin',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSidebarCollapsed = true;
                    });
                  },
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: 'Colapsar menú',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSidebarMenu() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        final isSelected = _selectedMenuIndex == index;

        return Tooltip(
          message: _isSidebarCollapsed ? item.title : '',
          preferBelow: false,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _onMenuItemSelected(index),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: _isSidebarCollapsed ? 12 : 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? VolunRedColors.primary.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: VolunRedColors.primary.withOpacity(0.5),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.6),
                        size: 24,
                      ),
                      if (!_isSidebarCollapsed) ...[
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.8),
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: VolunRedColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: EdgeInsets.all(_isSidebarCollapsed ? 12 : 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: _isSidebarCollapsed
          ? IconButton(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: 'Cerrar Sesión',
            )
          : FilledButton.icon(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Cerrar Sesión'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.9),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          // Top bar
          _buildTopBar(),
          // Contenido según selección
          Expanded(
            child: _buildSelectedContent(),
          ),
        ],
      ),
    );
  }

  /// Construye el contenido según el índice seleccionado en el menú
  Widget _buildSelectedContent() {
    switch (_selectedMenuIndex) {
      case 0: // Dashboard
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _buildDashboardContent(),
        );
      case 1: // Usuarios
        return BlocProvider(
          create: (context) => AdminBloc(Modular.get<AdminRepository>()),
          child: const UsuariosManagementPage(embedded: true),
        );
      case 2: // Roles
        return BlocProvider(
          create: (context) => AdminBloc(Modular.get<AdminRepository>()),
          child: const RolesManagementPage(embedded: true),
        );
      case 3: // Permisos
        return BlocProvider(
          create: (context) => AdminBloc(Modular.get<AdminRepository>()),
          child: const PermisosManagementPage(embedded: true),
        );
      case 4: // Programas
        return BlocProvider(
          create: (context) => AdminBloc(Modular.get<AdminRepository>()),
          child: const ProgramasManagementPage(embedded: true),
        );
      case 5: // Aptitudes
        return BlocProvider(
          create: (context) => AdminBloc(Modular.get<AdminRepository>()),
          child: const AptitudesManagementPage(embedded: true),
        );
      case 6: // Organizaciones
        return BlocProvider(
          create: (context) => AdminBloc(Modular.get<AdminRepository>()),
          child: const OrganizacionesManagementPage(embedded: true),
        );
      case 7: // Proyectos
        return BlocProvider(
          create: (context) => AdminBloc(Modular.get<AdminRepository>()),
          child: const ProyectosManagementPage(embedded: true),
        );
      case 8: // Tareas
        return BlocProvider(
          create: (context) => AdminBloc(Modular.get<AdminRepository>()),
          child: const TareasManagementPage(embedded: true),
        );
      default:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: _buildDashboardContent(),
        );
    }
  }

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Título de la sección actual
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _menuItems[_selectedMenuIndex].title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                _menuItems[_selectedMenuIndex].subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Botón de refrescar
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar datos',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF0F2F5),
              foregroundColor: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 12),
          // Indicador de admin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: VolunRedColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: VolunRedColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Administrador',
                  style: TextStyle(
                    color: VolunRedColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjetas de estadísticas
        _buildStatsSection(),
        const SizedBox(height: 40),
        // Accesos rápidos
        _buildQuickAccessSection(),
        const SizedBox(height: 40),
        // Información del sistema
        _buildSystemInfoSection(),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen del Sistema',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 20),
        if (_isLoading)
          _buildStatsLoading()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1200
                  ? 4
                  : constraints.maxWidth > 800
                      ? 3
                      : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    title: 'Usuarios Totales',
                    value: _stats['totalUsuarios']?.toString() ?? '0',
                    icon: Icons.people_rounded,
                    color: const Color(0xFF3B82F6),
                    trend: '+12%',
                    trendUp: true,
                    subtitle:
                        '${_stats['voluntarios'] ?? 0} voluntarios, ${_stats['funcionarios'] ?? 0} funcionarios',
                  ),
                  _buildStatCard(
                    title: 'Proyectos Activos',
                    value: _stats['proyectosActivos']?.toString() ?? '0',
                    icon: Icons.folder_special_rounded,
                    color: const Color(0xFF10B981),
                    subtitle: 'de ${_stats['totalProyectos'] ?? 0} totales',
                  ),
                  _buildStatCard(
                    title: 'Organizaciones',
                    value: _stats['totalOrganizaciones']?.toString() ?? '0',
                    icon: Icons.business_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  _buildStatCard(
                    title: 'Administradores',
                    value: _stats['admins']?.toString() ?? '0',
                    icon: Icons.admin_panel_settings_rounded,
                    color: const Color(0xFFEF4444),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildStatsLoading() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: List.generate(4, (index) => _buildStatCardSkeleton()),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    String? trend,
    bool trendUp = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trendUp
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 16,
                        color: trendUp
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: trendUp
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonWidget(
                width: 52,
                height: 52,
                borderRadius: BorderRadius.circular(14),
              ),
              SkeletonWidget(
                width: 60,
                height: 24,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonWidget(
                width: 80,
                height: 32,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              SkeletonWidget(
                width: 120,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accesos Rápidos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1200
                ? 4
                : constraints.maxWidth > 800
                    ? 3
                    : 2;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: _menuItems.skip(1).toList().asMap().entries.map((entry) {
                final menuIndex = entry.key + 1; // +1 porque skip(1) omite Dashboard
                final item = entry.value;
                return _buildQuickAccessCard(item, menuIndex);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(_AdminMenuItem item, int menuIndex) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          // Navegar al índice correspondiente en el menú
          _onMenuItemSelected(menuIndex);
        },
        borderRadius: BorderRadius.circular(16),
        hoverColor: VolunRedColors.primary.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      VolunRedColors.primary.withOpacity(0.1),
                      VolunRedColors.accent.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  color: VolunRedColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Información del Sistema',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.update_rounded,
                  label: 'Última actualización',
                  value: _formatTimestamp(_stats['timestamp']),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.storage_rounded,
                  label: 'Estado del servidor',
                  value: _stats['error'] != null ? 'Con errores' : 'Operativo',
                  valueColor: _stats['error'] != null
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.verified_rounded,
                  label: 'Versión',
                  value: '1.0.0',
                ),
              ),
            ],
          ),
          if (_stats['error'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error: ${_stats['error']}',
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}

class _AdminMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;

  _AdminMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
