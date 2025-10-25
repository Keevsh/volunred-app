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
      final response = await _dioClient.dio.post(
        ApiConfig.perfilesVoluntarios,
        data: request.toJson(),
      );

      final perfil = PerfilVoluntario.fromJson(response.data);

      // Guardar perfil en storage
      await StorageService.saveString(
        ApiConfig.perfilVoluntarioKey,
        jsonEncode(perfil.toJson()),
      );

      return perfil;
    } on DioException catch (e) {
      throw _handleError(e);
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

      switch (statusCode) {
        case 400:
          return data['message'] ?? 'Datos inválidos';
        case 401:
          return 'No autorizado. Inicia sesión nuevamente.';
        case 409:
          return 'Ya tienes un perfil de voluntario';
        case 404:
          return 'Recurso no encontrado';
        default:
          return data['message'] ?? 'Error en el servidor';
      }
    } else {
      return 'Error de conexión. Verifica tu internet.';
    }
  }
}
