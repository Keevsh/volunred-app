import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/aplicacion.dart';
import '../models/aptitud.dart';
import '../models/dto/request_models.dart';
import '../models/modulo.dart';
import '../models/organizacion.dart';
import '../models/permiso.dart';
import '../models/programa.dart';
import '../models/proyecto.dart';
import '../models/tarea.dart';
import '../models/inscripcion.dart';
import '../models/rol.dart';
import '../models/usuario.dart';
import '../services/dio_client.dart';
import '../services/storage_service.dart';

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

      final url = '${ApiConfig.baseUrl}${ApiConfig.perfilesUsuarios}';
      print('🔵 URL COMPLETA USUARIOS: $url');
      print('🔵 Intentando obtener usuarios desde: ${ApiConfig.perfilesUsuarios}');
      final response = await _dioClient.dio.get(
        ApiConfig.perfilesUsuarios,
        queryParameters: queryParams,
      );
      
      print('🔵 Respuesta usuarios: ${response.statusCode}');
      print('🔵 Tipo de datos: ${response.data.runtimeType}');
      print('🔵 Datos usuarios: ${response.data}');

      // El backend devuelve directamente un array []
      if (response.data is List) {
        final usuariosList = (response.data as List)
            .map((u) => Usuario.fromJson(u as Map<String, dynamic>))
            .toList();
        
        return {
          'usuarios': usuariosList,
          'total': usuariosList.length,
          'page': page ?? 1,
          'limit': limit ?? usuariosList.length,
        };
      }
      
      // Si por alguna razón viene como objeto con data
      final data = response.data as Map<String, dynamic>;
      
      // Helper function to safely get int value
      int _getInt(dynamic value, {int defaultValue = 0}) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        return int.tryParse(value.toString()) ?? defaultValue;
      }
      
      return {
        'usuarios': (data['data'] as List)
            .map((u) => Usuario.fromJson(u as Map<String, dynamic>))
            .toList(),
        'total': _getInt(data['total']),
        'page': _getInt(data['page']),
        'limit': _getInt(data['limit']),
      };
    } on DioException catch (e) {
      print('🔴 Error al obtener usuarios: ${e.response?.statusCode}');
      print('🔴 URL que falló usuarios: ${e.requestOptions.uri}');
      print('🔴 Mensaje: ${e.response?.data}');
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

  /// Crear usuario
  Future<Usuario> createUsuario(CreateUsuarioRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.perfilesUsuarios,
        data: request.toJson(),
      );
      
      // Manejar diferentes formatos de respuesta
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final usuarioData = data.containsKey('data') ? data['data'] : data;
        return Usuario.fromJson(usuarioData as Map<String, dynamic>);
      }
      
      throw Exception('Formato de respuesta inválido');
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
      
      // Manejar diferentes formatos de respuesta
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final usuarioData = data.containsKey('data') ? data['data'] : data;
        return Usuario.fromJson(usuarioData as Map<String, dynamic>);
      }
      
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
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['roles'] ?? []);
      return data.map((r) => Rol.fromJson(r as Map<String, dynamic>)).toList();
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
      // La respuesta viene directamente como el objeto usuario, no envuelto
      return Usuario.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener permisos de un rol (programas asignados al rol)
  /// 
  /// Consulta la tabla `permisos` para obtener todos los programas (acciones)
  /// que tiene asignados un rol específico.
  /// 
  /// La tabla `permisos` es la tabla intermedia que relaciona roles con programas.
  Future<Map<String, dynamic>> getPermisosByRol(int idRol) async {
    try {
      // Primero obtener el rol
      final rol = await getRolById(idRol);
      
      // Luego obtener los permisos (registros de la tabla permisos donde id_rol = idRol)
      final response = await _dioClient.dio.get(
        '${ApiConfig.adminRoles}/$idRol/permisos',
      );
      
      // La respuesta puede ser una lista directamente o un objeto con permisos
      List<Permiso> permisos = [];
      int total = 0;
      
      if (response.data is List) {
        // Si la respuesta es una lista directamente
        final permisosList = response.data as List;
        permisos = permisosList
            .map((p) => Permiso.fromJson(p as Map<String, dynamic>))
            .toList();
        total = permisos.length;
      } else if (response.data is Map<String, dynamic>) {
        // Si la respuesta es un objeto con estructura
        final data = response.data as Map<String, dynamic>;
        if (data['permisos'] != null && data['permisos'] is List) {
          permisos = (data['permisos'] as List)
              .map((p) => Permiso.fromJson(p as Map<String, dynamic>))
              .toList();
        }
        total = data['total_permisos'] as int? ?? permisos.length;
      }
      
      return {
        'rol': rol,
        'permisos': permisos,
        'total': total,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== PERMISOS ====================
  // NOTA: La tabla `permisos` es la tabla intermedia entre `roles` y `programas`.
  // Representa qué programas (acciones) tiene acceso cada rol.
  // NO existe una tabla `roles_permisos` - todo se maneja a través de `permisos`.

  /// Listar todos los permisos (relaciones rol-programa)
  Future<List<Permiso>> getPermisos() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.adminPermisos);
      return (response.data as List).map((p) => Permiso.fromJson(p)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Asignar programas a rol (crear registros en la tabla permisos)
  /// 
  /// Cuando se asignan programas a un rol, se crean registros en la tabla `permisos`
  /// que relacionan el rol con cada programa. Esto otorga al rol acceso a esas acciones.
  /// 
  /// La tabla `permisos` es la única tabla intermedia entre `roles` y `programas`.
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

  /// Revocar permiso (eliminar registro de la tabla permisos)
  /// 
  /// Elimina un registro de la tabla `permisos`, revocando el acceso de un rol
  /// a un programa específico.
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

  /// Actualizar programa
  Future<Programa> updatePrograma(int id, UpdateProgramaRequest request) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConfig.adminProgramas}/$id',
        data: request.toJson(),
      );
      
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final programaData = data.containsKey('data') ? data['data'] : data;
        return Programa.fromJson(programaData as Map<String, dynamic>);
      }
      
      return Programa.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar programa
  Future<void> deletePrograma(int id) async {
    try {
      await _dioClient.dio.delete('${ApiConfig.adminProgramas}/$id');
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

  /// Actualizar módulo
  Future<Modulo> updateModulo(int id, UpdateModuloRequest request) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConfig.adminModulos}/$id',
        data: request.toJson(),
      );
      
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final moduloData = data.containsKey('data') ? data['data'] : data;
        return Modulo.fromJson(moduloData as Map<String, dynamic>);
      }
      
      return Modulo.fromJson(response.data);
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

  /// Actualizar aplicación
  Future<Aplicacion> updateAplicacion(int id, UpdateAplicacionRequest request) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConfig.adminAplicaciones}/$id',
        data: request.toJson(),
      );
      
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final aplicacionData = data.containsKey('data') ? data['data'] : data;
        return Aplicacion.fromJson(aplicacionData as Map<String, dynamic>);
      }
      
      return Aplicacion.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar aplicación
  Future<void> deleteAplicacion(int id) async {
    try {
      await _dioClient.dio.delete('${ApiConfig.adminAplicaciones}/$id');
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

  // ==================== CATEGORÍAS DE ORGANIZACIONES ====================

  /// Listar categorías de organizaciones
  Future<List<dynamic>> getCategoriasOrganizaciones() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.categoriasOrganizaciones);
      return response.data as List;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear categoría de organización
  Future<Map<String, dynamic>> createCategoriaOrganizacion(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.categoriasOrganizaciones,
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar categoría de organización
  Future<Map<String, dynamic>> updateCategoriaOrganizacion(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConfig.categoriasOrganizaciones}/$id',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar categoría de organización
  Future<void> deleteCategoriaOrganizacion(int id) async {
    try {
      await _dioClient.dio.delete('${ApiConfig.categoriasOrganizaciones}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== CATEGORÍAS DE PROYECTOS ====================

  /// Listar categorías de proyectos
  Future<List<dynamic>> getCategoriasProyectos() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.categoriasProyectos);
      return response.data as List;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear categoría de proyecto
  Future<Map<String, dynamic>> createCategoriaProyecto(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.categoriasProyectos,
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar categoría de proyecto
  Future<Map<String, dynamic>> updateCategoriaProyecto(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConfig.categoriasProyectos}/$id',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar categoría de proyecto
  Future<void> deleteCategoriaProyecto(int id) async {
    try {
      await _dioClient.dio.delete('${ApiConfig.categoriasProyectos}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== ORGANIZACIONES ====================

  /// Listar todas las organizaciones
  Future<List<Organizacion>> getOrganizaciones() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.organizaciones);
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['organizaciones'] ?? []);
      return data.map((json) => Organizacion.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener organizaciones a las que pertenece un usuario (basado en inscripciones aprobadas)
  Future<List<Organizacion>> getOrganizacionesByUsuario(int userId) async {
    try {
      // Obtener todas las inscripciones del usuario
      final response = await _dioClient.dio.get(
        '${ApiConfig.inscripciones}?usuario_id=$userId&estado=aprobado',
      );
      
      final List<dynamic> inscripcionesData = response.data is List
          ? response.data
          : (response.data['inscripciones'] ?? []);
      
      // Extraer IDs únicos de organizaciones
      final Set<int> organizacionIds = {};
      for (final item in inscripcionesData) {
        final inscripcion = Inscripcion.fromJson(item as Map<String, dynamic>);
        organizacionIds.add(inscripcion.organizacionId);
      }
      
      // Si no hay organizaciones, devolver lista vacía
      if (organizacionIds.isEmpty) {
        return [];
      }
      
      // Obtener detalles de cada organización
      final organizaciones = <Organizacion>[];
      for (final id in organizacionIds) {
        try {
          final org = await getOrganizacionById(id);
          organizaciones.add(org);
        } catch (e) {
          // Si falla una, continuar con las demás
          print('Error obteniendo organización $id: $e');
        }
      }
      
      return organizaciones;
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
      return Organizacion.fromJson(response.data as Map<String, dynamic>);
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

  // ==================== PROYECTOS ====================
  // NOTA: Relación 1:N con Organización
  // Una organización puede tener muchos proyectos.
  // Los proyectos se relacionan con la organización mediante `organizacion_id`.

  /// Listar todos los proyectos
  /// 
  /// NOTA: Cada proyecto pertenece a una organización (relación 1:N).
  /// Para obtener solo los proyectos de una organización específica,
  /// filtra por `organizacionId`.
  Future<List<Proyecto>> getProyectos() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.proyectos);
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['proyectos'] ?? []);
      return data.map((json) => Proyecto.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener proyecto por ID
  Future<Proyecto> getProyectoById(int id) async {
    try {
      final response = await _dioClient.dio.get('${ApiConfig.proyectos}/$id');
      return Proyecto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear proyecto
  Future<Proyecto> createProyecto(Map<String, dynamic> data) async {
    try {
      print('🚀 [ADMIN REPO] Iniciando creación de proyecto...');
      print('📦 [ADMIN REPO] Datos originales recibidos: $data');
      print('🔍 [ADMIN REPO] Tipos de datos:');
      data.forEach((key, value) {
        print('   $key: ${value.runtimeType} = $value');
      });

      // Verificar si hay token antes de hacer la petición
      final token = await StorageService.getString(ApiConfig.accessTokenKey);
      print('🔐 [ADMIN REPO] Token disponible para crear proyecto: ${token != null}');
      if (token != null) {
        print('🔐 [ADMIN REPO] Token length: ${token.length}');
      }

      final response = await _dioClient.dio.post(
        ApiConfig.proyectos,
        data: data,
      );
      
      print('✅ [ADMIN REPO] Proyecto creado exitosamente');
      print('📦 [ADMIN REPO] Respuesta del backend: ${response.data}');
      
      return Proyecto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('❌ [ADMIN REPO] Error creando proyecto: ${e.message}');
      if (e.response != null) {
        print('🔍 [ADMIN REPO] Error Response Status: ${e.response!.statusCode}');
        print('🔍 [ADMIN REPO] Error Response Data: ${e.response!.data}');
        print('🔍 [ADMIN REPO] Error Response Headers: ${e.response!.headers}');
      } else {
        print('🔍 [ADMIN REPO] Error sin respuesta del servidor');
      }
      throw _handleError(e);
    }
  }

  /// Actualizar proyecto
  Future<Proyecto> updateProyecto(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConfig.proyectos}/$id',
        data: data,
      );
      return Proyecto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar proyecto
  Future<void> deleteProyecto(int id) async {
    try {
      await _dioClient.dio.delete('${ApiConfig.proyectos}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== TAREAS ====================

  /// Listar todas las tareas
  Future<List<Tarea>> getTareas() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.tareas);
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['tareas'] ?? []);
      return data.map((json) => Tarea.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener tarea por ID
  Future<Tarea> getTareaById(int id) async {
    try {
      final response = await _dioClient.dio.get('${ApiConfig.tareas}/$id');
      return Tarea.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear tarea
  Future<Tarea> createTarea(Map<String, dynamic> data) async {
    try {
      print('🚀 [ADMIN REPO] Iniciando creación de tarea...');
      print('📦 [ADMIN REPO] Datos originales recibidos: $data');
      print('🔍 [ADMIN REPO] Tipos de datos:');
      data.forEach((key, value) {
        print('   $key: ${value.runtimeType} = $value');
      });
      
      final response = await _dioClient.dio.post(
        ApiConfig.tareas,
        data: data,
      );
      
      print('✅ [ADMIN REPO] Tarea creada exitosamente');
      print('📦 [ADMIN REPO] Respuesta del backend: ${response.data}');
      
      return Tarea.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('❌ [ADMIN REPO] Error creando tarea: ${e.message}');
      if (e.response != null) {
        print('🔍 [ADMIN REPO] Error Response Status: ${e.response!.statusCode}');
        print('🔍 [ADMIN REPO] Error Response Data: ${e.response!.data}');
      }
      throw _handleError(e);
    }
  }

  /// Actualizar tarea
  Future<Tarea> updateTarea(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConfig.tareas}/$id',
        data: data,
      );
      return Tarea.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar tarea
  Future<void> deleteTarea(int id) async {
    try {
      await _dioClient.dio.delete('${ApiConfig.tareas}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== INSCRIPCIONES ====================

  /// Listar todas las inscripciones
  Future<List<Inscripcion>> getInscripciones() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.inscripciones);
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['inscripciones'] ?? []);
      return data.map((json) => Inscripcion.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener inscripción por ID
  Future<Inscripcion> getInscripcionById(int id) async {
    try {
      final response = await _dioClient.dio.get('${ApiConfig.inscripciones}/$id');
      return Inscripcion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear inscripción
  Future<Inscripcion> createInscripcion(Map<String, dynamic> data) async {
    try {
      print('🚀 [ADMIN REPO] Iniciando creación de inscripción...');
      print('📦 [ADMIN REPO] Datos originales recibidos: $data');
      
      // Normalizar el estado a minúsculas si está presente (el backend espera: pendiente, aprobado, rechazado)
      final normalizedData = Map<String, dynamic>.from(data);
      if (normalizedData.containsKey('estado') && normalizedData['estado'] is String) {
        normalizedData['estado'] = (normalizedData['estado'] as String).toLowerCase();
      } else if (!normalizedData.containsKey('estado')) {
        normalizedData['estado'] = 'pendiente';
      }
      
      print('📦 [ADMIN REPO] Datos normalizados: $normalizedData');
      print('🔍 [ADMIN REPO] Tipos de datos:');
      normalizedData.forEach((key, value) {
        print('   $key: ${value.runtimeType} = $value');
      });
      
      final response = await _dioClient.dio.post(
        ApiConfig.inscripciones,
        data: normalizedData,
      );
      
      print('✅ [ADMIN REPO] Inscripción creada exitosamente');
      print('📦 [ADMIN REPO] Respuesta del backend: ${response.data}');
      
      return Inscripcion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // Proporcionar mensajes de error más descriptivos para errores 500
      if (e.response?.statusCode == 500) {
        final errorData = e.response?.data;
        String errorMessage = 'Error del servidor al crear la inscripción';
        
        if (errorData is Map<String, dynamic>) {
          if (errorData.containsKey('message')) {
            errorMessage = errorData['message'] as String;
          } else if (errorData.containsKey('error')) {
            errorMessage = errorData['error'] as String;
          }
        }
        
        print('❌ [ADMIN REPO] Error 500 del servidor: $errorMessage');
        throw Exception(errorMessage);
      }
      print('❌ [ADMIN REPO] Error creando inscripción: ${e.message}');
      if (e.response != null) {
        print('🔍 [ADMIN REPO] Error Response Status: ${e.response!.statusCode}');
        print('🔍 [ADMIN REPO] Error Response Data: ${e.response!.data}');
      }
      throw _handleError(e);
    }
  }

  /// Actualizar inscripción (aprobar/rechazar)
  Future<Inscripcion> updateInscripcion(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConfig.inscripciones}/$id',
        data: data,
      );
      return Inscripcion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar inscripción
  Future<void> deleteInscripcion(int id) async {
    try {
      await _dioClient.dio.delete('${ApiConfig.inscripciones}/$id');
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
