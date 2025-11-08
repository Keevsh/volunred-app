import 'package:equatable/equatable.dart';

class Participacion extends Equatable {
  final int idParticipacion;
  final int perfilVolId;
  final int proyectoId;
  final String? rolAsignado;
  final int? horasComprometidasSemana;
  final String estado;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  // Relaciones opcionales
  final Map<String, dynamic>? perfilVoluntario;
  final Map<String, dynamic>? proyecto;

  const Participacion({
    required this.idParticipacion,
    required this.perfilVolId,
    required this.proyectoId,
    this.rolAsignado,
    this.horasComprometidasSemana,
    required this.estado,
    required this.creadoEn,
    this.actualizadoEn,
    this.perfilVoluntario,
    this.proyecto,
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
    
    return Participacion(
      idParticipacion: _getInt(json['id_participacion']) ?? 0,
      perfilVolId: _getInt(json['perfil_vol_id']) ?? 0,
      proyectoId: _getInt(json['proyecto_id']) ?? 0,
      rolAsignado: _getString(json['rol_asignado']),
      horasComprometidasSemana: _getInt(json['horas_comprometidas_semana']),
      estado: _getString(json['estado']) ?? 'programada',
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn,
      perfilVoluntario: json['perfilVoluntario'] is Map 
          ? json['perfilVoluntario'] as Map<String, dynamic>? 
          : null,
      proyecto: json['proyecto'] is Map 
          ? json['proyecto'] as Map<String, dynamic>? 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_participacion': idParticipacion,
      'perfil_vol_id': perfilVolId,
      'proyecto_id': proyectoId,
      if (rolAsignado != null) 'rol_asignado': rolAsignado,
      if (horasComprometidasSemana != null) 'horas_comprometidas_semana': horasComprometidasSemana,
      'estado': estado,
      'creado_en': creadoEn.toIso8601String(),
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn!.toIso8601String(),
      if (perfilVoluntario != null) 'perfilVoluntario': perfilVoluntario,
      if (proyecto != null) 'proyecto': proyecto,
    };
  }

  @override
  List<Object?> get props => [
        idParticipacion,
        perfilVolId,
        proyectoId,
        rolAsignado,
        horasComprometidasSemana,
        estado,
        creadoEn,
        actualizadoEn,
      ];
}

