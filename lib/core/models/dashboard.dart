import 'package:equatable/equatable.dart';

/// Modelo de Dashboard
/// 
/// Representa el resumen del dashboard para funcionarios.
/// Contiene estadísticas generales de proyectos, tareas, inscripciones y participaciones.
class Dashboard extends Equatable {
  /// Total de proyectos de la organización
  final int totalProyectos;
  
  /// Total de tareas de todos los proyectos
  final int totalTareas;
  
  /// Número de inscripciones pendientes de aprobación
  final int inscripcionesPendientes;
  
  /// Total de participaciones (voluntarios asignados a proyectos)
  final int totalParticipaciones;

  const Dashboard({
    required this.totalProyectos,
    required this.totalTareas,
    required this.inscripcionesPendientes,
    required this.totalParticipaciones,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    // El JSON puede venir directamente o dentro de un objeto 'resumen'
    final data = json['resumen'] ?? json;
    
    return Dashboard(
      totalProyectos: (data['total_proyectos'] ?? 0) as int,
      totalTareas: (data['total_tareas'] ?? 0) as int,
      inscripcionesPendientes: (data['inscripciones_pendientes'] ?? 0) as int,
      totalParticipaciones: (data['total_participaciones'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_proyectos': totalProyectos,
      'total_tareas': totalTareas,
      'inscripciones_pendientes': inscripcionesPendientes,
      'total_participaciones': totalParticipaciones,
    };
  }

  @override
  List<Object?> get props => [
        totalProyectos,
        totalTareas,
        inscripcionesPendientes,
        totalParticipaciones,
      ];
}

