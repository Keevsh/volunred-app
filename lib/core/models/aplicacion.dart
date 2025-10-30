import 'package:equatable/equatable.dart';
import 'modulo.dart';

class Aplicacion extends Equatable {
  final int idAplicacion;
  final String nombre;
  final String estado;
  final int idModulo;
  final Modulo? modulo;

  const Aplicacion({
    required this.idAplicacion,
    required this.nombre,
    this.estado = 'activo',
    required this.idModulo,
    this.modulo,
  });

  factory Aplicacion.fromJson(Map<String, dynamic> json) {
    return Aplicacion(
      idAplicacion: json['id_aplicacion'] as int,
      nombre: json['nombre'] as String,
      estado: json['estado'] as String? ?? 'activo',
      idModulo: json['id_modulo'] as int,
      modulo: json['modulo'] != null
          ? Modulo.fromJson(json['modulo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_aplicacion': idAplicacion,
      'nombre': nombre,
      'estado': estado,
      'id_modulo': idModulo,
      if (modulo != null) 'modulo': modulo!.toJson(),
    };
  }

  @override
  List<Object?> get props => [idAplicacion, nombre, estado, idModulo, modulo];
}
