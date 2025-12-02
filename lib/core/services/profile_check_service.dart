import 'package:flutter_modular/flutter_modular.dart';
import '../models/usuario.dart';
import '../models/dto/response_models.dart';
import '../repositories/organizacion_repository.dart';
import '../repositories/voluntario_repository.dart';

/// Servicio para verificar si un usuario tiene el perfil requerido según su rol
class ProfileCheckService {
  final OrganizacionRepository _orgRepo;
  final VoluntarioRepository _volRepo;

  ProfileCheckService(this._orgRepo, this._volRepo);

  /// Verifica si el usuario tiene el perfil requerido según su rol
  /// Retorna null si tiene el perfil, o la ruta a la que debe redirigirse si no lo tiene
  ///
  /// Si se proporciona authResponse, usa los perfiles del login (más eficiente)
  /// Si no, hace llamadas adicionales a la API
  Future<String?> checkProfileRequired(
    Usuario usuario, {
    AuthResponse? authResponse,
  }) async {
    // Si tenemos la respuesta del login, usar los perfiles directamente
    if (authResponse != null) {
      print('📋 Usando perfiles del login response');
      return authResponse.rutaRedireccion;
    }

    // Si no tenemos la respuesta del login, hacer llamadas a la API (fallback)
    print('📋 Verificando perfiles mediante llamadas API');

    // Admin no necesita perfil
    if (usuario.isAdmin) {
      print('✅ Usuario admin - no requiere perfil');
      return null; // Puede ir al admin
    }

    // Funcionario necesita PerfilFuncionario
    if (usuario.isFuncionario) {
      print(
        '🔍 Verificando perfil de funcionario para usuario ${usuario.idUsuario}...',
      );
      try {
        final perfil = await _orgRepo.getPerfilFuncionarioByUsuario(
          usuario.idUsuario,
        );
        if (perfil != null) {
          print(
            '✅ Usuario funcionario tiene perfil: ${perfil.idPerfilFuncionario}',
          );
          return null; // Tiene perfil, puede ir al home
        } else {
          print(
            '⚠️ Usuario funcionario NO tiene perfil - necesita configurar organización',
          );
          return '/profile/funcionario-options'; // Necesita elegir opción de organización
        }
      } catch (e) {
        print('❌ Error verificando perfil de funcionario: $e');
        // Si hay error, asumimos que no tiene perfil
        return '/profile/funcionario-options';
      }
    }

    // Voluntario necesita PerfilVoluntario
    if (usuario.isVoluntario) {
      print(
        '🔍 Verificando perfil de voluntario para usuario ${usuario.idUsuario}...',
      );
      try {
        final perfil = await _volRepo.getPerfilByUsuario(usuario.idUsuario);
        if (perfil != null) {
          print(
            '✅ Usuario voluntario tiene perfil: ${perfil.idPerfilVoluntario}',
          );
          return null; // Tiene perfil, puede ir al home
        } else {
          print(
            '⚠️ Usuario voluntario NO tiene perfil - necesita crear perfil',
          );
          return '/profile/create'; // Necesita crear perfil
        }
      } catch (e) {
        print('❌ Error verificando perfil de voluntario: $e');
        // Si hay error, asumimos que no tiene perfil
        return '/profile/create';
      }
    }

    // Si no tiene rol definido, no sabemos qué hacer
    print('⚠️ Usuario sin rol definido: ${usuario.idRol}');
    return null;
  }

  /// Método estático para uso rápido con respuesta de login
  static String? checkProfileFromLogin(AuthResponse authResponse) {
    return authResponse.rutaRedireccion;
  }

  /// Método estático para uso rápido sin respuesta de login (hace llamadas API)
  static Future<String?> checkProfile(Usuario usuario) async {
    final orgRepo = Modular.get<OrganizacionRepository>();
    final volRepo = Modular.get<VoluntarioRepository>();
    final service = ProfileCheckService(orgRepo, volRepo);
    return await service.checkProfileRequired(usuario);
  }
}
