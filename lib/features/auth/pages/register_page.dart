import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/models/dto/request_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/repositories/admin_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _ciController = TextEditingController();
  
  String? _sexo;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isFuncionario = false; // Por defecto es voluntario

  @override
  void initState() {
    super.initState();
    // Por defecto es voluntario
    _isFuncionario = false;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _telefonoController.dispose();
    _ciController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

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
            idRol: _isFuncionario ? 2 : 3, // 2 = funcionario, 3 = voluntario
          ),
        ),
      );
    }
  }

  void _nextStep() {
    if (_validateStep(_currentStep)) {
      if (_currentStep < 1) {
        setState(() => _currentStep++);
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _handleRegister();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Modular.to.navigate('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) async {
            if (state is AuthAuthenticated) {
              setState(() => _isLoading = false);
              if (state.usuario.idRol == null) {
                final idRol = _isFuncionario ? 2 : 3;
                try {
                  final adminRepo = Modular.get<AdminRepository>();
                  await adminRepo.asignarRol(
                    AsignarRolRequest(
                      idUsuario: state.usuario.idUsuario,
                      idRol: idRol,
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('¡Registro exitoso!')),
                  );
                  Future.delayed(const Duration(milliseconds: 500), () {
                    Modular.to.navigate(idRol == 2 
                        ? '/profile/funcionario-options' 
                        : '/profile/create');
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              } else if (state.usuario.idRol != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('¡Registro exitoso!')),
                );
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (state.usuario.idRol == 2) {
                    Modular.to.navigate('/profile/funcionario-options');
                  } else if (state.usuario.idRol == 3) {
                    Modular.to.navigate('/profile/create');
                  } else {
                    Modular.to.navigate('/home');
                  }
                });
              }
            } else if (state is AuthError) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                _buildHeader(),
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1(),
                      _buildStep2(),
                    ],
                  ),
                ),
                _buildNavigation(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _currentStep == 0 ? () => Modular.to.navigate('/') : _previousStep,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: const Color(0xFF1D1D1F),
          ),
          Expanded(
            child: Text(
              'Crear cuenta',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance para el botón de atrás
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          for (int i = 0; i < 2; i++) ...[
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: i <= _currentStep 
                      ? const Color(0xFF007AFF)
                      : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i < 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Logo o icono principal
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF007AFF),
                    const Color(0xFF0051D5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Únete a nuestra comunidad',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.8,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Conecta con organizaciones y participa en proyectos que marcan la diferencia',
            style: TextStyle(
              fontSize: 17,
              color: Color(0xFF86868B),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Formulario principal
          _buildTextField(
            controller: _nombresController,
            label: 'Nombre',
            hint: 'Tu nombre',
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _apellidosController,
            label: 'Apellido',
            hint: 'Tu apellido',
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Correo electrónico',
            hint: 'tu@correo.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo requerido';
              }
              if (!value.contains('@')) {
                return 'Email inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: 'Contraseña',
            hint: 'Mínimo 6 caracteres',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            onSuffixIconPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo requerido';
              }
              if (value.length < 6) {
                return 'Mínimo 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirmar contraseña',
            hint: 'Repite tu contraseña',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirmPassword,
            suffixIcon: _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            onSuffixIconPressed: () {
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Campo requerido';
              }
              if (value != _passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          // Términos y condiciones
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                children: const [
                  TextSpan(text: 'Al continuar, aceptas nuestros '),
                  TextSpan(
                    text: 'Términos de Servicio',
                    style: TextStyle(
                      color: Color(0xFF007AFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' y '),
                  TextSpan(
                    text: 'Política de Privacidad',
                    style: TextStyle(
                      color: Color(0xFF007AFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Opción: Solicitar cuenta de organización (checkbox)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Checkbox(
                value: _isFuncionario,
                activeColor: const Color(0xFF007AFF),
                onChanged: (value) {
                  setState(() {
                    _isFuncionario = value ?? false;
                  });
                },
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Solicitar cuenta de organización',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24), // Espacio adicional para el teclado
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              _isFuncionario ? 'Información adicional' : 'Completa tu perfil',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isFuncionario 
                  ? 'Información adicional para tu cuenta de organización'
                  : 'Algunos datos opcionales para conocerte mejor',
              style: const TextStyle(
                fontSize: 17,
                color: Color(0xFF86868B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            DropdownButtonFormField<String>(
              value: _sexo,
              decoration: InputDecoration(
                labelText: 'Sexo',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                prefixIcon: const Icon(Icons.wc_rounded, color: Color(0xFF86868B), size: 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF007AFF), width: 2),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'M', child: Text('Masculino')),
                DropdownMenuItem(value: 'F', child: Text('Femenino')),
                DropdownMenuItem(value: 'O', child: Text('Otro')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecciona tu sexo';
                }
                return null;
              },
              onChanged: (value) {
                setState(() => _sexo = value);
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _telefonoController,
              label: 'Teléfono (opcional)',
              hint: '78945612',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _ciController,
              label: 'CI (opcional)',
              hint: '12345678',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 24), // Espacio adicional para el teclado
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconPressed,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        validator: validator,
        style: const TextStyle(
          fontSize: 17,
          color: Color(0xFF1D1D1F),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 17,
          ),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 17,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF86868B), size: 22),
          suffixIcon: suffixIcon != null
              ? IconButton(
                  icon: Icon(suffixIcon, color: const Color(0xFF86868B), size: 22),
                  onPressed: onSuffixIconPressed,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: _isLoading
              ? null
              : (_currentStep == 0 ? _nextStep : _handleRegister),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _currentStep == 0 ? 'Continuar' : 'Crear cuenta',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
        ),
      ),
    );
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_nombresController.text.isEmpty || 
            _apellidosController.text.isEmpty || 
            _emailController.text.isEmpty ||
            _passwordController.text.isEmpty ||
            _confirmPasswordController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor completa todos los campos requeridos')),
          );
          return false;
        }
        if (!_emailController.text.contains('@')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor ingresa un email válido')),
          );
          return false;
        }
        if (_passwordController.text.length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
          );
          return false;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Las contraseñas no coinciden')),
          );
          return false;
        }
        return true;
      case 1:
        if (!_formKey.currentState!.validate()) {
          return false;
        }
        return true;
      default:
        return false;
    }
  }
}
