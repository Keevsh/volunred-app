import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

/// Utilidades para manejar imágenes en formato base64
class ImageUtils {
  /// Tipos de imagen permitidos
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'image/gif',
  ];

  /// Tamaño máximo del archivo en bytes (5MB)
  static const int maxFileSize = 5 * 1024 * 1024;

  /// Convierte un archivo de imagen a base64 con data URI
  /// 
  /// [file] - El archivo de imagen a convertir
  /// 
  /// Retorna un String en formato `data:image/[tipo];base64,[datos]`
  /// 
  /// Lanza una excepción si:
  /// - El archivo es null
  /// - El tipo de archivo no está permitido
  /// - El tamaño del archivo excede 5MB
  static Future<String> convertFileToBase64(File file) async {
    if (!await file.exists()) {
      throw Exception('El archivo no existe');
    }

    // Verificar tamaño del archivo
    final fileSize = await file.length();
    if (fileSize > maxFileSize) {
      throw Exception(
        'El archivo es demasiado grande. Tamaño máximo: 5MB. Tamaño actual: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB',
      );
    }

    // Leer el archivo como bytes
    final bytes = await file.readAsBytes();
    
    // Determinar el tipo MIME basado en la extensión
    final extension = file.path.split('.').last.toLowerCase();
    String mimeType;
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        mimeType = 'image/jpeg';
        break;
      case 'png':
        mimeType = 'image/png';
        break;
      case 'webp':
        mimeType = 'image/webp';
        break;
      case 'gif':
        mimeType = 'image/gif';
        break;
      default:
        throw Exception('Tipo de archivo no permitido. Use: JPEG, PNG, WEBP o GIF');
    }

    // Convertir a base64
    final base64String = base64Encode(bytes);
    
    // Retornar con formato data URI
    return 'data:$mimeType;base64,$base64String';
  }

  /// Convierte un XFile (de image_picker) a base64 con data URI
  /// 
  /// [xFile] - El XFile de imagen a convertir
  /// 
  /// Retorna un String en formato `data:image/[tipo];base64,[datos]`
  static Future<String> convertXFileToBase64(XFile xFile) async {
    // Verificar tipo de archivo
    if (xFile.mimeType != null && !allowedImageTypes.contains(xFile.mimeType)) {
      throw Exception('Tipo de archivo no permitido. Use: JPEG, PNG, WEBP o GIF');
    }

    // Verificar tamaño del archivo
    final fileSize = await xFile.length();
    if (fileSize > maxFileSize) {
      throw Exception(
        'El archivo es demasiado grande. Tamaño máximo: 5MB. Tamaño actual: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB',
      );
    }

    // Leer el archivo como bytes
    final bytes = await xFile.readAsBytes();
    
    // Determinar el tipo MIME
    String mimeType = xFile.mimeType ?? 'image/jpeg';
    
    // Si no tiene mimeType, intentar determinarlo por extensión
    if (xFile.mimeType == null) {
      final extension = xFile.path.split('.').last.toLowerCase();
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        default:
          mimeType = 'image/jpeg'; // Default
      }
    }

    // Convertir a base64
    final base64String = base64Encode(bytes);
    
    // Retornar con formato data URI
    return 'data:$mimeType;base64,$base64String';
  }

  /// Valida si un string base64 es una imagen válida
  /// 
  /// [base64String] - El string base64 a validar
  /// 
  /// Retorna true si es válido, false en caso contrario
  static bool isValidBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return false;
    }

    // Debe comenzar con data:image/
    if (!base64String.startsWith('data:image/')) {
      return false;
    }

    // Debe contener ;base64,
    if (!base64String.contains(';base64,')) {
      return false;
    }

    // Extraer el tipo MIME
    final mimeTypeMatch = RegExp(r'data:image/([^;]+)').firstMatch(base64String);
    if (mimeTypeMatch == null) {
      return false;
    }

    final mimeType = 'image/${mimeTypeMatch.group(1)}';
    
    // Verificar que el tipo esté permitido
    return allowedImageTypes.contains(mimeType);
  }

  /// Extrae el tipo MIME de un string base64
  /// 
  /// [base64String] - El string base64
  /// 
  /// Retorna el tipo MIME o null si no se puede determinar
  static String? getMimeTypeFromBase64(String? base64String) {
    if (base64String == null || !base64String.startsWith('data:image/')) {
      return null;
    }

    final match = RegExp(r'data:image/([^;]+)').firstMatch(base64String);
    return match != null ? 'image/${match.group(1)}' : null;
  }

  /// Valida el tamaño de un string base64
  /// 
  /// [base64String] - El string base64
  /// 
  /// Retorna true si el tamaño es válido (menor a 5MB), false en caso contrario
  static bool isValidBase64Size(String? base64String) {
    if (base64String == null) {
      return true; // null es válido (campo opcional)
    }

    // Extraer solo la parte base64 (después de ;base64,)
    final base64Match = RegExp(r';base64,(.+)$').firstMatch(base64String);
    if (base64Match == null) {
      return false;
    }

    final base64Data = base64Match.group(1)!;
    
    // Calcular tamaño aproximado (base64 es ~33% más grande que el original)
    // Tamaño en bytes = (longitud del string * 3) / 4
    final estimatedSize = (base64Data.length * 3) ~/ 4;
    
    return estimatedSize <= maxFileSize;
  }
}

