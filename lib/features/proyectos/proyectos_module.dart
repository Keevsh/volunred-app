import 'package:flutter_modular/flutter_modular.dart';
import 'pages/create_proyecto_page.dart';
import 'pages/proyecto_detail_page.dart';

class ProyectosModule extends Module {
  @override
  List<Bind> get binds => [];

  @override
  List<ModularRoute> get routes => [
        ChildRoute(
          '/create',
          child: (_, __) => const CreateProyectoPage(),
        ),
        ChildRoute(
          '/:id',
          child: (_, args) => ProyectoDetailPage(
            proyectoId: int.parse(args.params['id']!),
          ),
        ),
      ];
}

