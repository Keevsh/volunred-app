import 'package:flutter/material.dart';
import '../../../core/theme/app_styles.dart';

class ViewFuncionarioProfilePage extends StatefulWidget {
  const ViewFuncionarioProfilePage({super.key});

  @override
  State<ViewFuncionarioProfilePage> createState() =>
      _ViewFuncionarioProfilePageState();
}

class _ViewFuncionarioProfilePageState
    extends State<ViewFuncionarioProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Datos de ejemplo (reemplazar con datos reales desde API)
  final Map<String, dynamic> funcionario = {
    'nombres': 'Juan',
    'apellidos': 'García',
    'email': 'juan@example.com',
    'telefono': '+591 2 1234567',
    'organizacion': 'Cruz Roja Boliviana',
    'cargo': 'Coordinador de Voluntariado',
    'departamento': 'Recursos Humanos',
    'bio':
        'Profesional apasionado por el voluntariado con 5 años de experiencia coordinando proyectos sociales. Especializado en gestión de voluntarios y desarrollo comunitario.',
    'sitioWeb': 'www.cruzroja.org.bo',
    'fotoPerfil': null,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Perfil de Funcionario'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: Navegar a editar perfil
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeaderSection(colorScheme),
              const SizedBox(height: 24),
              _buildContactSection(colorScheme),
              const SizedBox(height: 16),
              _buildProfessionalSection(colorScheme),
              const SizedBox(height: 16),
              _buildBioSection(colorScheme),
              const SizedBox(height: 16),
              _buildStatsSection(colorScheme),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Foto de perfil
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: funcionario['fotoPerfil'] != null
                  ? Image.network(
                      funcionario['fotoPerfil'],
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Nombre completo
          Text(
            '${funcionario['nombres']} ${funcionario['apellidos']}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Cargo
          Text(
            funcionario['cargo'],
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          // Organización
          Text(
            funcionario['organizacion'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),

          const SizedBox(height: 16),

          // Badge de estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green[400],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Activo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_mail_outlined, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Información de Contacto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            colorScheme: colorScheme,
            icon: Icons.email_outlined,
            label: 'Email',
            value: funcionario['email'],
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            colorScheme: colorScheme,
            icon: Icons.phone_outlined,
            label: 'Teléfono',
            value: funcionario['telefono'],
          ),
          if (funcionario['sitioWeb'] != null && funcionario['sitioWeb']!.isNotEmpty)
            ...[
              const SizedBox(height: 12),
              _buildContactItem(
                colorScheme: colorScheme,
                icon: Icons.language,
                label: 'Sitio Web',
                value: funcionario['sitioWeb'],
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalSection(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work_outline, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Información Profesional',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProfessionalItem(
            colorScheme: colorScheme,
            icon: Icons.business_center,
            label: 'Cargo',
            value: funcionario['cargo'],
          ),
          const SizedBox(height: 12),
          _buildProfessionalItem(
            colorScheme: colorScheme,
            icon: Icons.corporate_fare,
            label: 'Departamento',
            value: funcionario['departamento'],
          ),
          const SizedBox(height: 12),
          _buildProfessionalItem(
            colorScheme: colorScheme,
            icon: Icons.business,
            label: 'Organización',
            value: funcionario['organizacion'],
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalItem({
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBioSection(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Sobre el Funcionario',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            funcionario['bio'],
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  colorScheme: colorScheme,
                  icon: Icons.folder_outlined,
                  label: 'Proyectos',
                  value: '8',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  colorScheme: colorScheme,
                  icon: Icons.group_outlined,
                  label: 'Voluntarios',
                  value: '45',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  colorScheme: colorScheme,
                  icon: Icons.schedule_outlined,
                  label: 'Horas',
                  value: '320',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  colorScheme: colorScheme,
                  icon: Icons.trending_up_outlined,
                  label: 'Impacto',
                  value: '9/10',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
