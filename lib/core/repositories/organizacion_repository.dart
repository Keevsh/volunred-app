import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../services/dio_client.dart';
import '../models/organizacion.dart';
import '../models/perfil_funcionario.dart';

class OrganizacionRepository {
  final DioClient _dioClient;

  OrganizacionRepository(this._dioClient);

  // ==================== ORGANIZACIONES ====================
  // NOTA: Relación 1:N con Proyectos
  // Una organización puede tener muchos proyectos.
  // Los proyectos se relacionan con la organización mediante `organizacion_id`.

  /// Obtener todas las organizaciones
  /// 
  /// NOTA: Cada organización puede tener muchos proyectos (relación 1:N).
  /// Para obtener los proyectos de una organización específica,
  /// consulta la tabla `proyectos` filtrando por `organizacion_id`.
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
  /// 
  /// NOTA: Una organización puede tener muchos proyectos.
  /// Los proyectos no se incluyen directamente en este modelo,
  /// pero puedes obtenerlos consultando la tabla `proyectos`
  /// filtrando por `organizacion_id = id`.
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
      // Log exact data being sent
      print('📤 Enviando datos de creación de organización:');
      print('📤 Keys: ${data.keys.toList()}');
      print('📤 Values: $data');
      
      // Ensure id_categoria_organizacion is NOT in the data
      final cleanedData = Map<String, dynamic>.from(data);
      if (cleanedData.containsKey('id_categoria_organizacion')) {
        print('⚠️ ADVERTENCIA: id_categoria_organizacion encontrado en datos, removiendo...');
        cleanedData.remove('id_categoria_organizacion');
      }
      
      final response = await _dioClient.dio.post(
        ApiConfig.organizaciones,
        data: cleanedData,
      );
      print('🔍 Respuesta del servidor: ${response.data}');
      print('🔍 Tipo de respuesta: ${response.data.runtimeType}');
      
      // Si la respuesta viene envuelta en un objeto, extraer los datos
      final jsonData = response.data is Map<String, dynamic> 
          ? response.data as Map<String, dynamic>
          : response.data;
      
      // Log the actual JSON keys to help debug
      if (jsonData is Map) {
        print('🔍 Keys en respuesta: ${jsonData.keys.toList()}');
        print('🔍 Valores en respuesta: $jsonData');
      }
          
      try {
        return Organizacion.fromJson(jsonData);
      } catch (e, stackTrace) {
        print('❌ Error parseando Organizacion desde JSON: $e');
        print('❌ StackTrace: $stackTrace');
        print('❌ JSON que causó el error: $jsonData');
        rethrow;
      }
    } on DioException catch (e) {
      print('❌ Error en createOrganizacion: ${e.response?.data}');
      throw _handleError(e);
    }
  }

  /// Actualizar organización
  Future<Organizacion> updateOrganizacion(int id, Map<String, dynamic> data) async {
    try {
      print('📤 Actualizando organización ID: $id');
      print('📤 Datos de actualización: $data');
      
      final response = await _dioClient.dio.patch(
        '${ApiConfig.organizaciones}/$id',
        data: data,
      );
      print('✅ Organización actualizada exitosamente');
      return Organizacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('❌ Error en updateOrganizacion: ${e.response?.data}');
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
      final response = await _dioClient.dio.get('${ApiConfig.perfilesFuncionarios}/$idUsuario');
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
      final url = ApiConfig.baseUrl + ApiConfig.perfilesFuncionarios;
      print('📤 Creando perfil funcionario');
      print('📤 URL: $url');
      print('📤 Datos: $data');
      print('📤 Keys: ${data.keys.toList()}');
      print('📤 Valores: ${data.values.toList()}');
      
      final response = await _dioClient.dio.post(
        ApiConfig.perfilesFuncionarios,
        data: data,
      );
      print('✅ Respuesta recibida');
      print('🔍 Status code: ${response.statusCode}');
      print('🔍 Respuesta perfil funcionario: ${response.data}');
      print('🔍 Tipo de respuesta: ${response.data.runtimeType}');
      
      // Si la respuesta viene envuelta en un objeto, extraer los datos
      final jsonData = response.data is Map<String, dynamic> 
          ? response.data as Map<String, dynamic>
          : response.data;
      
      try {
        final perfil = PerfilFuncionario.fromJson(jsonData);
        print('✅ Perfil parseado correctamente: ID=${perfil.idPerfilFuncionario}');
        return perfil;
      } catch (e, stackTrace) {
        print('❌ Error parseando PerfilFuncionario desde JSON: $e');
        print('❌ StackTrace: $stackTrace');
        print('❌ JSON que causó el error: $jsonData');
        rethrow;
      }
    } on DioException catch (e) {
      print('❌ DioException en createPerfilFuncionario');
      print('❌ URL solicitada: ${e.requestOptions.uri}');
      print('❌ Método: ${e.requestOptions.method}');
      print('❌ Datos enviados: ${e.requestOptions.data}');
      print('❌ Status code: ${e.response?.statusCode}');
      print('❌ Error response data: ${e.response?.data}');
      print('❌ Error message: ${e.message}');
      throw _handleError(e);
    } catch (e, stackTrace) {
      print('❌ Error inesperado en createPerfilFuncionario: $e');
      print('❌ StackTrace: $stackTrace');
      rethrow;
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
      print('🔍 Error Response Data: $data');
      print('🔍 Error Response Type: ${data.runtimeType}');
      
      if (data is Map) {
        // Handle message field - can be String or List<String>
        if (data.containsKey('message')) {
          final message = data['message'];
          if (message is List) {
            return message.join(', ');
          } else if (message is String) {
            return message;
          }
        }
        // Handle error field
        if (data.containsKey('error')) {
          final error = data['error'];
          if (error is String) {
            return error;
          }
        }
        // If we have a statusCode, include it
        if (data.containsKey('statusCode')) {
          return 'Error ${data['statusCode']}: ${data['error'] ?? 'Bad Request'}';
        }
      }
      return 'Error: ${e.response!.statusCode}';
    }
    return 'Error de conexión: ${e.message}';
  }
}
