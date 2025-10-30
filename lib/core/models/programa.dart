import 'package:equatable/equatable.dart';
import 'aplicacion.dart';

class Programa extends Equatable {
  final int idPrograma;
  final String nombre;
  final String? descripcion;
  final String estado;
  final int idAplicacion;
  final Aplicacion? aplicacion;

  const Programa({
    required this.idPrograma,
    required this.nombre,
    this.descripcion,
    this.estado = 'activo',
    required this.idAplicacion,
    this.aplicacion,
  });

  factory Programa.fromJson(Map<String, dynamic> json) {
    return Programa(
      idPrograma: json['id_programa'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      estado: json['estado'] as String? ?? 'activo',
      idAplicacion: json['id_aplicacion'] as int,
      aplicacion: json['aplicacion'] != null
          ? Aplicacion.fromJson(json['aplicacion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_programa': idPrograma,
      'nombre': nombre,
      'descripcion': descripcion,
      'estado': estado,
      'id_aplicacion': idAplicacion,
      if (aplicacion != null) 'aplicacion': aplicacion!.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        idPrograma,
        nombre,
        descripcion,
        estado,
        idAplicacion,
        aplicacion,
      ];
}
