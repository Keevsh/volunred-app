import 'package:equatable/equatable.dart';
import 'modulo.dart';

class Aplicacion extends Equatable {
  final int idAplicacion;
  final String nombre;
  final String estado;
  final int idModulo;
  final Modulo? modulo;
  final String descripcion;

  const Aplicacion({
    required this.idAplicacion,
    required this.nombre,
    this.estado = 'activo',
    required this.idModulo,
    this.modulo,
    this.descripcion = 'sin descripcion',
  });

  factory Aplicacion.fromJson(Map<String, dynamic> json) {
    // Helper function to safely get int value
    int? _getInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return Aplicacion(
      idAplicacion: _getInt(json['id_aplicacion']) ?? 0,
      nombre: json['nombre'] as String? ?? '',
      estado: json['estado'] as String? ?? 'activo',
      idModulo: _getInt(json['id_modulo']) ?? 0,
      modulo: json['modulo'] != null ? Modulo.fromJson(json['modulo']) : null,
      descripcion: json['descripcion'] as String? ?? 'sin descripcion',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_aplicacion': idAplicacion,
      'nombre': nombre,
      'estado': estado,
      'id_modulo': idModulo,
      if (modulo != null) 'modulo': modulo!.toJson(),
      'descripcion': descripcion,
    };
  }

  @override
  List<Object?> get props => [
    idAplicacion,
    nombre,
    estado,
    idModulo,
    modulo,
    descripcion,
  ];
}
