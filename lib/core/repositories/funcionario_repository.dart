import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../services/dio_client.dart';
import '../models/proyecto.dart';
import '../models/tarea.dart';
import '../models/inscripcion.dart';
import '../models/participacion.dart';
import '../models/asignacion_tarea.dart';
import '../models/organizacion.dart';
import '../models/perfil_funcionario.dart';
import '../models/perfil_voluntario.dart';
import 'auth_repository.dart';
import 'organizacion_repository.dart';

class FuncionarioRepository {
  final DioClient _dioClient;

  FuncionarioRepository(this._dioClient);

  // ==================== DASHBOARD ====================

  /// Obtener resumen del dashboard
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.funcionariosDashboard);
      final data = response.data as Map<String, dynamic>;
      return data['resumen'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== MI ORGANIZACIÓN ====================

  /// Obtener información de mi organización
  /// Primero intenta el endpoint específico, si falla, obtiene desde el perfil
  Future<Organizacion> getMiOrganizacion() async {
    try {
      // Intentar usar el endpoint específico primero
      try {
        final response = await _dioClient.dio.get(ApiConfig.funcionariosMiOrganizacion);
        return Organizacion.fromJson(response.data as Map<String, dynamic>);
      } on DioException catch (e) {
        // Si el endpoint específico no existe (404), obtener desde el perfil
        if (e.response?.statusCode == 404) {
          print('⚠️ Endpoint específico de mi-organizacion no disponible (404), obteniendo desde perfil...');
          
          // Obtener el perfil del funcionario
          final perfil = await getMiPerfil();
          
          // Si el perfil tiene la organización como objeto, usarla directamente
          if (perfil.organizacion != null && perfil.organizacion is Map<String, dynamic>) {
            try {
              return Organizacion.fromJson(perfil.organizacion as Map<String, dynamic>);
            } catch (e2) {
              print('⚠️ Error parseando organización desde perfil: $e2');
            }
          }
          
          // Si no, obtener la organización por ID
          final orgId = perfil.idOrganizacion;
          final orgRepo = OrganizacionRepository(_dioClient);
          return await orgRepo.getOrganizacionById(orgId);
        }
        // Si es otro error, re-lanzarlo
        throw _handleError(e);
      }
    } catch (e) {
      print('❌ Error en getMiOrganizacion: $e');
      rethrow;
    }
  }

  /// Actualizar información de mi organización
  Future<Organizacion> updateMiOrganizacion(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiConfig.funcionariosMiOrganizacion,
        data: data,
      );
      return Organizacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== MI PERFIL ====================

  /// Obtener mi perfil completo
  /// Intenta usar el endpoint específico, si no existe, obtiene el perfil por usuario_id
  Future<PerfilFuncionario> getMiPerfil() async {
    try {
      // Intentar usar el endpoint específico primero
      try {
        final response = await _dioClient.dio.get(ApiConfig.funcionariosMiPerfil);
        return PerfilFuncionario.fromJson(response.data as Map<String, dynamic>);
      } on DioException catch (e) {
        // Si el endpoint específico no existe (404), obtener desde el endpoint general
        if (e.response?.statusCode == 404) {
          print('⚠️ Endpoint específico /api/funcionarios/mi-perfil no disponible (404), obteniendo desde endpoint general...');
          
          // Obtener el usuario actual desde storage
          try {
            final authRepo = AuthRepository(_dioClient);
            final usuario = await authRepo.getStoredUser();
            
            if (usuario != null) {
              print('🔍 Buscando perfil para usuario_id: ${usuario.idUsuario}');
              // Obtener el perfil por usuario_id usando el método del repositorio
              final perfil = await getPerfilFuncionarioByUsuario(usuario.idUsuario);
              if (perfil != null) {
                print('✅ Perfil encontrado: ID=${perfil.idPerfilFuncionario}');
                return perfil;
              }
            }
            
            // Si no encontramos por usuario_id, obtener todos y buscar
            print('⚠️ No se encontró perfil por usuario_id, buscando en todos los perfiles...');
            final response = await _dioClient.dio.get(ApiConfig.perfilesFuncionarios);
            final List<dynamic> data = response.data is List 
                ? response.data 
                : [];
            
            // Buscar el perfil del usuario actual
            if (usuario != null) {
              for (var item in data) {
                final perfil = PerfilFuncionario.fromJson(item as Map<String, dynamic>);
                if (perfil.idUsuario == usuario.idUsuario) {
                  print('✅ Perfil encontrado en lista: ID=${perfil.idPerfilFuncionario}');
                  return perfil;
                }
              }
            }
            
            // Si no encontramos, retornar el primero como fallback (temporal)
            if (data.isNotEmpty) {
              print('⚠️ Retornando primer perfil como fallback');
              return PerfilFuncionario.fromJson(data.first as Map<String, dynamic>);
            }
            
            throw Exception('No se encontró perfil de funcionario');
          } catch (e2) {
            print('❌ Error obteniendo perfil desde endpoint general: $e2');
            throw Exception('No se pudo obtener el perfil de funcionario: $e2');
          }
        }
        // Si es otro error, re-lanzarlo
        throw _handleError(e);
      }
    } catch (e) {
      print('❌ Error en getMiPerfil: $e');
      rethrow;
    }
  }

  // ==================== PROYECTOS ====================

  /// Obtener todos los proyectos de mi organización
  /// Usa el endpoint general de proyectos y filtra por organización del funcionario
  Future<List<Proyecto>> getProyectos() async {
    try {
      // Intentar usar el endpoint específico de funcionarios primero
      try {
        final response = await _dioClient.dio.get(ApiConfig.funcionariosProyectos);
        final List<dynamic> data = response.data is List 
            ? response.data 
            : (response.data['proyectos'] ?? []);
        return data.map((json) => Proyecto.fromJson(json as Map<String, dynamic>)).toList();
      } on DioException catch (e) {
        // Si el endpoint específico no existe (404), usar el endpoint general
        if (e.response?.statusCode == 404) {
          print('⚠️ Endpoint específico /api/funcionarios/proyectos no disponible (404), usando endpoint general /informacion/proyectos');
          
          // Obtener el organizacion_id del perfil del funcionario
          int? organizacionId;
          
          try {
            // Intentar obtener desde el perfil
            final perfil = await getMiPerfil();
            organizacionId = perfil.idOrganizacion;
            print('✅ Organización ID obtenida desde perfil: $organizacionId');
          } catch (e2) {
            print('⚠️ No se pudo obtener perfil: $e2, intentando obtener organización directamente...');
            try {
              // Si no podemos obtener el perfil, intentar obtener la organización directamente
              final org = await getMiOrganizacion();
              organizacionId = org.idOrganizacion;
              print('✅ Organización ID obtenida directamente: $organizacionId');
            } catch (e3) {
              print('❌ Error obteniendo organización: $e3');
              // Si todo falla, retornar lista vacía
              return [];
            }
          }
          
          // Si tenemos el organizacion_id, obtener todos los proyectos y filtrar
          if (organizacionId != null) {
            try {
              final response = await _dioClient.dio.get(ApiConfig.proyectos);
              final List<dynamic> data = response.data is List 
                  ? response.data 
                  : [];
              
              final proyectos = data
                  .map((json) => Proyecto.fromJson(json as Map<String, dynamic>))
                  .where((proyecto) => proyecto.organizacionId == organizacionId)
                  .toList();
              
              print('✅ Proyectos encontrados para organización $organizacionId: ${proyectos.length}');
              return proyectos;
            } catch (e4) {
              print('❌ Error obteniendo proyectos: $e4');
              return [];
            }
          }
          
          return [];
        }
        // Si es otro error, re-lanzarlo
        throw _handleError(e);
      }
    } catch (e) {
      print('❌ Error en getProyectos: $e');
      // Retornar lista vacía en caso de error para no romper la UI
      return [];
    }
  }

  /// Obtener proyecto por ID
  Future<Proyecto> getProyectoById(int id) async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.funcionariosProyecto(id));
      return Proyecto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear proyecto para la organización del funcionario
  /// 
  /// Relación 1:N: Una organización puede tener muchos proyectos.
  /// El `organizacion_id` se asigna automáticamente desde el perfil del funcionario.
  /// 
  /// Cuando se crea un proyecto, se establece la relación con la organización
  /// mediante el campo `organizacion_id` en la tabla `proyectos`.
  Future<Proyecto> createProyecto(Map<String, dynamic> data) async {
    try {
      // Remover organizacion_id si existe, ya que se asigna automáticamente
      // desde el perfil del funcionario (la organización del funcionario)
      final cleanData = Map<String, dynamic>.from(data);
      cleanData.remove('organizacion_id');
      
      final response = await _dioClient.dio.post(
        ApiConfig.funcionariosProyectos,
        data: cleanData,
      );
      return Proyecto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar proyecto
  Future<Proyecto> updateProyecto(int id, Map<String, dynamic> data) async {
    try {
      // Remover organizacion_id si existe, no se puede cambiar
      final cleanData = Map<String, dynamic>.from(data);
      cleanData.remove('organizacion_id');
      
      final response = await _dioClient.dio.patch(
        ApiConfig.funcionariosProyecto(id),
        data: cleanData,
      );
      return Proyecto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar proyecto
  Future<void> deleteProyecto(int id) async {
    try {
      await _dioClient.dio.delete(ApiConfig.funcionariosProyecto(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== TAREAS ====================

  /// Obtener todas las tareas de un proyecto
  Future<List<Tarea>> getTareasByProyecto(int proyectoId) async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.funcionariosTareasProyecto(proyectoId));
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
      final response = await _dioClient.dio.get(ApiConfig.funcionariosTarea(id));
      return Tarea.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear tarea en un proyecto (proyecto_id se toma de la URL)
  Future<Tarea> createTarea(int proyectoId, Map<String, dynamic> data) async {
    try {
      // Remover proyecto_id si existe, ya que se toma de la URL
      final cleanData = Map<String, dynamic>.from(data);
      cleanData.remove('proyecto_id');
      
      final response = await _dioClient.dio.post(
        ApiConfig.funcionariosTareasProyecto(proyectoId),
        data: cleanData,
      );
      return Tarea.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar tarea
  Future<Tarea> updateTarea(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiConfig.funcionariosTarea(id),
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
      await _dioClient.dio.delete(ApiConfig.funcionariosTarea(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== INSCRIPCIONES ====================

  /// Obtener todas las inscripciones de mi organización
  Future<List<Inscripcion>> getInscripciones() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.funcionariosInscripciones);
      final List<dynamic> data = response.data is List 
          ? response.data 
          : (response.data['inscripciones'] ?? []);
      return data.map((json) => Inscripcion.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener inscripciones pendientes
  Future<List<Inscripcion>> getInscripcionesPendientes() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.funcionariosInscripcionesPendientes);
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
      final response = await _dioClient.dio.get(ApiConfig.funcionariosInscripcion(id));
      return Inscripcion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Aprobar inscripción
  Future<Inscripcion> aprobarInscripcion(int id) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiConfig.funcionariosAprobarInscripcion(id),
      );
      return Inscripcion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Rechazar inscripción
  Future<Inscripcion> rechazarInscripcion(int id, String motivoRechazo) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiConfig.funcionariosRechazarInscripcion(id),
        data: {'motivo_rechazo': motivoRechazo},
      );
      return Inscripcion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== PARTICIPACIONES ====================

  /// Obtener todas las participaciones de proyectos de mi organización
  Future<List<Participacion>> getParticipaciones() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.funcionariosParticipaciones);
      final List<dynamic> data = response.data is List 
          ? response.data 
          : (response.data['participaciones'] ?? []);
      return data.map((json) => Participacion.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener participaciones de un proyecto específico
  Future<List<Participacion>> getParticipacionesByProyecto(int proyectoId) async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.funcionariosParticipacionesProyecto(proyectoId));
      final List<dynamic> data = response.data is List 
          ? response.data 
          : (response.data['participaciones'] ?? []);
      return data.map((json) => Participacion.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener participación por ID
  Future<Participacion> getParticipacionById(int id) async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.funcionariosParticipacion(id));
      return Participacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear participación (asignar voluntario a proyecto)
  Future<Participacion> createParticipacion(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.funcionariosParticipaciones,
        data: data,
      );
      return Participacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar participación (cambiar estado, rol, horas, etc.)
  Future<Participacion> updateParticipacion(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiConfig.funcionariosParticipacion(id),
        data: data,
      );
      return Participacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar participación (quitar voluntario de proyecto)
  Future<void> deleteParticipacion(int id) async {
    try {
      await _dioClient.dio.delete(ApiConfig.funcionariosParticipacion(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== ASIGNACIONES DE TAREAS ====================

  /// Obtener todas las asignaciones de tareas de proyectos de mi organización
  Future<List<AsignacionTarea>> getAsignacionesTareas() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.funcionariosAsignacionesTareas);
      final List<dynamic> data = response.data is List 
          ? response.data 
          : (response.data['asignaciones'] ?? []);
      return data.map((json) => AsignacionTarea.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener asignaciones de una tarea específica
  Future<List<AsignacionTarea>> getAsignacionesByTarea(int tareaId) async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.funcionariosAsignacionesTarea(tareaId));
      final List<dynamic> data = response.data is List 
          ? response.data 
          : (response.data['asignaciones'] ?? []);
      return data.map((json) => AsignacionTarea.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Asignar tarea a voluntario aprobado
  Future<AsignacionTarea> asignarTareaVoluntario(int tareaId, Map<String, dynamic> data) async {
    try {
      // Remover tarea_id si existe, ya que se toma de la URL
      final cleanData = Map<String, dynamic>.from(data);
      cleanData.remove('tarea_id');
      
      final response = await _dioClient.dio.post(
        ApiConfig.funcionariosAsignarVoluntarioTarea(tareaId),
        data: cleanData,
      );
      return AsignacionTarea.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== PERFILES DE VOLUNTARIOS ====================

  /// Obtener todos los perfiles de voluntarios (con organización si están aprobados)
  Future<List<PerfilVoluntario>> getPerfilesVoluntarios() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.perfilesVoluntarios);
      final List<dynamic> data = response.data is List 
          ? response.data 
          : (response.data['perfiles'] ?? []);
      return data.map((json) => PerfilVoluntario.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener perfil de voluntario por ID
  Future<PerfilVoluntario> getPerfilVoluntarioById(int id) async {
    try {
      final response = await _dioClient.dio.get('${ApiConfig.perfilesVoluntarios}/$id');
      return PerfilVoluntario.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener voluntarios de mi organización (filtrados)
  Future<List<PerfilVoluntario>> getVoluntariosDeMiOrganizacion() async {
    try {
      final perfiles = await getPerfilesVoluntarios();
      final miOrganizacion = await getMiOrganizacion();
      
      return perfiles.where((perfil) {
        // Verificar que tenga organización y que sea la mía
        if (perfil.organizacion == null) return false;
        final orgId = perfil.organizacion!['id_organizacion'];
        if (orgId != miOrganizacion.idOrganizacion) return false;
        
        // Verificar que tenga inscripción aprobada
        if (perfil.inscripcion == null) return false;
        final estado = perfil.inscripcion!['estado'];
        return estado == 'APROBADO';
      }).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== PERFILES DE FUNCIONARIOS ====================

  /// Obtener todos los perfiles de funcionarios (con organización)
  Future<List<PerfilFuncionario>> getPerfilesFuncionarios() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.perfilesFuncionarios);
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

  /// Obtener perfil de funcionario por usuario_id
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
      final response = await _dioClient.dio.post(
        ApiConfig.perfilesFuncionarios,
        data: data,
      );
      return PerfilFuncionario.fromJson(response.data as Map<String, dynamic>);
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

  /// Eliminar perfil de funcionario
  Future<void> deletePerfilFuncionario(int id) async {
    try {
      await _dioClient.dio.delete('${ApiConfig.perfilesFuncionarios}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== CATEGORÍAS DE PROYECTOS ====================

  /// Obtener categorías de proyectos
  Future<List<Map<String, dynamic>>> getCategoriasProyectos() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.categoriasProyectos);
      final List<dynamic> data = response.data is List 
          ? response.data 
          : (response.data['categorias'] ?? []);
      return data.map((item) => item as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw _handleError(e);
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
