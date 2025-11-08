import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Componentes Material Design 3
class M3Components {
  /// Card Material 3 simple
  static Widget card({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    Color? color,
  }) {
    final card = Card(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color,
      child: padding != null
          ? Padding(
              padding: padding,
              child: child,
            )
          : child,
    );
    
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }
    
    return card;
  }
  
  /// Elevated Card (con elevación)
  static Widget elevatedCard({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double elevation = 2,
  }) {
    return Card(
      elevation: elevation,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: padding != null
          ? Padding(
              padding: padding,
              child: child,
            )
          : child,
    );
  }
  
  /// Filled Button (Material 3)
  static Widget filledButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : icon != null
              ? Icon(icon, size: 20)
              : const SizedBox.shrink(),
      label: isLoading
          ? const SizedBox.shrink()
          : Text(text),
      style: FilledButton.styleFrom(
        minimumSize: isFullWidth ? const Size(double.infinity, 40) : null,
      ),
    );
  }
  
  /// Outlined Button (Material 3)
  static Widget outlinedButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : icon != null
              ? Icon(icon, size: 20)
              : const SizedBox.shrink(),
      label: isLoading
          ? const SizedBox.shrink()
          : Text(text),
      style: OutlinedButton.styleFrom(
        minimumSize: isFullWidth ? const Size(double.infinity, 40) : null,
      ),
    );
  }
  
  /// Text Button (Material 3)
  static Widget textButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
      label: Text(text),
    );
  }
  
  /// Text Field Material 3
  static Widget textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconTap,
    bool obscureText = false,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon),
                onPressed: onSuffixIconTap,
              )
            : null,
      ),
    );
  }
  
  /// Chip Material 3
  static Widget chip({
    required String label,
    VoidCallback? onDeleted,
    bool selected = false,
    IconData? icon,
    ValueChanged<bool>? onSelected,
  }) {
    if (onDeleted != null) {
      return Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: onDeleted,
        avatar: icon != null ? Icon(icon, size: 18) : null,
      );
    }
    
    // Si necesita selección, usar FilterChip
    if (selected || onSelected != null) {
      return FilterChip(
        label: Text(label),
        avatar: icon != null ? Icon(icon, size: 18) : null,
        selected: selected,
        onSelected: onSelected ?? (value) {}, // Callback requerido
      );
    }
    
    return Chip(
      label: Text(label),
      avatar: icon != null ? Icon(icon, size: 18) : null,
    );
  }
  
  /// List Tile Material 3
  static Widget listTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    bool selected = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
      selected: selected,
      selectedTileColor: selected ? colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
  
  /// Snackbar Material 3
  static void showSnackBar({
    required BuildContext context,
    required String message,
    bool isError = false,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    final snackBar = SnackBar(
      content: Text(message),
      action: action,
      duration: duration,
      behavior: SnackBarBehavior.floating,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  
  /// Dialog Material 3
  static Future<T?> showConfirmDialog<T>({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: onCancel ?? () => Navigator.of(context).pop(),
              child: Text(cancelText),
            ),
          if (confirmText != null)
            FilledButton(
              onPressed: onConfirm ?? () => Navigator.of(context).pop(),
              style: isDestructive
                  ? FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    )
                  : null,
              child: Text(confirmText),
            ),
        ],
      ),
    );
  }
  
  /// Avatar Material 3
  static Widget avatar({
    String? imageUrl,
    String? name,
    double size = 40,
  }) {
    if (imageUrl != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl),
      );
    }
    
    final initials = name != null && name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : '?';
    
    return CircleAvatar(
      radius: size / 2,
      child: Text(initials),
    );
  }
}

