import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/models/perfil_funcionario.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_widgets.dart';
import '../../../core/widgets/skeleton_widget.dart';

class EditFuncionarioProfilePage extends StatefulWidget {
  const EditFuncionarioProfilePage({super.key});

  @override
  State<EditFuncionarioProfilePage> createState() =>
      _EditFuncionarioProfilePageState();
}

class _EditFuncionarioProfilePageState
    extends State<EditFuncionarioProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _cargoController = TextEditingController();
  final _departamentoController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final FuncionarioRepository _repository =
      Modular.get<FuncionarioRepository>();

  PerfilFuncionario? _perfil;
  bool _isLoading = true;
  bool _isSaving = false;
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
        // Cargar datos en los controllers
        _cargoController.text = perfil.cargo ?? '';
        _departamentoController.text = perfil.area ?? perfil.departamento ?? '';
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
    _cargoController.dispose();
    _departamentoController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_perfil == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final data = {
        'cargo': _cargoController.text.trim(),
        'area': _departamentoController.text.trim(),
      };

      await _repository.updatePerfilFuncionario(
        _perfil!.idPerfilFuncionario,
        data,
      );

      _showSnackBar('¡Perfil actualizado correctamente!', isError: false);

      Future.delayed(const Duration(milliseconds: 500), () {
        Modular.to.pop();
      });
    } catch (e) {
      _showSnackBar('Error al actualizar: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Editar Perfil'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: colorScheme.onSurface,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: const [
                SkeletonCard(height: 150),
                SizedBox(height: 16),
                SkeletonCard(height: 120),
                SizedBox(height: 16),
                SkeletonWidget(width: double.infinity, height: 50),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null || _perfil == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Editar Perfil'),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Error: ${_error ?? 'Perfil no encontrado'}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
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
        title: const Text('Editar Perfil'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección: Información del Funcionario
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
                  ],
                ),
                const SizedBox(height: AppStyles.spacingXLarge),

                // Botón de guardar
                AppWidgets.gradientButton(
                  text: _isSaving ? 'Guardando...' : 'Guardar Cambios',
                  onPressed: _isSaving ? () {} : () => _handleUpdateProfile(),
                  icon: Icons.save_outlined,
                ),

                const SizedBox(height: AppStyles.spacingMedium),

                // Botón de cancelar
                Center(
                  child: TextButton(
                    onPressed: _isSaving ? null : () => Modular.to.pop(),
                    child: Text(
                      'Cancelar',
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
}
