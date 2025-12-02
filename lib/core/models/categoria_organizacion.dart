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
    // Helper function to safely get int value
    int? _getInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return CategoriaOrganizacion(
      idCategoria: _getInt(json['id_categoria']) ?? 0,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : DateTime.now(),
      cantidadOrganizaciones: json['_count'] != null
          ? _getInt(json['_count']['organizaciones'])
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
