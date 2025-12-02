import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/dto/request_models.dart';
import '../models/dto/response_models.dart';
import '../models/usuario.dart';
import '../models/perfil_funcionario.dart';
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

      // Siempre limpiar cualquier perfil de voluntario previo
      await StorageService.remove(ApiConfig.perfilVoluntarioKey);

      // Guardar perfil de voluntario si está disponible para el nuevo usuario
      if (authResponse.perfilVoluntario != null) {
        await StorageService.saveString(
          ApiConfig.perfilVoluntarioKey,
          jsonEncode(authResponse.perfilVoluntario!.toJson()),
        );
      }
      // Nota: No hay storage key para perfilFuncionario aún, pero se puede agregar si es necesario

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

      print('📥 Respuesta del login: ${response.data}');
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

      // Siempre limpiar cualquier perfil de voluntario previo
      await StorageService.remove(ApiConfig.perfilVoluntarioKey);

      // Guardar perfiles si están disponibles para este usuario
      if (authResponse.perfilVoluntario != null) {
        print('💾 Guardando perfil de voluntario en storage');
        await StorageService.saveString(
          ApiConfig.perfilVoluntarioKey,
          jsonEncode(authResponse.perfilVoluntario!.toJson()),
        );
      }
      if (authResponse.perfilFuncionario != null) {
        print(
          '💾 Guardando perfil de funcionario en storage: ${authResponse.perfilFuncionario!.idPerfilFuncionario}',
        );
        await StorageService.saveString(
          ApiConfig.perfilFuncionarioKey,
          jsonEncode(authResponse.perfilFuncionario!.toJson()),
        );
        await StorageService.saveString(
          ApiConfig.tienePerfilFuncionarioKey,
          'true',
        );
      } else if (authResponse.tienePerfilFuncionarioRaw) {
        // Si el perfil existe en el backend pero no se pudo parsear, guardar el flag
        print(
          '💾 Perfil de funcionario existe en backend pero no se pudo parsear. Guardando flag.',
        );
        await StorageService.saveString(
          ApiConfig.tienePerfilFuncionarioKey,
          'true',
        );
      } else if (authResponse.esFuncionario) {
        // Si es funcionario y no tiene perfil, guardar flag como false
        print('💾 Funcionario sin perfil. Guardando flag.');
        await StorageService.saveString(
          ApiConfig.tienePerfilFuncionarioKey,
          'false',
        );
      }

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

  /// Obtener perfil de funcionario desde storage
  Future<PerfilFuncionario?> getStoredPerfilFuncionario() async {
    final perfilJson = await StorageService.getString(
      ApiConfig.perfilFuncionarioKey,
    );
    if (perfilJson != null) {
      try {
        return PerfilFuncionario.fromJson(jsonDecode(perfilJson));
      } catch (e) {
        print('⚠️ Error parseando perfilFuncionario desde storage: $e');
        return null;
      }
    }
    return null;
  }

  /// Verificar si tiene perfil de funcionario (desde storage)
  Future<bool> tienePerfilFuncionario() async {
    final flag = await StorageService.getString(
      ApiConfig.tienePerfilFuncionarioKey,
    );
    if (flag != null) {
      return flag == 'true';
    }
    // Si no hay flag, verificar si hay perfil guardado
    final perfil = await getStoredPerfilFuncionario();
    return perfil != null;
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
