import 'package:flutter_modular/flutter_modular.dart';
import 'pages/organizaciones_explore_page.dart';
import 'pages/organizacion_detail_page.dart';
import 'pages/proyectos_explore_page.dart';
import 'pages/proyecto_detail_voluntario_page.dart';
import 'pages/participaciones_page.dart';
import 'pages/mis_tareas_page.dart';
import 'pages/tarea_detail_page.dart';

class VoluntarioModule extends Module {
  @override
  List<ModularRoute> get routes => [
    // Organizaciones
    ChildRoute(
      '/organizaciones',
      child: (_, __) => const OrganizacionesExplorePage(),
    ),
    ChildRoute(
      '/organizaciones/:id',
      child: (_, args) =>
          OrganizacionDetailPage(organizacionId: int.parse(args.params['id'])),
    ),

    // Proyectos
    ChildRoute('/proyectos', child: (_, __) => const ProyectosExplorePage()),
    ChildRoute(
      '/proyectos/:id',
      child: (_, args) => ProyectoDetailVoluntarioPage(
        proyectoId: int.parse(args.params['id']),
      ),
    ),

    // Participaciones
    ChildRoute(
      '/participaciones',
      child: (_, __) => const ParticipacionesPage(),
    ),
    ChildRoute(
      '/participaciones/:id',
      child: (_, args) =>
          const ParticipacionesPage(), // TODO: Crear página de detalle
    ),

    // Mis tareas
    ChildRoute('/tareas', child: (_, __) => const MisTareasPage()),
    ChildRoute(
      '/tareas/:tareaId',
      child: (_, args) =>
          TareaDetailPage(tareaId: int.parse(args.params['tareaId'])),
    ),
  ];
}
