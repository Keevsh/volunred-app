import 'package:equatable/equatable.dart';

// ==================== DASHBOARD ====================

/// Resumen de tareas del voluntario
class ResumenTareas extends Equatable {
  final int asignadas;
  final int enProgreso;
  final int completadas;
  final int total;

  const ResumenTareas({
    required this.asignadas,
    required this.enProgreso,
    required this.completadas,
    required this.total,
  });

  factory ResumenTareas.fromJson(Map<String, dynamic> json) {
    return ResumenTareas(
      asignadas: _getInt(json['asignadas']),
      enProgreso: _getInt(json['en_progreso']),
      completadas: _getInt(json['completadas']),
      total: _getInt(json['total']),
    );
  }

  Map<String, dynamic> toJson() => {
    'asignadas': asignadas,
    'en_progreso': enProgreso,
    'completadas': completadas,
    'total': total,
  };

  @override
  List<Object?> get props => [asignadas, enProgreso, completadas, total];
}

/// Resumen general del dashboard del voluntario
class ResumenVoluntario extends Equatable {
  final int organizacionesInscritas;
  final int proyectosParticipando;
  final int participacionesPendientes;
  final ResumenTareas tareas;

  const ResumenVoluntario({
    required this.organizacionesInscritas,
    required this.proyectosParticipando,
    required this.participacionesPendientes,
    required this.tareas,
  });

  factory ResumenVoluntario.fromJson(Map<String, dynamic> json) {
    return ResumenVoluntario(
      organizacionesInscritas: _getInt(json['organizaciones_inscritas']),
      proyectosParticipando: _getInt(json['proyectos_participando']),
      participacionesPendientes: _getInt(json['participaciones_pendientes']),
      tareas: json['tareas'] != null
          ? ResumenTareas.fromJson(json['tareas'] as Map<String, dynamic>)
          : const ResumenTareas(asignadas: 0, enProgreso: 0, completadas: 0, total: 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'organizaciones_inscritas': organizacionesInscritas,
    'proyectos_participando': proyectosParticipando,
    'participaciones_pendientes': participacionesPendientes,
    'tareas': tareas.toJson(),
  };

  @override
  List<Object?> get props => [
    organizacionesInscritas,
    proyectosParticipando,
    participacionesPendientes,
    tareas,
  ];
}

/// Tarea resumida para el dashboard
class TareaResumida extends Equatable {
  final int idTarea;
  final String nombre;
  final String estado;
  final String? prioridad;

  const TareaResumida({
    required this.idTarea,
    required this.nombre,
    required this.estado,
    this.prioridad,
  });

  factory TareaResumida.fromJson(Map<String, dynamic> json) {
    return TareaResumida(
      idTarea: _getInt(json['id_tarea']),
      nombre: _getString(json['nombre']) ?? '',
      estado: _getString(json['estado']) ?? 'pendiente',
      prioridad: _getString(json['prioridad']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_tarea': idTarea,
    'nombre': nombre,
    'estado': estado,
    if (prioridad != null) 'prioridad': prioridad,
  };

  @override
  List<Object?> get props => [idTarea, nombre, estado, prioridad];
}

/// Proyecto resumido para el dashboard
class ProyectoResumido extends Equatable {
  final int idProyecto;
  final String nombre;

  const ProyectoResumido({
    required this.idProyecto,
    required this.nombre,
  });

  factory ProyectoResumido.fromJson(Map<String, dynamic> json) {
    return ProyectoResumido(
      idProyecto: _getInt(json['id_proyecto']),
      nombre: _getString(json['nombre']) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id_proyecto': idProyecto,
    'nombre': nombre,
  };

  @override
  List<Object?> get props => [idProyecto, nombre];
}

/// Última tarea del dashboard
class UltimaTarea extends Equatable {
  final int idAsignacion;
  final String estado;
  final DateTime fechaAsignacion;
  final TareaResumida tarea;
  final ProyectoResumido proyecto;

  const UltimaTarea({
    required this.idAsignacion,
    required this.estado,
    required this.fechaAsignacion,
    required this.tarea,
    required this.proyecto,
  });

  factory UltimaTarea.fromJson(Map<String, dynamic> json) {
    return UltimaTarea(
      idAsignacion: _getInt(json['id_asignacion']),
      estado: _getString(json['estado']) ?? 'asignada',
      fechaAsignacion: _parseDateTime(json['fecha_asignacion']),
      tarea: json['tarea'] != null
          ? TareaResumida.fromJson(json['tarea'] as Map<String, dynamic>)
          : const TareaResumida(idTarea: 0, nombre: '', estado: 'pendiente'),
      proyecto: json['proyecto'] != null
          ? ProyectoResumido.fromJson(json['proyecto'] as Map<String, dynamic>)
          : const ProyectoResumido(idProyecto: 0, nombre: ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_asignacion': idAsignacion,
    'estado': estado,
    'fecha_asignacion': fechaAsignacion.toIso8601String(),
    'tarea': tarea.toJson(),
    'proyecto': proyecto.toJson(),
  };

  @override
  List<Object?> get props => [idAsignacion, estado, fechaAsignacion, tarea, proyecto];
}

/// Respuesta del dashboard del voluntario
class VoluntarioDashboardResponse extends Equatable {
  final ResumenVoluntario resumen;
  final List<UltimaTarea> ultimasTareas;

  const VoluntarioDashboardResponse({
    required this.resumen,
    required this.ultimasTareas,
  });

  factory VoluntarioDashboardResponse.fromJson(Map<String, dynamic> json) {
    final ultimasTareasJson = json['ultimas_tareas'];
    List<UltimaTarea> ultimasTareas = [];
    
    if (ultimasTareasJson != null && ultimasTareasJson is List) {
      ultimasTareas = ultimasTareasJson
          .whereType<Map<String, dynamic>>()
          .map((e) => UltimaTarea.fromJson(e))
          .toList();
    }

    return VoluntarioDashboardResponse(
      resumen: json['resumen'] != null
          ? ResumenVoluntario.fromJson(json['resumen'] as Map<String, dynamic>)
          : const ResumenVoluntario(
              organizacionesInscritas: 0,
              proyectosParticipando: 0,
              participacionesPendientes: 0,
              tareas: ResumenTareas(asignadas: 0, enProgreso: 0, completadas: 0, total: 0),
            ),
      ultimasTareas: ultimasTareas,
    );
  }

  Map<String, dynamic> toJson() => {
    'resumen': resumen.toJson(),
    'ultimas_tareas': ultimasTareas.map((e) => e.toJson()).toList(),
  };

  @override
  List<Object?> get props => [resumen, ultimasTareas];
}

// ==================== ORGANIZACION RESUMIDA ====================

/// Organización resumida para proyectos
class OrganizacionResumida extends Equatable {
  final int idOrganizacion;
  final String nombreLegal;
  final String? nombreCorto;
  final String? logo;

  const OrganizacionResumida({
    required this.idOrganizacion,
    required this.nombreLegal,
    this.nombreCorto,
    this.logo,
  });

  factory OrganizacionResumida.fromJson(Map<String, dynamic> json) {
    return OrganizacionResumida(
      idOrganizacion: _getInt(json['id_organizacion']),
      nombreLegal: _getString(json['nombre_legal']) ?? '',
      nombreCorto: _getString(json['nombre_corto']),
      logo: _getString(json['logo']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_organizacion': idOrganizacion,
    'nombre_legal': nombreLegal,
    if (nombreCorto != null) 'nombre_corto': nombreCorto,
    if (logo != null) 'logo': logo,
  };

  @override
  List<Object?> get props => [idOrganizacion, nombreLegal, nombreCorto, logo];
}

// ==================== MI PARTICIPACION ====================

/// Mi participación en un proyecto
class MiParticipacion extends Equatable {
  final int idParticipacion;
  final String? rolAsignado;
  final String estado;
  final double? horasComprometidasSemana;

  const MiParticipacion({
    required this.idParticipacion,
    this.rolAsignado,
    required this.estado,
    this.horasComprometidasSemana,
  });

  factory MiParticipacion.fromJson(Map<String, dynamic> json) {
    double? horas;
    final horasValue = json['horas_comprometidas_semana'];
    if (horasValue != null) {
      if (horasValue is double) {
        horas = horasValue;
      } else if (horasValue is int) {
        horas = horasValue.toDouble();
      } else {
        horas = double.tryParse(horasValue.toString());
      }
    }

    return MiParticipacion(
      idParticipacion: _getInt(json['id_participacion']),
      rolAsignado: _getString(json['rol_asignado']),
      estado: _getString(json['estado']) ?? 'pendiente',
      horasComprometidasSemana: horas,
    );
  }

  Map<String, dynamic> toJson() => {
    'id_participacion': idParticipacion,
    if (rolAsignado != null) 'rol_asignado': rolAsignado,
    'estado': estado,
    if (horasComprometidasSemana != null) 'horas_comprometidas_semana': horasComprometidasSemana,
  };

  /// Indica si la participación está activa
  bool get isActive {
    final estadoLower = estado.toLowerCase();
    return estadoLower == 'aprobada' || 
           estadoLower == 'programada' || 
           estadoLower == 'en_progreso';
  }

  @override
  List<Object?> get props => [idParticipacion, rolAsignado, estado, horasComprometidasSemana];
}

// ==================== PROYECTO DEL VOLUNTARIO ====================

/// Proyecto en el que participa el voluntario
class ProyectoVoluntario extends Equatable {
  final int idProyecto;
  final String nombre;
  final String? objetivo;
  final String? ubicacion;
  final String? imagen;
  final String estado;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final OrganizacionResumida organizacion;
  final MiParticipacion miParticipacion;

  const ProyectoVoluntario({
    required this.idProyecto,
    required this.nombre,
    this.objetivo,
    this.ubicacion,
    this.imagen,
    required this.estado,
    this.fechaInicio,
    this.fechaFin,
    required this.organizacion,
    required this.miParticipacion,
  });

  factory ProyectoVoluntario.fromJson(Map<String, dynamic> json) {
    return ProyectoVoluntario(
      idProyecto: _getInt(json['id_proyecto']),
      nombre: _getString(json['nombre']) ?? '',
      objetivo: _getString(json['objetivo']),
      ubicacion: _getString(json['ubicacion']),
      imagen: _getString(json['imagen']),
      estado: _getString(json['estado']) ?? 'activo',
      fechaInicio: _parseDateTimeNullable(json['fecha_inicio']),
      fechaFin: _parseDateTimeNullable(json['fecha_fin']),
      organizacion: json['organizacion'] != null
          ? OrganizacionResumida.fromJson(json['organizacion'] as Map<String, dynamic>)
          : const OrganizacionResumida(idOrganizacion: 0, nombreLegal: ''),
      miParticipacion: json['mi_participacion'] != null
          ? MiParticipacion.fromJson(json['mi_participacion'] as Map<String, dynamic>)
          : const MiParticipacion(idParticipacion: 0, estado: 'pendiente'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_proyecto': idProyecto,
    'nombre': nombre,
    if (objetivo != null) 'objetivo': objetivo,
    if (ubicacion != null) 'ubicacion': ubicacion,
    if (imagen != null) 'imagen': imagen,
    'estado': estado,
    if (fechaInicio != null) 'fecha_inicio': fechaInicio!.toIso8601String().split('T').first,
    if (fechaFin != null) 'fecha_fin': fechaFin!.toIso8601String().split('T').first,
    'organizacion': organizacion.toJson(),
    'mi_participacion': miParticipacion.toJson(),
  };

  @override
  List<Object?> get props => [
    idProyecto, nombre, objetivo, ubicacion, imagen, estado,
    fechaInicio, fechaFin, organizacion, miParticipacion,
  ];
}

// ==================== MI ASIGNACION ====================

/// Mi asignación de tarea
class MiAsignacion extends Equatable {
  final int idAsignacion;
  final String estado;
  final DateTime? fechaAsignacion;

  const MiAsignacion({
    required this.idAsignacion,
    required this.estado,
    this.fechaAsignacion,
  });

  factory MiAsignacion.fromJson(Map<String, dynamic> json) {
    return MiAsignacion(
      idAsignacion: _getInt(json['id_asignacion']),
      estado: _getString(json['estado']) ?? 'asignada',
      fechaAsignacion: _parseDateTimeNullable(json['fecha_asignacion']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_asignacion': idAsignacion,
    'estado': estado,
    if (fechaAsignacion != null) 'fecha_asignacion': fechaAsignacion!.toIso8601String(),
  };

  @override
  List<Object?> get props => [idAsignacion, estado, fechaAsignacion];
}

// ==================== TAREA DEL PROYECTO ====================

/// Tarea de un proyecto (con información de asignación al voluntario)
class TareaProyecto extends Equatable {
  final int idTarea;
  final String nombre;
  final String? descripcion;
  final String estado;
  final String? prioridad;
  final DateTime? fechaFin;
  final bool asignadaAMi;
  final MiAsignacion? miAsignacion;

  const TareaProyecto({
    required this.idTarea,
    required this.nombre,
    this.descripcion,
    required this.estado,
    this.prioridad,
    this.fechaFin,
    required this.asignadaAMi,
    this.miAsignacion,
  });

  factory TareaProyecto.fromJson(Map<String, dynamic> json) {
    return TareaProyecto(
      idTarea: _getInt(json['id_tarea']),
      nombre: _getString(json['nombre']) ?? '',
      descripcion: _getString(json['descripcion']),
      estado: _getString(json['estado']) ?? 'pendiente',
      prioridad: _getString(json['prioridad']),
      fechaFin: _parseDateTimeNullable(json['fecha_fin']),
      asignadaAMi: json['asignada_a_mi'] == true,
      miAsignacion: json['mi_asignacion'] != null
          ? MiAsignacion.fromJson(json['mi_asignacion'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id_tarea': idTarea,
    'nombre': nombre,
    if (descripcion != null) 'descripcion': descripcion,
    'estado': estado,
    if (prioridad != null) 'prioridad': prioridad,
    if (fechaFin != null) 'fecha_fin': fechaFin!.toIso8601String().split('T').first,
    'asignada_a_mi': asignadaAMi,
    if (miAsignacion != null) 'mi_asignacion': miAsignacion!.toJson(),
  };

  @override
  List<Object?> get props => [
    idTarea, nombre, descripcion, estado, prioridad, fechaFin, asignadaAMi, miAsignacion,
  ];
}

// ==================== RESUMEN TAREAS PROYECTO ====================

/// Resumen de tareas de un proyecto
class ResumenTareasProyecto extends Equatable {
  final int total;
  final int pendientes;
  final int enProgreso;
  final int completadas;
  final int asignadasAMi;

  const ResumenTareasProyecto({
    required this.total,
    required this.pendientes,
    required this.enProgreso,
    required this.completadas,
    required this.asignadasAMi,
  });

  factory ResumenTareasProyecto.fromJson(Map<String, dynamic> json) {
    return ResumenTareasProyecto(
      total: _getInt(json['total']),
      pendientes: _getInt(json['pendientes']),
      enProgreso: _getInt(json['en_progreso']),
      completadas: _getInt(json['completadas']),
      asignadasAMi: _getInt(json['asignadas_a_mi']),
    );
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'pendientes': pendientes,
    'en_progreso': enProgreso,
    'completadas': completadas,
    'asignadas_a_mi': asignadasAMi,
  };

  @override
  List<Object?> get props => [total, pendientes, enProgreso, completadas, asignadasAMi];
}

// ==================== DETALLE PROYECTO VOLUNTARIO ====================

/// Detalle de un proyecto donde participa el voluntario
class ProyectoDetalleVoluntario extends Equatable {
  final int idProyecto;
  final String nombre;
  final String? objetivo;
  final String? ubicacion;
  final String? imagen;
  final String estado;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final OrganizacionResumida organizacion;
  final MiParticipacion miParticipacion;
  final List<TareaProyecto> tareas;
  final ResumenTareasProyecto resumenTareas;

  const ProyectoDetalleVoluntario({
    required this.idProyecto,
    required this.nombre,
    this.objetivo,
    this.ubicacion,
    this.imagen,
    required this.estado,
    this.fechaInicio,
    this.fechaFin,
    required this.organizacion,
    required this.miParticipacion,
    required this.tareas,
    required this.resumenTareas,
  });

  factory ProyectoDetalleVoluntario.fromJson(Map<String, dynamic> json) {
    final tareasJson = json['tareas'];
    List<TareaProyecto> tareas = [];
    
    if (tareasJson != null && tareasJson is List) {
      tareas = tareasJson
          .whereType<Map<String, dynamic>>()
          .map((e) => TareaProyecto.fromJson(e))
          .toList();
    }

    return ProyectoDetalleVoluntario(
      idProyecto: _getInt(json['id_proyecto']),
      nombre: _getString(json['nombre']) ?? '',
      objetivo: _getString(json['objetivo']),
      ubicacion: _getString(json['ubicacion']),
      imagen: _getString(json['imagen']),
      estado: _getString(json['estado']) ?? 'activo',
      fechaInicio: _parseDateTimeNullable(json['fecha_inicio']),
      fechaFin: _parseDateTimeNullable(json['fecha_fin']),
      organizacion: json['organizacion'] != null
          ? OrganizacionResumida.fromJson(json['organizacion'] as Map<String, dynamic>)
          : const OrganizacionResumida(idOrganizacion: 0, nombreLegal: ''),
      miParticipacion: json['mi_participacion'] != null
          ? MiParticipacion.fromJson(json['mi_participacion'] as Map<String, dynamic>)
          : const MiParticipacion(idParticipacion: 0, estado: 'pendiente'),
      tareas: tareas,
      resumenTareas: json['resumen_tareas'] != null
          ? ResumenTareasProyecto.fromJson(json['resumen_tareas'] as Map<String, dynamic>)
          : const ResumenTareasProyecto(
              total: 0, pendientes: 0, enProgreso: 0, completadas: 0, asignadasAMi: 0,
            ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_proyecto': idProyecto,
    'nombre': nombre,
    if (objetivo != null) 'objetivo': objetivo,
    if (ubicacion != null) 'ubicacion': ubicacion,
    if (imagen != null) 'imagen': imagen,
    'estado': estado,
    if (fechaInicio != null) 'fecha_inicio': fechaInicio!.toIso8601String().split('T').first,
    if (fechaFin != null) 'fecha_fin': fechaFin!.toIso8601String().split('T').first,
    'organizacion': organizacion.toJson(),
    'mi_participacion': miParticipacion.toJson(),
    'tareas': tareas.map((e) => e.toJson()).toList(),
    'resumen_tareas': resumenTareas.toJson(),
  };

  @override
  List<Object?> get props => [
    idProyecto, nombre, objetivo, ubicacion, imagen, estado,
    fechaInicio, fechaFin, organizacion, miParticipacion, tareas, resumenTareas,
  ];
}

// ==================== EVIDENCIA ====================

/// Evidencia de una tarea
class Evidencia extends Equatable {
  final int idEvidencia;
  final String tipo;
  final String? descripcion;
  final String? foto;
  final DateTime creadoEn;

  const Evidencia({
    required this.idEvidencia,
    required this.tipo,
    this.descripcion,
    this.foto,
    required this.creadoEn,
  });

  factory Evidencia.fromJson(Map<String, dynamic> json) {
    return Evidencia(
      idEvidencia: _getInt(json['id_evidencia']),
      tipo: _getString(json['tipo']) ?? 'foto',
      descripcion: _getString(json['descripcion']),
      foto: _getString(json['foto']),
      creadoEn: _parseDateTime(json['creado_en']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_evidencia': idEvidencia,
    'tipo': tipo,
    if (descripcion != null) 'descripcion': descripcion,
    if (foto != null) 'foto': foto,
    'creado_en': creadoEn.toIso8601String(),
  };

  @override
  List<Object?> get props => [idEvidencia, tipo, descripcion, foto, creadoEn];
}

// ==================== TAREA COMPLETA DEL VOLUNTARIO ====================

/// Tarea completa con información de proyecto (para GET /voluntarios/my/tasks)
class TareaCompletaInfo extends Equatable {
  final int idTarea;
  final String nombre;
  final String? descripcion;
  final String estado;
  final String? prioridad;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final ProyectoResumido proyecto;

  const TareaCompletaInfo({
    required this.idTarea,
    required this.nombre,
    this.descripcion,
    required this.estado,
    this.prioridad,
    this.fechaInicio,
    this.fechaFin,
    required this.proyecto,
  });

  factory TareaCompletaInfo.fromJson(Map<String, dynamic> json) {
    return TareaCompletaInfo(
      idTarea: _getInt(json['id_tarea']),
      nombre: _getString(json['nombre']) ?? '',
      descripcion: _getString(json['descripcion']),
      estado: _getString(json['estado']) ?? 'pendiente',
      prioridad: _getString(json['prioridad']),
      fechaInicio: _parseDateTimeNullable(json['fecha_inicio']),
      fechaFin: _parseDateTimeNullable(json['fecha_fin']),
      proyecto: json['proyecto'] != null
          ? ProyectoResumido.fromJson(json['proyecto'] as Map<String, dynamic>)
          : const ProyectoResumido(idProyecto: 0, nombre: ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_tarea': idTarea,
    'nombre': nombre,
    if (descripcion != null) 'descripcion': descripcion,
    'estado': estado,
    if (prioridad != null) 'prioridad': prioridad,
    if (fechaInicio != null) 'fecha_inicio': fechaInicio!.toIso8601String().split('T').first,
    if (fechaFin != null) 'fecha_fin': fechaFin!.toIso8601String().split('T').first,
    'proyecto': proyecto.toJson(),
  };

  @override
  List<Object?> get props => [
    idTarea, nombre, descripcion, estado, prioridad, fechaInicio, fechaFin, proyecto,
  ];
}

/// Asignación de tarea del voluntario (para GET /voluntarios/my/tasks)
class AsignacionTareaVoluntario extends Equatable {
  final int idAsignacion;
  final String estado;
  final DateTime fechaAsignacion;
  final TareaCompletaInfo tarea;
  final List<Evidencia> evidencias;

  const AsignacionTareaVoluntario({
    required this.idAsignacion,
    required this.estado,
    required this.fechaAsignacion,
    required this.tarea,
    required this.evidencias,
  });

  factory AsignacionTareaVoluntario.fromJson(Map<String, dynamic> json) {
    final evidenciasJson = json['evidencias'];
    List<Evidencia> evidencias = [];
    
    if (evidenciasJson != null && evidenciasJson is List) {
      evidencias = evidenciasJson
          .whereType<Map<String, dynamic>>()
          .map((e) => Evidencia.fromJson(e))
          .toList();
    }

    return AsignacionTareaVoluntario(
      idAsignacion: _getInt(json['id_asignacion']),
      estado: _getString(json['estado']) ?? 'asignada',
      fechaAsignacion: _parseDateTime(json['fecha_asignacion']),
      tarea: json['tarea'] != null
          ? TareaCompletaInfo.fromJson(json['tarea'] as Map<String, dynamic>)
          : TareaCompletaInfo(
              idTarea: 0,
              nombre: '',
              estado: 'pendiente',
              proyecto: const ProyectoResumido(idProyecto: 0, nombre: ''),
            ),
      evidencias: evidencias,
    );
  }

  Map<String, dynamic> toJson() => {
    'id_asignacion': idAsignacion,
    'estado': estado,
    'fecha_asignacion': fechaAsignacion.toIso8601String(),
    'tarea': tarea.toJson(),
    'evidencias': evidencias.map((e) => e.toJson()).toList(),
  };

  @override
  List<Object?> get props => [idAsignacion, estado, fechaAsignacion, tarea, evidencias];
}

// ==================== PARTICIPACION VOLUNTARIO ====================

/// Proyecto resumido para participación
class ProyectoParticipacion extends Equatable {
  final int idProyecto;
  final String nombre;
  final String? objetivo;
  final String? ubicacion;
  final String? imagen;
  final String estado;
  final OrganizacionResumida? organizacion;

  const ProyectoParticipacion({
    required this.idProyecto,
    required this.nombre,
    this.objetivo,
    this.ubicacion,
    this.imagen,
    required this.estado,
    this.organizacion,
  });

  factory ProyectoParticipacion.fromJson(Map<String, dynamic> json) {
    return ProyectoParticipacion(
      idProyecto: _getInt(json['id_proyecto']),
      nombre: _getString(json['nombre']) ?? '',
      objetivo: _getString(json['objetivo']),
      ubicacion: _getString(json['ubicacion']),
      imagen: _getString(json['imagen']),
      estado: _getString(json['estado']) ?? 'activo',
      organizacion: json['organizacion'] != null
          ? OrganizacionResumida.fromJson(json['organizacion'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id_proyecto': idProyecto,
    'nombre': nombre,
    if (objetivo != null) 'objetivo': objetivo,
    if (ubicacion != null) 'ubicacion': ubicacion,
    if (imagen != null) 'imagen': imagen,
    'estado': estado,
    if (organizacion != null) 'organizacion': organizacion!.toJson(),
  };

  @override
  List<Object?> get props => [idProyecto, nombre, objetivo, ubicacion, imagen, estado, organizacion];
}

/// Participación del voluntario (para GET /voluntarios/my/participaciones)
class ParticipacionVoluntario extends Equatable {
  final int idParticipacion;
  final int inscripcionId;
  final int perfilVolId;
  final int proyectoId;
  final String? rolAsignado;
  final String estado;
  final double? horasComprometidasSemana;
  final DateTime creadoEn;
  final ProyectoParticipacion? proyecto;

  const ParticipacionVoluntario({
    required this.idParticipacion,
    required this.inscripcionId,
    required this.perfilVolId,
    required this.proyectoId,
    this.rolAsignado,
    required this.estado,
    this.horasComprometidasSemana,
    required this.creadoEn,
    this.proyecto,
  });

  factory ParticipacionVoluntario.fromJson(Map<String, dynamic> json) {
    double? horas;
    final horasValue = json['horas_comprometidas_semana'];
    if (horasValue != null) {
      if (horasValue is double) {
        horas = horasValue;
      } else if (horasValue is int) {
        horas = horasValue.toDouble();
      } else {
        horas = double.tryParse(horasValue.toString());
      }
    }

    return ParticipacionVoluntario(
      idParticipacion: _getInt(json['id_participacion']),
      inscripcionId: _getInt(json['inscripcion_id']),
      perfilVolId: _getInt(json['perfil_vol_id']),
      proyectoId: _getInt(json['proyecto_id']),
      rolAsignado: _getString(json['rol_asignado']),
      estado: _getString(json['estado']) ?? 'pendiente',
      horasComprometidasSemana: horas,
      creadoEn: _parseDateTime(json['creado_en']),
      proyecto: json['proyecto'] != null
          ? ProyectoParticipacion.fromJson(json['proyecto'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id_participacion': idParticipacion,
    'inscripcion_id': inscripcionId,
    'perfil_vol_id': perfilVolId,
    'proyecto_id': proyectoId,
    if (rolAsignado != null) 'rol_asignado': rolAsignado,
    'estado': estado,
    if (horasComprometidasSemana != null) 'horas_comprometidas_semana': horasComprometidasSemana,
    'creado_en': creadoEn.toIso8601String(),
    if (proyecto != null) 'proyecto': proyecto!.toJson(),
  };

  /// Indica si la participación está activa
  bool get isActive {
    final estadoLower = estado.toLowerCase();
    return estadoLower == 'aprobada' || 
           estadoLower == 'programada' || 
           estadoLower == 'en_progreso';
  }

  /// Indica si la participación está pendiente
  bool get isPending => estado.toLowerCase() == 'pendiente';

  @override
  List<Object?> get props => [
    idParticipacion, inscripcionId, perfilVolId, proyectoId,
    rolAsignado, estado, horasComprometidasSemana, creadoEn, proyecto,
  ];
}

/// Respuesta al crear una participación
class CrearParticipacionResponse extends Equatable {
  final int idParticipacion;
  final int inscripcionId;
  final int perfilVolId;
  final int proyectoId;
  final String? rolAsignado;
  final String estado;
  final double? horasComprometidasSemana;
  final DateTime creadoEn;
  final ProyectoParticipacion? proyecto;
  final String? mensaje;

  const CrearParticipacionResponse({
    required this.idParticipacion,
    required this.inscripcionId,
    required this.perfilVolId,
    required this.proyectoId,
    this.rolAsignado,
    required this.estado,
    this.horasComprometidasSemana,
    required this.creadoEn,
    this.proyecto,
    this.mensaje,
  });

  factory CrearParticipacionResponse.fromJson(Map<String, dynamic> json) {
    double? horas;
    final horasValue = json['horas_comprometidas_semana'];
    if (horasValue != null) {
      if (horasValue is double) {
        horas = horasValue;
      } else if (horasValue is int) {
        horas = horasValue.toDouble();
      } else {
        horas = double.tryParse(horasValue.toString());
      }
    }

    return CrearParticipacionResponse(
      idParticipacion: _getInt(json['id_participacion']),
      inscripcionId: _getInt(json['inscripcion_id']),
      perfilVolId: _getInt(json['perfil_vol_id']),
      proyectoId: _getInt(json['proyecto_id']),
      rolAsignado: _getString(json['rol_asignado']),
      estado: _getString(json['estado']) ?? 'pendiente',
      horasComprometidasSemana: horas,
      creadoEn: _parseDateTime(json['creado_en']),
      proyecto: json['proyecto'] != null
          ? ProyectoParticipacion.fromJson(json['proyecto'] as Map<String, dynamic>)
          : null,
      mensaje: _getString(json['mensaje']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_participacion': idParticipacion,
    'inscripcion_id': inscripcionId,
    'perfil_vol_id': perfilVolId,
    'proyecto_id': proyectoId,
    if (rolAsignado != null) 'rol_asignado': rolAsignado,
    'estado': estado,
    if (horasComprometidasSemana != null) 'horas_comprometidas_semana': horasComprometidasSemana,
    'creado_en': creadoEn.toIso8601String(),
    if (proyecto != null) 'proyecto': proyecto!.toJson(),
    if (mensaje != null) 'mensaje': mensaje,
  };

  @override
  List<Object?> get props => [
    idParticipacion, inscripcionId, perfilVolId, proyectoId,
    rolAsignado, estado, horasComprometidasSemana, creadoEn, proyecto, mensaje,
  ];
}

// ==================== HELPERS ====================

int _getInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? defaultValue;
}

String? _getString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}

DateTime? _parseDateTimeNullable(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      return null;
    }
  }
  return null;
}
