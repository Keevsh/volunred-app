import 'package:equatable/equatable.dart';

class CategoriaOrganizacion extends Equatable {
  final int idCategoria;
  final String nombre;
  final String? descripcion;
  final DateTime creadoEn;
  final int? cantidadOrganizaciones;

  const CategoriaOrganizacion({
    required this.idCategoria,
    required this.nombre,
    this.descripcion,
    required this.creadoEn,
    this.cantidadOrganizaciones,
  });

  factory CategoriaOrganizacion.fromJson(Map<String, dynamic> json) {
    return CategoriaOrganizacion(
      idCategoria: json['id_categoria'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      creadoEn: DateTime.parse(json['creado_en'] as String),
      cantidadOrganizaciones: json['_count'] != null 
          ? json['_count']['organizaciones'] as int?
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
        cantidadOrganizaciones,
      ];
}
