import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/repositories/admin_repository.dart';
import 'bloc/admin_bloc.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/aptitudes_management_page.dart';
import 'pages/usuarios_management_page.dart';
import 'pages/roles_management_page.dart';
import 'pages/permisos_management_page.dart';
import 'pages/programas_management_page.dart';

class AdminModule extends Module {
  @override
  List<Bind> get binds => [
        Bind.factory((i) => AdminBloc(i<AdminRepository>())),
      ];

  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/',
          child: (_, __) => const AdminDashboardPage(),
        ),
        ChildRoute(
          '/usuarios',
          child: (_, __) => BlocProvider(
            create: (context) => AdminBloc(Modular.get<AdminRepository>()),
            child: const UsuariosManagementPage(),
          ),
        ),
        ChildRoute(
          '/roles',
          child: (_, __) => const RolesManagementPage(),
        ),
        ChildRoute(
          '/permisos',
          child: (_, __) => const PermisosManagementPage(),
        ),
        ChildRoute(
          '/programas',
          child: (_, __) => const ProgramasManagementPage(),
        ),
        ChildRoute(
          '/aptitudes',
          child: (_, __) => BlocProvider(
            create: (context) => AdminBloc(Modular.get<AdminRepository>()),
            child: const AptitudesManagementPage(),
          ),
        ),
      ];
}
