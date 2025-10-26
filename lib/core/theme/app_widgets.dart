import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_styles.dart';

/// Widgets reutilizables con el estilo de la app
class AppWidgets {
  /// Card con gradiente y sombra estilo VolunRed
  static Widget gradientCard({
    required Widget child,
    List<Color>? gradientColors,
    double? height,
    double? width,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: AppStyles.borderRadiusLargeAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ?? AppColors.cardGradientLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppStyles.opacityLight),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Botón con gradiente estilo VolunRed
  static Widget gradientButton({
    required VoidCallback onPressed,
    required String text,
    List<Color>? gradientColors,
    IconData? icon,
    double? height,
    double? width,
    bool isLoading = false,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? AppStyles.buttonHeightLarge,
      decoration: BoxDecoration(
        borderRadius: AppStyles.borderRadiusMediumAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ?? AppColors.primaryGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppStyles.opacityLight),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppStyles.borderRadiusMediumAll,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: AppStyles.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: AppStyles.spacingSmall),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(AppStyles.opacityMedium),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 20),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  /// Input field con estilo VolunRed
  static Widget styledTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconPressed,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: AppStyles.fontSizeBody),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon),
                onPressed: onSuffixIconPressed,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: AppStyles.borderRadiusMediumAll,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppStyles.borderRadiusMediumAll,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppStyles.borderRadiusMediumAll,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.borderLight,
        contentPadding: const EdgeInsets.all(20),
      ),
      validator: validator,
    );
  }

  /// Icono decorativo circular con sombra
  static Widget decorativeIcon({
    required IconData icon,
    required Color color,
    double? size,
    double? iconSize,
  }) {
    return Container(
      width: size ?? 44,
      height: size ?? 44,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(AppStyles.opacityHigh),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppStyles.opacityLight),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: iconSize ?? AppStyles.iconSizeMedium,
      ),
    );
  }

  /// SnackBar con estilo consistente
  static void showStyledSnackBar({
    required BuildContext context,
    required String message,
    bool isError = false,
    IconData? icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon ?? (isError ? Icons.error_outline : Icons.check_circle_outline),
              color: Colors.white,
            ),
            const SizedBox(width: AppStyles.spacingMedium),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadiusSmallAll,
        ),
        margin: const EdgeInsets.all(AppStyles.spacingMedium),
      ),
    );
  }

  /// Header de página con título y subtítulo
  static Widget pageHeader({
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppStyles.fontSizeHeader,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppStyles.spacingSmall),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: AppStyles.fontSizeBody,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
        if (trailing != null) ...[
          const SizedBox(height: AppStyles.spacingMedium),
          trailing,
        ],
      ],
    );
  }

  /// Botón de retroceso estilizado
  static Widget backButton(BuildContext context, {VoidCallback? onPressed}) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      icon: const Icon(Icons.arrow_back_ios),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.borderLight,
      ),
    );
  }
}
