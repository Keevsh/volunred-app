/// Enums para estados y valores predefinidos en la API

/// Estados generales (organizaciones, aptitudes, roles, etc.)
enum EstadoGeneral {
  activo,
  inactivo;

  String get value {
    switch (this) {
      case EstadoGeneral.activo:
        return 'activo';
      case EstadoGeneral.inactivo:
        return 'inactivo';
    }
  }

  static EstadoGeneral fromString(String value) {
    switch (value.toLowerCase()) {
      case 'activo':
        return EstadoGeneral.activo;
      case 'inactivo':
        return EstadoGeneral.inactivo;
      default:
        return EstadoGeneral.activo;
    }
  }
}

/// Estados de proyecto
enum EstadoProyecto {
  planificacion,
  activo,
  enProgreso,
  completado,
  cancelado;

  String get value {
    switch (this) {
      case EstadoProyecto.planificacion:
        return 'planificacion';
      case EstadoProyecto.activo:
        return 'activo';
      case EstadoProyecto.enProgreso:
        return 'en_progreso';
      case EstadoProyecto.completado:
        return 'completado';
      case EstadoProyecto.cancelado:
        return 'cancelado';
    }
  }

  static EstadoProyecto fromString(String value) {
    switch (value.toLowerCase()) {
      case 'planificacion':
        return EstadoProyecto.planificacion;
      case 'activo':
        return EstadoProyecto.activo;
      case 'en_progreso':
        return EstadoProyecto.enProgreso;
      case 'completado':
        return EstadoProyecto.completado;
      case 'cancelado':
        return EstadoProyecto.cancelado;
      default:
        return EstadoProyecto.planificacion;
    }
  }

  String get displayName {
    switch (this) {
      case EstadoProyecto.planificacion:
        return 'Planificación';
      case EstadoProyecto.activo:
        return 'Activo';
      case EstadoProyecto.enProgreso:
        return 'En Progreso';
      case EstadoProyecto.completado:
        return 'Completado';
      case EstadoProyecto.cancelado:
        return 'Cancelado';
    }
  }
}

/// Estados de tarea
enum EstadoTarea {
  pendiente,
  enProgreso,
  completada,
  cancelada;

  String get value {
    switch (this) {
      case EstadoTarea.pendiente:
        return 'pendiente';
      case EstadoTarea.enProgreso:
        return 'en_progreso';
      case EstadoTarea.completada:
        return 'completada';
      case EstadoTarea.cancelada:
        return 'cancelada';
    }
  }

  static EstadoTarea fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pendiente':
        return EstadoTarea.pendiente;
      case 'en_progreso':
        return EstadoTarea.enProgreso;
      case 'completada':
        return EstadoTarea.completada;
      case 'cancelada':
        return EstadoTarea.cancelada;
      default:
        return EstadoTarea.pendiente;
    }
  }

  String get displayName {
    switch (this) {
      case EstadoTarea.pendiente:
        return 'Pendiente';
      case EstadoTarea.enProgreso:
        return 'En Progreso';
      case EstadoTarea.completada:
        return 'Completada';
      case EstadoTarea.cancelada:
        return 'Cancelada';
    }
  }
}

/// Estados de inscripción
enum EstadoInscripcion {
  pendiente,
  aprobado,
  rechazado;

  String get value {
    switch (this) {
      case EstadoInscripcion.pendiente:
        return 'pendiente';
      case EstadoInscripcion.aprobado:
        return 'aprobado';
      case EstadoInscripcion.rechazado:
        return 'rechazado';
    }
  }

  static EstadoInscripcion fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pendiente':
        return EstadoInscripcion.pendiente;
      case 'aprobado':
        return EstadoInscripcion.aprobado;
      case 'rechazado':
        return EstadoInscripcion.rechazado;
      default:
        return EstadoInscripcion.pendiente;
    }
  }

  String get displayName {
    switch (this) {
      case EstadoInscripcion.pendiente:
        return 'Pendiente';
      case EstadoInscripcion.aprobado:
        return 'Aprobado';
      case EstadoInscripcion.rechazado:
        return 'Rechazado';
    }
  }
}

/// Estados de participación
enum EstadoParticipacion {
  programada,
  enProgreso,
  completado,
  ausente;

  String get value {
    switch (this) {
      case EstadoParticipacion.programada:
        return 'programada';
      case EstadoParticipacion.enProgreso:
        return 'en_progreso';
      case EstadoParticipacion.completado:
        return 'completado';
      case EstadoParticipacion.ausente:
        return 'ausente';
    }
  }

  static EstadoParticipacion fromString(String value) {
    switch (value.toLowerCase()) {
      case 'programada':
        return EstadoParticipacion.programada;
      case 'en_progreso':
        return EstadoParticipacion.enProgreso;
      case 'completado':
        return EstadoParticipacion.completado;
      case 'ausente':
        return EstadoParticipacion.ausente;
      default:
        return EstadoParticipacion.programada;
    }
  }

  String get displayName {
    switch (this) {
      case EstadoParticipacion.programada:
        return 'Programada';
      case EstadoParticipacion.enProgreso:
        return 'En Progreso';
      case EstadoParticipacion.completado:
        return 'Completado';
      case EstadoParticipacion.ausente:
        return 'Ausente';
    }
  }
}

/// Estados de asignación de tareas
enum EstadoAsignacion {
  asignada,
  enProgreso,
  completada,
  cancelada;

  String get value {
    switch (this) {
      case EstadoAsignacion.asignada:
        return 'asignada';
      case EstadoAsignacion.enProgreso:
        return 'en_progreso';
      case EstadoAsignacion.completada:
        return 'completada';
      case EstadoAsignacion.cancelada:
        return 'cancelada';
    }
  }

  static EstadoAsignacion fromString(String value) {
    switch (value.toLowerCase()) {
      case 'asignada':
        return EstadoAsignacion.asignada;
      case 'en_progreso':
        return EstadoAsignacion.enProgreso;
      case 'completada':
        return EstadoAsignacion.completada;
      case 'cancelada':
        return EstadoAsignacion.cancelada;
      default:
        return EstadoAsignacion.asignada;
    }
  }

  String get displayName {
    switch (this) {
      case EstadoAsignacion.asignada:
        return 'Asignada';
      case EstadoAsignacion.enProgreso:
        return 'En Progreso';
      case EstadoAsignacion.completada:
        return 'Completada';
      case EstadoAsignacion.cancelada:
        return 'Cancelada';
    }
  }
}

/// Prioridad de tareas
enum PrioridadTarea {
  baja,
  media,
  alta;

  String get value {
    switch (this) {
      case PrioridadTarea.baja:
        return 'baja';
      case PrioridadTarea.media:
        return 'media';
      case PrioridadTarea.alta:
        return 'alta';
    }
  }

  static PrioridadTarea fromString(String value) {
    switch (value.toLowerCase()) {
      case 'baja':
        return PrioridadTarea.baja;
      case 'media':
        return PrioridadTarea.media;
      case 'alta':
        return PrioridadTarea.alta;
      default:
        return PrioridadTarea.media;
    }
  }

  String get displayName {
    switch (this) {
      case PrioridadTarea.baja:
        return 'Baja';
      case PrioridadTarea.media:
        return 'Media';
      case PrioridadTarea.alta:
        return 'Alta';
    }
  }
}

/// Sexo del usuario
enum Sexo {
  masculino,
  femenino,
  otro;

  String get value {
    switch (this) {
      case Sexo.masculino:
        return 'M';
      case Sexo.femenino:
        return 'F';
      case Sexo.otro:
        return 'O';
    }
  }

  static Sexo fromString(String value) {
    switch (value.toUpperCase()) {
      case 'M':
        return Sexo.masculino;
      case 'F':
        return Sexo.femenino;
      case 'O':
        return Sexo.otro;
      default:
        return Sexo.otro;
    }
  }

  String get displayName {
    switch (this) {
      case Sexo.masculino:
        return 'Masculino';
      case Sexo.femenino:
        return 'Femenino';
      case Sexo.otro:
        return 'Otro';
    }
  }
}

/// Tipo de usuario (para determinar flujo)
enum TipoUsuario {
  voluntario,
  funcionario;

  String get value {
    switch (this) {
      case TipoUsuario.voluntario:
        return 'voluntario';
      case TipoUsuario.funcionario:
        return 'funcionario';
    }
  }

  String get displayName {
    switch (this) {
      case TipoUsuario.voluntario:
        return 'Voluntario';
      case TipoUsuario.funcionario:
        return 'Funcionario';
    }
  }
}
