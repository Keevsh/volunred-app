import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/models/dto/request_models.dart';
import '../../../core/services/profile_check_service.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPageDesktop extends StatefulWidget {
  const LoginPageDesktop({super.key});

  @override
  State<LoginPageDesktop> createState() => _LoginPageDesktopState();
}

class _LoginPageDesktopState extends State<LoginPageDesktop> {
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
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthAuthenticated) {
            Future.microtask(() {
              try {
                if (state.authResponse != null) {
                  final profileRoute =
                      ProfileCheckService.checkProfileFromLogin(
                    state.authResponse!,
                  );

                  if (profileRoute != null) {
                    Modular.to.navigate(profileRoute);
                    return;
                  }

                  if (state.usuario.isAdmin) {
                    Modular.to.navigate('/admin/');
                  } else {
                    Modular.to.navigate('/home/');
                  }
                } else {
                  ProfileCheckService.checkProfile(state.usuario)
                      .then((profileRoute) {
                    if (profileRoute != null) {
                      Modular.to.navigate(profileRoute);
                    } else {
                      if (state.usuario.isAdmin) {
                        Modular.to.navigate('/admin/');
                      } else {
                        Modular.to.navigate('/home/');
                      }
                    }
                  }).catchError((e) {
                    if (state.usuario.isAdmin) {
                      Modular.to.navigate('/admin/');
                    } else {
                      Modular.to.navigate('/home/');
                    }
                  });
                }
              } catch (e) {
                if (state.usuario.isAdmin) {
                  Modular.to.navigate('/admin/');
                } else {
                  Modular.to.navigate('/home/');
                }
              }
            });
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return ResponsiveLayout(
            mobile: _buildMobileLayout(context, isLoading),
            desktop: _buildDesktopLayout(context, isLoading),
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildLoginForm(context, isLoading),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isLoading) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Left side - Brand/Hero section
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(64),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.volunteer_activism_rounded,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Title
                    Text(
                      'VolunRed',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 64,
                            height: 1.1,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sistema de Gestión de Voluntariado',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w300,
                          ),
                    ),
                    const SizedBox(height: 40),

                    // Features
                    _buildFeature(
                      icon: Icons.group_rounded,
                      text: 'Gestiona voluntarios y proyectos',
                    ),
                    const SizedBox(height: 16),
                    _buildFeature(
                      icon: Icons.task_alt_rounded,
                      text: 'Asigna y supervisa tareas',
                    ),
                    const SizedBox(height: 16),
                    _buildFeature(
                      icon: Icons.analytics_rounded,
                      text: 'Analiza el impacto social',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Right side - Login form
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(64),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: _buildLoginForm(context, isLoading),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeature({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, bool isLoading) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isDesktop) ...[
            // Mobile logo
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.volunteer_activism_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
          ],

          // Welcome text
          Text(
            isDesktop ? 'Iniciar Sesión' : 'Bienvenido',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDesktop ? Colors.grey.shade900 : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isDesktop
                ? 'Ingresa tus credenciales para continuar'
                : 'Inicia sesión en VolunRed',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDesktop
                  ? Colors.grey.shade600
                  : Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 40),

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'usuario@ejemplo.com',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: isDesktop
                  ? Colors.grey.shade50
                  : Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu correo';
              }
              if (!value.contains('@')) {
                return 'Por favor ingresa un correo válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            enabled: !isLoading,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: isDesktop
                  ? Colors.grey.shade50
                  : Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu contraseña';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 12),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : () {},
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: isDesktop
                      ? colorScheme.primary
                      : Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Login button
          FilledButton(
            onPressed: isLoading ? null : _handleLogin,
            style: FilledButton.styleFrom(
              backgroundColor: isDesktop
                  ? colorScheme.primary
                  : Colors.white,
              foregroundColor: isDesktop
                  ? Colors.white
                  : colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: isDesktop ? 2 : 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: isDesktop ? Colors.grey.shade300 : Colors.white.withOpacity(0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'O',
                  style: TextStyle(
                    color: isDesktop ? Colors.grey.shade600 : Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              Expanded(child: Divider(color: isDesktop ? Colors.grey.shade300 : Colors.white.withOpacity(0.3))),
            ],
          ),
          const SizedBox(height: 24),

          // Register button
          OutlinedButton(
            onPressed: isLoading
                ? null
                : () => Modular.to.pushNamed('/auth/register'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: isDesktop
                    ? colorScheme.primary
                    : Colors.white.withOpacity(0.9),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Crear cuenta nueva',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDesktop
                    ? colorScheme.primary
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
