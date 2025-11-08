import '../usuario.dart';
import '../perfil_voluntario.dart';
import '../perfil_funcionario.dart';

class AuthResponse {
  final String message;
  final Usuario usuario;
  final PerfilVoluntario? perfilVoluntario;
  final PerfilFuncionario? perfilFuncionario;
  final String accessToken;

  AuthResponse({
    required this.message,
    required this.usuario,
    this.perfilVoluntario,
    this.perfilFuncionario,
    required this.accessToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Parsear perfil de voluntario si existe
    PerfilVoluntario? perfilVol;
    if (json['perfilVoluntario'] != null && json['perfilVoluntario'] is Map) {
      try {
        perfilVol = PerfilVoluntario.fromJson(
          json['perfilVoluntario'] as Map<String, dynamic>,
        );
      } catch (e) {
        print('⚠️ Error parseando perfilVoluntario: $e');
      }
    }

    // Parsear perfil de funcionario si existe
    PerfilFuncionario? perfilFunc;
    if (json['perfilFuncionario'] != null && json['perfilFuncionario'] is Map) {
      try {
        perfilFunc = PerfilFuncionario.fromJson(
          json['perfilFuncionario'] as Map<String, dynamic>,
        );
      } catch (e) {
        print('⚠️ Error parseando perfilFuncionario: $e');
      }
    }

    return AuthResponse(
      message: json['message'] as String,
      usuario: Usuario.fromJson(json['usuario'] as Map<String, dynamic>),
      perfilVoluntario: perfilVol,
      perfilFuncionario: perfilFunc,
      accessToken: json['access_token'] as String,
    );
  }

  // Helpers para determinar el tipo de usuario
  bool get esVoluntario => usuario.idRol == 3;
  bool get esFuncionario => usuario.idRol == 2;
  bool get esAdmin => usuario.idRol == 1;
  bool get tienePerfil => perfilVoluntario != null || perfilFuncionario != null;

  // Para voluntarios: verificar si tiene organización aprobada
  bool get tieneOrganizacionAprobada {
    if (esVoluntario && perfilVoluntario != null) {
      return perfilVoluntario!.organizacion != null;
    }
    return false;
  }

  // Obtener la ruta a la que debe redirigirse según su estado
  String? get rutaRedireccion {
    if (esAdmin) {
      return null; // Admin va a /admin/
    }

    if (esVoluntario) {
      if (perfilVoluntario == null) {
        return '/profile/create'; // Necesita crear perfil
      }
      // Si tiene perfil, puede ir al home
      return null;
    }

    if (esFuncionario) {
      if (perfilFuncionario == null) {
        return '/profile/create-organizacion'; // Necesita crear organización/perfil
      }
      // Si tiene perfil, puede ir al home
      return null;
    }

    return null;
  }
}
