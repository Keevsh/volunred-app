import 'package:equatable/equatable.dart';

class Rol extends Equatable {
  final int idRol;
  final String nombre;
  final String? descripcion;
  final String estado;
  final DateTime? creadoEn;
  final List<Map<String, dynamic>>? permisos;

  const Rol({
    required this.idRol,
    required this.nombre,
    this.descripcion,
    this.estado = 'activo',
    this.creadoEn,
    this.permisos,
  });

  factory Rol.fromJson(Map<String, dynamic> json) {
    return Rol(
      idRol: json['id_rol'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      estado: json['estado'] as String? ?? 'activo',
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : null,
      permisos: json['permisos'] != null
          ? (json['permisos'] as List)
              .map((p) => p as Map<String, dynamic>)
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_rol': idRol,
      'nombre': nombre,
      'descripcion': descripcion,
      'estado': estado,
      'creado_en': creadoEn?.toIso8601String(),
      if (permisos != null) 'permisos': permisos,
    };
  }

  @override
  List<Object?> get props => [
        idRol,
        nombre,
        descripcion,
        estado,
        creadoEn,
        permisos,
      ];
}
