import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/widgets/skeleton_widget.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late AdminRepository _adminRepository;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

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
      // No es admin, redirigir al home
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

      // Navegar a login y limpiar el stack de navegación
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con logout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Administración',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1D1F),
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Panel de control del sistema',
                          style: TextStyle(
                            fontSize: 17,
                            color: Color(0xFF86868B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => _loadStats(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF1D1D1F),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => _handleLogout(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFF1D1D1F),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Tarjetas de estadísticas
              if (_isLoading)
                // Skeleton para KPIs
                GridView.count(
                  crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 2),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isDesktop ? 1.3 : 1.1,
                  children: List.generate(
                    4,
                    (index) => _buildStatCardSkeleton(),
                  ),
                )
              else ...[
                // Fila de KPIs principales - Grid responsivo
                GridView.count(
                  crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 2),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isDesktop ? 1.3 : 1.1,
                  children: [
                    _buildStatCard(
                      title: 'Usuarios Totales',
                      value: _stats['totalUsuarios']?.toString() ?? '0',
                      icon: Icons.people_rounded,
                      color: const Color(0xFF007AFF),
                      subtitle:
                          '${_stats['voluntarios'] ?? 0} voluntarios, ${_stats['funcionarios'] ?? 0} funcionarios',
                    ),
                    _buildStatCard(
                      title: 'Proyectos Activos',
                      value: _stats['proyectosActivos']?.toString() ?? '0',
                      icon: Icons.folder_special_rounded,
                      color: const Color(0xFF34C759),
                      subtitle:
                          'de ${_stats['totalProyectos'] ?? 0} totales',
                    ),
                    _buildStatCard(
                      title: 'Organizaciones',
                      value: _stats['totalOrganizaciones']?.toString() ?? '0',
                      icon: Icons.business_rounded,
                      color: const Color(0xFFFF9500),
                    ),
                    _buildStatCard(
                      title: 'Administradores',
                      value: _stats['admins']?.toString() ?? '0',
                      icon: Icons.admin_panel_settings_rounded,
                      color: const Color(0xFFFF2D55),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Título de opciones
                const Text(
                  'Gestión del Sistema',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 20),

                // Lista de opciones - Grid responsivo para desktop
                if (isDesktop)
                  GridView.count(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.2,
                    children: _buildAdminOptionsCards(),
                  )
                else
                  Column(
                    children: _buildOptionsList(),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAdminOptionsCards() {
    final items = [
      _AdminOption(
        icon: Icons.people_rounded,
        title: 'Usuarios',
        subtitle: 'Gestionar usuarios',
        color: const Color(0xFF007AFF),
        route: '/admin/usuarios',
      ),
      _AdminOption(
        icon: Icons.admin_panel_settings_rounded,
        title: 'Roles',
        subtitle: 'Configurar roles',
        color: const Color(0xFF34C759),
        route: '/admin/roles',
      ),
      _AdminOption(
        icon: Icons.security_rounded,
        title: 'Permisos',
        subtitle: 'Asignar permisos',
        color: const Color(0xFFFF9500),
        route: '/admin/permisos',
      ),
      _AdminOption(
        icon: Icons.apps_rounded,
        title: 'Programas',
        subtitle: 'Gestionar programas',
        color: const Color(0xFF5856D6),
        route: '/admin/programas',
      ),
      _AdminOption(
        icon: Icons.emoji_events_rounded,
        title: 'Aptitudes',
        subtitle: 'Administrar habilidades',
        color: const Color(0xFFFF2D55),
        route: '/admin/aptitudes',
      ),
      _AdminOption(
        icon: Icons.business_rounded,
        title: 'Organizaciones',
        subtitle: 'Gestionar organizaciones',
        color: const Color(0xFF007AFF),
        route: '/admin/organizaciones',
      ),
      _AdminOption(
        icon: Icons.folder_special_rounded,
        title: 'Proyectos',
        subtitle: 'Gestionar proyectos',
        color: const Color(0xFF5856D6),
        route: '/admin/proyectos',
      ),
      _AdminOption(
        icon: Icons.task_rounded,
        title: 'Tareas',
        subtitle: 'Gestionar tareas',
        color: const Color(0xFF007AFF),
        route: '/admin/tareas',
      ),
    ];

    return items
        .map((item) => _buildCardOption(item))
        .toList();
  }

  Widget _buildCardOption(_AdminOption data) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Modular.to.pushNamed(data.route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: data.color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                data.subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF86868B),
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF86868B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF86868B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOptionsList() {
    final items = [
      _AdminOption(
        icon: Icons.people_rounded,
        title: 'Usuarios',
        subtitle: 'Gestionar usuarios',
        color: const Color(0xFF007AFF),
        route: '/admin/usuarios',
      ),
      _AdminOption(
        icon: Icons.admin_panel_settings_rounded,
        title: 'Roles',
        subtitle: 'Configurar roles',
        color: const Color(0xFF34C759),
        route: '/admin/roles',
      ),
      _AdminOption(
        icon: Icons.security_rounded,
        title: 'Permisos',
        subtitle: 'Asignar permisos',
        color: const Color(0xFFFF9500),
        route: '/admin/permisos',
      ),
      _AdminOption(
        icon: Icons.apps_rounded,
        title: 'Programas',
        subtitle: 'Gestionar programas',
        color: const Color(0xFF5856D6),
        route: '/admin/programas',
      ),
      _AdminOption(
        icon: Icons.emoji_events_rounded,
        title: 'Aptitudes',
        subtitle: 'Administrar habilidades',
        color: const Color(0xFFFF2D55),
        route: '/admin/aptitudes',
      ),
      _AdminOption(
        icon: Icons.business_rounded,
        title: 'Organizaciones',
        subtitle: 'Gestionar organizaciones',
        color: const Color(0xFF007AFF),
        route: '/admin/organizaciones',
      ),
      _AdminOption(
        icon: Icons.folder_special_rounded,
        title: 'Proyectos',
        subtitle: 'Gestionar proyectos',
        color: const Color(0xFF5856D6),
        route: '/admin/proyectos',
      ),
      _AdminOption(
        icon: Icons.task_rounded,
        title: 'Tareas',
        subtitle: 'Gestionar tareas',
        color: const Color(0xFF007AFF),
        route: '/admin/tareas',
      ),
    ];

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return Padding(
        padding: EdgeInsets.only(bottom: index < items.length - 1 ? 12 : 0),
        child: _buildCleanCard(item),
      );
    }).toList();
  }

  Widget _buildCleanCard(_AdminOption data) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => Modular.to.pushNamed(data.route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: data.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF86868B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: Color(0xFFC7C7CC),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Skeleton para tarjetas de estadísticas
  Widget _buildStatCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonWidget(
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(24),
              ),
              const Spacer(),
              SkeletonWidget(
                width: 24,
                height: 24,
                borderRadius: BorderRadius.circular(4),
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
              const SizedBox(height: 4),
              SkeletonWidget(
                width: 100,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;

  _AdminOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });
}