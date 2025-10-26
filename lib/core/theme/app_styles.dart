import 'package:flutter/material.dart';

/// Constantes de diseño para la aplicación
class AppStyles {
  // Bordes redondeados
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 24.0;
  static const double borderRadiusXLarge = 32.0;
  
  // Espaciado
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;
  
  // Tamaños de fuente
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeNormal = 15.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeTitle = 24.0;
  static const double fontSizeHeader = 32.0;
  
  // Tamaños de botones
  static const double buttonHeightSmall = 40.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;
  
  // Tamaños de iconos
  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;
  
  // Elevación (sombras)
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  
  // Opacidad
  static const double opacityLight = 0.1;
  static const double opacityMedium = 0.2;
  static const double opacityHigh = 0.9;
  
  // Border radius como BorderRadius
  static BorderRadius get borderRadiusSmallAll => 
      BorderRadius.circular(borderRadiusSmall);
  static BorderRadius get borderRadiusMediumAll => 
      BorderRadius.circular(borderRadiusMedium);
  static BorderRadius get borderRadiusLargeAll => 
      BorderRadius.circular(borderRadiusLarge);
  static BorderRadius get borderRadiusXLargeAll => 
      BorderRadius.circular(borderRadiusXLarge);
}
