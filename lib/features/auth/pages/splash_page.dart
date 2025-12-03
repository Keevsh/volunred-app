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
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Pequeña pausa para mostrar splash
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Verificar si hay token guardado
      final token = await StorageService.getString(ApiConfig.accessTokenKey);
      
      if (token != null && token.isNotEmpty) {
        // Hay sesión activa, ir al home
        print('🔐 Token encontrado, redirigiendo a /home');
        Modular.to.navigate('/home');
      } else {
        // No hay sesión, ir a welcome
        print('⚠️ No hay token, redirigiendo a /auth/welcome');
        Modular.to.navigate('/auth/welcome');
      }
    } catch (e) {
      print('❌ Error verificando sesión: $e');
      // En caso de error, ir a welcome
      Modular.to.navigate('/auth/welcome');
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
