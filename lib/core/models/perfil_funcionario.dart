import 'package:equatable/equatable.dart';

class PerfilFuncionario extends Equatable {
  final int idPerfilFuncionario;
  final int idUsuario;
  final int idOrganizacion;
  final String? cargo;
  final String? departamento;
  final String estado;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;
  
  // Relaciones opcionales
  final Map<String, dynamic>? usuario;
  final Map<String, dynamic>? organizacion;

  const PerfilFuncionario({
    required this.idPerfilFuncionario,
    required this.idUsuario,
    required this.idOrganizacion,
    this.cargo,
    this.departamento,
    required this.estado,
    required this.creadoEn,
    this.actualizadoEn,
    this.usuario,
    this.organizacion,
  });

  factory PerfilFuncionario.fromJson(Map<String, dynamic> json) {
    return PerfilFuncionario(
      idPerfilFuncionario: json['id_perfil_funcionario'] as int,
      idUsuario: json['id_usuario'] as int,
      idOrganizacion: json['id_organizacion'] as int,
      cargo: json['cargo'] as String?,
      departamento: json['departamento'] as String?,
      estado: json['estado'] as String,
      creadoEn: DateTime.parse(json['creado_en'] as String),
      actualizadoEn: json['actualizado_en'] != null
          ? DateTime.parse(json['actualizado_en'] as String)
          : null,
      usuario: json['usuario'] as Map<String, dynamic>?,
      organizacion: json['organizacion'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_perfil_funcionario': idPerfilFuncionario,
      'id_usuario': idUsuario,
      'id_organizacion': idOrganizacion,
      if (cargo != null) 'cargo': cargo,
      if (departamento != null) 'departamento': departamento,
      'estado': estado,
      'creado_en': creadoEn.toIso8601String(),
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn!.toIso8601String(),
      if (usuario != null) 'usuario': usuario,
      if (organizacion != null) 'organizacion': organizacion,
    };
  }

  @override
  List<Object?> get props => [
        idPerfilFuncionario,
        idUsuario,
        idOrganizacion,
        cargo,
        departamento,
        estado,
        creadoEn,
        actualizadoEn,
      ];
}
