import 'package:equatable/equatable.dart';
import 'usuario.dart';

/// Modelo de Bitácora de Autores
///
/// Registra las acciones de autoría realizadas en el sistema.
class BitacoraAutor extends Equatable {
  final int idAutores;
  final int usuarioId;
  final String comentario;
  final String estado;
  final DateTime creadoEn;
  final Usuario? usuario;

  const BitacoraAutor({
    required this.idAutores,
    required this.usuarioId,
    required this.comentario,
    this.estado = 'activo',
    required this.creadoEn,
    this.usuario,
  });

  factory BitacoraAutor.fromJson(Map<String, dynamic> json) {
    return BitacoraAutor(
      idAutores: json['id_autores'] as int? ?? 0,
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
      'id_autores': idAutores,
      'usuario_id': usuarioId,
      'comentario': comentario,
      'estado': estado,
      'creado_en': creadoEn.toIso8601String(),
      if (usuario != null) 'usuario': usuario!.toJson(),
    };
  }

  /// Nombre completo del usuario autor
  String get nombreUsuario {
    if (usuario != null) {
      return '${usuario!.nombres} ${usuario!.apellidos}';
    }
    return 'Usuario #$usuarioId';
  }

  @override
  List<Object?> get props => [
        idAutores,
        usuarioId,
        comentario,
        estado,
        creadoEn,
        usuario,
      ];
}
