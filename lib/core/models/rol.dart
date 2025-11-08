import 'package:equatable/equatable.dart';

class Rol extends Equatable {
  final int idRol;
  final String nombre;
  final String? descripcion;
  final String estado;
  final DateTime? creadoEn;
  final List<Map<String, dynamic>>? permisos;
  final int? cantidadUsuarios;
  final int? cantidadPermisos;

  const Rol({
    required this.idRol,
    required this.nombre,
    this.descripcion,
    this.estado = 'activo',
    this.creadoEn,
    this.permisos,
    this.cantidadUsuarios,
    this.cantidadPermisos,
  });

  factory Rol.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>>? permisosList;
    if (json['permisos'] != null) {
      try {
        final permisosData = json['permisos'];
        if (permisosData is List) {
          permisosList = permisosData
              .map((p) => p is Map<String, dynamic> 
                  ? p 
                  : Map<String, dynamic>.from(p))
              .toList();
        }
      } catch (e) {
        // Si hay error al parsear permisos, los dejamos como null
        permisosList = null;
      }
    }

    // Manejo seguro del campo _count
    int? cantidadUsuarios;
    int? cantidadPermisos;
    if (json['_count'] != null && json['_count'] is Map<String, dynamic>) {
      final countMap = json['_count'] as Map<String, dynamic>;
      cantidadUsuarios = countMap['usuarios'] as int?;
      cantidadPermisos = countMap['permisos'] as int?;
    }

    return Rol(
      idRol: json['id_rol'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      estado: json['estado'] as String? ?? 'activo',
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : null,
      permisos: permisosList,
      cantidadUsuarios: cantidadUsuarios,
      cantidadPermisos: cantidadPermisos,
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
        cantidadUsuarios,
        cantidadPermisos,
      ];
}
