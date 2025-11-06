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
  static const String usuarios = '/usuarios';
  
  // Endpoints de perfiles voluntarios
  static const String perfilesVoluntarios = '/perfiles-voluntarios';
  
  // Endpoints de aptitudes
  static const String aptitudes = '/aptitudes';
  static const String aptitudesVoluntario = '/aptitudes-voluntario';
  
  // Endpoints de experiencias
  static const String experienciasVoluntario = '/experiencias-voluntario';
  
  // Endpoints de administración (solo admin)
  static const String perfilesUsuarios = '/usuarios';
  static const String adminRoles = '/administracion/roles';
  static const String adminPermisos = '/administracion/permisos';
  static const String adminProgramas = '/administracion/programas';
  static const String adminModulos = '/administracion/modulos';
  static const String adminAplicaciones = '/administracion/aplicaciones';
  static const String adminAsignarRol = '/administracion/roles/asignar-rol-usuario';
  static const String adminAsignarPermisos = '/administracion/roles/asignar-permisos';

  // Endpoints de categorías
  static const String categoriasOrganizaciones = '/categorias-organizaciones';
  static const String categoriasProyectos = '/categorias-proyectos';
  
  // Endpoints de organizaciones
  static const String organizaciones = '/configuracion/organizaciones';
  
  // Endpoints de perfiles
  static const String perfilesFuncionarios = '/perfiles/perfiles-funcionarios';
  
  // Timeouts
  static const int connectTimeout = 30000; // 30 segundos
  static const int receiveTimeout = 30000;
  
  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String usuarioKey = 'usuario';
  static const String perfilVoluntarioKey = 'perfil_voluntario';
}
