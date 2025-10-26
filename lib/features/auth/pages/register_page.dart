import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/models/dto/request_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
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
      'icon': Icons.description_outlined,
      'title': 'Datos Adicionales',
      'subtitle': 'Completa tu perfil',
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
        return Colors.green;
      case 'Media':
        return Colors.orange;
      case 'Débil':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validar paso 1
      if (!_nombresValid || !_apellidosValid) {
        _showSnackBar('Por favor completa tus nombres y apellidos');
        return;
      }
    } else if (_currentStep == 1) {
      // Validar paso 2
      if (!_emailValid || !_passwordValid || !_confirmPasswordValid) {
        _showSnackBar('Verifica tu email y contraseña');
        return;
      }
    }

    if (_currentStep < 2) {
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

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnackBar('Las contraseñas no coinciden');
        return;
      }

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
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            _showSnackBar('¡Registro exitoso! Bienvenido', isError: false);
            Future.delayed(const Duration(milliseconds: 500), () {
              Modular.to.navigate('/profile/create');
            });
          } else if (state is AuthError) {
            _showSnackBar(state.message);
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
          const SizedBox(height: 24),
          Text(
            'Creando tu cuenta...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
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
        padding: const EdgeInsets.all(24),
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
        return _buildStep1PersonalInfo();
      case 1:
        return _buildStep2AccountInfo();
      case 2:
        return _buildStep3AdditionalInfo();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1PersonalInfo() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Cómo te llamas?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa tu nombre completo',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
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
        const SizedBox(height: 16),
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
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configura tu cuenta',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Crea tus credenciales de acceso',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
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
        const SizedBox(height: 16),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: passwordStrength == 'Fuerte'
                      ? 1.0
                      : passwordStrength == 'Media'
                          ? 0.66
                          : 0.33,
                  backgroundColor: Colors.grey[300],
                  color: strengthColor,
                  minHeight: 4,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                passwordStrength,
                style: TextStyle(
                  fontSize: 12,
                  color: strengthColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
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
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información adicional',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Opcional - Puedes completar esto después',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _telefonoController,
          label: 'Teléfono',
          hint: '78945612',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _ciController,
          label: 'Cédula de Identidad',
          hint: '1234567',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _sexo,
          decoration: InputDecoration(
            labelText: 'Sexo',
            prefixIcon: const Icon(Icons.wc_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: const [
            DropdownMenuItem(value: 'M', child: Text('Masculino')),
            DropdownMenuItem(value: 'F', child: Text('Femenino')),
            DropdownMenuItem(value: 'O', child: Text('Otro')),
          ],
          onChanged: (value) => setState(() => _sexo = value),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Estos datos son opcionales y puedes completarlos más tarde en tu perfil.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[900],
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
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon ??
            (controller.text.isNotEmpty && validator != null
                ? Icon(
                    isValid ? Icons.check_circle : Icons.error,
                    color: isValid ? Colors.green : Colors.red,
                  )
                : null),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isValid && controller.text.isNotEmpty
                ? Colors.green
                : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildNavigationButtons(ColorScheme colorScheme, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Atrás'),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep < 2 ? 'Continuar' : 'Crear Cuenta',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _currentStep < 2 ? Icons.arrow_forward : Icons.check,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
