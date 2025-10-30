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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cargoController.dispose();
    _departamentoController.dispose();
    _bioController.dispose();
    _organizacionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authRepo = Modular.get<AuthRepository>();
    final usuario = await authRepo.getStoredUser();

    print('👤 Usuario funcionario: ${usuario?.toJson()}');
    print('👤 Cargo: ${_cargoController.text}');
    print('👤 Departamento: ${_departamentoController.text}');
    print('👤 Organización: ${_organizacionController.text}');

    if (usuario == null) {
      _showSnackBar('Error: Usuario no encontrado');
      return;
    }

    // TODO: Implementar creación de perfil de funcionario
    // Por ahora, solo redirigimos al home
    _showSnackBar(
      '¡Perfil de funcionario creado! (Mock)',
      isError: false,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      Modular.to.navigate('/home');
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

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
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
            // Organización
            const Text(
              'Organización',
              style: TextStyle(
                fontSize: AppStyles.fontSizeBody,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            AppWidgets.styledTextField(
              controller: _organizacionController,
              label: 'Nombre de la organización',
              hint: 'Ej: Cruz Roja Boliviana',
              prefixIcon: Icons.business,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: AppStyles.spacingLarge),

            // Cargo
            const Text(
              'Cargo',
              style: TextStyle(
                fontSize: AppStyles.fontSizeBody,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            AppWidgets.styledTextField(
              controller: _cargoController,
              label: 'Tu cargo en la organización',
              hint: 'Ej: Coordinador de Voluntariado',
              prefixIcon: Icons.work_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: AppStyles.spacingLarge),

            // Departamento
            const Text(
              'Departamento',
              style: TextStyle(
                fontSize: AppStyles.fontSizeBody,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            AppWidgets.styledTextField(
              controller: _departamentoController,
              label: 'Departamento o área',
              hint: 'Ej: Recursos Humanos',
              prefixIcon: Icons.corporate_fare,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: AppStyles.spacingLarge),

            // Bio
            const Text(
              'Descripción',
              style: TextStyle(
                fontSize: AppStyles.fontSizeBody,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bioController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Descripción de tu rol',
                hintText: 'Cuéntanos sobre tu experiencia y objetivos...',
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: AppStyles.spacingXLarge),

            // Información adicional
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Como funcionario, podrás crear proyectos, gestionar voluntarios y generar reportes de impacto.',
                      style: TextStyle(
                        fontSize: AppStyles.fontSizeSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
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
                  Modular.to.navigate('/home');
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
}
