import 'package:equatable/equatable.dart';

class PerfilVoluntario extends Equatable {
  final int idPerfilVoluntario;
  final String? bio;
  final String? disponibilidad;
  final String estado;
  final int usuarioId;
  final DateTime? creadoEn;

  const PerfilVoluntario({
    required this.idPerfilVoluntario,
    this.bio,
    this.disponibilidad,
    required this.estado,
    required this.usuarioId,
    this.creadoEn,
  });

  factory PerfilVoluntario.fromJson(Map<String, dynamic> json) {
    return PerfilVoluntario(
      idPerfilVoluntario: json['id_perfil_voluntario'] as int,
      bio: json['bio'] as String?,
      disponibilidad: json['disponibilidad'] as String?,
      estado: json['estado'] as String? ?? 'activo',
      usuarioId: json['usuario_id'] as int,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_perfil_voluntario': idPerfilVoluntario,
      'bio': bio,
      'disponibilidad': disponibilidad,
      'estado': estado,
      'usuario_id': usuarioId,
      'creado_en': creadoEn?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        idPerfilVoluntario,
        bio,
        disponibilidad,
        estado,
        usuarioId,
        creadoEn,
      ];
}
