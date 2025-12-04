import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/models/perfil_funcionario.dart';
import '../../../core/repositories/funcionario_repository.dart';

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
  
  final FuncionarioRepository _repository =
      Modular.get<FuncionarioRepository>();

  PerfilFuncionario? _perfil;
  bool _isLoading = true;
  String? _error;

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
    _loadPerfil();
  }

  Future<void> _loadPerfil() async {
    try {
      final perfil = await _repository.getMiPerfil();
      setState(() {
        _perfil = perfil;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Perfil de Funcionario'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.onSurface,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _perfil == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Perfil de Funcionario'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.onSurface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Error: ${_error ?? 'Perfil no encontrado'}'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadPerfil();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

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
              Modular.to.pushNamed('/profile/edit-funcionario');
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
              child: _perfil?.fotoPerfil != null && _perfil!.fotoPerfil!.isNotEmpty
                  ? Image.memory(
                      base64Decode(_perfil!.fotoPerfil!.split(',').last),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white.withOpacity(0.2),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        );
                      },
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
            '${(_perfil?.usuario?['nombres'] ?? '')} ${(_perfil?.usuario?['apellidos'] ?? '')}',
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
            _perfil?.cargo ?? 'Funcionario',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          // Organización
          if (_perfil?.organizacion?['nombre'] != null)
            Text(
              _perfil!.organizacion!['nombre'],
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
            value: _perfil?.usuario?['email'] ?? 'No disponible',
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            colorScheme: colorScheme,
            icon: Icons.phone_outlined,
            label: 'Teléfono',
            value: _perfil?.usuario?['telefono'] ?? 'No disponible',
          ),
          if (_perfil?.usuario?['sitio_web'] != null && (_perfil?.usuario?['sitio_web'] as String?)?.isNotEmpty == true)
            ...[
              const SizedBox(height: 12),
              _buildContactItem(
                colorScheme: colorScheme,
                icon: Icons.language,
                label: 'Sitio Web',
                value: _perfil!.usuario!['sitio_web'],
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
            value: _perfil?.cargo ?? 'No especificado',
          ),
          const SizedBox(height: 12),
          _buildProfessionalItem(
            colorScheme: colorScheme,
            icon: Icons.corporate_fare,
            label: 'Departamento/Área',
            value: _perfil?.area ?? _perfil?.departamento ?? 'No especificado',
          ),
          const SizedBox(height: 12),
          _buildProfessionalItem(
            colorScheme: colorScheme,
            icon: Icons.business,
            label: 'Organización',
            value: _perfil?.organizacion?['nombre'] ?? 'No especificada',
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
            _perfil?.usuario?['bio'] ?? 'Sin información disponible',
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
