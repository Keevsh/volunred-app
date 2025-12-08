import 'package:equatable/equatable.dart';
import 'usuario.dart';

/// Modelo de Bitácora de Operaciones
///
/// Registra las operaciones realizadas en el sistema por los usuarios.
class BitacoraOperacion extends Equatable {
  final int idOperaciones;
  final int usuarioId;
  final String comentario;
  final String estado;
  final DateTime creadoEn;
  final Usuario? usuario;

  const BitacoraOperacion({
    required this.idOperaciones,
    required this.usuarioId,
    required this.comentario,
    this.estado = 'activo',
    required this.creadoEn,
    this.usuario,
  });

  factory BitacoraOperacion.fromJson(Map<String, dynamic> json) {
    return BitacoraOperacion(
      idOperaciones: json['id_operaciones'] as int? ?? 0,
      usuarioId: json['usuario_id'] as int? ?? 0,
      comentario: json['comentario'] as String? ?? '',
      estado: json['estado'] as String? ?? 'activo',
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : DateTime.now(),
      usuario: json['usuario'] != null
          ? Usuario.fromJson(json['usuario'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_operaciones': idOperaciones,
      'usuario_id': usuarioId,
      'comentario': comentario,
      'estado': estado,
      'creado_en': creadoEn.toIso8601String(),
      if (usuario != null) 'usuario': usuario!.toJson(),
    };
  }

  /// Nombre completo del usuario que realizó la operación
  String get nombreUsuario {
    if (usuario != null) {
      return '${usuario!.nombres} ${usuario!.apellidos}';
    }
    return 'Usuario #$usuarioId';
  }

  @override
  List<Object?> get props => [
        idOperaciones,
        usuarioId,
        comentario,
        estado,
        creadoEn,
        usuario,
      ];
}
