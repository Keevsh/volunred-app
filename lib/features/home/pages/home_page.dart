import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/repositories/organizacion_repository.dart';
import '../../../core/services/profile_check_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/models/organizacion.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/inscripcion.dart';
import '../../../core/widgets/social_components.dart';
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
          // Primero verificar desde storage (más rápido y confiable)
          if (usuario.isFuncionario) {
            final tienePerfil = await authRepo.tienePerfilFuncionario();
            if (!tienePerfil && mounted) {
              print('📋 Funcionario en home pero no tiene perfil guardado, redirigiendo a crear organización');
              Future.microtask(() {
                Modular.to.navigate('/profile/create-organizacion');
              });
              return;
            }
          } else if (usuario.isVoluntario) {
            // Para voluntarios, verificar desde storage también
            final perfilVolJson = await StorageService.getString(ApiConfig.perfilVoluntarioKey);
            if (perfilVolJson == null && mounted) {
              print('📋 Voluntario en home pero no tiene perfil guardado, redirigiendo a crear perfil');
              Future.microtask(() {
                Modular.to.navigate('/profile/create');
              });
              return;
            }
          }
          
          // Si llegamos aquí, el usuario tiene perfil o es admin
          print('✅ Usuario tiene perfil o es admin, continuando en home');
        } catch (e) {
          print('❌ Error verificando perfil en home: $e');
          // Continuar mostrando el home aunque haya error (mejor UX)
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

  // ========== VISTA HOME - ESTILO RED SOCIAL ==========
  Widget _buildHomeView() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadUserData();
        setState(() {});
      },
      child: CustomScrollView(
        slivers: [
          // AppBar estilo Instagram/Facebook
          SliverAppBar(
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.backgroundWhite,
            title: Row(
              children: [
                Text(
                  'VolunRed',
                  style: const TextStyle(
                    fontSize: AppStyles.fontSizeTitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_box_outlined, color: AppColors.textPrimary),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: AppColors.textPrimary),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.send_outlined, color: AppColors.textPrimary),
                  onPressed: () {},
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: AppColors.borderLight,
              ),
            ),
          ),
          
          // Sección de historias/stories
          SliverToBoxAdapter(
            child: SocialComponents.storiesSection(
              stories: [
                {
                  'userName': 'Cruz Roja',
                  'userAvatar': null,
                  'isViewed': false,
                  'onTap': () {},
                },
                {
                  'userName': 'ONG Verde',
                  'userAvatar': null,
                  'isViewed': true,
                  'onTap': () {},
                },
              ],
              onAddStory: () {
                // Crear nueva historia
              },
            ),
          ),
          
          // Feed de actividades
          SliverPadding(
            padding: EdgeInsets.zero,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildFeedItem(index);
                },
                childCount: 10, // Número de items en el feed
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeedItem(int index) {
    // Simular diferentes tipos de contenido en el feed
    if (index == 0) {
      return _buildProjectFeedCard();
    } else if (index == 1) {
      return _buildActivityFeedCard();
    } else {
      return _buildGenericFeedCard(index);
    }
  }
  
  Widget _buildProjectFeedCard() {
    return FutureBuilder<List<Proyecto>>(
      future: _loadProyectosOrganizacion(),
      builder: (context, proyectosSnapshot) {
        if (proyectosSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }
        
        if (proyectosSnapshot.hasError || proyectosSnapshot.data == null || proyectosSnapshot.data!.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(AppStyles.spacingMedium),
            padding: const EdgeInsets.all(AppStyles.spacingLarge),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
            ),
            child: Column(
              children: [
                SocialComponents.circleAvatar(name: 'VolunRed', size: 60),
                const SizedBox(height: AppStyles.spacingMedium),
                const Text(
                  'Explora proyectos de voluntariado',
                  style: TextStyle(
                    fontSize: AppStyles.fontSizeBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppStyles.spacingSmall),
                const Text(
                  'Descubre nuevas oportunidades de ayudar',
                  style: TextStyle(
                    fontSize: AppStyles.fontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final proyecto = proyectosSnapshot.data!.first;
        
        // Cargar la organización en paralelo
        return FutureBuilder<Organizacion?>(
          future: _loadOrganizacion(),
          builder: (context, orgSnapshot) {
            String orgName;
            if (orgSnapshot.data != null) {
              orgName = orgSnapshot.data!.nombre;
            } else if (proyecto.organizacion != null && proyecto.organizacion is Map<String, dynamic>) {
              final orgMap = proyecto.organizacion as Map<String, dynamic>;
              orgName = orgMap['nombre']?.toString() ?? 'Organización';
            } else {
              orgName = 'Organización';
            }
            
            return SocialComponents.projectPostCard(
              projectName: proyecto.nombre,
              organizationName: orgName,
              organizationAvatar: null,
              imageUrl: null,
              description: proyecto.objetivo,
              location: proyecto.ubicacion,
              date: proyecto.fechaInicio != null 
                  ? '${proyecto.fechaInicio!.day}/${proyecto.fechaInicio!.month}/${proyecto.fechaInicio!.year}'
                  : null,
              volunteersCount: 0,
              onTap: () {},
              onLike: () {},
              onApply: () {
                Modular.to.pushNamed('/proyectos/${proyecto.idProyecto}');
              },
            );
          },
        );
      },
    );
  }
  
  Widget _buildActivityFeedCard() {
    return SocialComponents.postCard(
      userName: 'VolunRed',
      userAvatar: null,
      timeAgo: 'Hace 2 horas',
      description: '🌟 ¡Nuevas oportunidades de voluntariado disponibles! Descubre proyectos increíbles y ayuda a hacer la diferencia en tu comunidad.',
      likesCount: 24,
      commentsCount: 5,
      isLiked: false,
      onLike: () {},
      onComment: () {},
      onShare: () {},
      customContent: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.volunteer_activism,
            size: 64,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  
  Widget _buildGenericFeedCard(int index) {
    return SocialComponents.postCard(
      userName: 'Organización ${index + 1}',
      userAvatar: null,
      timeAgo: 'Hace ${index + 1} horas',
      description: 'Únete a nuestro proyecto de voluntariado y ayuda a crear un impacto positivo en la comunidad. Cada pequeño esfuerzo cuenta.',
      likesCount: (index + 1) * 5,
      commentsCount: index + 1,
      isLiked: index % 2 == 0,
      onLike: () {},
      onComment: () {},
      onShare: () {},
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

  // ========== VISTAS FUNCIONARIO - ESTILO RED SOCIAL ==========

  Widget _buildFuncionarioHomeView() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadUserData();
        setState(() {});
      },
      child: CustomScrollView(
        slivers: [
          // AppBar estilo Instagram/Facebook
          SliverAppBar(
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.backgroundWhite,
            title: Row(
              children: [
                Text(
                  'Mi Organización',
                  style: const TextStyle(
                    fontSize: AppStyles.fontSizeTitle,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_box_outlined, color: AppColors.textPrimary),
                  onPressed: () {
                    Modular.to.pushNamed('/proyectos/create');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                  onPressed: () {},
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: AppColors.borderLight,
              ),
            ),
          ),
          
          // Información de organización tipo perfil
          SliverToBoxAdapter(
            child: _buildFuncionarioOrganizationCard(),
          ),
          
          // Sección de estadísticas tipo stories
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppStyles.spacingMedium),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderLight,
                    width: 1,
                  ),
                ),
              ),
              child: _buildFuncionarioStatsSection(),
            ),
          ),
          
          // Feed de proyectos
          SliverPadding(
            padding: EdgeInsets.zero,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildFuncionarioProjectFeedItem(index);
                },
                childCount: 10, // Ajustar según necesidad
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFuncionarioOrganizationCard() {
    return FutureBuilder<Organizacion?>(
      future: _loadOrganizacion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasError || snapshot.data == null) {
          return Container(
            margin: const EdgeInsets.all(AppStyles.spacingMedium),
            padding: const EdgeInsets.all(AppStyles.spacingLarge),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
            ),
            child: Column(
              children: [
                SocialComponents.gradientAvatar(name: _userName, size: 80),
                const SizedBox(height: AppStyles.spacingMedium),
                const Text(
                  'No tienes organización',
                  style: TextStyle(
                    fontSize: AppStyles.fontSizeBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppStyles.spacingSmall),
                ElevatedButton(
                  onPressed: () => Modular.to.pushNamed('/profile/create-organizacion'),
                  child: const Text('Crear Organización'),
                ),
              ],
            ),
          );
        }
        
        final org = snapshot.data!;
        return Container(
          margin: const EdgeInsets.all(AppStyles.spacingMedium),
          padding: const EdgeInsets.all(AppStyles.spacingLarge),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          ),
          child: Column(
            children: [
              SocialComponents.gradientAvatar(
                name: org.nombre,
                size: 100,
              ),
              const SizedBox(height: AppStyles.spacingMedium),
              Text(
                org.nombre,
                style: const TextStyle(
                  fontSize: AppStyles.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (org.email.isNotEmpty) ...[
                const SizedBox(height: AppStyles.spacingSmall),
                Text(
                  org.email,
                  style: const TextStyle(
                    fontSize: AppStyles.fontSizeBody,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (org.direccion != null && org.direccion!.isNotEmpty) ...[
                const SizedBox(height: AppStyles.spacingSmall),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        org.direccion!,
                        style: const TextStyle(
                          fontSize: AppStyles.fontSizeSmall,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildFuncionarioProjectFeedItem(int index) {
    return FutureBuilder<List<Proyecto>>(
      future: _loadProyectosOrganizacion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && index == 0) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.all(AppStyles.spacingMedium),
              padding: const EdgeInsets.all(AppStyles.spacingLarge),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
              ),
              child: Column(
                children: [
                  const Icon(Icons.folder_outlined, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: AppStyles.spacingMedium),
                  const Text(
                    'No tienes proyectos aún',
                    style: TextStyle(
                      fontSize: AppStyles.fontSizeBody,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppStyles.spacingSmall),
                  ElevatedButton.icon(
                    onPressed: () => Modular.to.pushNamed('/proyectos/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Proyecto'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }
        
        if (index >= snapshot.data!.length) {
          return const SizedBox.shrink();
        }
        
        final proyecto = snapshot.data![index];
        
        // Cargar la organización para obtener el nombre
        return FutureBuilder<Organizacion?>(
          future: _loadOrganizacion(),
          builder: (context, orgSnapshot) {
            String orgName;
            if (orgSnapshot.data != null) {
              orgName = orgSnapshot.data!.nombre;
            } else if (proyecto.organizacion != null && proyecto.organizacion is Map<String, dynamic>) {
              final orgMap = proyecto.organizacion as Map<String, dynamic>;
              orgName = orgMap['nombre']?.toString() ?? 'Mi Organización';
            } else {
              orgName = 'Mi Organización';
            }
            
            return SocialComponents.projectPostCard(
              projectName: proyecto.nombre,
              organizationName: orgName,
              organizationAvatar: null,
              imageUrl: null,
              description: proyecto.objetivo,
              location: proyecto.ubicacion,
              date: proyecto.fechaInicio != null 
                  ? '${proyecto.fechaInicio!.day}/${proyecto.fechaInicio!.month}/${proyecto.fechaInicio!.year}'
                  : null,
              volunteersCount: 0,
              onTap: () {
                Modular.to.pushNamed('/proyectos/${proyecto.idProyecto}');
              },
              onLike: () {},
              onApply: () {
                Modular.to.pushNamed('/proyectos/${proyecto.idProyecto}');
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFuncionarioStatsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadFuncionarioStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {
          'proyectos': 0,
          'inscripciones_pendientes': 0,
          'voluntarios': 0,
        };
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItemCompact(
              count: '${stats['proyectos'] ?? 0}',
              label: 'Proyectos',
              icon: Icons.folder,
              gradient: AppColors.gradientBlue,
            ),
            _buildStatItemCompact(
              count: '${stats['inscripciones_pendientes'] ?? 0}',
              label: 'Pendientes',
              icon: Icons.person_add,
              gradient: AppColors.gradientOrange,
            ),
            _buildStatItemCompact(
              count: '${stats['voluntarios'] ?? 0}',
              label: 'Voluntarios',
              icon: Icons.people,
              gradient: AppColors.gradientGreen,
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildStatItemCompact({
    required String count,
    required String label,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            fontSize: AppStyles.fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppStyles.fontSizeSmall,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
      // Si somos funcionarios, usar el repositorio de funcionarios
      if (_isFuncionario) {
        final funcionarioRepo = Modular.get<FuncionarioRepository>();
        return await funcionarioRepo.getProyectos();
      }
      
      // Si somos voluntarios, obtener proyectos de la organización a la que pertenecen
      // (esto se implementará más adelante)
      return [];
    } catch (e) {
      print('Error cargando proyectos: $e');
      // En caso de error, retornar lista vacía para no romper la UI
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
