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
  TipoUsuario? _tipoUsuario;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;
  bool _isLoading = false;

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
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las contraseñas no coinciden')),
        );
        return;
      }

      if (_tipoUsuario == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona un tipo de cuenta')),
        );
        setState(() => _currentStep = 0);
        return;
      }

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
            idRol: _tipoUsuario == TipoUsuario.funcionario ? 2 : 3,
          ),
        ),
      );
    }
  }

  void _nextStep() {
    if (_validateStep(_currentStep)) {
      if (_currentStep < 2) {
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
              if (state.usuario.idRol == null && _tipoUsuario != null) {
                final idRol = _tipoUsuario == TipoUsuario.funcionario ? 2 : 3;
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
                _buildHeader(colorScheme),
                _buildProgressIndicator(colorScheme),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1(colorScheme),
                      _buildStep2(colorScheme),
                      _buildStep3(colorScheme),
                    ],
                  ),
                ),
                _buildNavigation(colorScheme),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: _currentStep == 0 ? () => Modular.to.navigate('/') : _previousStep,
            icon: const Icon(Icons.arrow_back_rounded),
            color: const Color(0xFF007AFF),
          ),
          Expanded(
            child: Text(
              'Crear Cuenta',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= _currentStep 
                      ? const Color(0xFF007AFF)
                      : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i < 2) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildStep1(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paso 1: Tipo de Cuenta',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona el tipo de cuenta que mejor se adapte a ti',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 32),
          _buildAccountTypeCard(
            context,
            TipoUsuario.voluntario,
            'Voluntario',
            'Participa en proyectos de voluntariado y ayuda a tu comunidad',
            Icons.volunteer_activism,
            const Color(0xFF34C759),
          ),
          const SizedBox(height: 16),
          _buildAccountTypeCard(
            context,
            TipoUsuario.funcionario,
            'Funcionario',
            'Gestiona proyectos y coordina voluntarios para tu organización',
            Icons.business_center,
            const Color(0xFF007AFF),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paso 2: Información Personal',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuéntanos sobre ti',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF86868B),
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _nombresController,
              label: 'Nombres',
              hint: 'Ingresa tus nombres',
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _apellidosController,
              label: 'Apellidos',
              hint: 'Ingresa tus apellidos',
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _emailController,
              label: 'Correo electrónico',
              hint: 'ejemplo@correo.com',
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
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5EA)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: _sexo,
                decoration: const InputDecoration(
                  labelText: 'Sexo (opcional)',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.wc, color: Color(0xFF86868B)),
                ),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Masculino')),
                  DropdownMenuItem(value: 'F', child: Text('Femenino')),
                  DropdownMenuItem(value: 'O', child: Text('Otro')),
                ],
                onChanged: (value) => setState(() => _sexo = value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paso 3: Credenciales',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea una contraseña segura',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF86868B),
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _passwordController,
              label: 'Contraseña',
              hint: 'Mínimo 6 caracteres',
              icon: Icons.lock_outlined,
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
            const SizedBox(height: 20),
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirmar contraseña',
              hint: 'Repite tu contraseña',
              icon: Icons.lock_outlined,
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
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFC7C7CC)),
          prefixIcon: Icon(icon, color: const Color(0xFF86868B)),
          suffixIcon: suffixIcon != null
              ? IconButton(
                  icon: Icon(suffixIcon, color: const Color(0xFF86868B)),
                  onPressed: onSuffixIconPressed,
                )
              : null,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFE5E5EA)),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFE5E5EA)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF007AFF), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildNavigation(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF007AFF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Atrás'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: FilledButton(
              onPressed: _isLoading ? null : _nextStep,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF007AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  : Text(_currentStep == 2 ? 'Registrarse' : 'Continuar'),
            ),
          ),
        ],
      ),
    );
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_tipoUsuario == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor selecciona un tipo de cuenta')),
          );
          return false;
        }
        return true;
      case 1:
        if (_nombresController.text.isEmpty || 
            _apellidosController.text.isEmpty || 
            _emailController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor completa todos los campos requeridos')),
          );
          return false;
        }
        return true;
      case 2:
        if (!_formKey.currentState!.validate()) {
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  Widget _buildAccountTypeCard(
    BuildContext context,
    TipoUsuario tipo,
    String title,
    String subtitle,
    IconData icon,
    Color accentColor,
  ) {
    final isSelected = _tipoUsuario == tipo;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? accentColor : const Color(0xFFE5E5EA),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _tipoUsuario = tipo),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? accentColor.withOpacity(0.1)
                        : const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? accentColor : const Color(0xFF86868B),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? accentColor : const Color(0xFF1D1D1F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF86868B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor,
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
          ),
        ),
      ),
    );
  }
}
