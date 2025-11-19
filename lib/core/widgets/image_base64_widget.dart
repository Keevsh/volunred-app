import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../utils/image_utils.dart';

/// Widget para mostrar imágenes desde base64
/// 
/// Maneja automáticamente:
/// - Imágenes nulas o vacías (muestra placeholder)
/// - Errores de carga
/// - Validación de formato
class ImageBase64Widget extends StatelessWidget {
  /// String base64 de la imagen (puede ser null)
  final String? base64String;
  
  /// Texto alternativo para la imagen
  final String? alt;
  
  /// Ancho de la imagen
  final double? width;
  
  /// Alto de la imagen
  final double? height;
  
  /// BoxFit para la imagen
  final BoxFit fit;

  /// Calidad del filtro al escalar la imagen
  final FilterQuality filterQuality;
  
  /// Widget a mostrar cuando no hay imagen
  final Widget? placeholder;
  
  /// Widget a mostrar cuando hay error al cargar la imagen
  final Widget? errorWidget;
  
  /// Border radius para la imagen
  final BorderRadius? borderRadius;
  
  /// Color de fondo cuando no hay imagen
  final Color? backgroundColor;
  
  /// Icono a mostrar en el placeholder
  final IconData? placeholderIcon;
  
  /// Color del icono del placeholder
  final Color? placeholderIconColor;

  const ImageBase64Widget({
    super.key,
    required this.base64String,
    this.alt,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.filterQuality = FilterQuality.high,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
    this.placeholderIcon = Icons.image_outlined,
    this.placeholderIconColor,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay imagen, mostrar placeholder
    if (base64String == null || base64String!.isEmpty) {
      return _buildPlaceholder(context);
    }

    // Validar formato base64
    if (!ImageUtils.isValidBase64Image(base64String)) {
      return _buildErrorWidget(context, 'Formato de imagen inválido');
    }

    // Construir contenedor con imagen
    Widget imageWidget = Image.memory(
      _base64ToBytes(base64String!),
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildErrorWidget(context, 'Error al cargar la imagen');
      },
    );

    // Aplicar border radius si se especifica
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    // Aplicar dimensiones si se especifican
    if (width != null || height != null) {
      imageWidget = SizedBox(
        width: width,
        height: height,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) {
      return placeholder!;
    }

    final theme = Theme.of(context);
    final placeholderColor = placeholderIconColor ?? theme.colorScheme.onSurface.withOpacity(0.3);
    final bgColor = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;

    Widget placeholderContent = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Icon(
        placeholderIcon ?? Icons.image_outlined,
        color: placeholderColor,
        size: (width != null && height != null) 
            ? (width! < height! ? width! * 0.4 : height! * 0.4)
            : 48,
      ),
    );

    if (borderRadius != null) {
      placeholderContent = ClipRRect(
        borderRadius: borderRadius!,
        child: placeholderContent,
      );
    }

    return placeholderContent;
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    if (errorWidget != null) {
      return errorWidget!;
    }

    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final bgColor = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;

    Widget errorContent = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: errorColor,
            size: (width != null && height != null) 
                ? (width! < height! ? width! * 0.3 : height! * 0.3)
                : 32,
          ),
          if (width != null && width! > 100)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(color: errorColor),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );

    if (borderRadius != null) {
      errorContent = ClipRRect(
        borderRadius: borderRadius!,
        child: errorContent,
      );
    }

    return errorContent;
  }

  /// Convierte un string base64 a bytes
  Uint8List _base64ToBytes(String base64String) {
    // Extraer solo la parte base64 (después de ;base64,)
    final base64Match = RegExp(r';base64,(.+)$').firstMatch(base64String);
    if (base64Match == null) {
      throw Exception('Formato base64 inválido');
    }

    final base64Data = base64Match.group(1)!;
    return base64Decode(base64Data);
  }
}

/// Widget circular para mostrar foto de perfil desde base64
class CircularImageBase64Widget extends StatelessWidget {
  /// String base64 de la imagen
  final String? base64String;
  
  /// Tamaño del círculo
  final double size;
  
  /// Widget a mostrar cuando no hay imagen
  final Widget? placeholder;
  
  /// Color de fondo cuando no hay imagen
  final Color? backgroundColor;
  
  /// Color del borde
  final Color? borderColor;
  
  /// Ancho del borde
  final double borderWidth;

  const CircularImageBase64Widget({
    super.key,
    required this.base64String,
    this.size = 48,
    this.placeholder,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor != null && borderWidth > 0
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: ImageBase64Widget(
        base64String: base64String,
        width: size,
        height: size,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(size / 2),
        placeholder: placeholder,
        backgroundColor: backgroundColor,
        placeholderIcon: Icons.person_outline,
      ),
    );
  }
}

