import 'package:flutter/material.dart';

/// Colores principales de la aplicación
class AppColors {
  // Colores primarios
  static const Color primary = Color(0xFF0D4C3D);
  static const Color primaryLight = Color(0xFF1A6B56);
  static const Color primaryDark = Color(0xFF083329);
  
  // Gradientes principales
  static const List<Color> gradientGreen = [
    Color(0xFF4CAF50),
    Color(0xFF81C784),
  ];
  
  static const List<Color> gradientBlue = [
    Color(0xFF42A5F5),
    Color(0xFF64B5F6),
  ];
  
  static const List<Color> gradientOrange = [
    Color(0xFFFF9800),
    Color(0xFFFFB74D),
  ];
  
  static const List<Color> gradientPurple = [
    Color(0xFF9C27B0),
    Color(0xFFBA68C8),
  ];
  
  // Gradiente principal de la app
  static const List<Color> primaryGradient = [
    Color(0xFF0D4C3D),
    Color(0xFF1A6B56),
  ];
  
  // Colores de fondo para cards
  static const List<Color> cardGradientLight = [
    Color(0xFFC8E6C9), // green[100]
    Color(0xFFE3F2FD), // blue[50]
    Color(0xFFFFE0B2), // orange[50]
  ];
  
  // Colores de estado
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);
  
  // Colores de fondo
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFAFAFA);
  
  // Colores de información
  static const Color infoBackground = Color(0xFFE3F2FD);
  static const Color infoBorder = Color(0xFFBBDEFB);
  static const Color infoText = Color(0xFF0D47A1);
  
  // Colores de bordes
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF5F5F5);
  
  // Colores de iconos decorativos
  static const Color iconRed = Color(0xFFE57373);
  static const Color iconAmber = Color(0xFFFFB74D);
  static const Color iconGreen = Color(0xFF81C784);
  static const Color iconBlue = Color(0xFF64B5F6);
}
