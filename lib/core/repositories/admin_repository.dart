import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/aplicacion.dart';
import '../models/aptitud.dart';
import '../models/dto/request_models.dart';
import '../models/modulo.dart';
import '../models/permiso.dart';
import '../models/programa.dart';
import '../models/rol.dart';
import '../models/usuario.dart';
import '../services/dio_client.dart';

class AdminRepository {
  final DioClient _dioClient;

  AdminRepository(this._dioClient);

  // ==================== USUARIOS ====================

  /// Listar todos los usuarios (solo admin)
  Future<Map<String, dynamic>> getUsuarios({
    int? page,
    int? limit,
    String? email,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (email != null) queryParams['email'] = email;

      final response = await _dioClient.dio.get(
        ApiConfig.perfilesUsuarios,
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      return {
        'usuarios': (data['data'] as List)
            .map((u) => Usuario.fromJson(u))
            .toList(),
        'total': data['total'] as int,
        'page': data['page'] as int,
        'limit': data['limit'] as int,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener usuario por ID
  Future<Usuario> getUsuarioById(int id) async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiConfig.perfilesUsuarios}/$id',
      );
      return Usuario.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar usuario
  Future<Usuario> updateUsuario(int id, UpdateUsuarioRequest request) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConfig.perfilesUsuarios}/$id',
        data: request.toJson(),
      );
      return Usuario.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar usuario
  Future<void> deleteUsuario(int id) async {
    try {
      await _dioClient.dio.delete('${ApiConfig.perfilesUsuarios}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== ROLES ====================

  /// Listar todos los roles
  Future<List<Rol>> getRoles() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.adminRoles);
      return (response.data as List).map((r) => Rol.fromJson(r)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener rol por ID con permisos
  Future<Rol> getRolById(int id) async {
    try {
      final response = await _dioClient.dio.get('${ApiConfig.adminRoles}/$id');
      return Rol.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear rol
  Future<Rol> createRol(CreateRolRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.adminRoles,
        data: request.toJson(),
      );
      return Rol.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar rol
  Future<Rol> updateRol(int id, UpdateRolRequest request) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConfig.adminRoles}/$id',
        data: request.toJson(),
      );
      return Rol.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar rol
  Future<void> deleteRol(int id) async {
    try {
      await _dioClient.dio.delete('${ApiConfig.adminRoles}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Asignar rol a usuario
  Future<Usuario> asignarRol(AsignarRolRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.adminAsignarRol,
        data: request.toJson(),
      );
      return Usuario.fromJson(response.data['usuario']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener permisos de un rol
  Future<Map<String, dynamic>> getPermisosByRol(int idRol) async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiConfig.adminRoles}/$idRol/permisos',
      );
      final data = response.data as Map<String, dynamic>;
      return {
        'rol': Rol.fromJson(data),
        'permisos': (data['permisos'] as List)
            .map((p) => Permiso.fromJson(p))
            .toList(),
        'total': data['total_permisos'] as int,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== PERMISOS ====================

  /// Listar todos los permisos
  Future<List<Permiso>> getPermisos() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.adminPermisos);
      return (response.data as List).map((p) => Permiso.fromJson(p)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Asignar programas a rol (crear permisos)
  Future<Map<String, dynamic>> asignarPermisos(
      AsignarPermisosRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.adminAsignarPermisos,
        data: request.toJson(),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Revocar permiso (eliminar)
  Future<void> deletePermiso(int id) async {
    try {
      await _dioClient.dio.delete('${ApiConfig.adminPermisos}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== PROGRAMAS ====================

  /// Listar todos los programas
  Future<List<Programa>> getProgramas() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.adminProgramas);
      return (response.data as List).map((p) => Programa.fromJson(p)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear programa
  Future<Programa> createPrograma(CreateProgramaRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.adminProgramas,
        data: request.toJson(),
      );
      return Programa.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== MÓDULOS ====================

  /// Listar módulos
  Future<List<Modulo>> getModulos() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.adminModulos);
      return (response.data as List).map((m) => Modulo.fromJson(m)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== APLICACIONES ====================

  /// Listar aplicaciones
  Future<List<Aplicacion>> getAplicaciones() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.adminAplicaciones);
      return (response.data as List)
          .map((a) => Aplicacion.fromJson(a))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear aplicación
  Future<Aplicacion> createAplicacion(CreateAplicacionRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.adminAplicaciones,
        data: request.toJson(),
      );
      return Aplicacion.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== APTITUDES (ADMIN) ====================

  /// Listar todas las aptitudes
  Future<List<Aptitud>> getAptitudes() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.aptitudes);
      
      // Manejar diferentes formatos de respuesta del backend
      final data = response.data;
      
      // Si la respuesta tiene una propiedad 'data', usarla
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return (data['data'] as List)
            .map((a) => Aptitud.fromJson(a as Map<String, dynamic>))
            .toList();
      }
      
      // Si la respuesta es directamente una lista
      if (data is List) {
        return data
            .map((a) => Aptitud.fromJson(a as Map<String, dynamic>))
            .toList();
      }
      
      // Si ninguno de los casos anteriores, devolver lista vacía
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener aptitud por ID
  Future<Aptitud> getAptitudById(int id) async {
    try {
      final response = await _dioClient.dio.get('${ApiConfig.aptitudes}/$id');
      
      // Manejar diferentes formatos de respuesta
      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Si tiene propiedad 'data', usarla; sino usar el objeto completo
        final aptitudData = data.containsKey('data') ? data['data'] : data;
        return Aptitud.fromJson(aptitudData as Map<String, dynamic>);
      }
      
      throw Exception('Formato de respuesta inválido');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear aptitud
  Future<Aptitud> createAptitud(CreateAptitudRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.aptitudes,
        data: request.toJson(),
      );
      
      // Manejar diferentes formatos de respuesta
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final aptitudData = data.containsKey('data') ? data['data'] : data;
        return Aptitud.fromJson(aptitudData as Map<String, dynamic>);
      }
      
      throw Exception('Formato de respuesta inválido');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar aptitud
  Future<Aptitud> updateAptitud(int id, UpdateAptitudRequest request) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConfig.aptitudes}/$id',
        data: request.toJson(),
      );
      
      // Manejar diferentes formatos de respuesta
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final aptitudData = data.containsKey('data') ? data['data'] : data;
        return Aptitud.fromJson(aptitudData as Map<String, dynamic>);
      }
      
      throw Exception('Formato de respuesta inválido');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar aptitud
  Future<void> deleteAptitud(int id) async {
    try {
      await _dioClient.dio.delete('${ApiConfig.aptitudes}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== MANEJO DE ERRORES ====================

  String _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      switch (statusCode) {
        case 400:
          return data['message'] ?? 'Datos inválidos';
        case 401:
          return 'No autorizado. Inicia sesión nuevamente.';
        case 403:
          return data['message'] ?? 'No tienes permisos para esta acción';
        case 404:
          return 'Recurso no encontrado';
        case 409:
          return data['message'] ?? 'Conflicto con recurso existente';
        default:
          return data['message'] ?? 'Error en el servidor';
      }
    } else {
      return 'Error de conexión. Verifica tu internet.';
    }
  }
}
