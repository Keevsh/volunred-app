import 'package:equatable/equatable.dart';
import 'aplicacion.dart';

/// Modelo de Programa
/// 
/// Representa una acción/operación del sistema que puede ser asignada a un rol.
/// Los programas son las acciones específicas que los usuarios pueden realizar
/// dependiendo de su rol.
/// 
/// Los programas se relacionan con los roles a través de la tabla intermedia `permisos`:
/// - Un rol puede tener múltiples programas (acciones permitidas)
/// - Un programa puede estar asignado a múltiples roles
/// - La relación se establece en la tabla `permisos` (id_rol, id_programa)
/// 
/// Ejemplo de programas: "Crear proyecto", "Eliminar usuario", "Ver reportes", etc.
class Programa extends Equatable {
  /// ID único del programa
  final int idPrograma;
  
  /// Nombre del programa (acción)
  final String nombre;
  
  /// Descripción opcional del programa
  final String? descripcion;
  
  /// Estado del programa (activo/inactivo)
  final String estado;
  
  /// ID de la aplicación a la que pertenece este programa
  final int idAplicacion;
  
  /// Datos de la aplicación (opcional, se incluye cuando se hace join)
  final Aplicacion? aplicacion;

  const Programa({
    required this.idPrograma,
    required this.nombre,
    this.descripcion,
    this.estado = 'activo',
    required this.idAplicacion,
    this.aplicacion,
  });

  factory Programa.fromJson(Map<String, dynamic> json) {
    // Helper function to safely get int value
    int? _getInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }
    
    return Programa(
      idPrograma: _getInt(json['id_programa']) ?? 0,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      estado: json['estado'] as String? ?? 'activo',
      idAplicacion: _getInt(json['id_aplicacion']) ?? 0,
      aplicacion: json['aplicacion'] != null
          ? Aplicacion.fromJson(json['aplicacion'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_programa': idPrograma,
      'nombre': nombre,
      'descripcion': descripcion,
      'estado': estado,
      'id_aplicacion': idAplicacion,
      if (aplicacion != null) 'aplicacion': aplicacion!.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        idPrograma,
        nombre,
        descripcion,
        estado,
        idAplicacion,
        aplicacion,
      ];
}
