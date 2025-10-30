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

// ==================== MÓDULOS Y APLICACIONES ====================

class LoadModulosRequested extends AdminEvent {}

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
