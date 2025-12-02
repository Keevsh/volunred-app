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
    // Helper function to safely get int value
    int? _getInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return Aptitud(
      idAptitud: _getInt(json['id_aptitud']) ?? 0,
      nombre: json['nombre'] as String? ?? '',
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
  List<Object?> get props => [idAptitud, nombre, descripcion, estado, creadoEn];
}
