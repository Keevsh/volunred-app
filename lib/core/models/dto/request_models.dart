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

// ==================== ADMIN REQUESTS ====================

/// Crear rol
class CreateRolRequest {
  final String nombre;
  final String? descripcion;

  CreateRolRequest({
    required this.nombre,
    this.descripcion,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
    };
  }
}

/// Actualizar rol
class UpdateRolRequest {
  final String? nombre;
  final String? descripcion;
  final String? estado;

  UpdateRolRequest({
    this.nombre,
    this.descripcion,
    this.estado,
  });

  Map<String, dynamic> toJson() {
    return {
      if (nombre != null) 'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (estado != null) 'estado': estado,
    };
  }
}

/// Asignar rol a usuario
class AsignarRolRequest {
  final int idUsuario;
  final int idRol;

  AsignarRolRequest({
    required this.idUsuario,
    required this.idRol,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'id_rol': idRol,
    };
  }
}

/// Asignar programas a rol (permisos)
class AsignarPermisosRequest {
  final int idRol;
  final List<int> programas;

  AsignarPermisosRequest({
    required this.idRol,
    required this.programas,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_rol': idRol,
      'programas': programas,
    };
  }
}

/// Crear programa
class CreateProgramaRequest {
  final String nombre;
  final String? descripcion;
  final int idAplicacion;

  CreateProgramaRequest({
    required this.nombre,
    this.descripcion,
    required this.idAplicacion,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      'id_aplicacion': idAplicacion,
    };
  }
}

/// Crear aplicación
class CreateAplicacionRequest {
  final String nombre;
  final int idModulo;

  CreateAplicacionRequest({
    required this.nombre,
    required this.idModulo,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'id_modulo': idModulo,
    };
  }
}

/// Actualizar usuario (admin)
class UpdateUsuarioRequest {
  final String? nombre;
  final String? apellido;
  final String? email;
  final String? sexo;

  UpdateUsuarioRequest({
    this.nombre,
    this.apellido,
    this.email,
    this.sexo,
  });

  Map<String, dynamic> toJson() {
    return {
      if (nombre != null) 'nombre': nombre,
      if (apellido != null) 'apellido': apellido,
      if (email != null) 'email': email,
      if (sexo != null) 'sexo': sexo,
    };
  }
}

// ==================== APTITUDES (ADMIN) ====================

/// Crear aptitud
class CreateAptitudRequest {
  final String nombre;
  final String? descripcion;

  CreateAptitudRequest({
    required this.nombre,
    this.descripcion,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
    };
  }
}

/// Actualizar aptitud
class UpdateAptitudRequest {
  final String? nombre;
  final String? descripcion;
  final String? estado;

  UpdateAptitudRequest({
    this.nombre,
    this.descripcion,
    this.estado,
  });

  Map<String, dynamic> toJson() {
    return {
      if (nombre != null) 'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (estado != null) 'estado': estado,
    };
  }
}
