import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/dto/request_models.dart';
import '../models/dto/response_models.dart';
import '../models/usuario.dart';
import '../services/dio_client.dart';
import '../services/storage_service.dart';

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository(this._dioClient);

  /// Registrar un nuevo usuario
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.authRegister,
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Guardar token y usuario en storage
      await StorageService.saveString(
        ApiConfig.accessTokenKey,
        authResponse.accessToken,
      );
      await StorageService.saveString(
        ApiConfig.usuarioKey,
        jsonEncode(authResponse.usuario.toJson()),
      );

      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Iniciar sesión
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.authLogin,
        data: request.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Guardar token y usuario en storage
      await StorageService.saveString(
        ApiConfig.accessTokenKey,
        authResponse.accessToken,
      );
      await StorageService.saveString(
        ApiConfig.usuarioKey,
        jsonEncode(authResponse.usuario.toJson()),
      );

      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener perfil del usuario autenticado
  Future<Usuario> getProfile() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.authProfile);
      return Usuario.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Cerrar sesión (limpiar storage)
  Future<void> logout() async {
    await StorageService.clear();
  }

  /// Verificar si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    final token = await StorageService.getString(ApiConfig.accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Obtener usuario desde storage
  Future<Usuario?> getStoredUser() async {
    final userJson = await StorageService.getString(ApiConfig.usuarioKey);
    if (userJson != null) {
      return Usuario.fromJson(jsonDecode(userJson));
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
          return 'Credenciales inválidas';
        case 409:
          return 'El email ya está registrado';
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
