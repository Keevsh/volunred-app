import 'package:equatable/equatable.dart';

/// Modelo de Asignación de Tarea
///
/// Representa la asignación de una tarea específica a un voluntario aprobado.
/// Permite asignar tareas individuales a voluntarios con información adicional.
///
/// Relaciones:
/// - **Tarea (N:1)**: Una asignación pertenece a una tarea.
/// - **Perfil Voluntario (N:1)**: Una asignación pertenece a un perfil de voluntario.
class AsignacionTarea extends Equatable {
  /// ID único de la asignación
  final int idAsignacion;

  /// ID de la tarea asignada
  final int tareaId;

  /// ID del perfil de voluntario al que se asigna la tarea
  ///
  /// NOTA: El voluntario debe tener una inscripción APROBADA en la organización.
  final int perfilVolId;

  /// Título de la asignación (opcional)
  final String? titulo;

  /// Descripción de la asignación (opcional)
  final String? descripcion;

  /// Fecha de asignación (opcional)
  final DateTime? fechaAsignacion;

  /// Estado de la asignación
  /// Valores posibles: 'activo', 'en_progreso', 'completada', 'cancelada'
  final String estado;

  /// Fecha de creación de la asignación
  final DateTime creadoEn;

  /// Fecha de última actualización (opcional)
  final DateTime? actualizadoEn;

  // Relaciones opcionales (se incluyen cuando se hace join en la consulta)

  /// Datos de la tarea (opcional, se incluye cuando se hace join)
  final Map<String, dynamic>? tarea;

  /// Datos del perfil de voluntario (opcional, se incluye cuando se hace join)
  final Map<String, dynamic>? perfilVoluntario;

  const AsignacionTarea({
    required this.idAsignacion,
    required this.tareaId,
    required this.perfilVolId,
    this.titulo,
    this.descripcion,
    this.fechaAsignacion,
    required this.estado,
    required this.creadoEn,
    this.actualizadoEn,
    this.tarea,
    this.perfilVoluntario,
  });

  factory AsignacionTarea.fromJson(Map<String, dynamic> json) {
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

    // Handle fecha_asignacion
    DateTime? fechaAsignacion;
    final fechaAsignacionValue = json['fecha_asignacion'];
    if (fechaAsignacionValue != null && fechaAsignacionValue is String) {
      try {
        fechaAsignacion = DateTime.parse(fechaAsignacionValue);
      } catch (e) {
        fechaAsignacion = null;
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

    return AsignacionTarea(
      idAsignacion: _getInt(
        json['id_asignacion'] ?? json['id_asignacion_tarea'],
      ),
      tareaId: _getInt(json['tarea_id']),
      perfilVolId: _getInt(json['perfil_vol_id']),
      titulo: _getString(json['titulo']),
      descripcion: _getString(json['descripcion']),
      fechaAsignacion: fechaAsignacion,
      estado: _getString(json['estado']) ?? 'activo',
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn,
      tarea: json['tarea'] is Map
          ? json['tarea'] as Map<String, dynamic>?
          : null,
      perfilVoluntario: json['perfil_voluntario'] is Map
          ? json['perfil_voluntario'] as Map<String, dynamic>?
          : (json['perfilVoluntario'] is Map
                ? json['perfilVoluntario'] as Map<String, dynamic>?
                : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_asignacion': idAsignacion,
      'tarea_id': tareaId,
      'perfil_vol_id': perfilVolId,
      if (titulo != null) 'titulo': titulo,
      if (descripcion != null) 'descripcion': descripcion,
      if (fechaAsignacion != null)
        'fecha_asignacion': fechaAsignacion!
            .toUtc()
            .toIso8601String()
            .replaceAll(RegExp(r'\.\d+'), ''),
      'estado': estado,
      'creado_en': creadoEn.toIso8601String(),
      if (actualizadoEn != null)
        'actualizado_en': actualizadoEn!.toIso8601String(),
      if (tarea != null) 'tarea': tarea,
      if (perfilVoluntario != null) 'perfilVoluntario': perfilVoluntario,
    };
  }

  @override
  List<Object?> get props => [
    idAsignacion,
    tareaId,
    perfilVolId,
    titulo,
    descripcion,
    fechaAsignacion,
    estado,
    creadoEn,
    actualizadoEn,
  ];
}
