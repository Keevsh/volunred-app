import '../usuario.dart';
import '../perfil_voluntario.dart';
import '../perfil_funcionario.dart';

class AuthResponse {
  final String message;
  final Usuario usuario;
  final PerfilVoluntario? perfilVoluntario;
  final PerfilFuncionario? perfilFuncionario;
  final String accessToken;
  final bool
  tienePerfilFuncionarioRaw; // Indica si el JSON del perfil existe (aunque no se pudo parsear)

  AuthResponse({
    required this.message,
    required this.usuario,
    this.perfilVoluntario,
    this.perfilFuncionario,
    required this.accessToken,
    this.tienePerfilFuncionarioRaw = false,
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
    bool tienePerfilRaw = false;

    if (json['perfilFuncionario'] != null && json['perfilFuncionario'] is Map) {
      tienePerfilRaw = true; // El JSON del perfil existe
      final perfilJson = json['perfilFuncionario'] as Map<String, dynamic>;

      print('🔍 Intentando parsear perfilFuncionario...');
      print('🔍 Keys disponibles: ${perfilJson.keys.toList()}');

      try {
        perfilFunc = PerfilFuncionario.fromJson(perfilJson);
        print(
          '✅ PerfilFuncionario parseado correctamente: ID=${perfilFunc.idPerfilFuncionario}, Organización=${perfilFunc.idOrganizacion}, Usuario=${perfilFunc.idUsuario}',
        );
      } catch (e, stackTrace) {
        print('❌ Error parseando perfilFuncionario: $e');
        print('❌ JSON del perfil: $perfilJson');
        print('❌ StackTrace: $stackTrace');

        // Intentar reparar el JSON normalizando los nombres de campos
        try {
          print('🔧 Intentando reparar JSON del perfil...');
          final perfilJsonReparado = Map<String, dynamic>.from(perfilJson);

          // Normalizar nombres de campos: si existe usuario_id, también crear id_usuario
          if (perfilJsonReparado.containsKey('usuario_id') &&
              !perfilJsonReparado.containsKey('id_usuario')) {
            perfilJsonReparado['id_usuario'] = perfilJsonReparado['usuario_id'];
            print(
              '✅ Agregado id_usuario desde usuario_id: ${perfilJsonReparado['id_usuario']}',
            );
          }
          // Normalizar organizacion_id
          if (perfilJsonReparado.containsKey('organizacion_id') &&
              !perfilJsonReparado.containsKey('id_organizacion')) {
            perfilJsonReparado['id_organizacion'] =
                perfilJsonReparado['organizacion_id'];
            print(
              '✅ Agregado id_organizacion desde organizacion_id: ${perfilJsonReparado['id_organizacion']}',
            );
          }
          // Normalizar id_funcionario
          if (perfilJsonReparado.containsKey('id_funcionario') &&
              !perfilJsonReparado.containsKey('id_perfil_funcionario')) {
            perfilJsonReparado['id_perfil_funcionario'] =
                perfilJsonReparado['id_funcionario'];
            print(
              '✅ Agregado id_perfil_funcionario desde id_funcionario: ${perfilJsonReparado['id_perfil_funcionario']}',
            );
          }

          // Intentar parsear de nuevo con el JSON reparado
          perfilFunc = PerfilFuncionario.fromJson(perfilJsonReparado);
          print(
            '✅ PerfilFuncionario parseado correctamente después de reparar JSON: ID=${perfilFunc.idPerfilFuncionario}',
          );
        } catch (e2, stackTrace2) {
          print(
            '❌ Error persistente al parsear perfilFuncionario incluso después de reparar: $e2',
          );
          print('❌ StackTrace2: $stackTrace2');
          // Si aún falla después de reparar, dejamos perfilFunc como null
          // Pero tenemos tienePerfilRaw = true para indicar que el perfil existe en el backend
        }
      }
    }

    return AuthResponse(
      message: json['message'] as String,
      usuario: Usuario.fromJson(json['usuario'] as Map<String, dynamic>),
      perfilVoluntario: perfilVol,
      perfilFuncionario: perfilFunc,
      accessToken: json['access_token'] as String,
      tienePerfilFuncionarioRaw: tienePerfilRaw,
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
      // Si tenemos el perfil parseado, no redirigir
      if (perfilFuncionario != null) {
        return null; // Tiene perfil, puede ir al home
      }

      // Si el JSON del perfil existe pero no se pudo parsear, asumimos que el perfil existe
      // y no redirigimos (para evitar redirecciones incorrectas)
      if (tienePerfilFuncionarioRaw) {
        print(
          '⚠️ PerfilFuncionario existe en respuesta pero no se pudo parsear. Asumiendo que el perfil existe y no redirigiendo.',
        );
        return null; // El perfil existe, aunque no se pudo parsear completamente
      }

      // Solo redirigir si realmente no hay perfil en la respuesta
      return '/profile/funcionario-options'; // Necesita elegir opción de organización
    }

    return null;
  }
}
