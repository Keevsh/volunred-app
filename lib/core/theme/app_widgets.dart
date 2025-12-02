import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_styles.dart';

/// Widgets reutilizables para la aplicación
class AppWidgets {
  // ==================== TEXT FIELDS ====================

  /// Campo de texto estilizado moderno
  static Widget styledTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconPressed,
    bool obscureText = false,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: AppStyles.textBody,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: AppColors.iconSecondary,
                size: AppStyles.iconSizeMedium,
              )
            : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(
                  suffixIcon,
                  color: AppColors.iconSecondary,
                  size: AppStyles.iconSizeMedium,
                ),
                onPressed: onSuffixIconPressed,
              )
            : null,
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacingNormal,
          vertical: AppStyles.spacingMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: AppStyles.radiusSmall,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppStyles.radiusSmall,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppStyles.radiusSmall,
          borderSide: const BorderSide(
            color: AppColors.borderFocus,
            width: AppStyles.borderWidthThick,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppStyles.radiusSmall,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppStyles.radiusSmall,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppStyles.borderWidthThick,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppStyles.radiusSmall,
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
        labelStyle: AppStyles.textBody.copyWith(color: AppColors.textSecondary),
        hintStyle: AppStyles.textBody.copyWith(color: AppColors.textHint),
      ),
    );
  }

  // ==================== BOTONES ====================

  /// Botón principal con gradiente
  static Widget gradientButton({
    required VoidCallback onPressed,
    required String text,
    IconData? icon,
    List<Color>? gradient,
    bool isLoading = false,
    double? width,
    double height = AppStyles.buttonHeightMedium,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient ?? AppColors.blueGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: AppStyles.radiusSmall,
          boxShadow: [AppColors.shadowMedium],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppColors.textLight,
            shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusSmall),
            padding: EdgeInsets.zero,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
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
                      style: AppStyles.textButton.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: AppStyles.spacingSmall),
                      Icon(icon, size: AppStyles.iconSizeSmall),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  /// Botón secundario (outline)
  static Widget outlineButton({
    required VoidCallback onPressed,
    required String text,
    IconData? icon,
    Color? borderColor,
    Color? textColor,
    bool isLoading = false,
    double? width,
    double height = AppStyles.buttonHeightMedium,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? AppColors.primary,
          side: BorderSide(
            color: borderColor ?? AppColors.border,
            width: AppStyles.borderWidthNormal,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusSmall),
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyles.spacingLarge,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? AppColors.primary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppStyles.iconSizeSmall),
                    const SizedBox(width: AppStyles.spacingSmall),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }

  /// Botón de texto
  static Widget textButton({
    required VoidCallback onPressed,
    required String text,
    IconData? icon,
    Color? textColor,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: AppStyles.textButtonStyle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppStyles.iconSizeSmall, color: textColor),
            const SizedBox(width: AppStyles.spacingSmall),
          ],
          Text(text, style: AppStyles.textLink.copyWith(color: textColor)),
        ],
      ),
    );
  }

  // ==================== SNACKBARS ====================

  /// SnackBar estilizado
  static void showStyledSnackBar({
    required BuildContext context,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: AppStyles.iconSizeMedium,
          ),
          const SizedBox(width: AppStyles.spacingMedium),
          Expanded(
            child: Text(
              message,
              style: AppStyles.textBody.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusSmall),
      duration: duration,
      action: action,
      margin: const EdgeInsets.all(AppStyles.spacingNormal),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // ==================== LOADING INDICATORS ====================

  /// Loading overlay
  static Widget loadingOverlay({String? message}) {
    return Container(
      color: AppColors.overlay,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppStyles.spacingXLarge),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppStyles.radiusMedium,
            boxShadow: [AppColors.shadowLarge],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: AppStyles.spacingNormal),
                Text(
                  message,
                  style: AppStyles.textBody,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Loading spinner simple
  static Widget loadingSpinner({Color? color, double size = 40}) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.primary),
        ),
      ),
    );
  }

  // ==================== CARDS ====================

  /// Card simple con sombra
  static Widget card({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding ?? const EdgeInsets.all(AppStyles.spacingNormal),
        decoration: AppStyles.cardDecoration,
        child: child,
      ),
    );
  }

  /// Card con borde (sin sombra)
  static Widget flatCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding ?? const EdgeInsets.all(AppStyles.spacingNormal),
        decoration: AppStyles.cardDecorationFlat,
        child: child,
      ),
    );
  }

  /// Card con gradiente (compatibilidad)
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
        borderRadius: AppStyles.radiusLarge,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ?? AppColors.cardGradientLight,
        ),
        boxShadow: [AppColors.shadowMedium],
      ),
      child: child,
    );
  }

  /// Icono decorativo (compatibilidad)
  static Widget decorativeIcon({
    required IconData icon,
    Color? color,
    double size = 48,
  }) {
    return Icon(icon, size: size, color: color ?? AppColors.primary);
  }

  // ==================== EMPTY STATES ====================

  /// Estado vacío
  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spacingXXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppStyles.spacingXLarge),
            Text(
              title,
              style: AppStyles.textTitle.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppStyles.spacingSmall),
              Text(
                subtitle,
                style: AppStyles.textSecondary,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppStyles.spacingXLarge),
              action,
            ],
          ],
        ),
      ),
    );
  }

  // ==================== MODALES ====================

  /// Bottom sheet moderno
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppStyles.borderRadiusXLarge),
          ),
        ),
        child: child,
      ),
    );
  }

  /// Modal de confirmación
  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusMedium),
        title: Text(title, style: AppStyles.textTitle),
        content: Text(message, style: AppStyles.textBody),
        actions: [
          textButton(
            onPressed: () => Navigator.of(context).pop(false),
            text: cancelText,
            textColor: AppColors.textSecondary,
          ),
          textButton(
            onPressed: () => Navigator.of(context).pop(true),
            text: confirmText,
            textColor: isDestructive ? AppColors.error : AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ==================== BADGES ====================

  /// Badge de notificación
  static Widget badge({
    required Widget child,
    required int count,
    bool showZero = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0 || showZero)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.badge,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
