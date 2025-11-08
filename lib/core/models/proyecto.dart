import 'package:equatable/equatable.dart';

class Proyecto extends Equatable {
  final int idProyecto;
  final int categoriaProyectoId;
  final int organizacionId;
  final String nombre;
  final String? objetivo;
  final String? ubicacion;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String estado;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  // Relaciones opcionales
  final Map<String, dynamic>? categoriaProyecto;
  final Map<String, dynamic>? organizacion;
  final List<dynamic>? tareas;

  const Proyecto({
    required this.idProyecto,
    required this.categoriaProyectoId,
    required this.organizacionId,
    required this.nombre,
    this.objetivo,
    this.ubicacion,
    this.fechaInicio,
    this.fechaFin,
    required this.estado,
    required this.creadoEn,
    this.actualizadoEn,
    this.categoriaProyecto,
    this.organizacion,
    this.tareas,
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
      
      return Proyecto(
        idProyecto: _getInt(json['id_proyecto']),
        categoriaProyectoId: _getInt(json['categoria_proyecto_id']),
        organizacionId: _getInt(json['organizacion_id']),
        nombre: _getString(json['nombre']) ?? '',
        objetivo: _getString(json['objetivo']),
        ubicacion: _getString(json['ubicacion']),
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        estado: _getString(json['estado']) ?? 'activo',
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
      );
    } catch (e, stackTrace) {
      throw Exception('Error parsing Proyecto from JSON: $e\nJSON: $json\nStackTrace: $stackTrace');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_proyecto': idProyecto,
      'categoria_proyecto_id': categoriaProyectoId,
      'organizacion_id': organizacionId,
      'nombre': nombre,
      'objetivo': objetivo,
      if (ubicacion != null) 'ubicacion': ubicacion,
      if (fechaInicio != null) 'fecha_inicio': fechaInicio!.toIso8601String().split('T')[0],
      if (fechaFin != null) 'fecha_fin': fechaFin!.toIso8601String().split('T')[0],
      'estado': estado,
      'creado_en': creadoEn.toIso8601String(),
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn!.toIso8601String(),
      if (categoriaProyecto != null) 'categoriaProyecto': categoriaProyecto,
      if (organizacion != null) 'organizacion': organizacion,
      if (tareas != null) 'tareas': tareas,
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
        creadoEn,
        actualizadoEn,
      ];
}

