import 'package:equatable/equatable.dart';

/// Modelo de Opinión sobre un Proyecto
///
/// Representa una opinión que un voluntario puede dejar sobre un proyecto.
/// Las opiniones pueden ser visibles públicamente o privadas.
///
/// Relaciones:
/// - **Proyecto (N:1)**: Una opinión pertenece a un proyecto.
/// - **Perfil Voluntario (N:1)**: Una opinión pertenece a un perfil de voluntario.
class Opinion extends Equatable {
  /// ID único de la opinión
  final int idOpinion;

  /// ID del proyecto
  final int proyectoId;

  /// ID del perfil de voluntario
  final int perfilVolId;

  /// Descripción de la opinión (requerido, máx. 250 caracteres)
  final String descripcion;

  /// Si la opinión es visible públicamente (default: true)
  final bool visible;

  /// Fecha de creación
  final DateTime creadoEn;

  /// Fecha de última actualización (opcional)
  final DateTime? actualizadoEn;

  const Opinion({
    required this.idOpinion,
    required this.proyectoId,
    required this.perfilVolId,
    required this.descripcion,
    this.visible = true,
    required this.creadoEn,
    this.actualizadoEn,
  });

  factory Opinion.fromJson(Map<String, dynamic> json) {
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

      // Handle visible - puede ser bool, int (0/1) o string ("true"/"false")
      bool visibleValue = true;
      final visibleRaw = json['visible'];
      if (visibleRaw != null) {
        if (visibleRaw is bool) {
          visibleValue = visibleRaw;
        } else if (visibleRaw is int) {
          visibleValue = visibleRaw == 1;
        } else if (visibleRaw is String) {
          visibleValue =
              visibleRaw.toLowerCase() == 'true' || visibleRaw == '1';
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

      return Opinion(
        idOpinion: _getInt(json['id_opinion']),
        proyectoId: _getInt(json['proyecto_id']),
        perfilVolId: _getInt(json['perfil_vol_id']),
        descripcion: _getString(json['descripcion']) ?? '',
        visible: visibleValue,
        creadoEn: creadoEn,
        actualizadoEn: actualizadoEn,
      );
    } catch (e, stackTrace) {
      throw Exception(
        'Error parsing Opinion from JSON: $e\nJSON: $json\nStackTrace: $stackTrace',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_opinion': idOpinion,
      'proyecto_id': proyectoId,
      'perfil_vol_id': perfilVolId,
      'descripcion': descripcion,
      'visible': visible,
      'creado_en': creadoEn.toIso8601String(),
      if (actualizadoEn != null)
        'actualizado_en': actualizadoEn!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    idOpinion,
    proyectoId,
    perfilVolId,
    descripcion,
    visible,
    creadoEn,
    actualizadoEn,
  ];
}
