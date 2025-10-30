class RegisterRequest {
  final String nombres;
  final String apellidos;
  final String email;
  final String contrasena;
  final int? telefono;
  final int? ci;
  final String? sexo;
  final String? tipoUsuario; // 'voluntario' o 'funcionario'

  RegisterRequest({
    required this.nombres,
    required this.apellidos,
    required this.email,
    required this.contrasena,
    this.telefono,
    this.ci,
    this.sexo,
    this.tipoUsuario,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombres': nombres,
      'apellidos': apellidos,
      'email': email,
      'contrasena': contrasena,
      'telefono': telefono,
      'ci': ci,
      'sexo': sexo,
      if (tipoUsuario != null) 'tipo_usuario': tipoUsuario,
    };
  }
}

class LoginRequest {
  final String email;
  final String contrasena;

  LoginRequest({
    required this.email,
    required this.contrasena,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'contrasena': contrasena,
    };
  }
}

class CreatePerfilVoluntarioRequest {
  final int usuarioId;
  final String? bio;
  final String? disponibilidad;
  final String estado;

  CreatePerfilVoluntarioRequest({
    required this.usuarioId,
    this.bio,
    this.disponibilidad,
    this.estado = 'activo',
  });

  Map<String, dynamic> toJson() {
    return {
      'usuario_id': usuarioId,
      'bio': bio,
      'disponibilidad': disponibilidad,
      'estado': estado,
    };
  }
}

class AsignarAptitudRequest {
  final int perfilVolId;
  final int aptitudId;

  AsignarAptitudRequest({
    required this.perfilVolId,
    required this.aptitudId,
  });

  Map<String, dynamic> toJson() {
    return {
      'perfil_vol_id': perfilVolId,
      'aptitud_id': aptitudId,
    };
  }
}
