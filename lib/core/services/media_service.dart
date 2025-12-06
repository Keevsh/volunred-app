import 'package:video_compress/video_compress.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import '../config/api_config.dart';

class MediaService {
  final Dio dio = Dio();
  static const int chunkSize = 1 * 1024 * 1024; // 1 MB por chunk

  /// Comprimir video y convertir a base64
  Future<String> comprimirVideoYConvertirABase64(
    File videoFile, {
    Function(int)? onProgress,
  }) async {
    print('📹 Comprimiendo video...');

    try {
      // Comprimir video a baja calidad para máxima reducción
      // VideoQuality.LowQuality = 360p (máxima compresión)
      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.LowQuality, // 360p - máxima compresión
        deleteOrigin: false,
      );

      if (info == null) {
        throw Exception('Error al comprimir video');
      }

      // Leer archivo comprimido
      final bytes = await File(info.file!.path).readAsBytes();
      final size = bytes.length / 1024 / 1024;

      final sizeOriginal = videoFile.lengthSync() / 1024 / 1024;
      print('📊 Tamaño original: ${sizeOriginal.toStringAsFixed(2)} MB');
      print('📊 Tamaño comprimido: ${size.toStringAsFixed(2)} MB');
      final reduccion = ((1 - (size / sizeOriginal)) * 100).toStringAsFixed(1);
      print('📉 Reducción: $reduccion%');

      // Validar que no supere límite de Vercel (~4.6MB)
      // Base64 aumenta tamaño ~33%, así que limitamos a 3.5MB
      if (size > 3.5) {
        throw Exception(
          'Video aún muy grande (${size.toStringAsFixed(2)}MB > 3.5MB). '
          'Vercel rechaza >4.6MB en base64. Intenta: duración más corta o comprime en app externa.',
        );
      }

      // Convertir a base64
      print('🔄 Convirtiendo a base64...');
      final base64 = base64Encode(bytes);
      final base64Size = (base64.length / 1024 / 1024).toStringAsFixed(2);
      print('✅ Conversión a base64 completada (${base64Size}MB)');

      return base64;
    } catch (e) {
      print('❌ Error en compresión: $e');
      rethrow;
    }
  }

  /// Subir video comprimido al proyecto (CON CHUNKS para videos grandes)
  Future<void> subirVideoAlProyecto({
    required File videoFile,
    required int proyectoId,
    required String jwtToken,
    required String nombreArchivo,
    Function(int)? onProgress,
  }) async {
    try {
      // 1️⃣ Comprimir video (sin límite de 3.5MB, ahora usamos chunks)
      print('📹 Comprimiendo video...');
      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
      );

      if (info == null) {
        throw Exception('Error al comprimir video');
      }

      final compressedFile = File(info.file!.path);
      final bytes = await compressedFile.readAsBytes();
      final size = bytes.length / 1024 / 1024;

      print('📊 Tamaño original: ${(videoFile.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB');
      print('📊 Tamaño comprimido: ${size.toStringAsFixed(2)} MB');
      print('📉 Reducción: ${((1 - (size / (videoFile.lengthSync() / 1024 / 1024))) * 100).toStringAsFixed(1)}%');

      // 2️⃣ Convertir a base64
      print('🔄 Convirtiendo a base64...');
      final base64 = base64Encode(bytes);
      final base64SizeMB = base64.length / 1024 / 1024;
      print('✅ Base64: ${base64SizeMB.toStringAsFixed(2)} MB');

      // 3️⃣ Decidir si usar chunks o upload directo
      if (base64SizeMB > 4) {
        print('📦 Video grande (${base64SizeMB.toStringAsFixed(2)}MB), usando CHUNKS...');
        await _subirPorChunks(
          base64: base64,
          proyectoId: proyectoId,
          jwtToken: jwtToken,
          nombreArchivo: nombreArchivo,
          mimeType: 'video/mp4',
          tipoMedia: 'video',
          onProgress: onProgress,
        );
      } else {
        print('📦 Video pequeño, upload directo...');
        await _subirDirecto(
          base64: base64,
          proyectoId: proyectoId,
          jwtToken: jwtToken,
          nombreArchivo: nombreArchivo,
          mimeType: 'video/mp4',
          tipoMedia: 'video',
        );
      }

      print('✅ Video subido exitosamente');
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  /// Upload directo (para archivos < 4 MB)
  Future<void> _subirDirecto({
    required String base64,
    required int proyectoId,
    required String jwtToken,
    required String nombreArchivo,
    required String mimeType,
    required String tipoMedia,
  }) async {
    final url = '${ApiConfig.baseUrl}/informacion/archivos-digitales';
    final payload = {
      'proyecto_id': proyectoId,
      'nombre_archivo': nombreArchivo,
      'contenido_base64': base64,
      'mime_type': mimeType,
      'tipo_media': tipoMedia,
    };

    print('🔑 Token presente: ${jwtToken.isNotEmpty ? "Sí" : "No"}');

    await dio.post(
      url,
      data: payload,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          if (jwtToken.isNotEmpty) 'Authorization': 'Bearer $jwtToken',
        },
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
      ),
    );
  }

  /// Upload por chunks (para archivos > 4 MB)
  Future<void> _subirPorChunks({
    required String base64,
    required int proyectoId,
    required String jwtToken,
    required String nombreArchivo,
    required String mimeType,
    required String tipoMedia,
    Function(int)? onProgress,
  }) async {
    final totalChunks = (base64.length / chunkSize).ceil();
    print('📦 Dividiendo en $totalChunks chunks de ${(chunkSize / 1024).toStringAsFixed(0)}KB cada uno');

    for (int i = 0; i < totalChunks; i++) {
      final start = i * chunkSize;
      final end = (i + 1) * chunkSize;
      final chunk = base64.substring(
        start,
        end > base64.length ? base64.length : end,
      );

      print('⬆️ Subiendo chunk ${i + 1}/$totalChunks (${(chunk.length / 1024).toStringAsFixed(0)}KB)...');

      final url = '${ApiConfig.baseUrl}/informacion/archivos-digitales/upload-chunk';
      final payload = {
        'proyecto_id': proyectoId,
        'chunk': chunk,
        'chunk_index': i,
        'total_chunks': totalChunks,
        'nombre_archivo': nombreArchivo,
        'mime_type': mimeType,
        'tipo_media': tipoMedia,
      };

      try {
        await dio.post(
          url,
          data: payload,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              if (jwtToken.isNotEmpty) 'Authorization': 'Bearer $jwtToken',
            },
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
          ),
        );

        final progreso = ((i + 1) / totalChunks * 100).toInt();
        if (onProgress != null) {
          onProgress(progreso);
        }
        print('✅ Chunk ${i + 1}/$totalChunks completado ($progreso%)');
        
      } catch (e) {
        print('❌ Error en chunk ${i + 1}: $e');
        rethrow;
      }
    }

    print('✅ Todos los chunks subidos exitosamente');
  }

  /// Subir imagen comprimida
  Future<void> subirImagenAlProyecto({
    required File imagenFile,
    required int proyectoId,
    required String jwtToken,
    required String nombreArchivo,
  }) async {
    try {
      print('🖼️ Leyendo imagen...');
      final bytes = await imagenFile.readAsBytes();
      final size = bytes.length / 1024 / 1024;

      if (size > 5) {
        print('⚠️ Imagen muy grande (${size.toStringAsFixed(2)}MB)');
        // Aqui podrias comprimir imagen tambien con image_compress
      }

      final base64 = base64Encode(bytes);

      print('🚀 Subiendo imagen...');
      await dio.post(
        '${ApiConfig.baseUrl}/informacion/archivos-digitales',
        data: {
          'proyecto_id': proyectoId,
          'nombre_archivo': nombreArchivo,
          'contenido_base64': base64,
          'mime_type': 'image/jpeg',
          'tipo_media': 'imagen',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('✅ Imagen subida exitosamente');
    } on DioException catch (e) {
      print('❌ Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }
}
