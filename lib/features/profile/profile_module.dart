import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/repositories/voluntario_repository.dart';
import 'bloc/profile_bloc.dart';
import 'pages/create_profile_page.dart';
import 'pages/create_funcionario_profile_page.dart';
import 'pages/select_aptitudes_page.dart';
import 'pages/create_organizacion_page.dart';

class ProfileModule extends Module {
  @override
  List<Bind> get binds => [
        Bind.factory((i) => ProfileBloc(i<VoluntarioRepository>())),
      ];

  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/create',
          child: (_, __) => BlocProvider(
            create: (_) => Modular.get<ProfileBloc>(),
            child: const CreateProfilePage(),
          ),
        ),
        ChildRoute(
          '/create-funcionario',
          child: (_, __) => const CreateFuncionarioProfilePage(),
        ),
        ChildRoute(
          '/create-organizacion',
          child: (_, __) => const CreateOrganizacionPage(),
        ),
        ChildRoute(
          '/aptitudes',
          child: (_, __) => BlocProvider(
            create: (_) => Modular.get<ProfileBloc>(),
            child: const SelectAptitudesPage(),
          ),
        ),
      ];
}
