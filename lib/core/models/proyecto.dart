import 'package:equatable/equatable.dart';

/// Modelo de Proyecto
///
/// Representa un proyecto en el sistema.
///
/// Relaciones:
/// - **Organización (1:N)**: Un proyecto pertenece a una organización.
///   Una organización puede tener muchos proyectos.
///   La relación se establece mediante `organizacionId`.
/// - **Categoría (N:1)**: Un proyecto pertenece a una categoría.
/// - **Tareas (1:N)**: Un proyecto puede tener muchas tareas.
class Proyecto extends Equatable {
  /// ID único del proyecto
  final int idProyecto;

  /// ID de la categoría del proyecto (legacy, mantener para compatibilidad)
  ///
  /// NOTA: Los proyectos ahora pueden tener múltiples categorías.
  /// Usar `categoriasProyectos` para obtener todas las categorías.
  final int? categoriaProyectoId;

  /// ID de la organización a la que pertenece este proyecto
  ///
  /// Relación 1:N: Una organización puede tener muchos proyectos,
  /// pero un proyecto pertenece a una sola organización.
  final int organizacionId;

  /// Nombre del proyecto
  final String nombre;

  /// Objetivo del proyecto (opcional)
  final String? objetivo;

  /// Ubicación del proyecto (opcional)
  final String? ubicacion;

  /// Fecha de inicio del proyecto (opcional)
  final DateTime? fechaInicio;

  /// Fecha de finalización del proyecto (opcional)
  final DateTime? fechaFin;

  /// Estado del proyecto (activo/inactivo)
  final String estado;

  /// Indica si la participación en el proyecto es pública (no requiere inscripción aprobada)
  ///
  /// Cuando es `true`, cualquier voluntario puede solicitar participación sin
  /// estar inscrito en la organización. Cuando es `false`, se requiere una
  /// inscripción aprobada en la organización del proyecto.
  final bool participacionPublica;

  /// Imagen representativa del proyecto en formato base64 (opcional)
  final String? imagen;

  /// Fecha de creación del proyecto
  final DateTime creadoEn;

  /// Fecha de última actualización del proyecto (opcional)
  final DateTime? actualizadoEn;

  // Relaciones opcionales (se incluyen cuando se hace join en la consulta)

  /// Datos de la categoría del proyecto (opcional, se incluye cuando se hace join)
  final Map<String, dynamic>? categoriaProyecto;

  /// Datos de la organización a la que pertenece el proyecto (opcional, se incluye cuando se hace join)
  ///
  /// NOTA: Una organización puede tener muchos proyectos.
  /// La relación se establece mediante `organizacionId`.
  final Map<String, dynamic>? organizacion;

  /// Lista de tareas del proyecto (opcional, se incluye cuando se hace join)
  final List<dynamic>? tareas;

  /// Lista de categorías del proyecto (opcional, se incluye cuando se hace join)
  ///
  /// NOTA: Un proyecto puede tener múltiples categorías.
  /// Al crear un proyecto, enviar `categorias_ids` como array de IDs.
  final List<dynamic>? categoriasProyectos;

  const Proyecto({
    required this.idProyecto,
    this.categoriaProyectoId,
    required this.organizacionId,
    required this.nombre,
    this.objetivo,
    this.ubicacion,
    this.fechaInicio,
    this.fechaFin,
    required this.estado,
    this.participacionPublica = false,
    this.imagen,
    required this.creadoEn,
    this.actualizadoEn,
    this.categoriaProyecto,
    this.organizacion,
    this.tareas,
    this.categoriasProyectos,
  });

  factory Proyecto.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to safely get string value
      String? _getString(dynamic value) {
        if (value == null) return null;
        return value.toString();
      }

      // Helper function to safely get int value
      int _getInt(dynamic value, {int defaultValue = 0}) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        return int.tryParse(value.toString()) ?? defaultValue;
      }

      // Handle fecha_inicio
      DateTime? fechaInicio;
      final fechaInicioValue = json['fecha_inicio'];
      if (fechaInicioValue != null && fechaInicioValue is String) {
        try {
          fechaInicio = DateTime.parse(fechaInicioValue);
        } catch (e) {
          fechaInicio = null;
        }
      }

      // Handle fecha_fin
      DateTime? fechaFin;
      final fechaFinValue = json['fecha_fin'];
      if (fechaFinValue != null && fechaFinValue is String) {
        try {
          fechaFin = DateTime.parse(fechaFinValue);
        } catch (e) {
          fechaFin = null;
        }
      }

      // Handle creado_en
      DateTime creadoEn;
      final creadoEnValue = json['creado_en'];
      if (creadoEnValue != null && creadoEnValue is String) {
        try {
          creadoEn = DateTime.parse(creadoEnValue);
        } catch (e) {
          creadoEn = DateTime.now();
        }
      } else {
        creadoEn = DateTime.now();
      }

      // Handle actualizado_en
      DateTime? actualizadoEn;
      final actualizadoEnValue = json['actualizado_en'];
      if (actualizadoEnValue != null && actualizadoEnValue is String) {
        try {
          actualizadoEn = DateTime.parse(actualizadoEnValue);
        } catch (e) {
          actualizadoEn = null;
        }
      }

      // Manejar categoriasProyectos (puede venir como array)
      List<dynamic>? categoriasProyectos;
      if (json['categoriasProyectos'] != null &&
          json['categoriasProyectos'] is List) {
        categoriasProyectos = json['categoriasProyectos'] as List<dynamic>;
      }

      // Obtener categoriaProyectoId si existe (legacy)
      int? categoriaProyectoId;
      if (json['categoria_proyecto_id'] != null) {
        categoriaProyectoId = _getInt(json['categoria_proyecto_id']);
      } else if (categoriasProyectos != null &&
          categoriasProyectos.isNotEmpty) {
        // Si hay categorías, usar la primera como fallback para compatibilidad
        final primeraCategoria = categoriasProyectos.first;
        if (primeraCategoria is Map) {
          categoriaProyectoId = _getInt(
            primeraCategoria['categoria_id'] ??
                primeraCategoria['id_categoria_proyecto'],
          );
        }
      }

      // Manejar participacion_publica (puede venir como bool o 0/1)
      bool participacionPublica = false;
      if (json.containsKey('participacion_publica')) {
        final value = json['participacion_publica'];
        if (value is bool) {
          participacionPublica = value;
        } else if (value is num) {
          participacionPublica = value != 0;
        } else {
          final str = _getString(value)?.toLowerCase();
          if (str == 'true' || str == '1') {
            participacionPublica = true;
          }
        }
      }

      return Proyecto(
        idProyecto: _getInt(json['id_proyecto']),
        categoriaProyectoId: categoriaProyectoId,
        organizacionId: _getInt(json['organizacion_id']),
        nombre: _getString(json['nombre']) ?? '',
        objetivo: _getString(json['objetivo']),
        ubicacion: _getString(json['ubicacion']),
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        estado: _getString(json['estado']) ?? 'activo',
        participacionPublica: participacionPublica,
        imagen: _getString(json['imagen']),
        creadoEn: creadoEn,
        actualizadoEn: actualizadoEn,
        categoriaProyecto: json['categoriaProyecto'] is Map
            ? json['categoriaProyecto'] as Map<String, dynamic>?
            : null,
        organizacion: json['organizacion'] is Map
            ? json['organizacion'] as Map<String, dynamic>?
            : null,
        tareas: json['tareas'] is List
            ? json['tareas'] as List<dynamic>?
            : null,
        categoriasProyectos: categoriasProyectos,
      );
    } catch (e, stackTrace) {
      throw Exception(
        'Error parsing Proyecto from JSON: $e\nJSON: $json\nStackTrace: $stackTrace',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_proyecto': idProyecto,
      if (categoriaProyectoId != null)
        'categoria_proyecto_id': categoriaProyectoId,
      'organizacion_id': organizacionId,
      'nombre': nombre,
      'objetivo': objetivo,
      if (ubicacion != null) 'ubicacion': ubicacion,
      if (fechaInicio != null)
        'fecha_inicio': fechaInicio!.toUtc().toIso8601String().replaceAll(
          RegExp(r'\.\d+'),
          '',
        ),
      if (fechaFin != null)
        'fecha_fin': fechaFin!.toUtc().toIso8601String().replaceAll(
          RegExp(r'\.\d+'),
          '',
        ),
      'estado': estado,
      'participacion_publica': participacionPublica,
      if (imagen != null) 'imagen': imagen,
      'creado_en': creadoEn.toIso8601String(),
      if (actualizadoEn != null)
        'actualizado_en': actualizadoEn!.toIso8601String(),
      if (categoriaProyecto != null) 'categoriaProyecto': categoriaProyecto,
      if (organizacion != null) 'organizacion': organizacion,
      if (tareas != null) 'tareas': tareas,
      if (categoriasProyectos != null)
        'categoriasProyectos': categoriasProyectos,
    };
  }

  @override
  List<Object?> get props => [
    idProyecto,
    categoriaProyectoId,
    organizacionId,
    nombre,
    objetivo,
    ubicacion,
    fechaInicio,
    fechaFin,
    estado,
    participacionPublica,
    imagen,
    creadoEn,
    actualizadoEn,
  ];
}
