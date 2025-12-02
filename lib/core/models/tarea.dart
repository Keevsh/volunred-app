import 'package:equatable/equatable.dart';

class Tarea extends Equatable {
  final int idTarea;
  final int proyectoId;
  final String nombre;
  final String? descripcion;
  final String? prioridad;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String estado;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  // Relaciones opcionales
  final Map<String, dynamic>? proyecto;

  const Tarea({
    required this.idTarea,
    required this.proyectoId,
    required this.nombre,
    this.descripcion,
    this.prioridad,
    this.fechaInicio,
    this.fechaFin,
    required this.estado,
    required this.creadoEn,
    this.actualizadoEn,
    this.proyecto,
  });

  factory Tarea.fromJson(Map<String, dynamic> json) {
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

      return Tarea(
        idTarea: _getInt(json['id_tarea']),
        proyectoId: _getInt(json['proyecto_id']),
        nombre: _getString(json['nombre']) ?? '',
        descripcion: _getString(json['descripcion']),
        prioridad: _getString(json['prioridad']),
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        estado: _getString(json['estado']) ?? 'activo',
        creadoEn: creadoEn,
        actualizadoEn: actualizadoEn,
        proyecto: json['proyecto'] is Map
            ? json['proyecto'] as Map<String, dynamic>?
            : null,
      );
    } catch (e, stackTrace) {
      throw Exception(
        'Error parsing Tarea from JSON: $e\nJSON: $json\nStackTrace: $stackTrace',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_tarea': idTarea,
      'proyecto_id': proyectoId,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (prioridad != null) 'prioridad': prioridad,
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
      'creado_en': creadoEn.toIso8601String(),
      if (actualizadoEn != null)
        'actualizado_en': actualizadoEn!.toIso8601String(),
      if (proyecto != null) 'proyecto': proyecto,
    };
  }

  @override
  List<Object?> get props => [
    idTarea,
    proyectoId,
    nombre,
    descripcion,
    prioridad,
    fechaInicio,
    fechaFin,
    estado,
    creadoEn,
    actualizadoEn,
  ];
}
