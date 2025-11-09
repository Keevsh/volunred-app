import 'package:flutter/material.dart';

/// Colores principales de la aplicación - Estilo Red Social Moderno
class AppColors {
  // Colores primarios - Más vibrantes y modernos
  static const Color primary = Color(0xFF0066FF); // Azul moderno tipo Facebook/Instagram
  static const Color primaryLight = Color(0xFF3399FF);
  static const Color primaryDark = Color(0xFF0052CC);
  
  // Colores secundarios tipo red social
  static const Color secondary = Color(0xFFFF0066); // Rosa/Magenta tipo Instagram
  static const Color accent = Color(0xFF00CC99); // Verde/Teal moderno
  
  // Gradientes principales - Más vibrantes y modernos
  static const List<Color> gradientGreen = [
    Color(0xFF00E676), // Verde brillante
    Color(0xFF00C853),
  ];
  
  static const List<Color> gradientBlue = [
    Color(0xFF0066FF), // Azul vibrante
    Color(0xFF3399FF),
  ];
  
  static const List<Color> gradientOrange = [
    Color(0xFFFF6B35), // Naranja vibrante
    Color(0xFFFF8C42),
  ];
  
  static const List<Color> gradientPurple = [
    Color(0xFF9D4EDD), // Púrpura vibrante
    Color(0xFFC77DFF),
  ];
  
  static const List<Color> gradientPink = [
    Color(0xFFFF0066), // Rosa vibrante
    Color(0xFFFF3399),
  ];
  
  // Gradiente principal de la app - Tipo Instagram/Facebook
  static const List<Color> primaryGradient = [
    Color(0xFF0066FF),
    Color(0xFF00CC99),
  ];
  
  // Gradientes para avatares (estilo Instagram Stories)
  static const List<List<Color>> avatarGradients = [
    [Color(0xFFFF0066), Color(0xFFFF3399)], // Rosa
    [Color(0xFF0066FF), Color(0xFF3399FF)], // Azul
    [Color(0xFF00E676), Color(0xFF00C853)], // Verde
    [Color(0xFFFF6B35), Color(0xFFFF8C42)], // Naranja
    [Color(0xFF9D4EDD), Color(0xFFC77DFF)], // Púrpura
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
  
  // Colores de fondo - Más limpios tipo red social
  static const Color backgroundLight = Color(0xFFF8F9FA); // Fondo tipo Instagram
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Colores para interacciones tipo red social
  static const Color likeRed = Color(0xFFED4956); // Rojo tipo Instagram
  static const Color commentBlue = Color(0xFF0066FF);
  static const Color shareGreen = Color(0xFF00C853);
  static const Color saveBlue = Color(0xFF2196F3);
  
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
