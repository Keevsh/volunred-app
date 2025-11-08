import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/models/dto/request_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/theme/theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _ciController = TextEditingController();
  
  final _nombresFocus = FocusNode();
  final _apellidosFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  
  String? _sexo;
  TipoUsuario? _tipoUsuario; // Voluntario o Funcionario
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Validación en tiempo real
  bool _nombresValid = false;
  bool _apellidosValid = false;
  bool _emailValid = false;
  bool _passwordValid = false;
  bool _confirmPasswordValid = false;

  // Datos del carrusel para cada paso
  final List<Map<String, dynamic>> _stepData = [
    {
      'icon': Icons.how_to_reg_outlined,
      'title': 'Tipo de Cuenta',
      'subtitle': '¿Cómo quieres participar?',
    },
    {
      'icon': Icons.person_outline,
      'title': 'Información Personal',
      'subtitle': 'Cuéntanos sobre ti',
    },
    {
      'icon': Icons.lock_outline,
      'title': 'Seguridad',
      'subtitle': 'Crea tu acceso seguro',
    },
    {
      'icon': Icons.info_outline,
      'title': 'Información Adicional',
      'subtitle': 'Completa tu perfil (opcional)',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Listeners para validación en tiempo real
    _nombresController.addListener(() {
      setState(() {
        _nombresValid = _nombresController.text.trim().length >= 2;
      });
    });
    _apellidosController.addListener(() {
      setState(() {
        _apellidosValid = _apellidosController.text.trim().length >= 2;
      });
    });
    _emailController.addListener(() {
      setState(() {
        _emailValid = _emailController.text.contains('@') &&
            _emailController.text.contains('.');
      });
    });
    _passwordController.addListener(() {
      setState(() {
        _passwordValid = _passwordController.text.length >= 6;
        _confirmPasswordValid = _confirmPasswordController.text ==
            _passwordController.text &&
            _confirmPasswordController.text.isNotEmpty;
      });
    });
    _confirmPasswordController.addListener(() {
      setState(() {
        _confirmPasswordValid = _confirmPasswordController.text ==
            _passwordController.text &&
            _confirmPasswordController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _telefonoController.dispose();
    _ciController.dispose();
    _nombresFocus.dispose();
    _apellidosFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  String _getPasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) return '';
    if (password.length < 6) return 'Débil';
    if (password.length < 8) return 'Media';
    
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    int strength = 0;
    if (hasUpper) strength++;
    if (hasLower) strength++;
    if (hasDigit) strength++;
    if (hasSpecial) strength++;
    
    if (strength >= 3 && password.length >= 8) return 'Fuerte';
    if (strength >= 2) return 'Media';
    return 'Débil';
  }

  Color _getPasswordStrengthColor() {
    final strength = _getPasswordStrength();
    switch (strength) {
      case 'Fuerte':
        return AppColors.success;
      case 'Media':
        return AppColors.warning;
      case 'Débil':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validar paso 0: Tipo de usuario
      if (_tipoUsuario == null) {
        AppWidgets.showStyledSnackBar(
          context: context,
          message: 'Por favor selecciona el tipo de cuenta',
          isError: true,
        );
        return;
      }
    } else if (_currentStep == 1) {
      // Validar paso 1: Datos personales
      if (!_nombresValid || !_apellidosValid) {
        AppWidgets.showStyledSnackBar(
          context: context,
          message: 'Por favor completa tus nombres y apellidos',
          isError: true,
        );
        return;
      }
    } else if (_currentStep == 2) {
      // Validar paso 2: Credenciales
      if (!_emailValid || !_passwordValid || !_confirmPasswordValid) {
        AppWidgets.showStyledSnackBar(
          context: context,
          message: 'Verifica tu email y contraseña',
          isError: true,
        );
        return;
      }
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _handleRegister();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }



  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        AppWidgets.showStyledSnackBar(
          context: context,
          message: 'Las contraseñas no coinciden',
          isError: true,
        );
        return;
      }

      // Validar que se haya seleccionado un tipo de usuario
      if (_tipoUsuario == null) {
        AppWidgets.showStyledSnackBar(
          context: context,
          message: 'Por favor selecciona un tipo de cuenta',
          isError: true,
        );
        // Ir al primer paso donde se selecciona el tipo
        setState(() => _currentStep = 0);
        return;
      }

      print('🎯 Registrando usuario con tipo: ${_tipoUsuario?.value}');

      BlocProvider.of<AuthBloc>(context).add(
        AuthRegisterRequested(
          RegisterRequest(
            nombres: _nombresController.text.trim(),
            apellidos: _apellidosController.text.trim(),
            email: _emailController.text.trim(),
            contrasena: _passwordController.text,
            telefono: int.tryParse(_telefonoController.text),
            ci: int.tryParse(_ciController.text),
            sexo: _sexo,
            // Mapear tipoUsuario a id_rol: funcionario=2, voluntario=3
            // El backend requiere id_rol, así que siempre debe tener un valor
            idRol: _tipoUsuario == TipoUsuario.funcionario 
                ? 2 
                : 3, // Si es voluntario o cualquier otro caso, usar 3
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthAuthenticated) {
            print('✅ Usuario registrado: ${state.usuario.nombreCompleto}');
            print('✅ ID Rol actual: ${state.usuario.idRol}');
            print('✅ Tipo de usuario seleccionado: ${_tipoUsuario?.value}');
            
            // Si el usuario no tiene rol asignado y seleccionó un tipo
            if (state.usuario.idRol == null && _tipoUsuario != null) {
              print('⚠️ Usuario sin rol, asignando automáticamente...');
              
              // Mapear tipo_usuario a id_rol
              final idRol = _tipoUsuario == TipoUsuario.funcionario ? 2 : 3;
              
              try {
                final adminRepo = Modular.get<AdminRepository>();
                await adminRepo.asignarRol(
                  AsignarRolRequest(
                    idUsuario: state.usuario.idUsuario,
                    idRol: idRol,
                  ),
                );
                
                print('✅ Rol $idRol asignado correctamente');
                
                // Recargar usuario para obtener el rol actualizado
                final authRepo = Modular.get<AuthRepository>();
                final usuarioActualizado = await authRepo.getProfile();
                
                print('✅ Usuario actualizado con rol: ${usuarioActualizado.rol?.nombre}');
                
                AppWidgets.showStyledSnackBar(
                  context: context,
                  message: '¡Registro exitoso! Bienvenido',
                  isError: false,
                );
                
                // Redirigir según el rol asignado
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (idRol == 2) {
                    print('➡️ Redirigiendo a crear organización');
                    Modular.to.navigate('/profile/create-organizacion');
                  } else {
                    print('➡️ Redirigiendo a crear perfil de voluntario');
                    Modular.to.navigate('/profile/create');
                  }
                });
              } catch (e) {
                print('❌ Error al asignar rol: $e');
                AppWidgets.showStyledSnackBar(
                  context: context,
                  message: 'Error al asignar rol: ${e.toString()}',
                  isError: true,
                );
              }
            } else if (state.usuario.idRol != null) {
              // Usuario ya tiene rol (caso poco probable en registro)
              
              // IMPORTANTE: Admin NO se crea por registro, solo desde BD
              if (state.usuario.idRol == 1) {
                print('⚠️ Usuario admin detectado - no debería registrarse por la app');
                AppWidgets.showStyledSnackBar(
                  context: context,
                  message: 'Error: Los administradores no se crean desde el registro',
                  isError: true,
                );
                return;
              }
              
              AppWidgets.showStyledSnackBar(
                context: context,
                message: '¡Registro exitoso! Bienvenido',
                isError: false,
              );
              
              Future.delayed(const Duration(milliseconds: 500), () {
                if (state.usuario.idRol == 2) {
                  // Funcionario → crear organización
                  Modular.to.navigate('/profile/create-organizacion');
                } else if (state.usuario.idRol == 3) {
                  // Voluntario → crear perfil de voluntario
                  Modular.to.navigate('/profile/create');
                } else {
                  // Rol desconocido
                  print('❌ Rol no reconocido: ${state.usuario.idRol}');
                  Modular.to.navigate('/home');
                }
              });
            } else {
              // No se seleccionó tipo de usuario (no debería pasar)
              AppWidgets.showStyledSnackBar(
                context: context,
                message: 'Registro exitoso, pero no se pudo asignar rol',
                isError: true,
              );
            }
          } else if (state is AuthError) {
            AppWidgets.showStyledSnackBar(
              context: context,
              message: state.message,
              isError: true,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(colorScheme, isLoading),
                
                // Stepper Progress
                _buildStepperProgress(colorScheme),
                
                // Form Content
                Expanded(
                  child: isLoading
                      ? _buildLoadingState()
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildFormContent(),
                        ),
                ),
                
                // Navigation Buttons
                _buildNavigationButtons(colorScheme, isLoading),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, bool isLoading) {
    final stepInfo = _stepData[_currentStep];
    
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Botón atrás minimalista
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingLarge,
                vertical: AppStyles.spacingMedium,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    onPressed: isLoading ? null : () {
                      if (_currentStep > 0) {
                        _previousStep();
                      } else {
                        Modular.to.navigate('/');
                      }
                    },
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Paso ${_currentStep + 1} de 3',
                    style: const TextStyle(
                      fontSize: AppStyles.fontSizeSmall,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Carrusel visual minimalista
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey<int>(_currentStep),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacingXLarge,
                  vertical: AppStyles.spacingLarge,
                ),
                child: Column(
                  children: [
                    // Icono minimalista
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        stepInfo['icon'] as IconData,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppStyles.spacingLarge),
                    // Título del paso
                    Text(
                      stepInfo['title'] as String,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppStyles.spacingSmall),
                    // Subtítulo
                    Text(
                      stepInfo['subtitle'] as String,
                      style: const TextStyle(
                        fontSize: AppStyles.fontSizeBody,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppStyles.spacingLarge),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperProgress(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingXLarge,
        vertical: AppStyles.spacingSmall,
      ),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < 2 ? AppStyles.spacingSmall : 0,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 3,
                decoration: BoxDecoration(
                  color: index <= _currentStep 
                      ? AppColors.primary 
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppStyles.spacingLarge),
          Text(
            'Creando tu cuenta...',
            style: TextStyle(
              fontSize: AppStyles.fontSizeBody,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppStyles.spacingLarge),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _getCurrentStepWidget(),
        ),
      ),
    );
  }

  Widget _getCurrentStepWidget() {
    switch (_currentStep) {
      case 0:
        return _buildStep0TipoCuenta();
      case 1:
        return _buildStep1PersonalInfo();
      case 2:
        return _buildStep2AccountInfo();
      case 3:
        return _buildStep3AdditionalInfo();
      default:
        return const SizedBox();
    }
  }

  // Paso 0: Selección de tipo de cuenta
  Widget _buildStep0TipoCuenta() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Cómo quieres participar?',
          style: TextStyle(
            fontSize: AppStyles.fontSizeTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppStyles.spacingSmall),
        Text(
          'Selecciona el tipo de cuenta que mejor se adapte a ti',
          style: TextStyle(
            fontSize: AppStyles.fontSizeSmall,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppStyles.spacingXLarge),
        _buildTipoCuentaCard(
          tipo: TipoUsuario.voluntario,
          icon: Icons.volunteer_activism,
          title: 'Voluntario',
          description:
              'Participa en proyectos sociales y ayuda a construir un mundo mejor',
          features: [
            'Explora proyectos de voluntariado',
            'Inscríbete en actividades',
            'Registra tus horas de voluntariado',
            'Obtén reconocimientos y certificados',
          ],
        ),
        const SizedBox(height: AppStyles.spacingLarge),
        _buildTipoCuentaCard(
          tipo: TipoUsuario.funcionario,
          icon: Icons.business_center,
          title: 'Funcionario/Organización',
          description:
              'Crea y gestiona proyectos de voluntariado para tu organización',
          features: [
            'Crea proyectos y actividades',
            'Gestiona voluntarios',
            'Asigna tareas y responsabilidades',
            'Genera reportes de impacto',
          ],
        ),
      ],
    );
  }

  Widget _buildTipoCuentaCard({
    required TipoUsuario tipo,
    required IconData icon,
    required String title,
    required String description,
    required List<String> features,
  }) {
    final isSelected = _tipoUsuario == tipo;

    return InkWell(
      onTap: () => setState(() => _tipoUsuario = tipo),
      borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppStyles.spacingLarge),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
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
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.borderLight,
                    borderRadius:
                        BorderRadius.circular(AppStyles.borderRadiusSmall),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    size: AppStyles.iconSizeLarge,
                  ),
                ),
                const SizedBox(width: AppStyles.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: AppStyles.fontSizeTitle,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: AppStyles.fontSizeSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingMedium),
            const Divider(),
            const SizedBox(height: AppStyles.spacingSmall),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: AppStyles.spacingSmall),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppStyles.spacingSmall),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: AppStyles.fontSizeSmall,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1PersonalInfo() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Cómo te llamas?',
          style: TextStyle(
            fontSize: AppStyles.fontSizeTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppStyles.spacingSmall),
        Text(
          'Ingresa tu nombre completo',
          style: TextStyle(
            fontSize: AppStyles.fontSizeSmall,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppStyles.spacingLarge),
        _buildTextField(
          controller: _nombresController,
          focusNode: _nombresFocus,
          label: 'Nombres',
          hint: 'Ej: Juan Carlos',
          icon: Icons.person_outline,
          isValid: _nombresValid,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Este campo es requerido';
            }
            if (value.trim().length < 2) {
              return 'Ingresa al menos 2 caracteres';
            }
            return null;
          },
          onFieldSubmitted: (_) => _apellidosFocus.requestFocus(),
        ),
        const SizedBox(height: AppStyles.spacingMedium),
        _buildTextField(
          controller: _apellidosController,
          focusNode: _apellidosFocus,
          label: 'Apellidos',
          hint: 'Ej: Pérez López',
          icon: Icons.person,
          isValid: _apellidosValid,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Este campo es requerido';
            }
            if (value.trim().length < 2) {
              return 'Ingresa al menos 2 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep2AccountInfo() {
    final passwordStrength = _getPasswordStrength();
    final strengthColor = _getPasswordStrengthColor();

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configura tu cuenta',
          style: TextStyle(
            fontSize: AppStyles.fontSizeTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppStyles.spacingSmall),
        Text(
          'Crea tus credenciales de acceso',
          style: TextStyle(
            fontSize: AppStyles.fontSizeSmall,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppStyles.spacingLarge),
        _buildTextField(
          controller: _emailController,
          focusNode: _emailFocus,
          label: 'Correo Electrónico',
          hint: 'tu@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          isValid: _emailValid,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Este campo es requerido';
            }
            if (!value.contains('@') || !value.contains('.')) {
              return 'Ingresa un email válido';
            }
            return null;
          },
          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        const SizedBox(height: AppStyles.spacingMedium),
        _buildTextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          label: 'Contraseña',
          hint: 'Mínimo 6 caracteres',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          isValid: _passwordValid,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }
            if (value.length < 6) {
              return 'Mínimo 6 caracteres';
            }
            return null;
          },
          onFieldSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
        ),
        if (_passwordController.text.isNotEmpty) ...[
          const SizedBox(height: AppStyles.spacingSmall),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: passwordStrength == 'Fuerte'
                      ? 1.0
                      : passwordStrength == 'Media'
                          ? 0.66
                          : 0.33,
                  backgroundColor: AppColors.borderLight,
                  color: strengthColor,
                  minHeight: 4,
                ),
              ),
              const SizedBox(width: AppStyles.spacingMedium),
              Text(
                passwordStrength,
                style: TextStyle(
                  fontSize: AppStyles.fontSizeSmall,
                  color: strengthColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppStyles.spacingMedium),
        _buildTextField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          label: 'Confirmar Contraseña',
          hint: 'Repite tu contraseña',
          icon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          isValid: _confirmPasswordValid,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () =>
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es requerido';
            }
            if (value != _passwordController.text) {
              return 'Las contraseñas no coinciden';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep3AdditionalInfo() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información adicional',
          style: TextStyle(
            fontSize: AppStyles.fontSizeTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppStyles.spacingSmall),
        Text(
          'Opcional - Puedes completar esto después',
          style: TextStyle(
            fontSize: AppStyles.fontSizeSmall,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppStyles.spacingLarge),
        _buildTextField(
          controller: _telefonoController,
          label: 'Teléfono',
          hint: '78945612',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: AppStyles.spacingMedium),
        _buildTextField(
          controller: _ciController,
          label: 'Cédula de Identidad',
          hint: '1234567',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: AppStyles.spacingMedium),
        DropdownButtonFormField<String>(
          value: _sexo,
          decoration: InputDecoration(
            labelText: 'Sexo',
            prefixIcon: const Icon(Icons.wc_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
            ),
            filled: true,
            fillColor: AppColors.cardBackground,
          ),
          items: const [
            DropdownMenuItem(value: 'M', child: Text('Masculino')),
            DropdownMenuItem(value: 'F', child: Text('Femenino')),
            DropdownMenuItem(value: 'O', child: Text('Otro')),
          ],
          onChanged: (value) => setState(() => _sexo = value),
        ),
        const SizedBox(height: AppStyles.spacingLarge),
        Container(
          padding: const EdgeInsets.all(AppStyles.spacingMedium),
          decoration: BoxDecoration(
            color: AppColors.infoBackground,
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
            border: Border.all(color: AppColors.infoBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info),
              const SizedBox(width: AppStyles.spacingMedium),
              Expanded(
                child: Text(
                  'Estos datos son opcionales y puedes completarlos más tarde en tu perfil.',
                  style: TextStyle(
                    fontSize: AppStyles.fontSizeSmall,
                    color: AppColors.infoText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    bool isValid = false,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return AppWidgets.styledTextField(
      controller: controller,
      label: label,
      hint: hint,
      prefixIcon: icon,
      suffixIcon: suffixIcon != null ? null : (isValid && controller.text.isNotEmpty ? Icons.check_circle : null),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      enabled: true,
    );
  }

  Widget _buildNavigationButtons(ColorScheme colorScheme, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppStyles.opacityLight),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppStyles.spacingMedium),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppStyles.borderRadiusMediumAll,
                  ),
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Atrás'),
              ),
            ),
            const SizedBox(width: AppStyles.spacingMedium),
          ],
          Expanded(
            flex: 2,
            child: AppWidgets.gradientButton(
              onPressed: _nextStep,
              text: _currentStep < 2 ? 'Continuar' : 'Crear Cuenta',
              icon: _currentStep < 2 ? Icons.arrow_forward : Icons.check,
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
