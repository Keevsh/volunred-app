import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/theme/theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _userName = 'Usuario';

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
      });
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
        children: [
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
          items: const [
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
}
