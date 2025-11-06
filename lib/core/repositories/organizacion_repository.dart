import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../services/dio_client.dart';
import '../models/organizacion.dart';
import '../models/perfil_funcionario.dart';

class OrganizacionRepository {
  final DioClient _dioClient;

  OrganizacionRepository(this._dioClient);

  // ==================== ORGANIZACIONES ====================

  /// Obtener todas las organizaciones
  Future<List<Organizacion>> getOrganizaciones({
    int? page,
    int? limit,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConfig.organizaciones,
        queryParameters: {
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
      );
      
      final List<dynamic> data = response.data is List 
          ? response.data 
          : (response.data['organizaciones'] ?? []);
          
      return data.map((json) => Organizacion.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener organización por ID
  Future<Organizacion> getOrganizacionById(int id) async {
    try {
      final response = await _dioClient.dio.get('${ApiConfig.organizaciones}/$id');
      return Organizacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear organización
  Future<Organizacion> createOrganizacion(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.organizaciones,
        data: data,
      );
      print('🔍 Respuesta del servidor: ${response.data}');
      print('🔍 Tipo de respuesta: ${response.data.runtimeType}');
      
      // Si la respuesta viene envuelta en un objeto, extraer los datos
      final jsonData = response.data is Map<String, dynamic> 
          ? response.data as Map<String, dynamic>
          : response.data;
          
      return Organizacion.fromJson(jsonData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar organización
  Future<Organizacion> updateOrganizacion(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConfig.organizaciones}/$id',
        data: data,
      );
      return Organizacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar organización
  Future<void> deleteOrganizacion(int id) async {
    try {
      await _dioClient.dio.delete('${ApiConfig.organizaciones}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== PERFILES FUNCIONARIOS ====================

  /// Obtener todos los perfiles de funcionarios
  Future<List<PerfilFuncionario>> getPerfilesFuncionarios({
    int? page,
    int? limit,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConfig.perfilesFuncionarios,
        queryParameters: {
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
      );
      
      final List<dynamic> data = response.data is List 
          ? response.data 
          : (response.data['perfiles'] ?? []);
          
      return data.map((json) => PerfilFuncionario.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener perfil de funcionario por ID
  Future<PerfilFuncionario> getPerfilFuncionarioById(int id) async {
    try {
      final response = await _dioClient.dio.get('${ApiConfig.perfilesFuncionarios}/$id');
      return PerfilFuncionario.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener perfil de funcionario por usuario
  Future<PerfilFuncionario?> getPerfilFuncionarioByUsuario(int idUsuario) async {
    try {
      final response = await _dioClient.dio.get('${ApiConfig.perfilesFuncionarios}/usuario/$idUsuario');
      return PerfilFuncionario.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // No tiene perfil de funcionario
      }
      throw _handleError(e);
    }
  }

  /// Crear perfil de funcionario
  Future<PerfilFuncionario> createPerfilFuncionario(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.perfilesFuncionarios,
        data: data,
      );
      print('🔍 Respuesta perfil funcionario: ${response.data}');
      print('🔍 Tipo de respuesta: ${response.data.runtimeType}');
      
      // Si la respuesta viene envuelta en un objeto, extraer los datos
      final jsonData = response.data is Map<String, dynamic> 
          ? response.data as Map<String, dynamic>
          : response.data;
          
      return PerfilFuncionario.fromJson(jsonData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar perfil de funcionario
  Future<PerfilFuncionario> updatePerfilFuncionario(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConfig.perfilesFuncionarios}/$id',
        data: data,
      );
      return PerfilFuncionario.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== CATEGORÍAS ORGANIZACIONES ====================

  /// Obtener categorías de organizaciones
  Future<List<Map<String, dynamic>>> getCategoriasOrganizaciones() async {
    try {
      print('🔍 Obteniendo categorías de organizaciones...');
      final response = await _dioClient.dio.get(ApiConfig.categoriasOrganizaciones);
      print('🔍 Respuesta categorías: ${response.data}');
      print('🔍 Tipo de respuesta: ${response.data.runtimeType}');
      
      final categorias = List<Map<String, dynamic>>.from(response.data as List);
      print('🔍 Categorías parseadas: ${categorias.length} categorías');
      
      return categorias;
    } on DioException catch (e) {
      print('❌ Error obteniendo categorías: ${e.message}');
      print('❌ Respuesta error: ${e.response?.data}');
      throw _handleError(e);
    } catch (e) {
      print('❌ Error inesperado obteniendo categorías: $e');
      rethrow;
    }
  }

  // ==================== MANEJO DE ERRORES ====================

  String _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'] as String;
      }
      return 'Error: ${e.response!.statusCode}';
    }
    return 'Error de conexión: ${e.message}';
  }
}
