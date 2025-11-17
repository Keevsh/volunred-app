import 'package:equatable/equatable.dart';

/// Modelo de Rol
/// 
/// Representa un rol en el sistema (Admin, Funcionario, Voluntario, etc.).
/// 
/// Los roles se relacionan con los programas (acciones) a través de la tabla intermedia `permisos`:
/// - Un rol puede tener múltiples programas asignados (permisos)
/// - Los programas son las acciones que el rol puede realizar
/// - La relación se establece en la tabla `permisos` (id_rol, id_programa)
/// 
/// NOTA: La tabla `permisos` es la tabla intermedia entre `roles` y `programas`.
/// NO existe una tabla `roles_permisos` - todo se maneja a través de `permisos`.
class Rol extends Equatable {
  /// ID único del rol
  final int idRol;
  
  /// Nombre del rol
  final String nombre;
  
  /// Descripción opcional del rol
  final String? descripcion;
  
  /// Estado del rol (activo/inactivo)
  final String estado;
  
  /// Fecha de creación del rol
  final DateTime? creadoEn;
  
  /// Lista de permisos (programas asignados) - opcional, se incluye cuando se hace join
  /// Cada permiso representa un programa (acción) que el rol puede realizar
  final List<Map<String, dynamic>>? permisos;
  
  /// Cantidad de usuarios con este rol
  final int? cantidadUsuarios;
  
  /// Cantidad de permisos (programas) asignados a este rol
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
    // Helper function to safely get int value
    int? _getInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }
    
    int? cantidadUsuarios;
    int? cantidadPermisos;
    if (json['_count'] != null && json['_count'] is Map<String, dynamic>) {
      final countMap = json['_count'] as Map<String, dynamic>;
      cantidadUsuarios = _getInt(countMap['usuarios']);
      cantidadPermisos = _getInt(countMap['permisos']);
    }

    return Rol(
      idRol: _getInt(json['id_rol']) ?? 0,
      nombre: json['nombre'] as String? ?? '',
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
