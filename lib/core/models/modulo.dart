import 'package:equatable/equatable.dart';

class Modulo extends Equatable {
  final int idModulo;
  final String nombre;
  final String estado;
  final String descripcion;

  const Modulo({
    required this.idModulo,
    required this.nombre,
    this.estado = 'activo',
    this.descripcion = '',
  });

  factory Modulo.fromJson(Map<String, dynamic> json) {
    // Helper function to safely get int value
    int? _getInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }
    
    return Modulo(
      idModulo: _getInt(json['id_modulo']) ?? 0,
      nombre: json['nombre'] as String? ?? '',
      estado: json['estado'] as String? ?? 'activo',
      descripcion: json['descripcion'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_modulo': idModulo,
      'nombre': nombre,
      'estado': estado,
      'descripcion': descripcion,
    };
  }

  @override
  List<Object?> get props => [idModulo, nombre, estado, descripcion];
}
