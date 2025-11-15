import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

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

  /// Tamaño máximo del archivo en bytes (2MB para evitar "entity too large")
  static const int maxFileSize = 2 * 1024 * 1024; // Reducido de 5MB a 2MB

  /// Calidad de compresión por defecto (70% para buen balance calidad/tamaño)
  static const int defaultQuality = 70;

  /// Dimensiones máximas para redimensionar imágenes grandes
  static const int maxWidth = 1200;
  static const int maxHeight = 1200;

  /// Convierte un archivo de imagen a base64 con data URI
  /// 
  /// [file] - El archivo de imagen a convertir
  /// 
  /// Retorna un String en formato `data:image/[tipo];base64,[datos]`
  /// 
  /// Lanza una excepción si:
  /// - El archivo es null
  /// - El tipo de archivo no está permitido
  /// - El tamaño del archivo excede 2MB
  static Future<String> convertFileToBase64(File file) async {
    if (!await file.exists()) {
      throw Exception('El archivo no existe');
    }

    // Verificar tamaño del archivo
    final fileSize = await file.length();
    if (fileSize > maxFileSize) {
      throw Exception(
        'El archivo es demasiado grande. Tamaño máximo: 2MB. Tamaño actual: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB',
      );
    }

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

    // Leer el archivo como bytes
    final bytes = await file.readAsBytes();
    
    // Comprimir la imagen antes de convertir a base64
    final compressedBytes = await _compressImage(bytes, mimeType);
    
    // Convertir a base64
    final base64String = base64Encode(compressedBytes);
    
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
        'El archivo es demasiado grande. Tamaño máximo: 2MB. Tamaño actual: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB',
      );
    }

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

    // Leer el archivo como bytes
    final bytes = await xFile.readAsBytes();
    
    // Comprimir la imagen antes de convertir a base64
    final compressedBytes = await _compressImage(bytes, mimeType);
    
    // Convertir a base64
    final base64String = base64Encode(compressedBytes);
    
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

  /// Comprime una imagen para reducir su tamaño
  /// 
  /// [bytes] - Los bytes de la imagen original
  /// [mimeType] - El tipo MIME de la imagen
  /// 
  /// Retorna los bytes comprimidos de la imagen
  static Future<Uint8List> _compressImage(Uint8List bytes, String mimeType) async {
    try {
      // Decodificar la imagen
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        // Si no se puede decodificar, retornar los bytes originales
        return bytes;
      }

      // Redimensionar si es necesario
      if (image.width > maxWidth || image.height > maxHeight) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? maxWidth : null,
          height: image.height > image.width ? maxHeight : null,
          maintainAspect: true,
        );
      }

      // Comprimir según el tipo de imagen
      Uint8List compressedBytes;
      if (mimeType == 'image/jpeg' || mimeType == 'image/jpg') {
        compressedBytes = img.encodeJpg(image, quality: defaultQuality);
      } else if (mimeType == 'image/png') {
        compressedBytes = img.encodePng(image, level: 6); // Compresión PNG
      } else {
        // Para WEBP y otros formatos, convertir a JPEG
        compressedBytes = img.encodeJpg(image, quality: defaultQuality);
      }

      // Verificar que el archivo comprimido no exceda el límite
      if (compressedBytes.length > maxFileSize) {
        // Si aún es muy grande, reducir más la calidad
        if (mimeType == 'image/jpeg' || mimeType == 'image/jpg') {
          compressedBytes = img.encodeJpg(image, quality: 50); // Reducir calidad a 50%
        } else if (mimeType == 'image/png') {
          compressedBytes = img.encodePng(image, level: 9); // Máxima compresión PNG
        } else {
          compressedBytes = img.encodeJpg(image, quality: 50);
        }

        // Si aún es grande, redimensionar a un tamaño más pequeño
        if (compressedBytes.length > maxFileSize) {
          image = img.copyResize(
            image,
            width: image.width > image.height ? 800 : null,
            height: image.height > image.width ? 800 : null,
            maintainAspect: true,
          );
          
          if (mimeType == 'image/jpeg' || mimeType == 'image/jpg') {
            compressedBytes = img.encodeJpg(image, quality: 50);
          } else if (mimeType == 'image/png') {
            compressedBytes = img.encodePng(image, level: 9); // Máxima compresión
          } else {
            compressedBytes = img.encodeJpg(image, quality: 50);
          }
        }
      }

      return compressedBytes;
    } catch (e) {
      print('Error al comprimir imagen: $e');
      // En caso de error, retornar los bytes originales
      return bytes;
    }
  }
}

