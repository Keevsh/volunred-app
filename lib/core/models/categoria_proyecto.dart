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
    // Helper function to safely get int value
    int? _getInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }
    
    return CategoriaProyecto(
      idCategoria: _getInt(json['id_categoria']) ?? 0,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : DateTime.now(),
      cantidadProyectos: json['_count'] != null 
          ? _getInt(json['_count']['proyectos'])
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
