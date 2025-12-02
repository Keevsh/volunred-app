import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/aptitud.dart';
import '../models/dto/request_models.dart';
import '../models/dto/voluntario_responses.dart';
import '../models/perfil_voluntario.dart';
import '../models/experiencia_voluntario.dart';
import '../models/inscripcion.dart';
import '../models/participacion.dart';
import '../models/opinion.dart';
import '../models/calificacion_proyecto.dart';
import '../models/proyecto.dart';
import '../models/organizacion.dart';
import '../models/tarea.dart';
import '../models/asignacion_tarea.dart';
import '../models/categoria.dart';
import '../services/dio_client.dart';
import '../services/storage_service.dart';

class VoluntarioRepository {
  final DioClient _dioClient;

  VoluntarioRepository(this._dioClient);

  /// Crear perfil de voluntario
  ///
  /// Verifica si el usuario ya tiene un perfil antes de intentar crear uno nuevo.
  /// Si ya existe, lo retorna. Si no existe, crea uno nuevo.
  Future<PerfilVoluntario> createPerfil(
    CreatePerfilVoluntarioRequest request,
  ) async {
    try {
      // Primero verificar si el usuario ya tiene un perfil
      print(
        '🔍 Verificando si el usuario ${request.usuarioId} ya tiene un perfil...',
      );
      final perfilExistente = await getPerfilByUsuario(request.usuarioId);

      if (perfilExistente != null) {
        print(
          '✅ El usuario ya tiene un perfil de voluntario. Retornando perfil existente.',
        );
        // Actualizar el perfil existente con los nuevos datos si es necesario
        if (request.bio != null || request.disponibilidad != null) {
          final datosActualizacion = <String, dynamic>{};
          if (request.bio != null && request.bio!.isNotEmpty) {
            datosActualizacion['bio'] = request.bio;
          }
          if (request.disponibilidad != null &&
              request.disponibilidad!.isNotEmpty) {
            datosActualizacion['disponibilidad'] = request.disponibilidad;
          }
          if (datosActualizacion.isNotEmpty) {
            try {
              final perfilActualizado = await updatePerfil(
                perfilExistente.idPerfilVoluntario,
                datosActualizacion,
              );
              return perfilActualizado;
            } catch (e) {
              print(
                '⚠️ No se pudo actualizar el perfil, retornando perfil existente: $e',
              );
            }
          }
        }
        return perfilExistente;
      }

      print('📤 Creando nuevo perfil de voluntario...');
      print('📤 Request data: ${request.toJson()}');

      final response = await _dioClient.dio.post(
        ApiConfig.perfilesVoluntarios,
        data: request.toJson(),
      );

      print('📥 Respuesta del servidor: ${response.data}');
      print('📥 Status code: ${response.statusCode}');
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
        final responseData = response.data as Map<String, dynamic>;

        // La respuesta puede venir envuelta en una clave 'perfil' o directamente
        if (responseData.containsKey('perfil')) {
          perfil = PerfilVoluntario.fromJson(
            responseData['perfil'] as Map<String, dynamic>,
          );
        } else {
          perfil = PerfilVoluntario.fromJson(responseData);
        }
      } else {
        throw Exception(
          'Formato de respuesta no reconocido: ${response.data.runtimeType}',
        );
      }

      // Guardar perfil en storage
      await StorageService.saveString(
        ApiConfig.perfilVoluntarioKey,
        jsonEncode(perfil.toJson()),
      );

      print('✅ Perfil guardado en storage: ID=${perfil.idPerfilVoluntario}');
      return perfil;
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      print('❌ Status Code: ${e.response?.statusCode}');
      print('❌ Request data: ${request.toJson()}');

      // Si el error es 409 (Conflict), el usuario ya tiene un perfil
      if (e.response?.statusCode == 409) {
        print(
          '⚠️ El usuario ya tiene un perfil (409 Conflict). Obteniendo perfil existente...',
        );
        final perfilExistente = await getPerfilByUsuario(request.usuarioId);
        if (perfilExistente != null) {
          return perfilExistente;
        }
      }

      // Si el error es 500, puede ser que el usuario ya tenga un perfil
      if (e.response?.statusCode == 500) {
        print(
          '⚠️ Error 500 del servidor. Verificando si el usuario ya tiene un perfil...',
        );
        try {
          final perfilExistente = await getPerfilByUsuario(request.usuarioId);
          if (perfilExistente != null) {
            print(
              '✅ El usuario ya tiene un perfil. Retornando perfil existente.',
            );
            return perfilExistente;
          }
        } catch (e2) {
          print('⚠️ No se pudo verificar el perfil existente: $e2');
        }
      }

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
  ///
  /// Asigna las aptitudes especificadas al perfil de voluntario.
  /// Si alguna aptitud ya está asignada, el backend debería manejar el error 409 o similar.
  Future<void> asignarMultiplesAptitudes(
    int perfilVolId,
    List<int> aptitudesIds,
  ) async {
    print(
      '📤 Asignando ${aptitudesIds.length} aptitudes al perfil $perfilVolId',
    );

    // Primero, obtener las aptitudes ya asignadas para evitar duplicados
    List<int> aptitudesAsignadas = [];
    try {
      final aptitudes = await getAptitudesByVoluntario(perfilVolId);
      aptitudesAsignadas = aptitudes.map((a) => a.idAptitud).toList();
      print('📋 Aptitudes ya asignadas: $aptitudesAsignadas');
    } catch (e) {
      print('⚠️ No se pudieron obtener las aptitudes asignadas: $e');
      // Continuar con la asignación incluso si no se pudieron obtener las asignadas
    }

    // Filtrar solo las aptitudes que no están asignadas
    final aptitudesNuevas = aptitudesIds
        .where((id) => !aptitudesAsignadas.contains(id))
        .toList();
    print('📤 Aptitudes nuevas a asignar: $aptitudesNuevas');

    if (aptitudesNuevas.isEmpty) {
      print('ℹ️ Todas las aptitudes ya están asignadas');
      return;
    }

    // Asignar solo las nuevas aptitudes
    int asignadas = 0;
    int errores = 0;
    for (final aptitudId in aptitudesNuevas) {
      try {
        await asignarAptitud(
          AsignarAptitudRequest(perfilVolId: perfilVolId, aptitudId: aptitudId),
        );
        asignadas++;
      } on DioException catch (e) {
        // Si es 409 (Conflict), la aptitud ya está asignada (puede pasar en casos de concurrencia)
        if (e.response?.statusCode == 409) {
          print('ℹ️ La aptitud $aptitudId ya está asignada (409)');
        } else {
          print('❌ Error al asignar aptitud $aptitudId: ${e.message}');
          errores++;
        }
      } catch (e) {
        print('❌ Error inesperado al asignar aptitud $aptitudId: $e');
        errores++;
      }
    }

    print('✅ Aptitudes asignadas: $asignadas, Errores: $errores');

    if (errores > 0 && asignadas == 0) {
      throw Exception(
        'No se pudieron asignar las aptitudes. Verifica tu conexión e intenta nuevamente.',
      );
    }
  }

  /// Obtener perfil de voluntario por usuario
  /// Retorna null si no existe el perfil
  Future<PerfilVoluntario?> getPerfilByUsuario(int usuarioId) async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiConfig.perfilesVoluntarios}/$usuarioId',
      );
      return PerfilVoluntario.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // Si el endpoint no existe o retorna 404, intentar obtener todos y filtrar
      if (e.response?.statusCode == 404) {
        try {
          final response = await _dioClient.dio.get(
            ApiConfig.perfilesVoluntarios,
          );
          final List<dynamic> data = response.data is List
              ? response.data
              : (response.data['perfiles'] ?? []);

          for (var json in data) {
            final perfil = PerfilVoluntario.fromJson(
              json as Map<String, dynamic>,
            );
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
      print(
        '⚠️ Error obteniendo perfil de voluntario: ${e.response?.statusCode}',
      );
      return null;
    }
  }

  /// Obtener perfil desde storage
  Future<PerfilVoluntario?> getStoredPerfil() async {
    final perfilJson = await StorageService.getString(
      ApiConfig.perfilVoluntarioKey,
    );
    if (perfilJson != null) {
      return PerfilVoluntario.fromJson(jsonDecode(perfilJson));
    }
    return null;
  }

  /// Obtener perfil de voluntario por ID
  Future<PerfilVoluntario> getPerfilById(int id) async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiConfig.perfilesVoluntarios}/$id',
      );
      return PerfilVoluntario.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar perfil de voluntario
  Future<PerfilVoluntario> updatePerfil(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConfig.perfilesVoluntarios}/$id',
        data: data,
      );
      final perfil = PerfilVoluntario.fromJson(
        response.data as Map<String, dynamic>,
      );

      // Actualizar en storage
      await StorageService.saveString(
        ApiConfig.perfilVoluntarioKey,
        jsonEncode(perfil.toJson()),
      );

      return perfil;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar perfil de voluntario
  Future<void> deletePerfil(int id) async {
    try {
      await _dioClient.dio.delete('${ApiConfig.perfilesVoluntarios}/$id');
      // Eliminar de storage
      await StorageService.remove(ApiConfig.perfilVoluntarioKey);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener aptitudes de un voluntario específico
  Future<List<Aptitud>> getAptitudesByVoluntario(int perfilVolId) async {
    try {
      print('🔍 Obteniendo aptitudes para perfil voluntario: $perfilVolId');
      final url = ApiConfig.aptitudesVoluntarioByVoluntario(perfilVolId);
      print('🔍 URL: $url');

      final response = await _dioClient.dio.get(url);

      print('📥 Respuesta obtenida: ${response.statusCode}');
      print('📥 Datos: ${response.data}');
      print('📥 Tipo de datos: ${response.data.runtimeType}');

      // El backend puede devolver un array directamente o envuelto en un objeto
      List<dynamic> data = [];

      if (response.data is List) {
        data = response.data as List<dynamic>;
      } else if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        // Puede venir en diferentes claves: 'aptitudes', 'data', 'result', etc.
        if (responseMap.containsKey('aptitudes')) {
          data = responseMap['aptitudes'] is List
              ? responseMap['aptitudes'] as List<dynamic>
              : [];
        } else if (responseMap.containsKey('data')) {
          data = responseMap['data'] is List
              ? responseMap['data'] as List<dynamic>
              : [];
        } else if (responseMap.containsKey('result')) {
          data = responseMap['result'] is List
              ? responseMap['result'] as List<dynamic>
              : [];
        }
      }

      print('📥 Datos procesados: ${data.length} aptitudes encontradas');

      // Extraer aptitudes de las asignaciones
      final aptitudes = <Aptitud>[];
      for (var item in data) {
        try {
          if (item is Map<String, dynamic>) {
            // Si el item tiene una clave 'aptitud', usar esa
            if (item.containsKey('aptitud') &&
                item['aptitud'] is Map<String, dynamic>) {
              aptitudes.add(
                Aptitud.fromJson(item['aptitud'] as Map<String, dynamic>),
              );
            }
            // Si el item tiene 'id_aptitud' o 'aptitud_id', es una aptitud directamente
            else if (item.containsKey('id_aptitud') ||
                item.containsKey('aptitud_id') ||
                item.containsKey('nombre')) {
              aptitudes.add(Aptitud.fromJson(item));
            }
          }
        } catch (e) {
          print('⚠️ Error parseando aptitud: $e');
          print('⚠️ Item que causó el error: $item');
        }
      }

      print('✅ Aptitudes parseadas: ${aptitudes.length}');
      return aptitudes;
    } on DioException catch (e) {
      print('❌ Error al obtener aptitudes del voluntario: ${e.message}');
      print('❌ Status code: ${e.response?.statusCode}');
      print('❌ Response data: ${e.response?.data}');

      // Si es 404, el voluntario no tiene aptitudes asignadas (no es un error crítico)
      if (e.response?.statusCode == 404) {
        print('ℹ️ El voluntario no tiene aptitudes asignadas (404)');
        return [];
      }

      // Para otros errores, lanzar excepción pero con más información
      throw _handleError(e);
    } catch (e, stackTrace) {
      print('❌ Error general al obtener aptitudes: $e');
      print('❌ StackTrace: $stackTrace');
      // En caso de error, retornar lista vacía para no bloquear la UI
      return [];
    }
  }

  /// Eliminar aptitud de voluntario
  Future<void> eliminarAptitud(int idAptitudVol) async {
    try {
      await _dioClient.dio.delete(
        '${ApiConfig.aptitudesVoluntario}/$idAptitudVol',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== EXPERIENCIAS DE VOLUNTARIADO ====================

  /// Crear experiencia de voluntariado
  Future<ExperienciaVoluntario> createExperiencia(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.experienciasVoluntario,
        data: data,
      );
      return ExperienciaVoluntario.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener todas las experiencias
  Future<List<ExperienciaVoluntario>> getExperiencias() async {
    try {
      final response = await _dioClient.dio.get(
        ApiConfig.experienciasVoluntario,
      );
      final List<dynamic> data = response.data is List ? response.data : [];
      return data
          .map(
            (json) =>
                ExperienciaVoluntario.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener experiencia por ID
  Future<ExperienciaVoluntario> getExperienciaById(int id) async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiConfig.experienciasVoluntario}/$id',
      );
      return ExperienciaVoluntario.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar experiencia
  Future<ExperienciaVoluntario> updateExperiencia(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.dio.patch(
        '${ApiConfig.experienciasVoluntario}/$id',
        data: data,
      );
      return ExperienciaVoluntario.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar experiencia
  Future<void> deleteExperiencia(int id) async {
    try {
      await _dioClient.dio.delete('${ApiConfig.experienciasVoluntario}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== ORGANIZACIONES ====================

  /// Obtener todas las organizaciones
  Future<List<Organizacion>> getOrganizaciones() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.organizaciones);
      final List<dynamic> data = response.data is List ? response.data : [];
      return data
          .map((json) => Organizacion.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener organización por ID
  Future<Organizacion> getOrganizacionById(int id) async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiConfig.organizaciones}/$id',
      );
      return Organizacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== PROYECTOS ====================

  /// Obtener todos los proyectos
  Future<List<Proyecto>> getProyectos() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.proyectos);
      final List<dynamic> data = response.data is List ? response.data : [];
      return data
          .map((json) => Proyecto.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener proyecto por ID
  Future<Proyecto> getProyectoById(int id) async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.proyecto(id));
      return Proyecto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener todas las categorías
  Future<List<Categoria>> getCategorias() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.categorias);
      final List<dynamic> data = response.data is List ? response.data : [];
      return data
          .map((json) => Categoria.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener categoría por ID
  Future<Categoria> getCategoriaById(int id) async {
    try {
      final response = await _dioClient.dio.get('${ApiConfig.categorias}/$id');
      return Categoria.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== INSCRIPCIONES ====================

  /// Crear inscripción a una organización
  Future<Inscripcion> createInscripcion(Map<String, dynamic> data) async {
    try {
      // Normalizar el estado a minúsculas si está presente (el backend espera: pendiente, aprobado, rechazado)
      final normalizedData = Map<String, dynamic>.from(data);
      if (normalizedData.containsKey('estado') &&
          normalizedData['estado'] is String) {
        normalizedData['estado'] = (normalizedData['estado'] as String)
            .toLowerCase();
      } else if (!normalizedData.containsKey('estado')) {
        normalizedData['estado'] = 'pendiente';
      }

      print('📤 Creando inscripción: $normalizedData');

      final response = await _dioClient.dio.post(
        ApiConfig.inscripciones,
        data: normalizedData,
      );

      print('📥 Respuesta del servidor: ${response.data}');
      print('📥 Status code: ${response.statusCode}');
      print('📥 Tipo de respuesta: ${response.data.runtimeType}');
      print('📥 Content-Type: ${response.headers.value('content-type')}');

      Inscripcion inscripcion;

      // El backend puede devolver un string (mensaje HTML/texto) o un JSON (inscripción)
      // Si el content-type es text/html o text/plain, tratar como string
      final contentType = response.headers.value('content-type') ?? '';
      final isTextResponse =
          contentType.contains('text/html') ||
          contentType.contains('text/plain') ||
          response.data is String;

      if (isTextResponse || response.data is String) {
        // Si la respuesta es un string, la inscripción se creó exitosamente
        // Intentamos obtener la inscripción recién creada
        print('✅ Inscripción creada exitosamente. Obteniendo inscripción...');

        try {
          // Obtener todas las inscripciones del usuario y buscar la más reciente
          final inscripciones = await getInscripciones();
          final usuarioId = normalizedData['usuario_id'] as int?;
          final organizacionId = normalizedData['organizacion_id'] as int?;

          if (usuarioId == null || organizacionId == null) {
            throw Exception('usuario_id o organizacion_id no pueden ser null');
          }

          // Buscar la inscripción más reciente para este usuario y organización
          final inscripcionEncontrada =
              inscripciones
                  .where(
                    (ins) =>
                        ins.usuarioId == usuarioId &&
                        ins.organizacionId == organizacionId,
                  )
                  .toList()
                ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));

          if (inscripcionEncontrada.isNotEmpty) {
            inscripcion = inscripcionEncontrada.first;
            print('✅ Inscripción encontrada: ID=${inscripcion.idInscripcion}');
          } else {
            // Si no podemos obtenerla, crear una inscripción temporal con los datos del request
            print(
              '⚠️ No se pudo obtener la inscripción, creando inscripción temporal...',
            );
            inscripcion = Inscripcion(
              idInscripcion: 0, // Temporal, se actualizará después
              usuarioId: usuarioId,
              organizacionId: organizacionId,
              fechaRecepcion: normalizedData['fecha_recepcion'] != null
                  ? DateTime.parse(normalizedData['fecha_recepcion'] as String)
                  : DateTime.now(),
              estado:
                  (normalizedData['estado'] as String?)?.toUpperCase() ??
                  'PENDIENTE', // Normalizar a mayúsculas para el modelo
              creadoEn: DateTime.now(),
            );
          }
        } catch (e) {
          print('⚠️ No se pudo obtener la inscripción: $e');
          // Crear una inscripción temporal con los datos del request
          final usuarioId = normalizedData['usuario_id'] as int?;
          final organizacionId = normalizedData['organizacion_id'] as int?;

          if (usuarioId == null || organizacionId == null) {
            throw Exception('usuario_id o organizacion_id no pueden ser null');
          }

          inscripcion = Inscripcion(
            idInscripcion: 0, // Temporal, se actualizará después
            usuarioId: usuarioId,
            organizacionId: organizacionId,
            fechaRecepcion: normalizedData['fecha_recepcion'] != null
                ? DateTime.parse(normalizedData['fecha_recepcion'] as String)
                : DateTime.now(),
            estado:
                (normalizedData['estado'] as String?)?.toUpperCase() ??
                'PENDIENTE',
            creadoEn: DateTime.now(),
          );
        }
      } else if (response.data is Map<String, dynamic>) {
        // Si la respuesta es un JSON, parseamos normalmente
        final responseData = response.data as Map<String, dynamic>;

        // La respuesta puede venir envuelta en una clave 'inscripcion' o directamente
        if (responseData.containsKey('inscripcion')) {
          inscripcion = Inscripcion.fromJson(
            responseData['inscripcion'] as Map<String, dynamic>,
          );
        } else {
          inscripcion = Inscripcion.fromJson(responseData);
        }
      } else {
        throw Exception(
          'Formato de respuesta no reconocido: ${response.data.runtimeType}',
        );
      }

      print('✅ Inscripción procesada: ID=${inscripcion.idInscripcion}');
      return inscripcion;
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      print('❌ Status Code: ${e.response?.statusCode}');

      // Proporcionar mensajes de error más descriptivos
      if (e.response?.statusCode == 500) {
        final errorData = e.response?.data;
        String errorMessage =
            'Error del servidor al crear la inscripción. Por favor, intenta nuevamente más tarde.';

        if (errorData is Map<String, dynamic>) {
          // Intentar extraer un mensaje más específico
          if (errorData.containsKey('message')) {
            final message = errorData['message'];
            if (message is String) {
              errorMessage = message;
            } else if (message is List && message.isNotEmpty) {
              errorMessage = message.first.toString();
            }
          } else if (errorData.containsKey('error')) {
            errorMessage = errorData['error'] as String;
          }

          // Log detallado para debugging
          print('🔍 Error detallado del servidor: $errorData');
        }

        // Verificar si podría ser un error de duplicado
        final errorMessageLower = errorMessage.toLowerCase();
        if (errorMessageLower.contains('duplicate') ||
            errorMessageLower.contains('ya existe') ||
            errorMessageLower.contains('already exists') ||
            errorMessageLower.contains('unique constraint')) {
          throw Exception('Ya tienes una inscripción para esta organización');
        }

        // Verificar si podría ser un error de foreign key
        if (errorMessageLower.contains('foreign key') ||
            errorMessageLower.contains('constraint') ||
            errorMessageLower.contains('reference')) {
          throw Exception(
            'Error: La organización o el usuario no existe. Por favor, verifica los datos.',
          );
        }

        // Verificar si es un error de truncamiento de datos (columna demasiado pequeña)
        if (errorMessageLower.contains('data truncated') ||
            errorMessageLower.contains('truncated for column')) {
          throw Exception(
            'Error de configuración del servidor: La base de datos no puede almacenar el estado. Por favor, contacta al administrador.',
          );
        }

        throw Exception(errorMessage);
      }

      // Manejar errores 400 (Bad Request) con mensajes más claros
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        String errorMessage = 'Error en los datos enviados';

        if (errorData is Map<String, dynamic>) {
          if (errorData.containsKey('message')) {
            final message = errorData['message'];
            if (message is String) {
              errorMessage = message;
            } else if (message is List && message.isNotEmpty) {
              errorMessage = message.join(', ');
            }
          } else if (errorData.containsKey('error')) {
            errorMessage = errorData['error'] as String;
          }
        }

        throw Exception(errorMessage);
      }

      // Manejar errores 409 (Conflict) - inscripción duplicada
      if (e.response?.statusCode == 409) {
        final errorData = e.response?.data;
        print('🔍 Error Response Data: $errorData');
        print('🔍 Error Response Type: ${errorData.runtimeType}');

        String errorMessage =
            'Ya tienes una solicitud pendiente para esta organización';

        if (errorData is Map<String, dynamic>) {
          if (errorData.containsKey('message')) {
            final message = errorData['message'];
            if (message is String) {
              errorMessage = message;
            }
          }
        }

        throw Exception(errorMessage);
      }

      throw _handleError(e);
    } catch (e, stackTrace) {
      print('❌ Error general: $e');
      print('❌ StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Obtener todas las inscripciones
  Future<List<Inscripcion>> getInscripciones() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.inscripciones);
      final List<dynamic> data = response.data is List ? response.data : [];
      return data
          .map((json) => Inscripcion.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener inscripción por ID
  Future<Inscripcion> getInscripcionById(int id) async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.inscripcion(id));
      return Inscripcion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar inscripción
  Future<void> deleteInscripcion(int id) async {
    try {
      await _dioClient.dio.delete(ApiConfig.inscripcion(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== PARTICIPACIONES ====================

  /// Crear participación en un proyecto
  Future<Participacion> createParticipacion(Map<String, dynamic> data) async {
    try {
      // Normalizar el estado a mayúsculas si está presente (el backend espera: PROGRAMADA, EN_PROGRESO, COMPLETADO, AUSENTE)
      final normalizedData = Map<String, dynamic>.from(data);
      if (normalizedData.containsKey('estado') &&
          normalizedData['estado'] is String) {
        normalizedData['estado'] = (normalizedData['estado'] as String)
            .toUpperCase();
      } else if (!normalizedData.containsKey('estado')) {
        normalizedData['estado'] = 'PROGRAMADA';
      }

      print('📤 Creando participación: $normalizedData');

      final response = await _dioClient.dio.post(
        ApiConfig.participaciones,
        data: normalizedData,
      );
      return Participacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener todas las participaciones
  Future<List<Participacion>> getParticipaciones() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.participaciones);
      final List<dynamic> data = response.data is List ? response.data : [];
      return data
          .map((json) => Participacion.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener participación por ID
  Future<Participacion> getParticipacionById(int id) async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.participacion(id));
      return Participacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar participación
  Future<Participacion> updateParticipacion(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiConfig.participacion(id),
        data: data,
      );
      return Participacion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar participación
  Future<void> deleteParticipacion(int id) async {
    try {
      await _dioClient.dio.delete(ApiConfig.participacion(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== TAREAS ====================

  /// Obtener todas las tareas
  Future<List<Tarea>> getTareas() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.tareas);
      final List<dynamic> data = response.data is List ? response.data : [];
      return data
          .map((json) => Tarea.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener tarea por ID
  Future<Tarea> getTareaById(int id) async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.tarea(id));
      return Tarea.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear tarea
  Future<Tarea> createTarea(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.post(ApiConfig.tareas, data: data);
      return Tarea.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar tarea
  Future<Tarea> updateTarea(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiConfig.tarea(id),
        data: data,
      );
      return Tarea.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar (cancelar) tarea
  Future<Map<String, dynamic>> deleteTarea(int id) async {
    try {
      final response = await _dioClient.dio.delete(ApiConfig.tarea(id));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== MIS TAREAS (VOLUNTARIO AUTENTICADO) ====================

  /// Obtener las tareas asignadas al voluntario autenticado
  /// Usa el endpoint GET /voluntarios/my/tasks con filtros opcionales
  Future<List<Map<String, dynamic>>> getMyTasks({
    String? estado,
    int? proyectoId,
  }) async {
    try {
      // Primero verificar si el voluntario participa en algún proyecto
      // Si no tiene proyectos, no tiene sentido pedir sus tareas
      final misProyectos = await getMyProyectos();
      if (misProyectos.isEmpty) {
        print(
          'ℹ️ getMyTasks: voluntario sin proyectos activos, retornando lista vacía',
        );
        return [];
      }

      final queryParameters = <String, dynamic>{};
      if (estado != null && estado.isNotEmpty) {
        queryParameters['estado'] = estado;
      }
      if (proyectoId != null) {
        queryParameters['proyectoId'] = proyectoId;
      }

      final response = await _dioClient.dio.get(
        ApiConfig.voluntariosMyTasks,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      final List<dynamic> data = response.data is List ? response.data : [];
      return data
          .whereType<Map>()
          .map((json) => Map<String, dynamic>.from(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener el detalle de una tarea asignada al voluntario autenticado
  /// Incluye información de la asignación, la tarea y las evidencias
  Future<Map<String, dynamic>> getMyTaskDetail(int tareaId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConfig.voluntariosMyTask(tareaId),
      );
      return response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar el estado de una tarea asignada al voluntario autenticado
  /// Usa PATCH /voluntarios/my/tasks/:tareaId/status
  Future<void> updateMyTaskStatus(
    int tareaId,
    String estado, {
    String? comentario,
  }) async {
    try {
      final body = <String, dynamic>{'estado': estado};
      if (comentario != null && comentario.isNotEmpty) {
        body['comentario'] = comentario;
      }

      await _dioClient.dio.patch(
        ApiConfig.voluntariosMyTaskStatus(tareaId),
        data: body,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== ASIGNACIONES DE TAREAS ====================

  /// Obtener todas las asignaciones de tareas
  Future<List<AsignacionTarea>> getAsignacionesTareas() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.asignacionesTareas);
      final List<dynamic> data = response.data is List ? response.data : [];
      return data
          .map((json) => AsignacionTarea.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener asignación de tarea por ID
  Future<AsignacionTarea> getAsignacionTareaById(int id) async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.asignacionTarea(id));
      return AsignacionTarea.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear asignación de tarea
  Future<AsignacionTarea> createAsignacionTarea(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.asignacionesTareas,
        data: data,
      );
      return AsignacionTarea.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar asignación de tarea
  Future<AsignacionTarea> updateAsignacionTarea(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiConfig.asignacionTarea(id),
        data: data,
      );
      return AsignacionTarea.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Cancelar asignación de tarea
  Future<Map<String, dynamic>> deleteAsignacionTarea(int id) async {
    try {
      final response = await _dioClient.dio.delete(
        ApiConfig.asignacionTarea(id),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== EVIDENCIAS DE TAREAS ====================

  /// Obtener evidencias de una tarea del voluntario autenticado
  Future<List<Map<String, dynamic>>> getMyTaskEvidences(int tareaId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConfig.voluntariosMyTaskEvidences(tareaId),
      );
      final List<dynamic> data = response.data is List ? response.data : [];
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crear evidencia para una tarea del voluntario autenticado
  Future<Map<String, dynamic>> createMyTaskEvidence(
    int tareaId, {
    required String comentario,
    String? fotoBase64,
  }) async {
    try {
      final body = <String, dynamic>{
        // El backend espera 'comentario' (no 'descripcion')
        'comentario': comentario,
        // Enviar siempre un tipo válido y corto
        'tipo': (fotoBase64 != null && fotoBase64.isNotEmpty)
            ? 'FOTO'
            : 'TEXTO',
      };

      if (fotoBase64 != null && fotoBase64.isNotEmpty) {
        body['foto'] = fotoBase64;
      }

      final response = await _dioClient.dio.post(
        ApiConfig.voluntariosMyTaskEvidences(tareaId),
        data: body,
      );
      return response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== OPINIONES ====================

  /// Crear opinión sobre un proyecto
  Future<Opinion> createOpinion(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.opiniones,
        data: data,
      );
      return Opinion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener todas las opiniones
  Future<List<Opinion>> getOpiniones() async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.opiniones);
      final List<dynamic> data = response.data is List ? response.data : [];
      return data
          .map((json) => Opinion.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener opiniones por proyecto
  Future<List<Opinion>> getOpinionesByProyecto(
    int proyectoId, {
    bool visibleOnly = false,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConfig.opinionesByProyecto(proyectoId),
        queryParameters: visibleOnly ? {'visibleOnly': 'true'} : null,
      );
      final List<dynamic> data = response.data is List ? response.data : [];
      return data
          .map((json) => Opinion.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener opiniones por voluntario
  Future<List<Opinion>> getOpinionesByVoluntario(int perfilVolId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConfig.opinionesByVoluntario(perfilVolId),
      );
      final List<dynamic> data = response.data is List ? response.data : [];
      return data
          .map((json) => Opinion.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener opinión por ID
  Future<Opinion> getOpinionById(int id) async {
    try {
      final response = await _dioClient.dio.get(ApiConfig.opinion(id));
      return Opinion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar opinión
  Future<Opinion> updateOpinion(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiConfig.opinion(id),
        data: data,
      );
      return Opinion.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar opinión
  Future<void> deleteOpinion(int id) async {
    try {
      await _dioClient.dio.delete(ApiConfig.opinion(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== CALIFICACIONES ====================

  /// Crear calificación de un proyecto
  Future<CalificacionProyecto> createCalificacion(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConfig.calificacionesProyectos,
        data: data,
      );
      return CalificacionProyecto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener todas las calificaciones
  Future<List<CalificacionProyecto>> getCalificaciones() async {
    try {
      final response = await _dioClient.dio.get(
        ApiConfig.calificacionesProyectos,
      );
      final List<dynamic> data = response.data is List ? response.data : [];
      return data
          .map(
            (json) =>
                CalificacionProyecto.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener calificación por ID
  Future<CalificacionProyecto> getCalificacionById(int id) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConfig.calificacionProyecto(id),
      );
      return CalificacionProyecto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar calificación
  Future<CalificacionProyecto> updateCalificacion(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiConfig.calificacionProyecto(id),
        data: data,
      );
      return CalificacionProyecto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Eliminar calificación
  Future<void> deleteCalificacion(int id) async {
    try {
      await _dioClient.dio.delete(ApiConfig.calificacionProyecto(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== ENDPOINTS VOLUNTARIO AUTENTICADO ====================
  // Estos endpoints usan el JWT del voluntario para filtrar automáticamente

  /// 1. Dashboard del voluntario
  /// GET /voluntarios/dashboard
  /// Devuelve un resumen general del voluntario y sus últimas tareas.
  Future<VoluntarioDashboardResponse> getDashboard() async {
    try {
      print('📊 Obteniendo dashboard del voluntario...');
      final response = await _dioClient.dio.get(ApiConfig.voluntariosDashboard);

      print('📥 Dashboard response: ${response.statusCode}');

      if (response.data is Map<String, dynamic>) {
        return VoluntarioDashboardResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      // Si la respuesta no es el formato esperado, retornar un dashboard vacío
      return const VoluntarioDashboardResponse(
        resumen: ResumenVoluntario(
          organizacionesInscritas: 0,
          proyectosParticipando: 0,
          participacionesPendientes: 0,
          tareas: ResumenTareas(
            asignadas: 0,
            enProgreso: 0,
            completadas: 0,
            total: 0,
          ),
        ),
        ultimasTareas: [],
      );
    } on DioException catch (e) {
      print('❌ Error obteniendo dashboard: ${e.message}');
      throw _handleError(e);
    }
  }

  /// 2. Proyectos en los que participa el voluntario
  /// GET /voluntarios/my/proyectos
  /// Lista de proyectos donde el voluntario tiene una participación activa.
  Future<List<ProyectoVoluntario>> getMyProyectos() async {
    try {
      print('📋 Obteniendo proyectos del voluntario...');
      final response = await _dioClient.dio.get(
        ApiConfig.voluntariosMyProyectos,
      );

      print('📥 Proyectos response: ${response.statusCode}');

      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((json) => ProyectoVoluntario.fromJson(json))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      print('❌ Error obteniendo proyectos: ${e.message}');
      throw _handleError(e);
    }
  }

  /// 3. Detalle de un proyecto donde participa
  /// GET /voluntarios/my/proyectos/:proyectoId
  /// Devuelve la información del proyecto + las tareas activas.
  Future<ProyectoDetalleVoluntario> getMyProyectoDetalle(int proyectoId) async {
    try {
      print('📋 Obteniendo detalle del proyecto $proyectoId...');
      final response = await _dioClient.dio.get(
        ApiConfig.voluntariosMyProyecto(proyectoId),
      );

      print('📥 Proyecto detalle response: ${response.statusCode}');

      if (response.data is Map<String, dynamic>) {
        return ProyectoDetalleVoluntario.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw Exception('Formato de respuesta no válido');
    } on DioException catch (e) {
      print('❌ Error obteniendo detalle del proyecto: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception(
          'No participas en este proyecto o tu participación no está activa.',
        );
      }
      throw _handleError(e);
    }
  }

  /// 4. Tareas activas de un proyecto
  /// GET /voluntarios/my/proyectos/:proyectoId/tareas
  /// Devuelve solo las tareas activas de un proyecto donde el voluntario participa.
  Future<List<TareaProyecto>> getMyProyectoTareas(int proyectoId) async {
    try {
      print('📋 Obteniendo tareas del proyecto $proyectoId...');
      final response = await _dioClient.dio.get(
        ApiConfig.voluntariosMyProyectoTareas(proyectoId),
      );

      print('📥 Tareas proyecto response: ${response.statusCode}');

      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((json) => TareaProyecto.fromJson(json))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      print('❌ Error obteniendo tareas del proyecto: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('No participas en este proyecto.');
      }
      throw _handleError(e);
    }
  }

  /// 5. Todas las tareas del voluntario (todos los proyectos)
  /// GET /voluntarios/my/tasks
  /// Devuelve todas las tareas asignadas al voluntario.
  Future<List<AsignacionTareaVoluntario>> getMyAllTasks({
    String? estado,
    int? proyectoId,
  }) async {
    try {
      print('📋 Obteniendo todas las tareas del voluntario...');

      final queryParameters = <String, dynamic>{};
      if (estado != null && estado.isNotEmpty) {
        queryParameters['estado'] = estado;
      }
      if (proyectoId != null) {
        queryParameters['proyectoId'] = proyectoId;
      }

      final response = await _dioClient.dio.get(
        ApiConfig.voluntariosMyTasks,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      print('📥 Todas las tareas response: ${response.statusCode}');

      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((json) => AsignacionTareaVoluntario.fromJson(json))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      print('❌ Error obteniendo todas las tareas: ${e.message}');
      // Si es error 500, retornar lista vacía en lugar de fallar
      // (el endpoint puede no estar implementado aún en el backend)
      if (e.response?.statusCode == 500) {
        print(
          '⚠️ El endpoint /voluntarios/my/tasks retornó 500 - retornando lista vacía',
        );
        return [];
      }
      throw _handleError(e);
    }
  }

  // ==================== PARTICIPACIONES DEL VOLUNTARIO ====================

  /// 6.1 Crear solicitud de participación
  /// POST /voluntarios/my/participaciones
  /// El voluntario solicita participar en un proyecto.
  Future<CrearParticipacionResponse> createMyParticipacion(
    CrearParticipacionRequest request,
  ) async {
    try {
      print('📤 Creando solicitud de participación...');
      print('📤 Proyecto ID: ${request.proyectoId}');

      // Construir body y asegurar que incluimos perfil_vol_id
      final body = Map<String, dynamic>.from(request.toJson());

      if (!body.containsKey('perfil_vol_id') || body['perfil_vol_id'] == null) {
        try {
          final perfilJson = await StorageService.getString(
            ApiConfig.perfilVoluntarioKey,
          );
          if (perfilJson != null) {
            final Map<String, dynamic> perfilMap =
                jsonDecode(perfilJson) as Map<String, dynamic>;
            final perfil = PerfilVoluntario.fromJson(perfilMap);
            body['perfil_vol_id'] = perfil.idPerfilVoluntario;
            print(
              '👤 perfil_vol_id detectado desde storage: ${perfil.idPerfilVoluntario}',
            );
          } else {
            print(
              '⚠️ No se encontró perfil_voluntario en storage, se enviará sin perfil_vol_id',
            );
          }
        } catch (e) {
          print('⚠️ Error obteniendo perfil_voluntario desde storage: $e');
        }
      }

      final response = await _dioClient.dio.post(
        ApiConfig.voluntariosMyParticipaciones,
        data: body,
      );

      print('📥 Crear participación response: ${response.statusCode}');

      if (response.data is Map<String, dynamic>) {
        return CrearParticipacionResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw Exception('Formato de respuesta no válido');
    } on DioException catch (e) {
      print('❌ Error creando participación: ${e.message}');
      print('❌ Response: ${e.response?.data}');

      // Manejar errores específicos
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          throw Exception(data['message'].toString());
        }
        throw Exception(
          'No tienes una inscripción aprobada en la organización de este proyecto.',
        );
      }
      if (e.response?.statusCode == 404) {
        throw Exception('El proyecto no existe.');
      }
      if (e.response?.statusCode == 409) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          throw Exception(data['message'].toString());
        }
        throw Exception(
          'Ya tienes una solicitud pendiente o ya participas en este proyecto.',
        );
      }

      throw _handleError(e);
    }
  }

  /// 6.2 Listar mis participaciones
  /// GET /voluntarios/my/participaciones
  /// Lista todas las participaciones del voluntario.
  Future<List<ParticipacionVoluntario>> getMyParticipaciones({
    String? estado,
  }) async {
    try {
      print('📋 Obteniendo participaciones del voluntario...');

      final queryParameters = <String, dynamic>{};
      if (estado != null && estado.isNotEmpty) {
        queryParameters['estado'] = estado;
      }

      final response = await _dioClient.dio.get(
        ApiConfig.voluntariosMyParticipaciones,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      print('📥 Participaciones response: ${response.statusCode}');

      if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((json) => ParticipacionVoluntario.fromJson(json))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      print('❌ Error obteniendo participaciones: ${e.message}');
      throw _handleError(e);
    }
  }

  /// 6.3 Cancelar solicitud de participación pendiente
  /// DELETE /voluntarios/my/participaciones/:id
  /// Cancela una solicitud de participación solo si está en estado pendiente.
  Future<void> cancelMyParticipacion(int participacionId) async {
    try {
      print('🗑️ Cancelando participación $participacionId...');

      final response = await _dioClient.dio.delete(
        ApiConfig.voluntariosMyParticipacion(participacionId),
      );

      print('📥 Cancelar participación response: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Error cancelando participación: ${e.message}');

      if (e.response?.statusCode == 400) {
        throw Exception(
          'Solo puedes cancelar solicitudes en estado pendiente.',
        );
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Participación no encontrada.');
      }

      throw _handleError(e);
    }
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
        case 500:
          // Error del servidor - puede ser que el usuario ya tenga un perfil
          if (data is Map && data['message'] != null) {
            final message = data['message'].toString().toLowerCase();
            if (message.contains('ya existe') ||
                message.contains('duplicate') ||
                message.contains('unique constraint')) {
              return 'Ya tienes un perfil de voluntario. Intenta actualizar tu perfil existente.';
            }
            return 'Error del servidor: ${data['message']}';
          }
          return 'Error del servidor. Si ya tienes un perfil, intenta actualizarlo en lugar de crear uno nuevo.';
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
