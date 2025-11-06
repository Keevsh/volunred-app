import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    _verificarAcceso();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestión del Sistema',
              style: TextStyle(
                fontSize: AppStyles.fontSizeTitle,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppStyles.spacingMedium),
            Text(
              'Administra usuarios, roles, permisos y configuraciones',
              style: TextStyle(
                fontSize: AppStyles.fontSizeBody,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppStyles.spacingXLarge),
            
            // Grid de acciones administrativas
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppStyles.spacingMedium,
              crossAxisSpacing: AppStyles.spacingMedium,
              childAspectRatio: 1.2,
              children: [
                _buildAdminCard(
                  icon: Icons.people,
                  title: 'Usuarios',
                  subtitle: 'Gestionar usuarios',
                  color: Colors.blue,
                  onTap: () => Modular.to.pushNamed('/admin/usuarios'),
                ),
                _buildAdminCard(
                  icon: Icons.admin_panel_settings,
                  title: 'Roles',
                  subtitle: 'Gestionar roles',
                  color: Colors.purple,
                  onTap: () => Modular.to.pushNamed('/admin/roles'),
                ),
                _buildAdminCard(
                  icon: Icons.security,
                  title: 'Permisos',
                  subtitle: 'Asignar permisos',
                  color: Colors.orange,
                  onTap: () => Modular.to.pushNamed('/admin/permisos'),
                ),
                _buildAdminCard(
                  icon: Icons.apps,
                  title: 'Programas',
                  subtitle: 'Gestionar programas',
                  color: Colors.green,
                  onTap: () => Modular.to.pushNamed('/admin/programas'),
                ),
                _buildAdminCard(
                  icon: Icons.emoji_events,
                  title: 'Aptitudes',
                  subtitle: 'Gestionar habilidades',
                  color: Colors.teal,
                  onTap: () => Modular.to.pushNamed('/admin/aptitudes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard({
    required IconData icon,
    required String title,
    required String subtitle,
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
        padding: const EdgeInsets.all(AppStyles.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingMedium),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: AppStyles.spacingMedium),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.spacingSmall),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: AppStyles.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
