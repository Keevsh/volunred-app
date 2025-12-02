import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/auth_repository.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Gris claro estilo Apple
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
                          'Gestiona el sistema',
                          style: TextStyle(
                            fontSize: 17,
                            color: Color(0xFF86868B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón de logout simple
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

              // Lista de opciones
              ..._buildOptionsList(),
            ],
          ),
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
        color: const Color(0xFF007AFF), // Azul Apple
        route: '/admin/usuarios',
      ),
      _AdminOption(
        icon: Icons.admin_panel_settings_rounded,
        title: 'Roles',
        subtitle: 'Configurar roles',
        color: const Color(0xFF34C759), // Verde Apple
        route: '/admin/roles',
      ),
      _AdminOption(
        icon: Icons.security_rounded,
        title: 'Permisos',
        subtitle: 'Asignar permisos',
        color: const Color(0xFFFF9500), // Naranja Apple
        route: '/admin/permisos',
      ),
      _AdminOption(
        icon: Icons.apps_rounded,
        title: 'Programas',
        subtitle: 'Gestionar programas',
        color: const Color(0xFF5856D6), // Morado Apple
        route: '/admin/programas',
      ),
      _AdminOption(
        icon: Icons.emoji_events_rounded,
        title: 'Aptitudes',
        subtitle: 'Administrar habilidades',
        color: const Color(0xFFFF2D55), // Rosa Apple
        route: '/admin/aptitudes',
      ),
      _AdminOption(
        icon: Icons.business_rounded,
        title: 'Organizaciones',
        subtitle: 'Gestionar organizaciones',
        color: const Color(0xFF007AFF), // Azul Apple
        route: '/admin/organizaciones',
      ),
      _AdminOption(
        icon: Icons.folder_special_rounded,
        title: 'Proyectos',
        subtitle: 'Gestionar proyectos',
        color: const Color(0xFF5856D6), // Morado Apple
        route: '/admin/proyectos',
      ),
      _AdminOption(
        icon: Icons.task_rounded,
        title: 'Tareas',
        subtitle: 'Gestionar tareas',
        color: const Color(0xFF007AFF), // Azul Apple
        route: '/admin/tareas',
      ),
      _AdminOption(
        icon: Icons.person_add_rounded,
        title: 'Inscripciones',
        subtitle: 'Aprobar/rechazar',
        color: const Color(0xFFFF9500), // Naranja Apple
        route: '/admin/inscripciones',
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
              // Icono circular
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
              // Contenido
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
              // Flecha
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
