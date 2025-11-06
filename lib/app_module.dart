import 'package:flutter_modular/flutter_modular.dart';
import 'core/services/dio_client.dart';
import 'core/repositories/auth_repository.dart';
import 'core/repositories/voluntario_repository.dart';
import 'core/repositories/admin_repository.dart';
import 'core/repositories/organizacion_repository.dart';
import 'features/auth/auth_module.dart';
import 'features/auth/pages/welcome_page.dart';
import 'features/profile/profile_module.dart';
import 'features/home/home_module.dart';
import 'features/experiencias/experiencias_module.dart';
import 'features/admin/admin_module.dart';

class AppModule extends Module {
  @override
  List<Bind> get binds => [
        // Services
        Bind.singleton((i) => DioClient()),
        
        // Repositories
        Bind.singleton((i) => AuthRepository(i<DioClient>())),
        Bind.singleton((i) => VoluntarioRepository(i<DioClient>())),
        Bind.singleton((i) => AdminRepository(i<DioClient>())),
        Bind.singleton((i) => OrganizacionRepository(i<DioClient>())),
      ];

  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (_, __) => const WelcomePage()),
        ModuleRoute('/auth', module: AuthModule()),
        ModuleRoute('/profile', module: ProfileModule()),
        ModuleRoute('/home', module: HomeModule()),
        ModuleRoute('/experiencias', module: ExperienciasModule()),
        ModuleRoute('/admin', module: AdminModule()),
      ];
}
