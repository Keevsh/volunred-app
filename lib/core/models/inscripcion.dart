import 'package:equatable/equatable.dart';

class Inscripcion extends Equatable {
  final int idInscripcion;
  final int perfilVolId;
  final int organizacionId;
  final DateTime fechaRecepcion;
  final String estado;
  final String? motivoRechazo;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  // Relaciones opcionales
  final Map<String, dynamic>? perfilVoluntario;
  final Map<String, dynamic>? organizacion;
  final Map<String, dynamic>? usuario;
  final Map<String, dynamic>? usuarioCompleto;

  const Inscripcion({
    required this.idInscripcion,
    required this.perfilVolId,
    required this.organizacionId,
    required this.fechaRecepcion,
    required this.estado,
    this.motivoRechazo,
    required this.creadoEn,
    this.actualizadoEn,
    this.perfilVoluntario,
    this.organizacion,
    this.usuario,
    this.usuarioCompleto,
  });

  factory Inscripcion.fromJson(Map<String, dynamic> json) {
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

      // Handle fecha_recepcion
      DateTime fechaRecepcion;
      final fechaRecepcionValue = json['fecha_recepcion'];
      if (fechaRecepcionValue != null && fechaRecepcionValue is String) {
        try {
          fechaRecepcion = DateTime.parse(fechaRecepcionValue);
        } catch (e) {
          fechaRecepcion = DateTime.now();
        }
      } else {
        fechaRecepcion = DateTime.now();
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

      // Manejar estado: normalizar a mayúsculas (PENDIENTE, APROBADO, RECHAZADO)
      String estadoValue = _getString(json['estado']) ?? 'PENDIENTE';
      estadoValue = estadoValue.toUpperCase();

      return Inscripcion(
        idInscripcion: _getInt(json['id_inscripcion']),
        perfilVolId: _getInt(json['perfil_vol_id']),
        organizacionId: _getInt(json['organizacion_id']),
        fechaRecepcion: fechaRecepcion,
        estado: estadoValue,
        motivoRechazo: _getString(json['motivo_rechazo']),
        creadoEn: creadoEn,
        actualizadoEn: actualizadoEn,
        // Manejar tanto camelCase como snake_case para perfilVoluntario
        perfilVoluntario: (json['perfilVoluntario'] ?? json['perfil_voluntario']) is Map
          ? (json['perfilVoluntario'] ?? json['perfil_voluntario']) as Map<String, dynamic>?
            : null,
        organizacion: json['organizacion'] is Map
            ? json['organizacion'] as Map<String, dynamic>?
            : null,
        usuario: json['usuario'] is Map
            ? json['usuario'] as Map<String, dynamic>?
            : null,
        usuarioCompleto: (json['usuario_completo'] ?? json['usuarioCompleto']) is Map
            ? (json['usuario_completo'] ?? json['usuarioCompleto']) as Map<String, dynamic>?
            : null,
      );
    } catch (e, stackTrace) {
      throw Exception(
        'Error parsing Inscripcion from JSON: $e\nJSON: $json\nStackTrace: $stackTrace',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_inscripcion': idInscripcion,
      'perfil_vol_id': perfilVolId,
      'organizacion_id': organizacionId,
      'fecha_recepcion': fechaRecepcion.toUtc().toIso8601String(),
      'estado': estado,
      if (motivoRechazo != null) 'motivo_rechazo': motivoRechazo,
      'creado_en': creadoEn.toIso8601String(),
      if (actualizadoEn != null)
        'actualizado_en': actualizadoEn!.toIso8601String(),
      if (perfilVoluntario != null) 'perfil_voluntario': perfilVoluntario,
      if (organizacion != null) 'organizacion': organizacion,
      if (usuario != null) 'usuario': usuario,
      if (usuarioCompleto != null) 'usuario_completo': usuarioCompleto,
    };
  }

  @override
  List<Object?> get props => [
    idInscripcion,
    perfilVolId,
    organizacionId,
    fechaRecepcion,
    estado,
    motivoRechazo,
    creadoEn,
    actualizadoEn,
  ];
}
