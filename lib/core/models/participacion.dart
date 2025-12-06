import 'package:equatable/equatable.dart';

/// Modelo de Participación
///
/// Representa la relación entre un voluntario aprobado (inscripción) y un proyecto.
/// Una participación asigna un voluntario a un proyecto con un rol específico.
///
/// Relaciones:
/// - **Inscripción (N:1)**: Una participación pertenece a una inscripción aprobada.
/// - **Proyecto (N:1)**: Una participación pertenece a un proyecto.
class Participacion extends Equatable {
  /// ID único de la participación
  final int idParticipacion;

  /// ID de la inscripción (voluntario aprobado) que participa
  ///
  /// NOTA: Puede ser null para participaciones públicas (sin inscripción a la organización)
  /// Para participaciones privadas, la inscripción debe estar en estado APROBADO.
  final int? inscripcionId;

  /// ID del perfil de voluntario (viene del endpoint de participaciones)
  final int? perfilVolId;

  /// ID del proyecto en el que participa
  final int proyectoId;

  /// Rol asignado al voluntario en el proyecto (opcional)
  final String? rolAsignado;

  /// Horas comprometidas por semana (opcional)
  final double? horasComprometidasSemana;

  /// Estado de la participación
  /// Valores posibles: 'PROGRAMADA', 'EN_PROGRESO', 'COMPLETADO', 'AUSENTE'
  final String estado;

  /// Fecha de creación de la participación
  final DateTime creadoEn;

  /// Fecha de última actualización (opcional)
  final DateTime? actualizadoEn;

  // Relaciones opcionales (se incluyen cuando se hace join en la consulta)

  /// Datos de la inscripción (opcional, se incluye cuando se hace join)
  /// Contiene información del usuario y la organización
  final Map<String, dynamic>? inscripcion;

  /// Datos del proyecto (opcional, se incluye cuando se hace join)
  final Map<String, dynamic>? proyecto;

  /// Datos del perfil del voluntario (opcional, se incluye cuando se hace join)
  final Map<String, dynamic>? perfilVoluntario;

  /// Datos del usuario (opcional, se incluye cuando se hace join)
  final Map<String, dynamic>? usuario;

  /// Datos completos del usuario (opcional, se incluye cuando se hace join)
  final Map<String, dynamic>? usuarioCompleto;

  /// ID del usuario (normalizado por el backend, viene directo en participaciones públicas)
  final int? usuarioId;

  const Participacion({
    required this.idParticipacion,
    this.inscripcionId,
    this.perfilVolId,
    required this.proyectoId,
    this.rolAsignado,
    this.horasComprometidasSemana,
    required this.estado,
    required this.creadoEn,
    this.actualizadoEn,
    this.inscripcion,
    this.proyecto,
    this.perfilVoluntario,
    this.usuario,
    this.usuarioCompleto,
    this.usuarioId,
  });

  factory Participacion.fromJson(Map<String, dynamic> json) {
    // Helper function to safely get string value
    String? _getString(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    // Helper function to safely get int value
    int? _getInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
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

    // Handle horas_comprometidas_semana - puede ser int o double
    double? horasComprometidasSemana;
    final horasValue = json['horas_comprometidas_semana'];
    if (horasValue != null) {
      if (horasValue is double) {
        horasComprometidasSemana = horasValue;
      } else if (horasValue is int) {
        horasComprometidasSemana = horasValue.toDouble();
      } else {
        horasComprometidasSemana = double.tryParse(horasValue.toString());
      }
    }

    // Manejar estado: normalizar a mayúsculas (PROGRAMADA, EN_PROGRESO, COMPLETADO, AUSENTE)
    String estadoValue = _getString(json['estado']) ?? 'PROGRAMADA';
    estadoValue = estadoValue.toUpperCase();

    return Participacion(
      idParticipacion: _getInt(json['id_participacion']) ?? 0,
      inscripcionId: _getInt(json['inscripcion_id']),
      perfilVolId: _getInt(json['perfil_vol_id']),
      proyectoId: _getInt(json['proyecto_id']) ?? 0,
      rolAsignado: _getString(json['rol_asignado']),
      horasComprometidasSemana: horasComprometidasSemana,
      estado: estadoValue,
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn,
      inscripcion: json['inscripcion'] is Map
          ? json['inscripcion'] as Map<String, dynamic>?
          : null,
      proyecto: json['proyecto'] is Map
          ? json['proyecto'] as Map<String, dynamic>?
          : null,
      perfilVoluntario: json['perfil_voluntario'] is Map
          ? json['perfil_voluntario'] as Map<String, dynamic>?
          : null,
      usuario: json['usuario'] is Map
          ? json['usuario'] as Map<String, dynamic>?
          : null,
      usuarioCompleto: json['usuario_completo'] is Map
          ? json['usuario_completo'] as Map<String, dynamic>?
          : null,
      usuarioId: _getInt(json['usuario_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_participacion': idParticipacion,
      if (inscripcionId != null) 'inscripcion_id': inscripcionId,
      if (perfilVolId != null) 'perfil_vol_id': perfilVolId,
      'proyecto_id': proyectoId,
      if (rolAsignado != null) 'rol_asignado': rolAsignado,
      if (horasComprometidasSemana != null)
        'horas_comprometidas_semana': horasComprometidasSemana,
      'estado': estado,
      'creado_en': creadoEn.toIso8601String(),
      if (actualizadoEn != null)
        'actualizado_en': actualizadoEn!.toIso8601String(),
      if (inscripcion != null) 'inscripcion': inscripcion,
      if (proyecto != null) 'proyecto': proyecto,
      if (perfilVoluntario != null) 'perfil_voluntario': perfilVoluntario,
      if (usuario != null) 'usuario': usuario,
      if (usuarioCompleto != null) 'usuario_completo': usuarioCompleto,
      if (usuarioId != null) 'usuario_id': usuarioId,
    };
  }

  @override
  List<Object?> get props => [
    idParticipacion,
    inscripcionId,
    perfilVolId,
    proyectoId,
    rolAsignado,
    horasComprometidasSemana,
    estado,
    creadoEn,
    actualizadoEn,
    perfilVoluntario,
    usuario,
    usuarioCompleto,
    usuarioId,
  ];
}
