import 'package:equatable/equatable.dart';

class Modulo extends Equatable {
  final int idModulo;
  final String nombre;
  final String estado;

  const Modulo({
    required this.idModulo,
    required this.nombre,
    this.estado = 'activo',
  });

  factory Modulo.fromJson(Map<String, dynamic> json) {
    return Modulo(
      idModulo: json['id_modulo'] as int,
      nombre: json['nombre'] as String,
      estado: json['estado'] as String? ?? 'activo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_modulo': idModulo,
      'nombre': nombre,
      'estado': estado,
    };
  }

  @override
  List<Object?> get props => [idModulo, nombre, estado];
}
