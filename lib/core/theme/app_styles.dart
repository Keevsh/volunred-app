import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Estilos y constantes de diseño para la aplicación
/// Diseño moderno estilo red social
class AppStyles {
  // ==================== BORDER RADIUS ====================

  static const double borderRadiusXSmall = 4.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;
  static const double borderRadiusXXLarge = 32.0;

  /// Border Radius como BorderRadius objects
  static BorderRadius get radiusXSmall =>
      BorderRadius.circular(borderRadiusXSmall);
  static BorderRadius get radiusSmall =>
      BorderRadius.circular(borderRadiusSmall);
  static BorderRadius get radiusMedium =>
      BorderRadius.circular(borderRadiusMedium);
  static BorderRadius get radiusLarge =>
      BorderRadius.circular(borderRadiusLarge);
  static BorderRadius get radiusXLarge =>
      BorderRadius.circular(borderRadiusXLarge);
  static BorderRadius get radiusXXLarge =>
      BorderRadius.circular(borderRadiusXXLarge);
  static BorderRadius get radiusCircle => BorderRadius.circular(9999);

  // ==================== ESPACIADO ====================

  static const double spacingXXSmall = 2.0;
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingNormal = 16.0;
  static const double spacingLarge = 20.0;
  static const double spacingXLarge = 24.0;
  static const double spacingXXLarge = 32.0;
  static const double spacingXXXLarge = 48.0;

  // ==================== TAMAÑOS DE FUENTE ====================

  static const double fontSizeXSmall = 10.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeNormal = 15.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeTitle = 24.0;
  static const double fontSizeHeading = 28.0;
  static const double fontSizeHeader = 32.0;
  static const double fontSizeXXLarge = 40.0;

  // ==================== PESOS DE FUENTE ====================

  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;
  static const FontWeight fontWeightBlack = FontWeight.w900;

  // ==================== ALTURA DE LÍNEA ====================

  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;

  // ==================== TAMAÑOS DE BOTONES ====================

  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 44.0;
  static const double buttonHeightLarge = 52.0;
  static const double buttonHeightXLarge = 60.0;

  static const double buttonMinWidth = 88.0;

  // ==================== TAMAÑOS DE ICONOS ====================

  static const double iconSizeXSmall = 14.0;
  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 40.0;
  static const double iconSizeXXLarge = 48.0;
  static const double iconSizeXXXLarge = 64.0;

  // ==================== TAMAÑOS DE AVATAR ====================

  static const double avatarSizeXSmall = 24.0;
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 40.0;
  static const double avatarSizeLarge = 56.0;
  static const double avatarSizeXLarge = 80.0;
  static const double avatarSizeXXLarge = 120.0;

  // ==================== ELEVACIÓN (SOMBRAS) ====================

  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  static const double elevationXHigh = 16.0;

  // ==================== OPACIDAD ====================

  static const double opacityDisabled = 0.38;
  static const double opacityLight = 0.1;
  static const double opacityMedium = 0.54;
  static const double opacityHigh = 0.87;
  static const double opacityFull = 1.0;

  // ==================== BORDER RADIUS (compatibilidad) ====================

  static BorderRadius get borderRadiusSmallAll => radiusSmall;
  static BorderRadius get borderRadiusMediumAll => radiusMedium;
  static BorderRadius get borderRadiusLargeAll => radiusLarge;
  static BorderRadius get borderRadiusXLargeAll => radiusXLarge;

  // ==================== DURACIONES DE ANIMACIÓN ====================

  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 350);
  static const Duration animationVerySlow = Duration(milliseconds: 500);

  // ==================== CURVAS DE ANIMACIÓN ====================

  static const Curve curveEaseIn = Curves.easeIn;
  static const Curve curveEaseOut = Curves.easeOut;
  static const Curve curveEaseInOut = Curves.easeInOut;
  static const Curve curveSpring = Curves.elasticOut;
  static const Curve curveBounce = Curves.bounceOut;

  // ==================== TAMAÑOS DE BORDE ====================

  static const double borderWidthThin = 0.5;
  static const double borderWidthNormal = 1.0;
  static const double borderWidthThick = 2.0;
  static const double borderWidthXThick = 3.0;

  // ==================== ESTILOS DE TEXTO ====================

  /// Texto muy grande (Headers)
  static TextStyle get textHeaderLarge => const TextStyle(
    fontSize: fontSizeHeader,
    fontWeight: fontWeightBold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  /// Texto de título
  static TextStyle get textTitle => const TextStyle(
    fontSize: fontSizeTitle,
    fontWeight: fontWeightBold,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  /// Texto de subtítulo
  static TextStyle get textSubtitle => const TextStyle(
    fontSize: fontSizeLarge,
    fontWeight: fontWeightSemiBold,
    color: AppColors.textPrimary,
  );

  /// Texto de cuerpo (principal)
  static TextStyle get textBody => const TextStyle(
    fontSize: fontSizeNormal,
    fontWeight: fontWeightRegular,
    color: AppColors.textPrimary,
    height: lineHeightNormal,
  );

  /// Texto de cuerpo bold
  static TextStyle get textBodyBold => const TextStyle(
    fontSize: fontSizeNormal,
    fontWeight: fontWeightSemiBold,
    color: AppColors.textPrimary,
    height: lineHeightNormal,
  );

  /// Texto secundario
  static TextStyle get textSecondary => const TextStyle(
    fontSize: fontSizeMedium,
    fontWeight: fontWeightRegular,
    color: AppColors.textSecondary,
    height: lineHeightNormal,
  );

  /// Texto pequeño (captions)
  static TextStyle get textCaption => const TextStyle(
    fontSize: fontSizeSmall,
    fontWeight: fontWeightRegular,
    color: AppColors.textSecondary,
  );

  /// Texto muy pequeño
  static TextStyle get textXSmall => const TextStyle(
    fontSize: fontSizeXSmall,
    fontWeight: fontWeightRegular,
    color: AppColors.textTertiary,
  );

  /// Texto de botón
  static TextStyle get textButton => const TextStyle(
    fontSize: fontSizeNormal,
    fontWeight: fontWeightSemiBold,
    color: AppColors.primary,
    letterSpacing: 0.25,
  );

  /// Texto de link
  static TextStyle get textLink => const TextStyle(
    fontSize: fontSizeNormal,
    fontWeight: fontWeightMedium,
    color: AppColors.primary,
    decoration: TextDecoration.none,
  );

  // ==================== ESTILOS DE CARD ====================

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppColors.surface,
    borderRadius: radiusMedium,
    boxShadow: [AppColors.shadowCard],
  );

  static BoxDecoration get cardDecorationFlat => BoxDecoration(
    color: AppColors.surface,
    borderRadius: radiusMedium,
    border: Border.all(color: AppColors.border, width: borderWidthNormal),
  );

  // ==================== ESTILOS DE INPUT ====================

  static InputDecoration inputDecoration({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorText: errorText,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingNormal,
        vertical: spacingMedium,
      ),
      border: OutlineInputBorder(
        borderRadius: radiusSmall,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusSmall,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusSmall,
        borderSide: const BorderSide(
          color: AppColors.borderFocus,
          width: borderWidthThick,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radiusSmall,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radiusSmall,
        borderSide: const BorderSide(
          color: AppColors.error,
          width: borderWidthThick,
        ),
      ),
    );
  }

  // ==================== ESTILOS DE BOTÓN ====================

  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textLight,
    elevation: elevationNone,
    shape: RoundedRectangleBorder(borderRadius: radiusSmall),
    padding: const EdgeInsets.symmetric(
      horizontal: spacingXLarge,
      vertical: spacingMedium,
    ),
    textStyle: textButton.copyWith(color: AppColors.textLight),
  );

  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.border),
    shape: RoundedRectangleBorder(borderRadius: radiusSmall),
    padding: const EdgeInsets.symmetric(
      horizontal: spacingXLarge,
      vertical: spacingMedium,
    ),
  );

  static ButtonStyle get textButtonStyle => TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    shape: RoundedRectangleBorder(borderRadius: radiusSmall),
    padding: const EdgeInsets.symmetric(
      horizontal: spacingNormal,
      vertical: spacingSmall,
    ),
  );

  // ==================== DEGRADADOS ====================

  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AppColors.primaryGradient,
  );

  static LinearGradient get blueGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AppColors.blueGradient,
  );

  static LinearGradient get pinkGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AppColors.pinkGradient,
  );

  // ==================== DIVISORES ====================

  static Divider get divider => const Divider(
    color: AppColors.border,
    thickness: borderWidthNormal,
    height: borderWidthNormal,
  );

  static Divider get dividerLight => Divider(
    color: AppColors.border.withOpacity(0.5),
    thickness: borderWidthThin,
    height: borderWidthThin,
  );
}
