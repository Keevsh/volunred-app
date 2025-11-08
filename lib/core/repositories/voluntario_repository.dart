import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/aptitud.dart';
import '../models/dto/request_models.dart';
import '../models/perfil_voluntario.dart';
import '../services/dio_client.dart';
import '../services/storage_service.dart';

class VoluntarioRepository {
  final DioClient _dioClient;

  VoluntarioRepository(this._dioClient);

  /// Crear perfil de voluntario
  Future<PerfilVoluntario> createPerfil(
      CreatePerfilVoluntarioRequest request) async {
    try {
      print('📤 Enviando request: ${request.toJson()}');
      
      final response = await _dioClient.dio.post(
        ApiConfig.perfilesVoluntarios,
        data: request.toJson(),
      );

      print('📥 Respuesta del servidor: ${response.data}');
      print('📥 Tipo de respuesta: ${response.data.runtimeType}');

      PerfilVoluntario perfil;

      // El backend puede devolver un string (mensaje) o un JSON (perfil)
      if (response.data is String) {
        // Si la respuesta es un string, el perfil se creó exitosamente
        // Intentamos obtener el perfil del usuario
        print('✅ Perfil creado exitosamente. Obteniendo perfil del usuario...');
        final perfilObtenido = await getPerfilByUsuario(request.usuarioId);
        if (perfilObtenido != null) {
          perfil = perfilObtenido;
        } else {
          print('⚠️ No se pudo obtener el perfil, creando perfil temporal...');
          // Si no podemos obtenerlo, creamos un perfil temporal con los datos del request
          perfil = PerfilVoluntario(
            idPerfilVoluntario: 0, // Temporal, se actualizará después
            usuarioId: request.usuarioId,
            bio: request.bio,
            disponibilidad: request.disponibilidad,
            estado: request.estado,
          );
        }
      } else if (response.data is Map<String, dynamic>) {
        // Si la respuesta es un JSON, parseamos normalmente
        perfil = PerfilVoluntario.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Formato de respuesta no reconocido: ${response.data.runtimeType}');
      }

      // Guardar perfil en storage
      await StorageService.saveString(
        ApiConfig.perfilVoluntarioKey,
        jsonEncode(perfil.toJson()),
      );

      return perfil;
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      print('❌ Status Code: ${e.response?.statusCode}');
      throw _handleError(e);
    } catch (e, stackTrace) {
      print('❌ Error general: $e');
      print('❌ StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Obtener todas las aptitudes disponibles
  Future<List<Aptitud>> getAptitudes() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.aptitudes);
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Aptitud.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Asignar aptitud a voluntario
  Future<void> asignarAptitud(AsignarAptitudRequest request) async {
    try {
      await _dioClient.dio.post(
        ApiConfig.aptitudesVoluntario,
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Asignar múltiples aptitudes
  Future<void> asignarMultiplesAptitudes(
    int perfilVolId,
    List<int> aptitudesIds,
  ) async {
    for (final aptitudId in aptitudesIds) {
      await asignarAptitud(
        AsignarAptitudRequest(
          perfilVolId: perfilVolId,
          aptitudId: aptitudId,
        ),
      );
    }
  }

  /// Obtener perfil de voluntario por usuario
  /// Retorna null si no existe el perfil
  Future<PerfilVoluntario?> getPerfilByUsuario(int usuarioId) async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiConfig.perfilesVoluntarios}/usuario/$usuarioId',
      );
      return PerfilVoluntario.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // Si el endpoint no existe o retorna 404, intentar obtener todos y filtrar
      if (e.response?.statusCode == 404) {
        try {
          final response = await _dioClient.dio.get(ApiConfig.perfilesVoluntarios);
          final List<dynamic> data = response.data is List
              ? response.data
              : (response.data['perfiles'] ?? []);
          
          for (var json in data) {
            final perfil = PerfilVoluntario.fromJson(json as Map<String, dynamic>);
            if (perfil.usuarioId == usuarioId) {
              return perfil;
            }
          }
          // No se encontró el perfil
          return null;
        } catch (e2) {
          // Si falla obtener todos, retornar null
          print('⚠️ No se pudo obtener perfil de voluntario: $e2');
          return null;
        }
      }
      // Para otros errores, también retornar null (no lanzar excepción)
      print('⚠️ Error obteniendo perfil de voluntario: ${e.response?.statusCode}');
      return null;
    }
  }

  /// Obtener perfil desde storage
  Future<PerfilVoluntario?> getStoredPerfil() async {
    final perfilJson =
        await StorageService.getString(ApiConfig.perfilVoluntarioKey);
    if (perfilJson != null) {
      return PerfilVoluntario.fromJson(jsonDecode(perfilJson));
    }
    return null;
  }

  /// Manejo de errores
  String _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      print('🔍 Error Response Data: $data');
      print('🔍 Error Response Type: ${data.runtimeType}');

      switch (statusCode) {
        case 400:
          // Intentar extraer mensaje de error más específico
          if (data is Map<String, dynamic>) {
            if (data['message'] is String) {
              return 'Datos inválidos: ${data['message']}';
            } else if (data['message'] is List) {
              final messages = (data['message'] as List).join(', ');
              return 'Datos inválidos: $messages';
            } else if (data['error'] is String) {
              return 'Error: ${data['error']}';
            }
          }
          return 'Datos inválidos. Por favor verifica la información ingresada.';
        case 401:
          return 'No autorizado. Inicia sesión nuevamente.';
        case 409:
          if (data is Map && data['message'] != null) {
            return data['message'].toString();
          }
          return 'Ya tienes un perfil de voluntario';
        case 404:
          return 'Recurso no encontrado';
        default:
          if (data is Map && data['message'] != null) {
            return data['message'].toString();
          }
          return 'Error en el servidor (${statusCode ?? "desconocido"})';
      }
    } else {
      return 'Error de conexión. Verifica tu internet.';
    }
  }
}
