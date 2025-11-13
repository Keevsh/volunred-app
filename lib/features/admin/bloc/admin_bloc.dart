import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/dto/request_models.dart';
import '../../../core/repositories/admin_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository adminRepository;

  AdminBloc(this.adminRepository) : super(AdminInitial()) {
    // Usuarios
    on<LoadUsuariosRequested>(_onLoadUsuariosRequested);
    on<LoadUsuarioByIdRequested>(_onLoadUsuarioByIdRequested);
    on<CreateUsuarioRequested>(_onCreateUsuarioRequested);
    on<UpdateUsuarioRequested>(_onUpdateUsuarioRequested);
    on<DeleteUsuarioRequested>(_onDeleteUsuarioRequested);

    // Roles
    on<LoadRolesRequested>(_onLoadRolesRequested);
    on<LoadRolByIdRequested>(_onLoadRolByIdRequested);
    on<CreateRolRequested>(_onCreateRolRequested);
    on<DeleteRolRequested>(_onDeleteRolRequested);
    on<AsignarRolRequested>(_onAsignarRolRequested);

    // Permisos
    on<LoadPermisosRequested>(_onLoadPermisosRequested);
    on<LoadPermisosByRolRequested>(_onLoadPermisosByRolRequested);
    on<AsignarPermisosRequested>(_onAsignarPermisosRequested);
    on<DeletePermisoRequested>(_onDeletePermisoRequested);

    // Programas
    on<LoadProgramasRequested>(_onLoadProgramasRequested);
    on<CreateProgramaRequested>(_onCreateProgramaRequested);
    on<UpdateProgramaRequested>(_onUpdateProgramaRequested);
    on<DeleteProgramaRequested>(_onDeleteProgramaRequested);

    // Módulos y Aplicaciones
    on<LoadModulosRequested>(_onLoadModulosRequested);
    on<UpdateModuloRequested>(_onUpdateModuloRequested);
    on<LoadAplicacionesRequested>(_onLoadAplicacionesRequested);
    on<CreateAplicacionRequested>(_onCreateAplicacionRequested);
    on<UpdateAplicacionRequested>(_onUpdateAplicacionRequested);
    on<DeleteAplicacionRequested>(_onDeleteAplicacionRequested);

    // Aptitudes
    on<LoadAptitudesRequested>(_onLoadAptitudesRequested);
    on<LoadAptitudByIdRequested>(_onLoadAptitudByIdRequested);
    on<CreateAptitudRequested>(_onCreateAptitudRequested);
    on<UpdateAptitudRequested>(_onUpdateAptitudRequested);
    on<DeleteAptitudRequested>(_onDeleteAptitudRequested);

    // Update Rol
    on<UpdateRolRequested>(_onUpdateRolRequested);

    // Categorías Organizaciones
    on<LoadCategoriasOrganizacionesRequested>(_onLoadCategoriasOrganizacionesRequested);
    on<CreateCategoriaOrganizacionRequested>(_onCreateCategoriaOrganizacionRequested);
    on<UpdateCategoriaOrganizacionRequested>(_onUpdateCategoriaOrganizacionRequested);
    on<DeleteCategoriaOrganizacionRequested>(_onDeleteCategoriaOrganizacionRequested);

    // Categorías Proyectos
    on<LoadCategoriasProyectosRequested>(_onLoadCategoriasProyectosRequested);
    on<CreateCategoriaProyectoRequested>(_onCreateCategoriaProyectoRequested);
    on<UpdateCategoriaProyectoRequested>(_onUpdateCategoriaProyectoRequested);
    on<DeleteCategoriaProyectoRequested>(_onDeleteCategoriaProyectoRequested);

    // Organizaciones
    on<LoadOrganizacionesRequested>(_onLoadOrganizacionesRequested);
    on<LoadOrganizacionByIdRequested>(_onLoadOrganizacionByIdRequested);
    on<CreateOrganizacionRequested>(_onCreateOrganizacionRequested);
    on<UpdateOrganizacionRequested>(_onUpdateOrganizacionRequested);
    on<DeleteOrganizacionRequested>(_onDeleteOrganizacionRequested);

    // Proyectos
    on<LoadProyectosRequested>(_onLoadProyectosRequested);
    on<LoadProyectoByIdRequested>(_onLoadProyectoByIdRequested);
    on<CreateProyectoRequested>(_onCreateProyectoRequested);
    on<UpdateProyectoRequested>(_onUpdateProyectoRequested);
    on<DeleteProyectoRequested>(_onDeleteProyectoRequested);

    // Tareas
    on<LoadTareasRequested>(_onLoadTareasRequested);
    on<LoadTareaByIdRequested>(_onLoadTareaByIdRequested);
    on<CreateTareaRequested>(_onCreateTareaRequested);
    on<UpdateTareaRequested>(_onUpdateTareaRequested);
    on<DeleteTareaRequested>(_onDeleteTareaRequested);

    // Inscripciones
    on<LoadInscripcionesRequested>(_onLoadInscripcionesRequested);
    on<LoadInscripcionByIdRequested>(_onLoadInscripcionByIdRequested);
    on<CreateInscripcionRequested>(_onCreateInscripcionRequested);
    on<UpdateInscripcionRequested>(_onUpdateInscripcionRequested);
    on<DeleteInscripcionRequested>(_onDeleteInscripcionRequested);
  }

  // ==================== USUARIOS ====================

  Future<void> _onLoadUsuariosRequested(
    LoadUsuariosRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final result = await adminRepository.getUsuarios(
        page: event.page,
        limit: event.limit,
        email: event.email,
      );
      emit(UsuariosLoaded(
        usuarios: result['usuarios'],
        total: result['total'],
        page: result['page'],
        limit: result['limit'],
      ));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onLoadUsuarioByIdRequested(
    LoadUsuarioByIdRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final usuario = await adminRepository.getUsuarioById(event.id);
      emit(UsuarioLoaded(usuario));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onCreateUsuarioRequested(
    CreateUsuarioRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final usuario = await adminRepository.createUsuario(CreateUsuarioRequest(
        email: event.email,
        nombres: event.nombres,
        apellidos: event.apellidos,
        ci: event.ci,
        telefono: event.telefono,
        sexo: event.sexo,
      ));
      emit(UsuarioCreated(usuario));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUpdateUsuarioRequested(
    UpdateUsuarioRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final usuario = await adminRepository.updateUsuario(
        event.id,
        UpdateUsuarioRequest(
          email: event.email,
          nombres: event.nombres,
          apellidos: event.apellidos,
          ci: event.ci,
          telefono: event.telefono,
          sexo: event.sexo,
        ),
      );
      emit(UsuarioUpdated(usuario));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeleteUsuarioRequested(
    DeleteUsuarioRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await adminRepository.deleteUsuario(event.id);
      emit(const UsuarioDeleted('Usuario eliminado correctamente'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // ==================== ROLES ====================

  Future<void> _onLoadRolesRequested(
    LoadRolesRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final roles = await adminRepository.getRoles();
      emit(RolesLoaded(roles));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onLoadRolByIdRequested(
    LoadRolByIdRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final rol = await adminRepository.getRolById(event.id);
      emit(RolLoaded(rol));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onCreateRolRequested(
    CreateRolRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final rol = await adminRepository.createRol(
        CreateRolRequest(nombre: event.nombre, descripcion: event.descripcion),
      );
      emit(RolCreated(rol));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeleteRolRequested(
    DeleteRolRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await adminRepository.deleteRol(event.id);
      emit(const RolDeleted('Rol eliminado correctamente'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onAsignarRolRequested(
    AsignarRolRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final usuario = await adminRepository.asignarRol(
        AsignarRolRequest(idUsuario: event.idUsuario, idRol: event.idRol),
      );
      emit(RolAsignado(
        usuario: usuario,
        message: 'Rol asignado correctamente',
      ));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // ==================== PERMISOS ====================

  Future<void> _onLoadPermisosRequested(
    LoadPermisosRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final permisos = await adminRepository.getPermisos();
      emit(PermisosLoaded(permisos));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onLoadPermisosByRolRequested(
    LoadPermisosByRolRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final result = await adminRepository.getPermisosByRol(event.idRol);
      emit(PermisosByRolLoaded(
        rol: result['rol'],
        permisos: result['permisos'],
        total: result['total'],
      ));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onAsignarPermisosRequested(
    AsignarPermisosRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await adminRepository.asignarPermisos(
        AsignarPermisosRequest(idRol: event.idRol, programas: event.programas),
      );
      emit(const PermisosAsignados('Permisos asignados correctamente'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeletePermisoRequested(
    DeletePermisoRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await adminRepository.deletePermiso(event.id);
      emit(const PermisoDeleted('Permiso revocado correctamente'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // ==================== PROGRAMAS ====================

  Future<void> _onLoadProgramasRequested(
    LoadProgramasRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final programas = await adminRepository.getProgramas();
      emit(ProgramasLoaded(programas));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onCreateProgramaRequested(
    CreateProgramaRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final programa = await adminRepository.createPrograma(
        CreateProgramaRequest(
          nombre: event.nombre,
          descripcion: event.descripcion,
          idAplicacion: event.idAplicacion,
        ),
      );
      emit(ProgramaCreated(programa));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUpdateProgramaRequested(
    UpdateProgramaRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final programa = await adminRepository.updatePrograma(
        event.id,
        UpdateProgramaRequest(
          nombre: event.nombre,
          descripcion: event.descripcion,
          idAplicacion: event.idAplicacion,
        ),
      );
      emit(ProgramaUpdated(programa));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeleteProgramaRequested(
    DeleteProgramaRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await adminRepository.deletePrograma(event.id);
      emit(const ProgramaDeleted('Programa eliminado correctamente'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // ==================== MÓDULOS Y APLICACIONES ====================

  Future<void> _onLoadModulosRequested(
    LoadModulosRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final modulos = await adminRepository.getModulos();
      emit(ModulosLoaded(modulos));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUpdateModuloRequested(
    UpdateModuloRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final modulo = await adminRepository.updateModulo(
        event.id,
        UpdateModuloRequest(
          nombre: event.nombre,
          descripcion: event.descripcion,
        ),
      );
      emit(ModuloUpdated(modulo));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onLoadAplicacionesRequested(
    LoadAplicacionesRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final aplicaciones = await adminRepository.getAplicaciones();
      emit(AplicacionesLoaded(aplicaciones));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onCreateAplicacionRequested(
    CreateAplicacionRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final aplicacion = await adminRepository.createAplicacion(
        CreateAplicacionRequest(
          nombre: event.nombre,
          idModulo: event.idModulo,
        ),
      );
      emit(AplicacionCreated(aplicacion));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUpdateAplicacionRequested(
    UpdateAplicacionRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final aplicacion = await adminRepository.updateAplicacion(
        event.id,
        UpdateAplicacionRequest(
          nombre: event.nombre,
          descripcion: event.descripcion,
          idModulo: event.idModulo,
        ),
      );
      emit(AplicacionUpdated(aplicacion));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeleteAplicacionRequested(
    DeleteAplicacionRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await adminRepository.deleteAplicacion(event.id);
      emit(const AplicacionDeleted('Aplicación eliminada correctamente'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // ==================== APTITUDES ====================

  Future<void> _onLoadAptitudesRequested(
    LoadAptitudesRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final aptitudes = await adminRepository.getAptitudes();
      emit(AptitudesLoaded(aptitudes));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onLoadAptitudByIdRequested(
    LoadAptitudByIdRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final aptitud = await adminRepository.getAptitudById(event.id);
      emit(AptitudLoaded(aptitud));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onCreateAptitudRequested(
    CreateAptitudRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final aptitud = await adminRepository.createAptitud(
        CreateAptitudRequest(
          nombre: event.nombre,
          descripcion: event.descripcion,
        ),
      );
      emit(AptitudCreated(aptitud));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUpdateAptitudRequested(
    UpdateAptitudRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final aptitud = await adminRepository.updateAptitud(
        event.id,
        UpdateAptitudRequest(
          nombre: event.nombre,
          descripcion: event.descripcion,
          estado: event.estado,
        ),
      );
      emit(AptitudUpdated(aptitud));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeleteAptitudRequested(
    DeleteAptitudRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await adminRepository.deleteAptitud(event.id);
      emit(const AptitudDeleted('Aptitud eliminada correctamente'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // ==================== UPDATE ROL ====================

  Future<void> _onUpdateRolRequested(
    UpdateRolRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final rol = await adminRepository.updateRol(
        event.id,
        UpdateRolRequest(
          nombre: event.nombre,
          descripcion: event.descripcion,
          estado: event.estado,
        ),
      );
      emit(RolUpdated(rol));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // ==================== CATEGORÍAS ORGANIZACIONES ====================

  Future<void> _onLoadCategoriasOrganizacionesRequested(
    LoadCategoriasOrganizacionesRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final categorias = await adminRepository.getCategoriasOrganizaciones();
      emit(CategoriasOrganizacionesLoaded(categorias));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onCreateCategoriaOrganizacionRequested(
    CreateCategoriaOrganizacionRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final categoria = await adminRepository.createCategoriaOrganizacion({
        'nombre': event.nombre,
        if (event.descripcion != null) 'descripcion': event.descripcion,
      });
      emit(CategoriaOrganizacionCreated(categoria));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUpdateCategoriaOrganizacionRequested(
    UpdateCategoriaOrganizacionRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final categoria = await adminRepository.updateCategoriaOrganizacion(
        event.id,
        {
          if (event.nombre != null) 'nombre': event.nombre,
          if (event.descripcion != null) 'descripcion': event.descripcion,
        },
      );
      emit(CategoriaOrganizacionUpdated(categoria));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeleteCategoriaOrganizacionRequested(
    DeleteCategoriaOrganizacionRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await adminRepository.deleteCategoriaOrganizacion(event.id);
      emit(const CategoriaOrganizacionDeleted('Categoría eliminada correctamente'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // ==================== CATEGORÍAS PROYECTOS ====================

  Future<void> _onLoadCategoriasProyectosRequested(
    LoadCategoriasProyectosRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final categorias = await adminRepository.getCategoriasProyectos();
      emit(CategoriasProyectosLoaded(categorias));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onCreateCategoriaProyectoRequested(
    CreateCategoriaProyectoRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final categoria = await adminRepository.createCategoriaProyecto({
        'nombre': event.nombre,
        if (event.descripcion != null) 'descripcion': event.descripcion,
      });
      emit(CategoriaProyectoCreated(categoria));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUpdateCategoriaProyectoRequested(
    UpdateCategoriaProyectoRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final categoria = await adminRepository.updateCategoriaProyecto(
        event.id,
        {
          if (event.nombre != null) 'nombre': event.nombre,
          if (event.descripcion != null) 'descripcion': event.descripcion,
        },
      );
      emit(CategoriaProyectoUpdated(categoria));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeleteCategoriaProyectoRequested(
    DeleteCategoriaProyectoRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await adminRepository.deleteCategoriaProyecto(event.id);
      emit(const CategoriaProyectoDeleted('Categoría eliminada correctamente'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // ==================== ORGANIZACIONES ====================

  Future<void> _onLoadOrganizacionesRequested(
    LoadOrganizacionesRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final organizaciones = await adminRepository.getOrganizaciones();
      emit(OrganizacionesLoaded(organizaciones));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onLoadOrganizacionByIdRequested(
    LoadOrganizacionByIdRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final organizacion = await adminRepository.getOrganizacionById(event.id);
      emit(OrganizacionLoaded(organizacion));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onCreateOrganizacionRequested(
    CreateOrganizacionRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final organizacion = await adminRepository.createOrganizacion({
        'nombre_legal': event.nombreLegal,
        if (event.nombreCorto != null) 'nombre_corto': event.nombreCorto,
        'correo': event.correo,
        if (event.telefono != null) 'telefono': event.telefono,
        if (event.direccion != null) 'direccion': event.direccion,
        if (event.ciudad != null) 'ciudad': event.ciudad,
        if (event.idCategoria != null) 'id_categoria_organizacion': event.idCategoria,
        if (event.estado != null) 'estado': event.estado ?? 'activo',
      });
      emit(OrganizacionCreated(organizacion));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUpdateOrganizacionRequested(
    UpdateOrganizacionRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final data = <String, dynamic>{};
      if (event.nombreLegal != null) data['nombre_legal'] = event.nombreLegal;
      if (event.nombreCorto != null) data['nombre_corto'] = event.nombreCorto;
      if (event.correo != null) data['correo'] = event.correo;
      if (event.telefono != null) data['telefono'] = event.telefono;
      if (event.direccion != null) data['direccion'] = event.direccion;
      if (event.ciudad != null) data['ciudad'] = event.ciudad;
      if (event.idCategoria != null) data['id_categoria_organizacion'] = event.idCategoria;
      if (event.estado != null) data['estado'] = event.estado;

      final organizacion = await adminRepository.updateOrganizacion(event.id, data);
      emit(OrganizacionUpdated(organizacion));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeleteOrganizacionRequested(
    DeleteOrganizacionRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await adminRepository.deleteOrganizacion(event.id);
      emit(const OrganizacionDeleted('Organización eliminada correctamente'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // ==================== PROYECTOS ====================

  Future<void> _onLoadProyectosRequested(
    LoadProyectosRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final proyectos = await adminRepository.getProyectos();
      emit(ProyectosLoaded(proyectos));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onLoadProyectoByIdRequested(
    LoadProyectoByIdRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final proyecto = await adminRepository.getProyectoById(event.id);
      emit(ProyectoLoaded(proyecto));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onCreateProyectoRequested(
    CreateProyectoRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final data = <String, dynamic>{
        'categoria_proyecto_id': event.categoriaProyectoId,
        'organizacion_id': event.organizacionId,
        'nombre': event.nombre,
        'objetivo': event.objetivo,
        if (event.ubicacion != null) 'ubicacion': event.ubicacion,
        if (event.fechaInicio != null)
          'fecha_inicio': event.fechaInicio!.toIso8601String().split('T')[0],
        if (event.fechaFin != null)
          'fecha_fin': event.fechaFin!.toIso8601String().split('T')[0],
        'estado': event.estado ?? 'activo',
        if (event.imagen != null && event.imagen!.isNotEmpty) 'imagen': event.imagen,
      };
      final proyecto = await adminRepository.createProyecto(data);
      emit(ProyectoCreated(proyecto));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUpdateProyectoRequested(
    UpdateProyectoRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final data = <String, dynamic>{};
      if (event.categoriaProyectoId != null)
        data['categoria_proyecto_id'] = event.categoriaProyectoId;
      if (event.organizacionId != null) data['organizacion_id'] = event.organizacionId;
      if (event.nombre != null) data['nombre'] = event.nombre;
      if (event.objetivo != null) data['objetivo'] = event.objetivo;
      if (event.ubicacion != null) data['ubicacion'] = event.ubicacion;
      if (event.fechaInicio != null)
        data['fecha_inicio'] = event.fechaInicio!.toIso8601String().split('T')[0];
      if (event.fechaFin != null)
        data['fecha_fin'] = event.fechaFin!.toIso8601String().split('T')[0];
      if (event.estado != null) data['estado'] = event.estado;

      final proyecto = await adminRepository.updateProyecto(event.id, data);
      emit(ProyectoUpdated(proyecto));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeleteProyectoRequested(
    DeleteProyectoRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await adminRepository.deleteProyecto(event.id);
      emit(const ProyectoDeleted('Proyecto eliminado correctamente'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // ==================== TAREAS ====================

  Future<void> _onLoadTareasRequested(
    LoadTareasRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final tareas = await adminRepository.getTareas();
      emit(TareasLoaded(tareas));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onLoadTareaByIdRequested(
    LoadTareaByIdRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final tarea = await adminRepository.getTareaById(event.id);
      emit(TareaLoaded(tarea));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onCreateTareaRequested(
    CreateTareaRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final data = <String, dynamic>{
        'proyecto_id': event.proyectoId,
        'nombre': event.nombre,
        if (event.descripcion != null) 'descripcion': event.descripcion,
        if (event.prioridad != null) 'prioridad': event.prioridad,
        if (event.fechaInicio != null)
          'fecha_inicio': event.fechaInicio!.toIso8601String().split('T')[0],
        if (event.fechaFin != null)
          'fecha_fin': event.fechaFin!.toIso8601String().split('T')[0],
        'estado': event.estado ?? 'activo',
      };
      final tarea = await adminRepository.createTarea(data);
      emit(TareaCreated(tarea));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUpdateTareaRequested(
    UpdateTareaRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final data = <String, dynamic>{};
      if (event.proyectoId != null) data['proyecto_id'] = event.proyectoId;
      if (event.nombre != null) data['nombre'] = event.nombre;
      if (event.descripcion != null) data['descripcion'] = event.descripcion;
      if (event.prioridad != null) data['prioridad'] = event.prioridad;
      if (event.fechaInicio != null)
        data['fecha_inicio'] = event.fechaInicio!.toIso8601String().split('T')[0];
      if (event.fechaFin != null)
        data['fecha_fin'] = event.fechaFin!.toIso8601String().split('T')[0];
      if (event.estado != null) data['estado'] = event.estado;

      final tarea = await adminRepository.updateTarea(event.id, data);
      emit(TareaUpdated(tarea));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeleteTareaRequested(
    DeleteTareaRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await adminRepository.deleteTarea(event.id);
      emit(const TareaDeleted('Tarea eliminada correctamente'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  // ==================== INSCRIPCIONES ====================

  Future<void> _onLoadInscripcionesRequested(
    LoadInscripcionesRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final inscripciones = await adminRepository.getInscripciones();
      emit(InscripcionesLoaded(inscripciones));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onLoadInscripcionByIdRequested(
    LoadInscripcionByIdRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final inscripcion = await adminRepository.getInscripcionById(event.id);
      emit(InscripcionLoaded(inscripcion));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onCreateInscripcionRequested(
    CreateInscripcionRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final data = <String, dynamic>{
        'usuario_id': event.usuarioId,
        'organizacion_id': event.organizacionId,
        'fecha_recepcion': (event.fechaRecepcion ?? DateTime.now()).toIso8601String().split('T')[0],
        'estado': event.estado ?? 'activo',
      };
      final inscripcion = await adminRepository.createInscripcion(data);
      emit(InscripcionCreated(inscripcion));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onUpdateInscripcionRequested(
    UpdateInscripcionRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final data = <String, dynamic>{};
      if (event.estado != null) data['estado'] = event.estado;
      if (event.motivoRechazo != null) data['motivo_rechazo'] = event.motivoRechazo;

      final inscripcion = await adminRepository.updateInscripcion(event.id, data);
      emit(InscripcionUpdated(inscripcion));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeleteInscripcionRequested(
    DeleteInscripcionRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await adminRepository.deleteInscripcion(event.id);
      emit(const InscripcionDeleted('Inscripción eliminada correctamente'));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}
