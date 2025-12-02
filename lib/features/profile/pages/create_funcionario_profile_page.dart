import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_widgets.dart';

class CreateFuncionarioProfilePage extends StatefulWidget {
  const CreateFuncionarioProfilePage({super.key});

  @override
  State<CreateFuncionarioProfilePage> createState() =>
      _CreateFuncionarioProfilePageState();
}

class _CreateFuncionarioProfilePageState
    extends State<CreateFuncionarioProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cargoController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _bioController = TextEditingController();
  final _organizacionController = TextEditingController();
  final _sitioWebController = TextEditingController();
  final _telefonoController = TextEditingController();

  int _completionPercentage = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    // Agregar listeners a los controllers
    _organizacionController.addListener(_updateCompletionPercentage);
    _cargoController.addListener(_updateCompletionPercentage);
    _departamentoController.addListener(_updateCompletionPercentage);
    _bioController.addListener(_updateCompletionPercentage);

    // Actualizar porcentaje inicial
    _updateCompletionPercentage();
  }

  void _updateCompletionPercentage() {
    int filled = 0;
    if (_organizacionController.text.isNotEmpty) filled++;
    if (_cargoController.text.isNotEmpty) filled++;
    if (_departamentoController.text.isNotEmpty) filled++;
    if (_bioController.text.isNotEmpty) filled++;

    setState(() {
      _completionPercentage = (filled / 4 * 100).toInt();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cargoController
      ..removeListener(_updateCompletionPercentage)
      ..dispose();
    _departamentoController
      ..removeListener(_updateCompletionPercentage)
      ..dispose();
    _bioController
      ..removeListener(_updateCompletionPercentage)
      ..dispose();
    _organizacionController
      ..removeListener(_updateCompletionPercentage)
      ..dispose();
    _sitioWebController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authRepo = Modular.get<AuthRepository>();
    final usuario = await authRepo.getStoredUser();

    if (usuario == null) {
      _showSnackBar('Error: Usuario no encontrado');
      return;
    }

    print('👤 Usuario funcionario: ${usuario.toJson()}');
    print('📋 Cargo: ${_cargoController.text}');
    print('🏢 Departamento: ${_departamentoController.text}');
    print('🌐 Organización: ${_organizacionController.text}');
    print('🔗 Sitio Web: ${_sitioWebController.text}');
    print('📞 Teléfono: ${_telefonoController.text}');

    // TODO: Implementar creación de perfil de funcionario
    // Por ahora, solo redirigimos al home
    _showSnackBar('¡Perfil de funcionario creado! (Mock)', isError: false);

    Future.delayed(const Duration(milliseconds: 500), () {
      Modular.to.navigate('/home/');
    });
  }

  void _showSnackBar(String message, {bool isError = true}) {
    AppWidgets.showStyledSnackBar(
      context: context,
      message: message,
      isError: isError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colorScheme),
            _buildProgressIndicator(colorScheme),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildFormContent(colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completitud del perfil',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '$_completionPercentage%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _completionPercentage / 100,
              minHeight: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business_center,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Perfil de Funcionario',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completa tu información profesional',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección: Información de la Organización
            _buildSectionCard(
              colorScheme: colorScheme,
              title: 'Información de la Organización',
              icon: Icons.business,
              children: [
                AppWidgets.styledTextField(
                  controller: _organizacionController,
                  label: 'Nombre de la organización',
                  hint: 'Ej: Cruz Roja Boliviana',
                  prefixIcon: Icons.business,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Este campo es requerido';
                    }
                    if (value.length < 3) {
                      return 'Mínimo 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppWidgets.styledTextField(
                  controller: _sitioWebController,
                  label: 'Sitio web (opcional)',
                  hint: 'Ej: www.cruzroja.org.bo',
                  prefixIcon: Icons.language,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!value.contains('.')) {
                        return 'Ingresa un sitio web válido';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingLarge),

            // Sección: Información Personal del Funcionario
            _buildSectionCard(
              colorScheme: colorScheme,
              title: 'Tu Información',
              icon: Icons.person,
              children: [
                AppWidgets.styledTextField(
                  controller: _cargoController,
                  label: 'Tu cargo en la organización',
                  hint: 'Ej: Coordinador de Voluntariado',
                  prefixIcon: Icons.work_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Este campo es requerido';
                    }
                    if (value.length < 3) {
                      return 'Mínimo 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppWidgets.styledTextField(
                  controller: _departamentoController,
                  label: 'Departamento o área',
                  hint: 'Ej: Recursos Humanos',
                  prefixIcon: Icons.corporate_fare,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Este campo es requerido';
                    }
                    if (value.length < 2) {
                      return 'Mínimo 2 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppWidgets.styledTextField(
                  controller: _telefonoController,
                  label: 'Teléfono (opcional)',
                  hint: 'Ej: +591 2 1234567',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length < 7) {
                        return 'Teléfono inválido';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingLarge),

            // Sección: Descripción
            _buildSectionCard(
              colorScheme: colorScheme,
              title: 'Descripción del Rol',
              icon: Icons.description,
              children: [
                TextFormField(
                  controller: _bioController,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: 'Descripción de tu rol',
                    hintText:
                        'Cuéntanos sobre tu experiencia, responsabilidades y objetivos como funcionario...',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppStyles.borderRadiusMedium,
                      ),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Este campo es requerido';
                    }
                    if (value.length < 10) {
                      return 'Mínimo 10 caracteres';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingLarge),

            // Información adicional
            _buildInfoBox(
              colorScheme: colorScheme,
              icon: Icons.info_outline,
              title: 'Funcionalidades de Funcionario',
              description:
                  'Como funcionario podrás crear proyectos, gestionar voluntarios, generar reportes de impacto y coordinar actividades de voluntariado.',
            ),
            const SizedBox(height: AppStyles.spacingXLarge),

            // Botón de crear perfil
            AppWidgets.gradientButton(
              text: 'Crear Perfil',
              onPressed: _handleCreateProfile,
              icon: Icons.check_circle_outline,
            ),

            const SizedBox(height: AppStyles.spacingMedium),

            // Botón de saltar
            Center(
              child: TextButton(
                onPressed: () {
                  Modular.to.navigate('/home/');
                },
                child: Text(
                  'Completar después',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppStyles.fontSizeSmall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required ColorScheme colorScheme,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
              Icon(
                icon,
                size: 24,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: AppStyles.fontSizeSmall,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
