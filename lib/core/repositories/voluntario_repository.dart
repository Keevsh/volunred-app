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

      final perfil = PerfilVoluntario.fromJson(response.data);

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
