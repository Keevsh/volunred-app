class RegisterRequest {
  final String nombres;
  final String apellidos;
  final String email;
  final String contrasena;
  final int? telefono;
  final int? ci;
  final String? sexo;
  final int? idRol; // id_rol requerido por el backend

  RegisterRequest({
    required this.nombres,
    required this.apellidos,
    required this.email,
    required this.contrasena,
    this.telefono,
    this.ci,
    this.sexo,
    this.idRol,
  });

  Map<String, dynamic> toJson() {
    final json = {
      'nombres': nombres,
      'apellidos': apellidos,
      'email': email,
      'contrasena': contrasena,
      'telefono': telefono,
      'ci': ci,
      'sexo': sexo,
    };
    
    // id_rol es requerido por el backend
    if (idRol != null) {
      json['id_rol'] = idRol;
    }
    
    return json;
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
    // El backend no espera estos campos en la creación
    // El perfil se crea automáticamente o se actualiza después
    // Por ahora, enviamos un body vacío o solo campos permitidos
    return {};
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
      'usuario_id': idUsuario,
      'rol_id': idRol,
    };
  }
}

/// Asignar programas a rol (crear registros en la tabla permisos)
/// 
/// La tabla `permisos` es la tabla intermedia entre `roles` y `programas`.
/// Cuando se asignan programas a un rol, se crean registros en `permisos`
/// que relacionan el rol con cada programa, otorgando acceso a esas acciones.
/// 
/// NO existe una tabla `roles_permisos` - todo se maneja a través de `permisos`.
class AsignarPermisosRequest {
  /// ID del rol al que se le asignarán los programas
  final int idRol;
  
  /// Lista de IDs de programas (acciones) que se asignarán al rol
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

/// Actualizar programa
class UpdateProgramaRequest {
  final String? nombre;
  final String? descripcion;
  final int? idAplicacion;

  UpdateProgramaRequest({
    this.nombre,
    this.descripcion,
    this.idAplicacion,
  });

  Map<String, dynamic> toJson() {
    return {
      if (nombre != null) 'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (idAplicacion != null) 'id_aplicacion': idAplicacion,
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

/// Actualizar aplicación
class UpdateAplicacionRequest {
  final String? nombre;
  final String? descripcion;
  final int? idModulo;

  UpdateAplicacionRequest({
    this.nombre,
    this.descripcion,
    this.idModulo,
  });

  Map<String, dynamic> toJson() {
    return {
      if (nombre != null) 'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (idModulo != null) 'id_modulo': idModulo,
    };
  }
}

/// Actualizar módulo
class UpdateModuloRequest {
  final String? nombre;
  final String? descripcion;

  UpdateModuloRequest({
    this.nombre,
    this.descripcion,
  });

  Map<String, dynamic> toJson() {
    return {
      if (nombre != null) 'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
    };
  }
}

/// Crear usuario (admin)
class CreateUsuarioRequest {
  final String email;
  final String nombres;
  final String apellidos;
  final int ci;
  final int telefono;
  final String? sexo;

  CreateUsuarioRequest({
    required this.email,
    required this.nombres,
    required this.apellidos,
    required this.ci,
    required this.telefono,
    this.sexo,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'nombres': nombres,
      'apellidos': apellidos,
      'ci': ci,
      'telefono': telefono,
      if (sexo != null) 'sexo': sexo,
    };
  }
}

/// Actualizar usuario (admin)
class UpdateUsuarioRequest {
  final String? email;
  final String? nombres;
  final String? apellidos;
  final int? ci;
  final int? telefono;
  final String? sexo;

  UpdateUsuarioRequest({
    this.email,
    this.nombres,
    this.apellidos,
    this.ci,
    this.telefono,
    this.sexo,
  });

  Map<String, dynamic> toJson() {
    return {
      if (email != null) 'email': email,
      if (nombres != null) 'nombres': nombres,
      if (apellidos != null) 'apellidos': apellidos,
      if (ci != null) 'ci': ci,
      if (telefono != null) 'telefono': telefono,
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
