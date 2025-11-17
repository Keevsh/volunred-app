import 'package:equatable/equatable.dart';

/// Modelo de Organización
/// 
/// Representa una organización en el sistema.
/// 
/// Relaciones:
/// - **Proyectos (1:N)**: Una organización puede tener muchos proyectos.
///   Los proyectos se relacionan con la organización mediante `organizacion_id`.
///   Para obtener los proyectos de una organización, consulta la tabla `proyectos`
///   filtrando por `organizacion_id`.
/// - **Categoría (N:1)**: Una organización pertenece a una categoría.
/// - **Funcionarios (1:N)**: Una organización puede tener muchos funcionarios
///   (a través de `perfiles_funcionarios`).
/// - **Inscripciones (1:N)**: Una organización puede recibir muchas inscripciones
///   de voluntarios (a través de `inscripciones`).
class Organizacion extends Equatable {
  /// ID único de la organización
  final int idOrganizacion;
  
  /// Nombre de la organización
  final String nombre;
  
  /// Descripción de la organización (opcional)
  final String? descripcion;
  
  /// Dirección de la organización (opcional)
  final String? direccion;
  
  /// Teléfono de la organización (opcional)
  final String? telefono;
  
  /// Email de la organización
  final String email;
  
  /// Sitio web de la organización (opcional)
  final String? sitioWeb;
  
  /// ID de la categoría de la organización
  final int idCategoriaOrganizacion;
  
  /// RUC de la organización (opcional)
  final String? ruc;
  
  /// Razón social de la organización (opcional)
  final String? razonSocial;
  
  /// Estado de la organización (activo/inactivo)
  final String estado;
  
  /// Logo de la organización en formato base64 (opcional)
  final String? logo;
  
  /// Fecha de creación de la organización
  final DateTime creadoEn;
  
  /// Fecha de última actualización de la organización (opcional)
  final DateTime? actualizadoEn;
  
  // Relaciones opcionales (se incluyen cuando se hace join en la consulta)
  
  /// Datos de la categoría de la organización (opcional, se incluye cuando se hace join)
  final Map<String, dynamic>? categoriaOrganizacion;
  
  // NOTA: Los proyectos de la organización no se incluyen directamente en este modelo
  // porque es una relación 1:N. Para obtener los proyectos de una organización,
  // consulta la tabla `proyectos` filtrando por `organizacion_id`.

  const Organizacion({
    required this.idOrganizacion,
    required this.nombre,
    this.descripcion,
    this.direccion,
    this.telefono,
    required this.email,
    this.sitioWeb,
    required this.idCategoriaOrganizacion,
    this.ruc,
    this.razonSocial,
    required this.estado,
    this.logo,
    required this.creadoEn,
    this.actualizadoEn,
    this.categoriaOrganizacion,
  });

  factory Organizacion.fromJson(Map<String, dynamic> json) {
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
      
      // Handle different field name variations from API
      // API might return 'nombre', 'nombre_corto', or 'nombre_legal'
      final nombre = _getString(json['nombre']) ?? 
                     _getString(json['nombre_corto']) ?? 
                     _getString(json['nombre_legal']) ?? 
                     '';
      
      // API might return 'email' or 'correo'
      final email = _getString(json['email']) ?? 
                    _getString(json['correo']) ?? 
                    '';
      
      if (email.isEmpty) {
        throw Exception('Email is required but was not found in response');
      }
      
      // Handle creado_en - might be missing in creation response
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
      
      // Safely parse id_organizacion
      if (json['id_organizacion'] == null) {
        throw Exception('id_organizacion is required but was null');
      }
      final idOrg = _getInt(json['id_organizacion']);
      if (idOrg == 0) {
        throw Exception('id_organizacion cannot be 0');
      }
      
      // Manejar logo (puede ser muy grande si es base64)
      String? logo;
      try {
        logo = _getString(json['logo']);
        if (logo != null && logo.isNotEmpty) {
          // Validar que sea un base64 válido o URL
          if (!logo.startsWith('data:image/') && !logo.startsWith('http')) {
            print('⚠️ Logo inválido detectado, ignorando');
            logo = null;
          }
        }
      } catch (e) {
        print('⚠️ Error procesando logo: $e');
        logo = null;
      }
      
      return Organizacion(
        idOrganizacion: idOrg,
        nombre: nombre,
        descripcion: _getString(json['descripcion']),
        direccion: _getString(json['direccion']),
        telefono: _getString(json['telefono']),
        email: email,
        sitioWeb: _getString(json['sitio_web']),
        idCategoriaOrganizacion: _getInt(json['id_categoria_organizacion']),
        ruc: _getString(json['ruc']),
        razonSocial: _getString(json['razon_social']) ?? _getString(json['nombre_legal']),
        estado: _getString(json['estado']) ?? 'activo',
        logo: logo,
        creadoEn: creadoEn,
        actualizadoEn: actualizadoEn,
        categoriaOrganizacion: json['categoria_organizacion'] is Map 
            ? json['categoria_organizacion'] as Map<String, dynamic>? 
            : null,
      );
    } catch (e, stackTrace) {
      throw Exception('Error parsing Organizacion from JSON: $e\nJSON: $json\nStackTrace: $stackTrace');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_organizacion': idOrganizacion,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (direccion != null) 'direccion': direccion,
      if (telefono != null) 'telefono': telefono,
      'email': email,
      if (sitioWeb != null) 'sitio_web': sitioWeb,
      'id_categoria_organizacion': idCategoriaOrganizacion,
      if (ruc != null) 'ruc': ruc,
      if (razonSocial != null) 'razon_social': razonSocial,
      'estado': estado,
      if (logo != null) 'logo': logo,
      'creado_en': creadoEn.toIso8601String(),
      if (actualizadoEn != null) 'actualizado_en': actualizadoEn!.toIso8601String(),
      if (categoriaOrganizacion != null) 'categoria_organizacion': categoriaOrganizacion,
    };
  }

  @override
  List<Object?> get props => [
        idOrganizacion,
        nombre,
        descripcion,
        direccion,
        telefono,
        email,
        sitioWeb,
        idCategoriaOrganizacion,
        ruc,
        razonSocial,
        estado,
        logo,
        creadoEn,
        actualizadoEn,
      ];
}
