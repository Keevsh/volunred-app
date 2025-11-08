import 'package:equatable/equatable.dart';

class PerfilVoluntario extends Equatable {
  final int idPerfilVoluntario;
  final String? bio;
  final String? disponibilidad;
  final String estado;
  final int usuarioId;
  final DateTime? creadoEn;
  
  // Campos adicionales que pueden venir en las respuestas
  final Map<String, dynamic>? usuario;
  final Map<String, dynamic>? organizacion;
  final Map<String, dynamic>? inscripcion;

  const PerfilVoluntario({
    required this.idPerfilVoluntario,
    this.bio,
    this.disponibilidad,
    required this.estado,
    required this.usuarioId,
    this.creadoEn,
    this.usuario,
    this.organizacion,
    this.inscripcion,
  });

  factory PerfilVoluntario.fromJson(Map<String, dynamic> json) {
    // Manejar disponibilidad que puede venir como String o List
    String? disponibilidadValue;
    if (json['disponibilidad'] != null) {
      if (json['disponibilidad'] is List) {
        disponibilidadValue = (json['disponibilidad'] as List).join(', ');
      } else if (json['disponibilidad'] is String) {
        disponibilidadValue = json['disponibilidad'] as String;
      }
    }

    return PerfilVoluntario(
      idPerfilVoluntario: json['id_perfil_voluntario'] as int,
      bio: json['bio'] as String?,
      disponibilidad: disponibilidadValue,
      estado: json['estado'] as String? ?? 'activo',
      usuarioId: json['usuario_id'] as int,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : null,
      usuario: json['usuario'] is Map 
          ? json['usuario'] as Map<String, dynamic>? 
          : null,
      organizacion: json['organizacion'] is Map 
          ? json['organizacion'] as Map<String, dynamic>? 
          : null,
      inscripcion: json['inscripcion'] is Map 
          ? json['inscripcion'] as Map<String, dynamic>? 
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
        usuario,
        organizacion,
        inscripcion,
      ];
}
