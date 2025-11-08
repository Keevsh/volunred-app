import 'package:flutter/material.dart';

/// Colores Material Design 3
/// Usar estos colores a través del ColorScheme del tema
class AppColorsM3 {
  // Color primario (Azul Google)
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF1565C0);
  
  // Colores de superficie Material 3
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color surfaceContainer = Color(0xFFFAFAFA);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE0E0E0);
  
  // Colores de texto
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF49454F);
  
  // Colores de outline
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);
  
  // Colores de error y éxito
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFF6F00);
  
  /// Obtener ColorScheme del contexto
  static ColorScheme of(BuildContext context) {
    return Theme.of(context).colorScheme;
  }
  
  /// Obtener TextTheme del contexto
  static TextTheme textThemeOf(BuildContext context) {
    return Theme.of(context).textTheme;
  }
}

