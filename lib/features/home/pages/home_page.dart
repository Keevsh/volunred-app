import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/repositories/organizacion_repository.dart';
import '../../../core/services/profile_check_service.dart';
import '../../../core/models/organizacion.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/inscripcion.dart';
import '../../../core/theme/theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _userName = 'Usuario';
  bool _isAdmin = false;
  bool _isFuncionario = false;
  int? _usuarioId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authRepo = Modular.get<AuthRepository>();
    final usuario = await authRepo.getStoredUser();
    if (usuario != null) {
      setState(() {
        _userName = usuario.nombres;
        _isAdmin = usuario.isAdmin; // id_rol == 1
        _isFuncionario = usuario.isFuncionario; // id_rol == 2
        _usuarioId = usuario.idUsuario;
      });
      
      // Verificar si el usuario necesita crear un perfil
      // Admin no necesita perfil, puede estar aquí
      if (!usuario.isAdmin) {
        try {
          final profileRoute = await ProfileCheckService.checkProfile(usuario);
          if (profileRoute != null && mounted) {
            // El usuario no tiene el perfil requerido, redirigir a crear perfil
            print('📋 Usuario en home pero no tiene perfil, redirigiendo a: $profileRoute');
            Future.microtask(() {
              Modular.to.navigate(profileRoute);
            });
            return;
          }
        } catch (e) {
          print('❌ Error verificando perfil en home: $e');
          // Continuar mostrando el home aunque haya error
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Cerrar Sesión',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authRepo = Modular.get<AuthRepository>();
      await authRepo.logout();
      if (mounted) {
        Modular.to.navigate('/auth/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: IndexedStack(
        index: _currentIndex,
        children: _isFuncionario
            ? [
                _buildFuncionarioHomeView(),
                _buildFuncionarioProyectosView(),
                _buildFuncionarioInscripcionesView(),
                _buildProfileView(),
              ]
            : [
                _buildHomeView(),
                _buildActivitiesView(),
                _buildProfileView(),
              ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: AppStyles.fontSizeSmall,
          unselectedFontSize: AppStyles.fontSizeSmall,
          items: _isFuncionario
              ? const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.folder_outlined),
                    activeIcon: Icon(Icons.folder),
                    label: 'Proyectos',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_add_outlined),
                    activeIcon: Icon(Icons.person_add),
                    label: 'Inscripciones',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Perfil',
                  ),
                ]
              : const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Inicio',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.volunteer_activism_outlined),
                    activeIcon: Icon(Icons.volunteer_activism),
                    label: 'Actividades',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Perfil',
                  ),
                ],
        ),
      ),
    );
  }

  // ========== VISTA HOME ==========
  Widget _buildHomeView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppStyles.spacingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '¡Hola, $_userName!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppStyles.fontSizeHeader,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppStyles.spacingSmall),
                      const Text(
                        'Bienvenido a VolunRed',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: AppStyles.fontSizeBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppStyles.spacingLarge),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildStatsSection(),
              const SizedBox(height: AppStyles.spacingLarge),
              _buildQuickActionsSection(),
              const SizedBox(height: AppStyles.spacingLarge),
              _buildRecentActivitiesSection(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: AppWidgets.gradientCard(
            gradientColors: AppColors.gradientGreen,
            child: Column(
              children: [
                AppWidgets.decorativeIcon(
                  icon: Icons.volunteer_activism,
                  color: Colors.white,
                ),
                const SizedBox(height: AppStyles.spacingSmall),
                const Text(
                  '0',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Actividades',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: AppStyles.fontSizeSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppStyles.spacingMedium),
        Expanded(
          child: AppWidgets.gradientCard(
            gradientColors: AppColors.gradientBlue,
            child: Column(
              children: [
                AppWidgets.decorativeIcon(
                  icon: Icons.access_time,
                  color: Colors.white,
                ),
                const SizedBox(height: AppStyles.spacingSmall),
                const Text(
                  '0h',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Horas',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: AppStyles.fontSizeSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: AppStyles.fontSizeTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppStyles.spacingMedium),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppStyles.spacingMedium,
          crossAxisSpacing: AppStyles.spacingMedium,
          children: [
            _buildActionCard(
              icon: Icons.search,
              title: 'Buscar\nActividades',
              color: AppColors.iconBlue,
              onTap: () {
                AppWidgets.showStyledSnackBar(
                  context: context,
                  message: 'Próximamente disponible',
                  isError: false,
                );
              },
            ),
            _buildActionCard(
              icon: Icons.edit_note,
              title: 'Mis\nExperiencias',
              color: AppColors.iconGreen,
              onTap: () => Modular.to.pushNamed('/experiencias'),
            ),
            _buildActionCard(
              icon: Icons.notifications_outlined,
              title: 'Notificaciones',
              color: AppColors.iconAmber,
              onTap: () {
                AppWidgets.showStyledSnackBar(
                  context: context,
                  message: 'Próximamente disponible',
                  isError: false,
                );
              },
            ),
            _buildActionCard(
              icon: Icons.people_outline,
              title: 'Organizaciones',
              color: AppColors.iconRed,
              onTap: () {
                AppWidgets.showStyledSnackBar(
                  context: context,
                  message: 'Próximamente disponible',
                  isError: false,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingMedium),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: AppStyles.iconSizeLarge),
            ),
            const SizedBox(height: AppStyles.spacingSmall),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppStyles.fontSizeSmall,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividades Recientes',
          style: TextStyle(
            fontSize: AppStyles.fontSizeTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppStyles.spacingMedium),
        _buildEmptyState(
          icon: Icons.volunteer_activism_outlined,
          message: 'Aún no tienes actividades',
          subtitle: 'Comienza a explorar oportunidades de voluntariado',
        ),
      ],
    );
  }

  // ========== VISTA ACTIVIDADES ==========
  Widget _buildActivitiesView() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Mis Actividades'),
            backgroundColor: AppColors.primary,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppStyles.spacingLarge),
            sliver: SliverToBoxAdapter(
              child: _buildEmptyState(
                icon: Icons.calendar_today_outlined,
                message: 'No tienes actividades programadas',
                subtitle: 'Explora nuevas oportunidades de voluntariado',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== VISTA PERFIL ==========
  Widget _buildProfileView() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppStyles.spacingLarge),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppStyles.spacingSmall),
                        Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppStyles.fontSizeTitle,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppStyles.spacingLarge),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Mostrar opción de Admin solo si es administrador
                if (_isAdmin) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: AppStyles.spacingMedium),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple, Colors.purple.shade700],
                      ),
                      borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Modular.to.pushNamed('/admin/'),
                        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                        child: Padding(
                          padding: const EdgeInsets.all(AppStyles.spacingMedium),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppStyles.spacingSmall),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(AppStyles.borderRadiusSmall),
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppStyles.spacingMedium),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Panel de Administración',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Gestionar sistema',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacingMedium),
                ],
                _buildProfileOption(
                  icon: Icons.person_outline,
                  title: 'Editar Perfil',
                  onTap: () {
                    AppWidgets.showStyledSnackBar(
                      context: context,
                      message: 'Próximamente disponible',
                      isError: false,
                    );
                  },
                ),
                _buildProfileOption(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Mis Aptitudes',
                  onTap: () => Modular.to.pushNamed('/profile/aptitudes'),
                ),
                _buildProfileOption(
                  icon: Icons.history_edu_outlined,
                  title: 'Experiencias de Voluntariado',
                  onTap: () => Modular.to.pushNamed('/experiencias'),
                ),
                _buildProfileOption(
                  icon: Icons.settings_outlined,
                  title: 'Configuración',
                  onTap: () {
                    AppWidgets.showStyledSnackBar(
                      context: context,
                      message: 'Próximamente disponible',
                      isError: false,
                    );
                  },
                ),
                const SizedBox(height: AppStyles.spacingLarge),
                AppWidgets.gradientButton(
                  text: 'Cerrar Sesión',
                  onPressed: _handleLogout,
                  icon: Icons.logout,
                  gradientColors: [AppColors.error, AppColors.error.withOpacity(0.8)],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppStyles.spacingSmall),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusSmall),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingXLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppStyles.spacingLarge),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AppStyles.spacingLarge),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppStyles.fontSizeBody,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppStyles.spacingSmall),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppStyles.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ========== VISTAS FUNCIONARIO ==========

  Widget _buildFuncionarioHomeView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppStyles.spacingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '¡Hola, $_userName!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppStyles.fontSizeHeader,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppStyles.spacingSmall),
                      const Text(
                        'Panel de Gestión de Organización',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: AppStyles.fontSizeBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppStyles.spacingLarge),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildFuncionarioStatsSection(),
              const SizedBox(height: AppStyles.spacingLarge),
              _buildFuncionarioQuickActionsSection(),
              const SizedBox(height: AppStyles.spacingLarge),
              _buildFuncionarioOrganizationInfo(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildFuncionarioStatsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadFuncionarioStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {
          'proyectos': 0,
          'inscripciones_pendientes': 0,
        };
        
        return Row(
          children: [
            Expanded(
              child: AppWidgets.gradientCard(
                gradientColors: AppColors.gradientBlue,
                child: Column(
                  children: [
                    AppWidgets.decorativeIcon(
                      icon: Icons.folder,
                      color: Colors.white,
                    ),
                    const SizedBox(height: AppStyles.spacingSmall),
                    Text(
                      '${stats['proyectos']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Proyectos',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: AppStyles.fontSizeSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppStyles.spacingMedium),
            Expanded(
              child: AppWidgets.gradientCard(
                gradientColors: AppColors.gradientGreen,
                child: Column(
                  children: [
                    AppWidgets.decorativeIcon(
                      icon: Icons.person_add,
                      color: Colors.white,
                    ),
                    const SizedBox(height: AppStyles.spacingSmall),
                    Text(
                      '${stats['inscripciones_pendientes']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Pendientes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: AppStyles.fontSizeSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadFuncionarioStats() async {
    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      final dashboard = await funcionarioRepo.getDashboard();
      
      return {
        'proyectos': dashboard['total_proyectos'] ?? 0,
        'inscripciones_pendientes': dashboard['inscripciones_pendientes'] ?? 0,
      };
    } catch (e) {
      print('Error cargando estadísticas: $e');
      return {'proyectos': 0, 'inscripciones_pendientes': 0};
    }
  }

  Widget _buildFuncionarioQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: AppStyles.fontSizeTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppStyles.spacingMedium),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppStyles.spacingMedium,
          crossAxisSpacing: AppStyles.spacingMedium,
          children: [
            _buildActionCard(
              icon: Icons.add_circle_outline,
              title: 'Nuevo\nProyecto',
              color: AppColors.iconBlue,
              onTap: () {
                AppWidgets.showStyledSnackBar(
                  context: context,
                  message: 'Crear proyecto - Próximamente',
                  isError: false,
                );
              },
            ),
            _buildActionCard(
              icon: Icons.task_outlined,
              title: 'Gestionar\nTareas',
              color: AppColors.iconGreen,
              onTap: () {
                AppWidgets.showStyledSnackBar(
                  context: context,
                  message: 'Gestión de tareas - Próximamente',
                  isError: false,
                );
              },
            ),
            _buildActionCard(
              icon: Icons.people_outline,
              title: 'Ver\nInscripciones',
              color: AppColors.iconAmber,
              onTap: () {
                setState(() => _currentIndex = 2);
              },
            ),
            _buildActionCard(
              icon: Icons.business_outlined,
              title: 'Mi\nOrganización',
              color: AppColors.iconRed,
              onTap: () {
                AppWidgets.showStyledSnackBar(
                  context: context,
                  message: 'Información de organización - Próximamente',
                  isError: false,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFuncionarioOrganizationInfo() {
    return FutureBuilder<Organizacion?>(
      future: _loadOrganizacion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final organizacion = snapshot.data;
        if (organizacion == null) {
          return Container(
            padding: const EdgeInsets.all(AppStyles.spacingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
            ),
            child: Column(
              children: [
                const Icon(Icons.business, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: AppStyles.spacingMedium),
                const Text(
                  'No tienes organización asignada',
                  style: TextStyle(
                    fontSize: AppStyles.fontSizeBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppStyles.spacingSmall),
                TextButton(
                  onPressed: () => Modular.to.pushNamed('/profile/create-organizacion'),
                  child: const Text('Crear Organización'),
                ),
              ],
            ),
          );
        }
        
        return Container(
          padding: const EdgeInsets.all(AppStyles.spacingLarge),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                    padding: const EdgeInsets.all(AppStyles.spacingMedium),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppStyles.borderRadiusSmall),
                    ),
                    child: Icon(Icons.business, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppStyles.spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organizacion.nombre.isNotEmpty 
                              ? organizacion.nombre 
                              : organizacion.razonSocial ?? 'Organización',
                          style: const TextStyle(
                            fontSize: AppStyles.fontSizeTitle,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (organizacion.email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            organizacion.email,
                            style: TextStyle(
                              fontSize: AppStyles.fontSizeSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Organizacion?> _loadOrganizacion() async {
    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      return await funcionarioRepo.getMiOrganizacion();
    } catch (e) {
      print('Error cargando organización: $e');
      return null;
    }
  }

  Widget _buildFuncionarioProyectosView() {
    return FutureBuilder<List<Proyecto>>(
      future: _loadProyectosOrganizacion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final proyectos = snapshot.data ?? [];
        
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Mis Proyectos'),
              backgroundColor: AppColors.primary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    AppWidgets.showStyledSnackBar(
                      context: context,
                      message: 'Crear proyecto - Próximamente',
                      isError: false,
                    );
                  },
                ),
              ],
            ),
            if (proyectos.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(
                  icon: Icons.folder_outlined,
                  message: 'No tienes proyectos',
                  subtitle: 'Crea tu primer proyecto para comenzar',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppStyles.spacingLarge),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final proyecto = proyectos[index];
                      return _buildProyectoCard(proyecto);
                    },
                    childCount: proyectos.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<List<Proyecto>> _loadProyectosOrganizacion() async {
    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      // Los endpoints de funcionarios ya filtran automáticamente por organización
      return await funcionarioRepo.getProyectos();
    } catch (e) {
      print('Error cargando proyectos: $e');
      return [];
    }
  }

  Widget _buildProyectoCard(Proyecto proyecto) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppStyles.spacingMedium),
        leading: Container(
          padding: const EdgeInsets.all(AppStyles.spacingMedium),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusSmall),
          ),
          child: Icon(Icons.folder, color: AppColors.primary),
        ),
        title: Text(
          proyecto.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (proyecto.objetivo != null && proyecto.objetivo!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                proyecto.objetivo!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: proyecto.estado == 'activo' 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                proyecto.estado,
                style: TextStyle(
                  fontSize: 12,
                  color: proyecto.estado == 'activo' ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () {
          AppWidgets.showStyledSnackBar(
            context: context,
            message: 'Detalle de proyecto - Próximamente',
            isError: false,
          );
        },
      ),
    );
  }

  Widget _buildFuncionarioInscripcionesView() {
    return FutureBuilder<List<Inscripcion>>(
      future: _loadInscripcionesOrganizacion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final inscripciones = snapshot.data ?? [];
        
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Inscripciones'),
              backgroundColor: AppColors.primary,
            ),
            if (inscripciones.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(
                  icon: Icons.person_add_outlined,
                  message: 'No hay inscripciones',
                  subtitle: 'Las solicitudes de voluntarios aparecerán aquí',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppStyles.spacingLarge),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final inscripcion = inscripciones[index];
                      return _buildInscripcionCard(inscripcion);
                    },
                    childCount: inscripciones.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<List<Inscripcion>> _loadInscripcionesOrganizacion() async {
    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      // Los endpoints de funcionarios ya filtran automáticamente por organización
      return await funcionarioRepo.getInscripciones();
    } catch (e) {
      print('Error cargando inscripciones: $e');
      return [];
    }
  }

  Widget _buildInscripcionCard(Inscripcion inscripcion) {
    final usuario = inscripcion.usuario;
    final nombreUsuario = usuario != null 
        ? '${usuario['nombres'] ?? ''} ${usuario['apellidos'] ?? ''}'.trim()
        : 'Usuario ${inscripcion.usuarioId}';
    
    final estadoColor = inscripcion.estado.toUpperCase() == 'APROBADO' 
        ? Colors.green
        : inscripcion.estado.toUpperCase() == 'RECHAZADO'
            ? Colors.red
            : Colors.orange;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppStyles.spacingMedium),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : 'U',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          nombreUsuario,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (usuario?['email'] != null) ...[
              const SizedBox(height: 4),
              Text(usuario!['email']),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: estadoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                inscripcion.estado,
                style: TextStyle(
                  fontSize: 12,
                  color: estadoColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: inscripcion.estado.toUpperCase() == 'PENDIENTE'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _aprobarInscripcion(inscripcion.idInscripcion),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _rechazarInscripcion(inscripcion.idInscripcion),
                  ),
                ],
              )
            : Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
    );
  }

  Future<void> _aprobarInscripcion(int id) async {
    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      await funcionarioRepo.aprobarInscripcion(id);
      if (mounted) {
        AppWidgets.showStyledSnackBar(
          context: context,
          message: 'Inscripción aprobada exitosamente',
          isError: false,
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        AppWidgets.showStyledSnackBar(
          context: context,
          message: 'Error al aprobar inscripción: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _rechazarInscripcion(int id) async {
    final motivoController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Inscripción'),
        content: TextField(
          controller: motivoController,
          decoration: const InputDecoration(
            labelText: 'Motivo del rechazo',
            hintText: 'Ingresa el motivo...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed == true && motivoController.text.isNotEmpty) {
      try {
        final funcionarioRepo = Modular.get<FuncionarioRepository>();
        await funcionarioRepo.rechazarInscripcion(id, motivoController.text);
        if (mounted) {
          AppWidgets.showStyledSnackBar(
            context: context,
            message: 'Inscripción rechazada',
            isError: false,
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          AppWidgets.showStyledSnackBar(
            context: context,
            message: 'Error al rechazar inscripción: $e',
            isError: true,
          );
        }
      }
    }
  }
}
