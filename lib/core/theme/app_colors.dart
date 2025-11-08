import 'package:flutter/material.dart';

/// Paleta de colores moderna estilo Red Social
/// Inspirada en Instagram, Twitter y plataformas sociales modernas
class AppColors {
  // ==================== COLORES PRIMARIOS ====================
  
  /// Color primario principal - Azul vibrante moderno
  static const Color primary = Color(0xFF0095F6); // Instagram Blue
  static const Color primaryLight = Color(0xFF4DB6FF);
  static const Color primaryDark = Color(0xFF0074CC);
  static const Color primarySoft = Color(0xFFE3F2FD);
  
  /// Color secundario - Rosa/Magenta moderno
  static const Color secondary = Color(0xFFE91E63);
  static const Color secondaryLight = Color(0xFFFF4081);
  static const Color secondaryDark = Color(0xFFC2185B);
  
  /// Color de acento - Verde/Teal fresco
  static const Color accent = Color(0xFF00BFA5);
  static const Color accentLight = Color(0xFF64FFDA);
  static const Color accentDark = Color(0xFF00897B);
  
  // ==================== GRADIENTES ====================
  
  /// Gradiente principal de la app (estilo Instagram)
  static const List<Color> primaryGradient = [
    Color(0xFF833AB4), // Púrpura
    Color(0xFFFD1D1D), // Rojo
    Color(0xFFFCAF45), // Naranja
  ];
  
  /// Gradiente azul moderno
  static const List<Color> blueGradient = [
    Color(0xFF0095F6),
    Color(0xFF00D4FF),
  ];
  
  /// Gradiente rosa/púrpura
  static const List<Color> pinkGradient = [
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
  ];
  
  /// Gradiente verde fresco
  static const List<Color> greenGradient = [
    Color(0xFF00BFA5),
    Color(0xFF00E676),
  ];
  
  /// Gradiente naranja cálido
  static const List<Color> orangeGradient = [
    Color(0xFFFF6F00),
    Color(0xFFFFB300),
  ];
  
  /// Gradiente púrpura profundo
  static const List<Color> purpleGradient = [
    Color(0xFF7C4DFF),
    Color(0xFFB388FF),
  ];
  
  /// Gradientes para avatares y elementos decorativos
  static const List<List<Color>> avatarGradients = [
    [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCAF45)], // Instagram
    [Color(0xFF0095F6), Color(0xFF00D4FF)], // Azul cielo
    [Color(0xFFE91E63), Color(0xFF9C27B0)], // Rosa-Púrpura
    [Color(0xFF00BFA5), Color(0xFF00E676)], // Verde fresco
    [Color(0xFFFF6F00), Color(0xFFFFB300)], // Naranja dorado
    [Color(0xFF7C4DFF), Color(0xFFB388FF)], // Púrpura suave
  ];
  
  // ==================== COLORES DE ESTADO ====================
  
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);
  
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);
  
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);
  
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);
  
  // ==================== COLORES DE INTERACCIÓN (ESTILO RED SOCIAL) ====================
  
  /// Like/Corazón (estilo Instagram)
  static const Color like = Color(0xFFED4956);
  static const Color likeGradientStart = Color(0xFFFF6B9D);
  static const Color likeGradientEnd = Color(0xFFFF0066);
  
  /// Comentarios
  static const Color comment = Color(0xFF0095F6);
  
  /// Compartir
  static const Color share = Color(0xFF00C853);
  
  /// Guardar/Bookmark
  static const Color save = Color(0xFF262626);
  
  /// Enviar mensaje
  static const Color send = Color(0xFF0095F6);
  
  // ==================== COLORES DE TEXTO ====================
  
  static const Color textPrimary = Color(0xFF262626); // Negro suave
  static const Color textSecondary = Color(0xFF8E8E8E); // Gris medio
  static const Color textTertiary = Color(0xFFBDBDBD); // Gris claro
  static const Color textLight = Color(0xFFFFFFFF); // Blanco
  static const Color textHint = Color(0xFFC7C7C7);
  static const Color textDisabled = Color(0xFFE0E0E0);
  
  // ==================== COLORES DE FONDO ====================
  
  /// Fondo principal (estilo Instagram)
  static const Color background = Color(0xFFFAFAFA);
  
  /// Fondo blanco puro
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  
  /// Fondo de superficie (cards, modales)
  static const Color surface = Color(0xFFFFFFFF);
  
  /// Fondo alternativo (para secciones diferenciadas)
  static const Color backgroundAlt = Color(0xFFF5F5F5);
  
  /// Fondo oscuro (para elementos destacados)
  static const Color backgroundDark = Color(0xFF262626);
  
  // ==================== COLORES DE BORDE ====================
  
  static const Color border = Color(0xFFDBDBDB);
  static const Color borderLight = Color(0xFFEFEFEF);
  static const Color borderDark = Color(0xFFC4C4C4);
  static const Color borderFocus = Color(0xFF0095F6);
  
  // ==================== COLORES DE OVERLAY ====================
  
  static const Color overlay = Color(0x80000000); // Negro 50%
  static const Color overlayLight = Color(0x40000000); // Negro 25%
  static const Color overlayDark = Color(0xCC000000); // Negro 80%
  
  // ==================== COLORES DE ICONOS ====================
  
  static const Color iconPrimary = Color(0xFF262626);
  static const Color iconSecondary = Color(0xFF8E8E8E);
  static const Color iconLight = Color(0xFFFFFFFF);
  static const Color iconAccent = Color(0xFF0095F6);
  
  // ==================== COLORES DECORATIVOS ====================
  
  /// Para badges, notificaciones, etc.
  static const Color badge = Color(0xFFFF3B30);
  static const Color badgeGreen = Color(0xFF34C759);
  static const Color badgeBlue = Color(0xFF007AFF);
  static const Color badgeYellow = Color(0xFFFFCC00);
  
  // ==================== COLORES DE ICONOS DECORATIVOS (compatibilidad) ====================
  
  static const Color iconRed = Color(0xFFE57373);
  static const Color iconAmber = Color(0xFFFFB74D);
  static const Color iconGreen = Color(0xFF81C784);
  static const Color iconBlue = Color(0xFF64B5F6);
  
  // ==================== GRADIENTES ADICIONALES (compatibilidad) ====================
  
  static const List<Color> gradientGreen = greenGradient;
  static const List<Color> gradientBlue = blueGradient;
  static const List<Color> gradientOrange = orangeGradient;
  static const List<Color> gradientPurple = purpleGradient;
  static const List<Color> gradientPink = pinkGradient;
  
  // ==================== COLORES DE FONDO ADICIONALES (compatibilidad) ====================
  
  static const Color backgroundLight = background;
  static const Color cardBackground = surface;
  
  // ==================== COLORES DE INFORMACIÓN (compatibilidad) ====================
  
  static const Color infoBackground = Color(0xFFE3F2FD);
  static const Color infoBorder = Color(0xFFBBDEFB);
  static const Color infoText = Color(0xFF0D47A1);
  
  // ==================== GRADIENTES PARA CARDS (compatibilidad) ====================
  
  static const List<Color> cardGradientLight = [
    Color(0xFFC8E6C9), // green[100]
    Color(0xFFE3F2FD), // blue[50]
    Color(0xFFFFE0B2), // orange[50]
  ];
  
  // ==================== SOMBRAS ====================
  
  static BoxShadow get shadowSmall => BoxShadow(
    color: const Color(0x0A000000),
    blurRadius: 4,
    offset: const Offset(0, 2),
  );
  
  static BoxShadow get shadowMedium => BoxShadow(
    color: const Color(0x14000000),
    blurRadius: 8,
    offset: const Offset(0, 4),
  );
  
  static BoxShadow get shadowLarge => BoxShadow(
    color: const Color(0x1F000000),
    blurRadius: 16,
    offset: const Offset(0, 8),
  );
  
  static BoxShadow get shadowCard => BoxShadow(
    color: const Color(0x0D000000),
    blurRadius: 10,
    offset: const Offset(0, 2),
  );
  
  // ==================== UTILIDADES ====================
  
  /// Obtener un gradiente de avatar según un índice
  static List<Color> getAvatarGradient(int index) {
    return avatarGradients[index % avatarGradients.length];
  }
  
  /// Obtener un color de gradiente de avatar según un nombre
  static List<Color> getAvatarGradientByName(String name) {
    final hash = name.hashCode.abs();
    return avatarGradients[hash % avatarGradients.length];
  }
  
  /// Color con opacidad personalizada
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
}
