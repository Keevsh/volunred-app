import 'package:equatable/equatable.dart';

/// Modelo de Experiencia de Voluntariado
///
/// Representa una experiencia de voluntariado de un voluntario en una organización.
///
/// Relaciones:
/// - **Perfil Voluntario (N:1)**: Una experiencia pertenece a un perfil de voluntario.
/// - **Organización (N:1)**: Una experiencia está asociada a una organización.
class ExperienciaVoluntario extends Equatable {
  /// ID único de la experiencia
  final int idExperiencia;

  /// ID del perfil de voluntario
  final int perfilVolId;

  /// ID de la organización
  final int organizacionId;

  /// Área de la experiencia (requerido)
  final String area;

  /// Descripción detallada de la experiencia (opcional)
  final String? descripcion;

  /// Fecha de inicio de la experiencia (requerido)
  final DateTime fechaInicio;

  /// Fecha de fin de la experiencia (opcional)
  final DateTime? fechaFin;

  /// Fecha de creación
  final DateTime? creadoEn;

  /// Fecha de última actualización (opcional)
  final DateTime? actualizadoEn;

  // Relaciones opcionales (se incluyen cuando se hace join en la consulta)

  /// Datos de la organización (opcional, se incluye cuando se hace join)
  final Map<String, dynamic>? organizacion;

  const ExperienciaVoluntario({
    required this.idExperiencia,
    required this.perfilVolId,
    required this.organizacionId,
    required this.area,
    this.descripcion,
    required this.fechaInicio,
    this.fechaFin,
    this.creadoEn,
    this.actualizadoEn,
    this.organizacion,
  });

  factory ExperienciaVoluntario.fromJson(Map<String, dynamic> json) {
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
      DateTime fechaInicio;
      final fechaInicioValue = json['fecha_inicio'];
      if (fechaInicioValue != null && fechaInicioValue is String) {
        try {
          fechaInicio = DateTime.parse(fechaInicioValue);
        } catch (e) {
          fechaInicio = DateTime.now();
        }
      } else {
        fechaInicio = DateTime.now();
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
      DateTime? creadoEn;
      final creadoEnValue = json['creado_en'];
      if (creadoEnValue != null && creadoEnValue is String) {
        try {
          creadoEn = DateTime.parse(creadoEnValue);
        } catch (e) {
          creadoEn = null;
        }
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

      return ExperienciaVoluntario(
        idExperiencia: _getInt(json['id_experiencia']),
        perfilVolId: _getInt(json['perfil_vol_id']),
        organizacionId: _getInt(json['organizacion_id']),
        area: _getString(json['area']) ?? '',
        descripcion: _getString(json['descripcion']),
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        creadoEn: creadoEn,
        actualizadoEn: actualizadoEn,
        organizacion: json['organizacion'] is Map
            ? json['organizacion'] as Map<String, dynamic>?
            : null,
      );
    } catch (e, stackTrace) {
      throw Exception(
        'Error parsing ExperienciaVoluntario from JSON: $e\nJSON: $json\nStackTrace: $stackTrace',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_experiencia': idExperiencia,
      'perfil_vol_id': perfilVolId,
      'organizacion_id': organizacionId,
      'area': area,
      if (descripcion != null) 'descripcion': descripcion,
      'fecha_inicio': fechaInicio.toUtc().toIso8601String().replaceAll(
        RegExp(r'\.\d+'),
        '',
      ),
      if (fechaFin != null)
        'fecha_fin': fechaFin!.toUtc().toIso8601String().replaceAll(
          RegExp(r'\.\d+'),
          '',
        ),
      if (creadoEn != null) 'creado_en': creadoEn!.toIso8601String(),
      if (actualizadoEn != null)
        'actualizado_en': actualizadoEn!.toIso8601String(),
      if (organizacion != null) 'organizacion': organizacion,
    };
  }

  @override
  List<Object?> get props => [
    idExperiencia,
    perfilVolId,
    organizacionId,
    area,
    descripcion,
    fechaInicio,
    fechaFin,
    creadoEn,
    actualizadoEn,
  ];
}
