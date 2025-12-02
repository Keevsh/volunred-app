import 'package:equatable/equatable.dart';

/// Modelo de Calificación de Proyecto
///
/// Representa una calificación (rating) que un voluntario puede dar a un proyecto.
/// La calificación es de 1 a 5 estrellas.
///
/// Relaciones:
/// - **Proyecto (N:1)**: Una calificación pertenece a un proyecto.
/// - **Perfil Voluntario (N:1)**: Una calificación pertenece a un perfil de voluntario.
class CalificacionProyecto extends Equatable {
  /// ID único de la calificación
  final int idCalificacion;

  /// ID del proyecto calificado
  final int proyectoId;

  /// ID del perfil de voluntario que califica
  final int perfilVolId;

  /// Calificación del proyecto (1-5)
  final int calificacion;

  /// Comentario o feedback sobre el proyecto (opcional)
  final String? comentario;

  /// Fecha de creación
  final DateTime creadoEn;

  /// Fecha de última actualización (opcional)
  final DateTime? actualizadoEn;

  const CalificacionProyecto({
    required this.idCalificacion,
    required this.proyectoId,
    required this.perfilVolId,
    required this.calificacion,
    this.comentario,
    required this.creadoEn,
    this.actualizadoEn,
  });

  factory CalificacionProyecto.fromJson(Map<String, dynamic> json) {
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

      // Validar calificación (1-5)
      int calificacionValue = _getInt(json['calificacion'], defaultValue: 1);
      if (calificacionValue < 1) calificacionValue = 1;
      if (calificacionValue > 5) calificacionValue = 5;

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

      return CalificacionProyecto(
        idCalificacion: _getInt(json['id_calificacion']),
        proyectoId: _getInt(json['proyecto_id']),
        perfilVolId: _getInt(json['perfil_vol_id']),
        calificacion: calificacionValue,
        comentario: _getString(json['comentario']),
        creadoEn: creadoEn,
        actualizadoEn: actualizadoEn,
      );
    } catch (e, stackTrace) {
      throw Exception(
        'Error parsing CalificacionProyecto from JSON: $e\nJSON: $json\nStackTrace: $stackTrace',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_calificacion': idCalificacion,
      'proyecto_id': proyectoId,
      'perfil_vol_id': perfilVolId,
      'calificacion': calificacion,
      if (comentario != null) 'comentario': comentario,
      'creado_en': creadoEn.toIso8601String(),
      if (actualizadoEn != null)
        'actualizado_en': actualizadoEn!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    idCalificacion,
    proyectoId,
    perfilVolId,
    calificacion,
    comentario,
    creadoEn,
    actualizadoEn,
  ];
}
