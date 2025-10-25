import 'package:equatable/equatable.dart';

class Aptitud extends Equatable {
  final int idAptitud;
  final String nombre;
  final String? descripcion;
  final String estado;
  final DateTime? creadoEn;

  const Aptitud({
    required this.idAptitud,
    required this.nombre,
    this.descripcion,
    required this.estado,
    this.creadoEn,
  });

  factory Aptitud.fromJson(Map<String, dynamic> json) {
    return Aptitud(
      idAptitud: json['id_aptitud'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      estado: json['estado'] as String? ?? 'activo',
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_aptitud': idAptitud,
      'nombre': nombre,
      'descripcion': descripcion,
      'estado': estado,
      'creado_en': creadoEn?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        idAptitud,
        nombre,
        descripcion,
        estado,
        creadoEn,
      ];
}
