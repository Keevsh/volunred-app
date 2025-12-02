import 'package:equatable/equatable.dart';

class PerfilVoluntario extends Equatable {
  final int idPerfilVoluntario;
  final String? bio;
  final String? disponibilidad;
  final String estado;
  final int usuarioId;
  final String? fotoPerfil; // Foto de perfil en formato base64
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
    this.fotoPerfil,
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

    // Manejar estado que puede venir como String, int, o bool
    String estadoValue = 'activo';
    final estadoJson = json['estado'];
    if (estadoJson != null) {
      if (estadoJson is String) {
        estadoValue = estadoJson;
      } else if (estadoJson is int) {
        // 1 = activo, 0 = inactivo
        estadoValue = estadoJson == 1 ? 'activo' : 'inactivo';
      } else if (estadoJson is bool) {
        estadoValue = estadoJson ? 'activo' : 'inactivo';
      }
    }

    // Manejar bio que puede ser null o String
    String? bioValue;
    if (json['bio'] != null) {
      if (json['bio'] is String) {
        bioValue = json['bio'] as String;
      } else {
        bioValue = json['bio'].toString();
      }
    }

    return PerfilVoluntario(
      idPerfilVoluntario: json['id_perfil_voluntario'] is int
          ? json['id_perfil_voluntario'] as int
          : int.tryParse(json['id_perfil_voluntario'].toString()) ?? 0,
      bio: bioValue,
      disponibilidad: disponibilidadValue,
      estado: estadoValue,
      usuarioId: json['usuario_id'] is int
          ? json['usuario_id'] as int
          : int.tryParse(json['usuario_id'].toString()) ?? 0,
      fotoPerfil: json['foto_perfil'] != null
          ? json['foto_perfil'].toString()
          : null,
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'].toString())
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
      if (fotoPerfil != null) 'foto_perfil': fotoPerfil,
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
    fotoPerfil,
    creadoEn,
    usuario,
    organizacion,
    inscripcion,
  ];
}
