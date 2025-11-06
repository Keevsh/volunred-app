import 'package:equatable/equatable.dart';

class CategoriaProyecto extends Equatable {
  final int idCategoria;
  final String nombre;
  final String? descripcion;
  final DateTime creadoEn;
  final int? cantidadProyectos;

  const CategoriaProyecto({
    required this.idCategoria,
    required this.nombre,
    this.descripcion,
    required this.creadoEn,
    this.cantidadProyectos,
  });

  factory CategoriaProyecto.fromJson(Map<String, dynamic> json) {
    return CategoriaProyecto(
      idCategoria: json['id_categoria'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      creadoEn: DateTime.parse(json['creado_en'] as String),
      cantidadProyectos: json['_count'] != null 
          ? json['_count']['proyectos'] as int?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_categoria': idCategoria,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      'creado_en': creadoEn.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        idCategoria,
        nombre,
        descripcion,
        creadoEn,
        cantidadProyectos,
      ];
}
