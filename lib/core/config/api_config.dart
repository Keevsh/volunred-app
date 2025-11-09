class ApiConfig {
  // URL base del backend
  // static const String baseUrl = 'http://localhost:3000';

  // static const String baseUrl= 'http://192.168.26.3:3000';


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
  static const String aptitudesVoluntario = '/configuracion/aptitudes-voluntario';

  // Endpoints de experiencias
  static const String experienciasVoluntario = '/perfiles/experiencias-voluntario';
  
  // Endpoints de administración (solo admin)
  static const String perfilesUsuarios = '/perfiles/usuarios';
  static const String adminRoles = '/administracion/roles';
  static const String adminPermisos = '/administracion/permisos';
  static const String adminProgramas = '/administracion/programas';
  static const String adminModulos = '/administracion/modulos';
  static const String adminAplicaciones = '/administracion/aplicaciones';
  static const String adminAsignarRol = '/administracion/roles/asignar-rol-usuario';
  static const String adminAsignarPermisos = '/administracion/roles/asignar-permisos';

  // Endpoints de categorías
  static const String categoriasOrganizaciones = '/configuracion/categorias-organizaciones';
  static const String categoriasProyectos = '/informacion/categorias-proyectos'; // Legacy
  static const String categorias = '/configuracion/categorias'; // Endpoint correcto para categorías de proyectos
  
  // Endpoints de organizaciones
  static const String organizaciones = '/configuracion/organizaciones';
  
  // Endpoints de perfiles
  static const String perfilesFuncionarios = '/perfiles/perfiles-funcionarios';
  
  // Endpoints de información (proyectos, tareas, inscripciones, etc.)
  static const String proyectos = '/informacion/proyectos';
  static const String tareas = '/informacion/tareas';
  static const String inscripciones = '/informacion/inscripciones';
  static const String participaciones = '/informacion/participaciones';
  static const String calificacionesProyectos = '/informacion/calificaciones-proyectos';
  static const String asignacionesTareas = '/informacion/asignaciones-tareas';
  static const String evidencias = '/informacion/evidencias';
  static const String archivosDigitales = '/informacion/archivos-digitales';
  static const String opiniones = '/informacion/opiniones';
  
  // Endpoints de bitácoras
  static const String bitacorasOperaciones = '/administracion/bitacoras-operaciones';
  static const String bitacorasAutores = '/administracion/bitacoras-autores';
  
  // ==================== ENDPOINTS ESPECÍFICOS DE FUNCIONARIOS ====================
  // Base path para endpoints de funcionarios (filtran automáticamente por organización)
  static const String funcionariosBase = '/funcionarios';
  
  // Dashboard y Organización
  static const String funcionariosDashboard = '$funcionariosBase/dashboard';
  static const String funcionariosMiOrganizacion = '$funcionariosBase/mi-organizacion';
  static const String funcionariosMiPerfil = '$funcionariosBase/mi-perfil';
  
  // Proyectos
  static const String funcionariosProyectos = '$funcionariosBase/proyectos';
  static String funcionariosProyecto(int id) => '$funcionariosProyectos/$id';
  
  // Tareas
  static String funcionariosTareasProyecto(int proyectoId) => '$funcionariosProyectos/$proyectoId/tareas';
  static const String funcionariosTareas = '$funcionariosBase/tareas';
  static String funcionariosTarea(int id) => '$funcionariosTareas/$id';
  static String funcionariosAsignacionesTarea(int tareaId) => '$funcionariosTareas/$tareaId/asignaciones';
  static String funcionariosAsignarVoluntarioTarea(int tareaId) => '$funcionariosTareas/$tareaId/asignar-voluntario';
  
  // Inscripciones
  static const String funcionariosInscripciones = '$funcionariosBase/inscripciones';
  static const String funcionariosInscripcionesPendientes = '$funcionariosInscripciones/pendientes';
  static String funcionariosInscripcion(int id) => '$funcionariosInscripciones/$id';
  static String funcionariosAprobarInscripcion(int id) => '$funcionariosInscripciones/$id/aprobar';
  static String funcionariosRechazarInscripcion(int id) => '$funcionariosInscripciones/$id/rechazar';
  
  // Participaciones
  static const String funcionariosParticipaciones = '$funcionariosBase/participaciones';
  static String funcionariosParticipacion(int id) => '$funcionariosParticipaciones/$id';
  static String funcionariosParticipacionesProyecto(int proyectoId) => '$funcionariosProyectos/$proyectoId/participaciones';
  
  // Asignaciones de Tareas
  static const String funcionariosAsignacionesTareas = '$funcionariosBase/asignaciones-tareas';
  
  // Timeouts
  static const int connectTimeout = 30000; // 30 segundos
  static const int receiveTimeout = 30000;
  
  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String usuarioKey = 'usuario';
  static const String perfilVoluntarioKey = 'perfil_voluntario';
  static const String perfilFuncionarioKey = 'perfil_funcionario';
  static const String tienePerfilFuncionarioKey = 'tiene_perfil_funcionario'; // Flag simple
}
