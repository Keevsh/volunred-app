import 'package:equatable/equatable.dart';
import '../../../core/models/aplicacion.dart';
import '../../../core/models/aptitud.dart';
import '../../../core/models/modulo.dart';
import '../../../core/models/permiso.dart';
import '../../../core/models/programa.dart';
import '../../../core/models/rol.dart';
import '../../../core/models/usuario.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminError extends AdminState {
  final String message;

  const AdminError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== USUARIOS ====================

class UsuariosLoaded extends AdminState {
  final List<Usuario> usuarios;
  final int total;
  final int page;
  final int limit;

  const UsuariosLoaded({
    required this.usuarios,
    required this.total,
    required this.page,
    required this.limit,
  });

  @override
  List<Object?> get props => [usuarios, total, page, limit];
}

class UsuarioLoaded extends AdminState {
  final Usuario usuario;

  const UsuarioLoaded(this.usuario);

  @override
  List<Object?> get props => [usuario];
}

class UsuarioDeleted extends AdminState {
  final String message;

  const UsuarioDeleted(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== ROLES ====================

class RolesLoaded extends AdminState {
  final List<Rol> roles;

  const RolesLoaded(this.roles);

  @override
  List<Object?> get props => [roles];
}

class RolLoaded extends AdminState {
  final Rol rol;

  const RolLoaded(this.rol);

  @override
  List<Object?> get props => [rol];
}

class RolCreated extends AdminState {
  final Rol rol;

  const RolCreated(this.rol);

  @override
  List<Object?> get props => [rol];
}

class RolDeleted extends AdminState {
  final String message;

  const RolDeleted(this.message);

  @override
  List<Object?> get props => [message];
}

class RolAsignado extends AdminState {
  final Usuario usuario;
  final String message;

  const RolAsignado({required this.usuario, required this.message});

  @override
  List<Object?> get props => [usuario, message];
}

// ==================== PERMISOS ====================

class PermisosLoaded extends AdminState {
  final List<Permiso> permisos;

  const PermisosLoaded(this.permisos);

  @override
  List<Object?> get props => [permisos];
}

class PermisosByRolLoaded extends AdminState {
  final Rol rol;
  final List<Permiso> permisos;
  final int total;

  const PermisosByRolLoaded({
    required this.rol,
    required this.permisos,
    required this.total,
  });

  @override
  List<Object?> get props => [rol, permisos, total];
}

class PermisosAsignados extends AdminState {
  final String message;

  const PermisosAsignados(this.message);

  @override
  List<Object?> get props => [message];
}

class PermisoDeleted extends AdminState {
  final String message;

  const PermisoDeleted(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== PROGRAMAS ====================

class ProgramasLoaded extends AdminState {
  final List<Programa> programas;

  const ProgramasLoaded(this.programas);

  @override
  List<Object?> get props => [programas];
}

class ProgramaCreated extends AdminState {
  final Programa programa;

  const ProgramaCreated(this.programa);

  @override
  List<Object?> get props => [programa];
}

// ==================== MÓDULOS Y APLICACIONES ====================

class ModulosLoaded extends AdminState {
  final List<Modulo> modulos;

  const ModulosLoaded(this.modulos);

  @override
  List<Object?> get props => [modulos];
}

class AplicacionesLoaded extends AdminState {
  final List<Aplicacion> aplicaciones;

  const AplicacionesLoaded(this.aplicaciones);

  @override
  List<Object?> get props => [aplicaciones];
}

class AplicacionCreated extends AdminState {
  final Aplicacion aplicacion;

  const AplicacionCreated(this.aplicacion);

  @override
  List<Object?> get props => [aplicacion];
}

// ==================== APTITUDES ====================

class AptitudesLoaded extends AdminState {
  final List<Aptitud> aptitudes;

  const AptitudesLoaded(this.aptitudes);

  @override
  List<Object?> get props => [aptitudes];
}

class AptitudLoaded extends AdminState {
  final Aptitud aptitud;

  const AptitudLoaded(this.aptitud);

  @override
  List<Object?> get props => [aptitud];
}

class AptitudCreated extends AdminState {
  final Aptitud aptitud;

  const AptitudCreated(this.aptitud);

  @override
  List<Object?> get props => [aptitud];
}

class AptitudUpdated extends AdminState {
  final Aptitud aptitud;

  const AptitudUpdated(this.aptitud);

  @override
  List<Object?> get props => [aptitud];
}

class AptitudDeleted extends AdminState {
  final String message;

  const AptitudDeleted(this.message);

  @override
  List<Object?> get props => [message];
}
