import 'package:equatable/equatable.dart';

/// Modelo de Categoría
/// 
/// Representa una categoría genérica que se puede asignar a proyectos.
/// Las categorías son etiquetas que permiten organizar y clasificar proyectos.
/// 
/// Relaciones:
/// - **Proyectos (Many-to-Many)**: Una categoría puede estar en múltiples proyectos
///   y un proyecto puede tener múltiples categorías.
///   La relación se establece mediante la tabla intermedia `categorias_proyectos`.
class Categoria extends Equatable {
  /// ID único de la categoría
  final int idCategoria;
  
  /// Nombre de la categoría (único)
  final String nombre;
  
  /// Descripción de la categoría (opcional)
  final String? descripcion;
  
  /// Fecha de creación de la categoría
  final DateTime creadoEn;
  
  /// Fecha de última actualización (opcional)
  final DateTime? actualizadoEn;

  // Relaciones opcionales (se incluyen cuando se hace join en la consulta)
  
  /// Lista de relaciones categoría-proyecto (opcional, se incluye cuando se hace join)
  /// Contiene información sobre qué proyectos tienen esta categoría
  final List<dynamic>? categoriasProyectos;

  const Categoria({
    required this.idCategoria,
    required this.nombre,
    this.descripcion,
    required this.creadoEn,
    this.actualizadoEn,
    this.categoriasProyectos,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to safely get string value
      String? _getString(dynamic value) {
        if (value == null) return null;
        return value.toString();
      }
      
      // Helper function to safely get int value
      int _getInt(dynamic value, {int defaultValue = 0}) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        return int.tryParse(value.toString()) ?? defaultValue;
      }
      
      // Handle creado_en
      DateTime creadoEn;
      final creadoEnValue = json['creado_en'];
      if (creadoEnValue != null && creadoEnValue is String) {
        try {
          creadoEn = DateTime.parse(creadoEnValue);
        } catch (e) {
          creadoEn = DateTime.now();
        }
      } else {
        creadoEn = DateTime.now();
      }
      
      // Handle actualizado_en
      DateTime? actualizadoEn;
      final actualizadoEnValue = json['actualizado_en'];
      if (actualizadoEnValue != null && actualizadoEnValue is String) {
        try {
          actualizadoEn = DateTime.parse(actualizadoEnValue);
        } catch (e) {
          actualizadoEn = null;
        }
      }
      
      return Categoria(
        idCategoria: _getInt(json['id_categoria']),
        nombre: _getString(json['nombre']) ?? '',
        descripcion: _getString(json['descripcion']),
        creadoEn: creadoEn,
        actualizadoEn: actualizadoEn,
        categoriasProyectos: json['categoriasProyectos'] is List 
            ? json['categoriasProyectos'] as List<dynamic>? 
            : null,
      );
    } catch (e, stackTrace) {
      throw Exception('Error parsing Categoria from JSON: $e\nJSON: $json\nStackTrace: $stackTrace');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_categoria': idCategoria,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      'creado_en': creadoEn.toIso8601String(),
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn!.toIso8601String(),
      if (categoriasProyectos != null) 'categoriasProyectos': categoriasProyectos,
    };
  }

  @override
  List<Object?> get props => [
        idCategoria,
        nombre,
        descripcion,
        creadoEn,
        actualizadoEn,
      ];
}

