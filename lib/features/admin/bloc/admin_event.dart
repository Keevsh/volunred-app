import 'package:equatable/equatable.dart';
import '../../../core/models/aplicacion.dart';
import '../../../core/models/modulo.dart';
import '../../../core/models/permiso.dart';
import '../../../core/models/programa.dart';
import '../../../core/models/rol.dart';
import '../../../core/models/usuario.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

// ==================== USUARIOS ====================

class LoadUsuariosRequested extends AdminEvent {
  final int? page;
  final int? limit;
  final String? email;

  const LoadUsuariosRequested({this.page, this.limit, this.email});

  @override
  List<Object?> get props => [page, limit, email];
}

class LoadUsuarioByIdRequested extends AdminEvent {
  final int id;

  const LoadUsuarioByIdRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateUsuarioRequested extends AdminEvent {
  final String email;
  final String nombres;
  final String apellidos;
  final int ci;
  final int telefono;
  final String? sexo;

  const CreateUsuarioRequested({
    required this.email,
    required this.nombres,
    required this.apellidos,
    required this.ci,
    required this.telefono,
    this.sexo,
  });

  @override
  List<Object?> get props => [email, nombres, apellidos, ci, telefono, sexo];
}

class UpdateUsuarioRequested extends AdminEvent {
  final int id;
  final String? email;
  final String? nombres;
  final String? apellidos;
  final int? ci;
  final int? telefono;
  final String? sexo;

  const UpdateUsuarioRequested({
    required this.id,
    this.email,
    this.nombres,
    this.apellidos,
    this.ci,
    this.telefono,
    this.sexo,
  });

  @override
  List<Object?> get props => [id, email, nombres, apellidos, ci, telefono, sexo];
}

class DeleteUsuarioRequested extends AdminEvent {
  final int id;

  const DeleteUsuarioRequested(this.id);

  @override
  List<Object?> get props => [id];
}

// ==================== ROLES ====================

class LoadRolesRequested extends AdminEvent {}

class LoadRolByIdRequested extends AdminEvent {
  final int id;

  const LoadRolByIdRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateRolRequested extends AdminEvent {
  final String nombre;
  final String? descripcion;

  const CreateRolRequested({required this.nombre, this.descripcion});

  @override
  List<Object?> get props => [nombre, descripcion];
}

class DeleteRolRequested extends AdminEvent {
  final int id;

  const DeleteRolRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class AsignarRolRequested extends AdminEvent {
  final int idUsuario;
  final int idRol;

  const AsignarRolRequested({
    required this.idUsuario,
    required this.idRol,
  });

  @override
  List<Object?> get props => [idUsuario, idRol];
}

// ==================== PERMISOS ====================

class LoadPermisosRequested extends AdminEvent {}

class LoadPermisosByRolRequested extends AdminEvent {
  final int idRol;

  const LoadPermisosByRolRequested(this.idRol);

  @override
  List<Object?> get props => [idRol];
}

class AsignarPermisosRequested extends AdminEvent {
  final int idRol;
  final List<int> programas;

  const AsignarPermisosRequested({
    required this.idRol,
    required this.programas,
  });

  @override
  List<Object?> get props => [idRol, programas];
}

class DeletePermisoRequested extends AdminEvent {
  final int id;

  const DeletePermisoRequested(this.id);

  @override
  List<Object?> get props => [id];
}

// ==================== PROGRAMAS ====================

class LoadProgramasRequested extends AdminEvent {}

class CreateProgramaRequested extends AdminEvent {
  final String nombre;
  final String? descripcion;
  final int idAplicacion;

  const CreateProgramaRequested({
    required this.nombre,
    this.descripcion,
    required this.idAplicacion,
  });

  @override
  List<Object?> get props => [nombre, descripcion, idAplicacion];
}

class UpdateProgramaRequested extends AdminEvent {
  final int id;
  final String? nombre;
  final String? descripcion;
  final int? idAplicacion;

  const UpdateProgramaRequested({
    required this.id,
    this.nombre,
    this.descripcion,
    this.idAplicacion,
  });

  @override
  List<Object?> get props => [id, nombre, descripcion, idAplicacion];
}

class DeleteProgramaRequested extends AdminEvent {
  final int id;

  const DeleteProgramaRequested(this.id);

  @override
  List<Object?> get props => [id];
}

// ==================== MÓDULOS Y APLICACIONES ====================

class LoadModulosRequested extends AdminEvent {}

class UpdateModuloRequested extends AdminEvent {
  final int id;
  final String? nombre;
  final String? descripcion;

  const UpdateModuloRequested({
    required this.id,
    this.nombre,
    this.descripcion,
  });

  @override
  List<Object?> get props => [id, nombre, descripcion];
}

class LoadAplicacionesRequested extends AdminEvent {}

class CreateAplicacionRequested extends AdminEvent {
  final String nombre;
  final int idModulo;

  const CreateAplicacionRequested({
    required this.nombre,
    required this.idModulo,
  });

  @override
  List<Object?> get props => [nombre, idModulo];
}

class UpdateAplicacionRequested extends AdminEvent {
  final int id;
  final String? nombre;
  final String? descripcion;
  final int? idModulo;

  const UpdateAplicacionRequested({
    required this.id,
    this.nombre,
    this.descripcion,
    this.idModulo,
  });

  @override
  List<Object?> get props => [id, nombre, descripcion, idModulo];
}

class DeleteAplicacionRequested extends AdminEvent {
  final int id;

  const DeleteAplicacionRequested(this.id);

  @override
  List<Object?> get props => [id];
}

// ==================== APTITUDES ====================

class LoadAptitudesRequested extends AdminEvent {}

class LoadAptitudByIdRequested extends AdminEvent {
  final int id;

  const LoadAptitudByIdRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class CreateAptitudRequested extends AdminEvent {
  final String nombre;
  final String? descripcion;

  const CreateAptitudRequested({
    required this.nombre,
    this.descripcion,
  });

  @override
  List<Object?> get props => [nombre, descripcion];
}

class UpdateAptitudRequested extends AdminEvent {
  final int id;
  final String? nombre;
  final String? descripcion;
  final String? estado;

  const UpdateAptitudRequested({
    required this.id,
    this.nombre,
    this.descripcion,
    this.estado,
  });

  @override
  List<Object?> get props => [id, nombre, descripcion, estado];
}

class DeleteAptitudRequested extends AdminEvent {
  final int id;

  const DeleteAptitudRequested(this.id);

  @override
  List<Object?> get props => [id];
}

// ==================== UPDATE ROL ====================

class UpdateRolRequested extends AdminEvent {
  final int id;
  final String? nombre;
  final String? descripcion;
  final String? estado;

  const UpdateRolRequested({
    required this.id,
    this.nombre,
    this.descripcion,
    this.estado,
  });

  @override
  List<Object?> get props => [id, nombre, descripcion, estado];
}

// ==================== CATEGORÍAS ORGANIZACIONES ====================

class LoadCategoriasOrganizacionesRequested extends AdminEvent {}

class CreateCategoriaOrganizacionRequested extends AdminEvent {
  final String nombre;
  final String? descripcion;

  const CreateCategoriaOrganizacionRequested({
    required this.nombre,
    this.descripcion,
  });

  @override
  List<Object?> get props => [nombre, descripcion];
}

class UpdateCategoriaOrganizacionRequested extends AdminEvent {
  final int id;
  final String? nombre;
  final String? descripcion;

  const UpdateCategoriaOrganizacionRequested({
    required this.id,
    this.nombre,
    this.descripcion,
  });

  @override
  List<Object?> get props => [id, nombre, descripcion];
}

class DeleteCategoriaOrganizacionRequested extends AdminEvent {
  final int id;

  const DeleteCategoriaOrganizacionRequested(this.id);

  @override
  List<Object?> get props => [id];
}

// ==================== CATEGORÍAS PROYECTOS ====================

class LoadCategoriasProyectosRequested extends AdminEvent {}

class CreateCategoriaProyectoRequested extends AdminEvent {
  final String nombre;
  final String? descripcion;

  const CreateCategoriaProyectoRequested({
    required this.nombre,
    this.descripcion,
  });

  @override
  List<Object?> get props => [nombre, descripcion];
}

class UpdateCategoriaProyectoRequested extends AdminEvent {
  final int id;
  final String? nombre;
  final String? descripcion;

  const UpdateCategoriaProyectoRequested({
    required this.id,
    this.nombre,
    this.descripcion,
  });

  @override
  List<Object?> get props => [id, nombre, descripcion];
}

class DeleteCategoriaProyectoRequested extends AdminEvent {
  final int id;

  const DeleteCategoriaProyectoRequested(this.id);

  @override
  List<Object?> get props => [id];
}
