import 'package:equatable/equatable.dart';
import 'programa.dart';
import 'rol.dart';

/// Modelo de Permiso
///
/// La tabla `permisos` es la tabla intermedia entre `roles` y `programas`.
/// Representa la relación muchos-a-muchos entre roles y programas (acciones del sistema).
///
/// Estructura:
/// - roles: Los roles del sistema (Admin, Funcionario, Voluntario, etc.)
/// - programas: Las acciones/operaciones del sistema
/// - permisos: La tabla intermedia que asigna programas a roles
///
/// Cuando se asigna un programa a un rol, se crea un registro en `permisos`
/// con `id_rol` y `id_programa`.
class Permiso extends Equatable {
  /// ID único del permiso
  final int idPermiso;

  /// ID del rol al que pertenece este permiso
  final int idRol;

  /// ID del programa (acción) que este permiso otorga al rol
  final int idPrograma;

  /// Nombre opcional del permiso
  final String? nombre;

  /// Estado del permiso (activo/inactivo)
  final String estado;

  /// Datos del rol (opcional, se incluye cuando se hace join)
  final Rol? rol;

  /// Datos del programa (opcional, se incluye cuando se hace join)
  final Programa? programa;

  const Permiso({
    required this.idPermiso,
    required this.idRol,
    required this.idPrograma,
    this.nombre,
    this.estado = 'activo',
    this.rol,
    this.programa,
  });

  factory Permiso.fromJson(Map<String, dynamic> json) {
    // Helper function to safely get int value
    int? _getInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return Permiso(
      idPermiso: _getInt(json['id_permiso']) ?? 0,
      idRol: _getInt(json['id_rol']) ?? 0,
      idPrograma: _getInt(json['id_programa']) ?? 0,
      nombre: json['nombre'] as String?,
      estado: json['estado'] as String? ?? 'activo',
      rol: json['rol'] != null ? Rol.fromJson(json['rol']) : null,
      programa: json['programa'] != null
          ? Programa.fromJson(json['programa'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_permiso': idPermiso,
      'id_rol': idRol,
      'id_programa': idPrograma,
      'nombre': nombre,
      'estado': estado,
      if (rol != null) 'rol': rol!.toJson(),
      if (programa != null) 'programa': programa!.toJson(),
    };
  }

  @override
  List<Object?> get props => [
    idPermiso,
    idRol,
    idPrograma,
    nombre,
    estado,
    rol,
    programa,
  ];
}
