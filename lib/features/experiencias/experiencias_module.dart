import 'package:flutter_modular/flutter_modular.dart';
import 'pages/experiencias_page.dart';

class ExperienciasModule extends Module {
  @override
  List<Bind> get binds => [];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (_, __) => const ExperienciasPage()),
  ];
}
