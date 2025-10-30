import 'package:equatable/equatable.dart';
import 'programa.dart';
import 'rol.dart';

class Permiso extends Equatable {
  final int idPermiso;
  final int idRol;
  final int idPrograma;
  final String? nombre;
  final String estado;
  final Rol? rol;
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
    return Permiso(
      idPermiso: json['id_permiso'] as int,
      idRol: json['id_rol'] as int,
      idPrograma: json['id_programa'] as int,
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
