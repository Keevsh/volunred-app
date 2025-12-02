import 'package:flutter_modular/flutter_modular.dart';
import 'pages/create_proyecto_page.dart';
import 'pages/proyecto_detail_page.dart';
import 'pages/tareas_management_page.dart';
import 'pages/tareas_kanban_page.dart';
import 'pages/tarea_detail_page.dart';
import 'pages/asignar_voluntarios_page.dart';

class ProyectosModule extends Module {
  @override
  List<Bind> get binds => [];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/create', child: (_, __) => const CreateProyectoPage()),
    ChildRoute(
      '/:id',
      child: (_, args) =>
          ProyectoDetailPage(proyectoId: int.parse(args.params['id']!)),
    ),
    ChildRoute(
      '/:id/tareas',
      child: (_, args) =>
          TareasManagementPage(proyectoId: int.parse(args.params['id']!)),
    ),
    ChildRoute(
      '/:id/tareas-kanban',
      child: (_, args) => TareasKanbanPage(
        proyectoId: int.parse(args.params['id']!),
        isFuncionario: args.queryParams['role'] == 'funcionario',
      ),
    ),
    ChildRoute(
      '/tarea/:tareaId',
      child: (_, args) => TareaDetailPage(
        tareaId: int.parse(args.params['tareaId']!),
        isFuncionario: args.queryParams['role'] == 'funcionario',
      ),
    ),
    ChildRoute(
      '/tarea/:tareaId/asignar-voluntarios',
      child: (_, args) => AsignarVoluntariosPage(
        tareaId: int.parse(args.params['tareaId']!),
        tareaNombre: args.queryParams['nombre'] ?? 'Tarea',
      ),
    ),
  ];
}
