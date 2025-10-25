import 'package:equatable/equatable.dart';

class Usuario extends Equatable {
  final int idUsuario;
  final String nombres;
  final String apellidos;
  final String email;
  final int? telefono;
  final int? ci;
  final String? sexo;
  final DateTime? creadoEn;

  const Usuario({
    required this.idUsuario,
    required this.nombres,
    required this.apellidos,
    required this.email,
    this.telefono,
    this.ci,
    this.sexo,
    this.creadoEn,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['id_usuario'] as int,
      nombres: json['nombres'] as String,
      apellidos: json['apellidos'] as String,
      email: json['email'] as String,
      telefono: json['telefono'] as int?,
      ci: json['ci'] as int?,
      sexo: json['sexo'] as String?,
      creadoEn: json['creado_en'] != null 
          ? DateTime.parse(json['creado_en'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'nombres': nombres,
      'apellidos': apellidos,
      'email': email,
      'telefono': telefono,
      'ci': ci,
      'sexo': sexo,
      'creado_en': creadoEn?.toIso8601String(),
    };
  }

  String get nombreCompleto => '$nombres $apellidos';

  @override
  List<Object?> get props => [
        idUsuario,
        nombres,
        apellidos,
        email,
        telefono,
        ci,
        sexo,
        creadoEn,
      ];
}
