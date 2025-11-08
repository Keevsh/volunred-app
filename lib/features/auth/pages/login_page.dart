import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/models/dto/request_models.dart';
import '../../../core/services/profile_check_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_widgets.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      BlocProvider.of<AuthBloc>(context).add(
        AuthLoginRequested(
          LoginRequest(
            email: _emailController.text.trim(),
            contrasena: _passwordController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthAuthenticated) {
            AppWidgets.showStyledSnackBar(
              context: context,
              message: '¡Bienvenido ${state.usuario.nombres}!',
              isError: false,
            );
            
            // Usar los perfiles de la respuesta del login para redirigir
            Future.microtask(() {
              try {
                // Si tenemos la respuesta completa del login (con perfiles), usarla directamente
                if (state.authResponse != null) {
                  final profileRoute = ProfileCheckService.checkProfileFromLogin(state.authResponse!);
                  
                  if (profileRoute != null) {
                    print('📋 Usuario necesita crear perfil, redirigiendo a: $profileRoute');
                    Modular.to.navigate(profileRoute);
                    return;
                  }
                  
                  // El usuario tiene el perfil requerido (o es admin), redirigir según rol
                  if (state.usuario.isAdmin) {
                    print('👑 Usuario admin, redirigiendo a panel de administración');
                    Modular.to.navigate('/admin/');
                  } else {
                    print('🏠 Usuario con perfil, redirigiendo a home');
                    Modular.to.navigate('/home/');
                  }
                } else {
                  // Fallback: si no tenemos la respuesta completa, verificar usando llamadas API
                  print('⚠️ No se tiene respuesta completa del login, verificando mediante API...');
                  ProfileCheckService.checkProfile(state.usuario).then((profileRoute) {
                    if (profileRoute != null) {
                      print('📋 Usuario necesita crear perfil, redirigiendo a: $profileRoute');
                      Modular.to.navigate(profileRoute);
                    } else {
                      if (state.usuario.isAdmin) {
                        print('👑 Usuario admin, redirigiendo a panel de administración');
                        Modular.to.navigate('/admin/');
                      } else {
                        print('🏠 Usuario con perfil, redirigiendo a home');
                        Modular.to.navigate('/home/');
                      }
                    }
                  }).catchError((e) {
                    print('❌ Error verificando perfil: $e');
                    // En caso de error, redirigir según rol
                    if (state.usuario.isAdmin) {
                      Modular.to.navigate('/admin/');
                    } else {
                      Modular.to.navigate('/home/');
                    }
                  });
                }
              } catch (e) {
                print('❌ Error en redirección: $e');
                // En caso de error, redirigir según rol
                if (state.usuario.isAdmin) {
                  Modular.to.navigate('/admin/');
                } else {
                  Modular.to.navigate('/home/');
                }
              }
            });
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
                // Header minimalista
                _buildHeader(isLoading),
                
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppStyles.spacingXLarge),
                    child: _buildLoginForm(isLoading),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isLoading) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingLarge,
        vertical: AppStyles.spacingMedium,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: isLoading ? null : () => Modular.to.navigate('/'),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLoginForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icono de login
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 50,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppStyles.spacingXLarge),
          
          // Título
          const Text(
            'Iniciar Sesión',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppStyles.spacingSmall),
          
          const Text(
            'Bienvenido de vuelta',
            style: TextStyle(
              fontSize: AppStyles.fontSizeBody,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppStyles.spacingXXLarge),

          // Email field
          AppWidgets.styledTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'tu@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu email';
              }
              if (!value.contains('@')) {
                return 'Email inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: AppStyles.spacingLarge),

          // Password field
          AppWidgets.styledTextField(
            controller: _passwordController,
            label: 'Contraseña',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline,
            suffixIcon: _obscurePassword 
                ? Icons.visibility_outlined 
                : Icons.visibility_off_outlined,
            onSuffixIconPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            obscureText: _obscurePassword,
            enabled: !isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu contraseña';
              }
              return null;
            },
          ),
          const SizedBox(height: AppStyles.spacingMedium),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : () {},
              child: const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: AppStyles.fontSizeMedium,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppStyles.spacingXLarge),

          // Login button
          AppWidgets.gradientButton(
            onPressed: _handleLogin,
            text: 'Iniciar Sesión',
            icon: Icons.arrow_forward,
            isLoading: isLoading,
          ),
          const SizedBox(height: AppStyles.spacingXLarge),

          // Register link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¿No tienes cuenta? ',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppStyles.fontSizeNormal,
                ),
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        Modular.to.navigate('/auth/register');
                      },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  'Regístrate',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: AppStyles.fontSizeNormal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
