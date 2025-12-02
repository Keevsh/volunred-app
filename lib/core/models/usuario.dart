import 'package:equatable/equatable.dart';
import 'rol.dart';

class Usuario extends Equatable {
  final int idUsuario;
  final String nombres;
  final String apellidos;
  final String email;
  final int? telefono;
  final int? ci;
  final String? sexo;
  final String? tipoUsuario; // 'voluntario' o 'funcionario'
  final int? idRol;
  final Rol? rol;
  final DateTime? creadoEn;

  const Usuario({
    required this.idUsuario,
    required this.nombres,
    required this.apellidos,
    required this.email,
    this.telefono,
    this.ci,
    this.sexo,
    this.tipoUsuario,
    this.idRol,
    this.rol,
    this.creadoEn,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    // Helper function to safely get int value
    int? _getInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return Usuario(
      idUsuario: _getInt(json['id_usuario']) ?? 0,
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telefono: _getInt(json['telefono']),
      ci: _getInt(json['ci']),
      sexo: json['sexo'] as String?,
      tipoUsuario: json['tipo_usuario'] as String?,
      idRol: _getInt(json['id_rol']),
      rol: json['rol'] != null ? Rol.fromJson(json['rol']) : null,
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
      'tipo_usuario': tipoUsuario,
      'id_rol': idRol,
      if (rol != null) 'rol': rol!.toJson(),
      'creado_en': creadoEn?.toIso8601String(),
    };
  }

  String get nombreCompleto => '$nombres $apellidos';

  bool get isAdmin => idRol == 1;
  bool get isFuncionario => idRol == 2;
  bool get isVoluntario => idRol == 3;

  @override
  List<Object?> get props => [
    idUsuario,
    nombres,
    apellidos,
    email,
    telefono,
    ci,
    sexo,
    tipoUsuario,
    idRol,
    rol,
    creadoEn,
  ];
}
