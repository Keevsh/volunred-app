import 'package:equatable/equatable.dart';

class AsignacionTarea extends Equatable {
  final int idAsignacionTarea;
  final int tareaId;
  final int perfilVolId;
  final String? titulo;
  final String? descripcion;
  final DateTime? fechaAsignacion;
  final String estado;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  // Relaciones opcionales
  final Map<String, dynamic>? tarea;
  final Map<String, dynamic>? perfilVoluntario;

  const AsignacionTarea({
    required this.idAsignacionTarea,
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
      idAsignacionTarea: _getInt(json['id_asignacion_tarea']),
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
      perfilVoluntario: json['perfilVoluntario'] is Map 
          ? json['perfilVoluntario'] as Map<String, dynamic>? 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_asignacion_tarea': idAsignacionTarea,
      'tarea_id': tareaId,
      'perfil_vol_id': perfilVolId,
      if (titulo != null) 'titulo': titulo,
      if (descripcion != null) 'descripcion': descripcion,
      if (fechaAsignacion != null) 'fecha_asignacion': fechaAsignacion!.toIso8601String().split('T')[0],
      'estado': estado,
      'creado_en': creadoEn.toIso8601String(),
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn!.toIso8601String(),
      if (tarea != null) 'tarea': tarea,
      if (perfilVoluntario != null) 'perfilVoluntario': perfilVoluntario,
    };
  }

  @override
  List<Object?> get props => [
        idAsignacionTarea,
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

