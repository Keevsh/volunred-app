import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/config/api_config.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _checkAuth();
    }
  }

  Future<void> _checkAuth() async {
    // Pequeña pausa para mostrar splash
    await Future.delayed(const Duration(milliseconds: 500));

    // Detectar si es desktop (web o pantalla grande)
    final isDesktop = kIsWeb || MediaQuery.of(context).size.width >= 1100;

    try {
      // Verificar si hay token guardado
      print('🔍 Verificando sesión...');
      final token = await StorageService.getString(ApiConfig.accessTokenKey);
      
      print('🔐 Token encontrado: ${token != null ? "SÍ (${token.substring(0, 20)}...)" : "NO"}');
      
      if (token != null && token.isNotEmpty) {
        // Hay sesión activa, ir al home
        print('✅ Sesión activa, redirigiendo a /home');
        Modular.to.navigate('/home');
      } else {
        // No hay sesión
        if (isDesktop) {
          // En desktop ir directo al login
          print('💻 Desktop detectado, redirigiendo a /auth/login');
          Modular.to.navigate('/auth/login');
        } else {
          // En móvil ir a welcome
          print('📱 Móvil detectado, redirigiendo a /auth/welcome');
          Modular.to.navigate('/auth/welcome');
        }
      }
    } catch (e) {
      print('❌ Error verificando sesión: $e');
      // En caso de error, ir a login en desktop o welcome en móvil
      if (isDesktop) {
        Modular.to.navigate('/auth/login');
      } else {
        Modular.to.navigate('/auth/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo circular
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  'VR',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'VolunRed',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
