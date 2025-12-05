class ApiConfig {
  // URL base del backend
  // static const String baseUrl = 'http://localhost:3000';

  // static const String baseUrl= 'http://192.168.0.56:3000';

  static const String baseUrl = 'https://volunred-backend.vercel.app';

  // static const String baseUrl = 'http://10.172.90.187:3000';

  // Endpoints de autenticación
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authProfile = '/auth/profile';
  static const String authMe = '/auth/me';

  // Endpoints de usuarios
  static const String usuarios = '/perfiles/usuarios';

  // Endpoints de perfiles voluntarios
  static const String perfilesVoluntarios = '/perfiles/perfiles-voluntarios';

  // Endpoints de aptitudes
  static const String aptitudes = '/configuracion/aptitudes';
  static const String aptitudesVoluntario =
      '/configuracion/aptitudes-voluntario';
  static String aptitudesVoluntarioByVoluntario(int perfilVolId) =>
      '/configuracion/aptitudes-voluntario/voluntario/$perfilVolId';

  // Endpoints de experiencias
  static const String experienciasVoluntario =
      '/perfiles/experiencias-voluntario';

  // Endpoints de administración (solo admin)
  static const String perfilesUsuarios = '/perfiles/usuarios';
  static const String adminRoles = '/administracion/roles';
  static const String adminPermisos = '/administracion/permisos';
  static const String adminProgramas = '/administracion/programas';
  static const String adminModulos = '/administracion/modulos';
  static const String adminAplicaciones = '/administracion/aplicaciones';
  static const String adminAsignarRol =
      '/administracion/roles/asignar-rol-usuario';
  static const String adminAsignarPermisos =
      '/administracion/roles/asignar-permisos';

  // Endpoints de categorías
  static const String categoriasOrganizaciones = '/configuracion/categorias';
  static const String categoriasProyectos =
      '/informacion/categorias-proyectos'; // Legacy
  static const String categorias =
      '/configuracion/categorias'; // Endpoint correcto para categorías de proyectos

  // Endpoints de organizaciones
  static const String organizaciones = '/configuracion/organizaciones';

  // Endpoints de perfiles
  static const String perfilesFuncionarios = '/perfiles/perfiles-funcionarios';
    static String perfilFuncionarioByUsuario(int usuarioId) =>
            '$perfilesFuncionarios/usuario/$usuarioId';

  // Endpoints de información (proyectos, tareas, inscripciones, etc.)
  static const String proyectos = '/informacion/proyectos';
  static String proyecto(int id) => '$proyectos/$id';
  static const String tareas = '/informacion/tareas';
  static String tarea(int id) => '$tareas/$id';
  static const String inscripciones = '/informacion/inscripciones';
  static String inscripcion(int id) => '$inscripciones/$id';
  static const String participaciones = '/informacion/participaciones';
  static String participacion(int id) => '$participaciones/$id';
  static const String calificacionesProyectos =
      '/informacion/calificaciones-proyectos';
  static String calificacionProyecto(int id) => '$calificacionesProyectos/$id';
  static const String asignacionesTareas = '/informacion/asignaciones-tareas';
  static String asignacionTarea(int id) => '$asignacionesTareas/$id';
  static const String evidencias = '/informacion/evidencias';
  // Opiniones eliminadas del backend (02-12-2025)

  // Endpoints de voluntarios (voluntario autenticado)
  static const String voluntariosBase = '/voluntarios';

  // Dashboard
  static const String voluntariosDashboard = '$voluntariosBase/dashboard';

  // Proyectos del voluntario
  static const String voluntariosMyProyectos = '$voluntariosBase/my/proyectos';
  static String voluntariosMyProyecto(int proyectoId) =>
      '$voluntariosMyProyectos/$proyectoId';
  static String voluntariosMyProyectoTareas(int proyectoId) =>
      '$voluntariosMyProyectos/$proyectoId/tareas';

  // Tareas del voluntario
  static const String voluntariosMyTasks = '$voluntariosBase/my/tasks';
  static String voluntariosMyTask(int tareaId) =>
      '$voluntariosMyTasks/$tareaId';
  static String voluntariosMyTaskStatus(int tareaId) =>
      '$voluntariosMyTasks/$tareaId/status';
  static String voluntariosMyTaskEvidences(int tareaId) =>
      '$voluntariosMyTasks/$tareaId/evidences';

  // Participaciones del voluntario
  static const String voluntariosMyParticipaciones =
      '$voluntariosBase/my/participaciones';
  static String voluntariosMyParticipacion(int id) =>
      '$voluntariosMyParticipaciones/$id';

  // ==================== ENDPOINTS ESPECÍFICOS DE FUNCIONARIOS ====================
  // Base path para endpoints de funcionarios (filtran automáticamente por organización)
  static const String funcionariosBase = '/funcionarios';

  // Dashboard y Organización
  static const String funcionariosDashboard = '$funcionariosBase/dashboard';
  static const String funcionariosMiOrganizacion =
      '$funcionariosBase/mi-organizacion';
  static const String funcionariosMiPerfil = '$funcionariosBase/mi-perfil';

  // Proyectos
  static const String funcionariosProyectos = '$funcionariosBase/proyectos';
  static String funcionariosProyecto(int id) => '$funcionariosProyectos/$id';

  // Tareas
  static String funcionariosTareasProyecto(int proyectoId) =>
      '$funcionariosProyectos/$proyectoId/tareas';
  static const String funcionariosTareas = '$funcionariosBase/tareas';
  static String funcionariosTarea(int id) => '$funcionariosTareas/$id';
  static String funcionariosAsignacionesTarea(int tareaId) =>
      '$funcionariosTareas/$tareaId/asignaciones';
  static String funcionariosAsignarVoluntarioTarea(int tareaId) =>
      '$funcionariosTareas/$tareaId/asignar-voluntario';

  // Inscripciones
  static const String funcionariosInscripciones =
      '$funcionariosBase/inscripciones';
  static const String funcionariosInscripcionesPendientes =
      '$funcionariosInscripciones/pendientes';
  static String funcionariosInscripcion(int id) =>
      '$funcionariosInscripciones/$id';
  static String funcionariosAprobarInscripcion(int id) =>
      '$funcionariosInscripciones/$id/aprobar';
  static String funcionariosRechazarInscripcion(int id) =>
      '$funcionariosInscripciones/$id/rechazar';

  // Participaciones
  static const String funcionariosParticipaciones =
      '$funcionariosBase/participaciones';
  static String funcionariosParticipacion(int id) =>
      '$funcionariosParticipaciones/$id';
  static String funcionariosParticipacionesProyecto(int proyectoId) =>
      '$funcionariosProyectos/$proyectoId/participaciones';

  // Asignaciones de Tareas
  static const String funcionariosAsignacionesTareas =
      '$funcionariosBase/asignaciones-tareas';

  // Timeouts (aumentados para manejar respuestas con imágenes base64)
  static const int connectTimeout = 30000; // 30 segundos
  static const int receiveTimeout =
      60000; // 60 segundos para respuestas grandes

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String usuarioKey = 'usuario';
  static const String perfilVoluntarioKey = 'perfil_voluntario';
  static const String perfilFuncionarioKey = 'perfil_funcionario';
  static const String tienePerfilFuncionarioKey =
      'tiene_perfil_funcionario'; // Flag simple
}
