import 'package:equatable/equatable.dart';

class Organizacion extends Equatable {
  final int idOrganizacion;
  final String nombre;
  final String? descripcion;
  final String? direccion;
  final String? telefono;
  final String email;
  final String? sitioWeb;
  final int idCategoriaOrganizacion;
  final String? ruc;
  final String? razonSocial;
  final String estado;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;
  
  // Relaciones opcionales
  final Map<String, dynamic>? categoriaOrganizacion;

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
        creadoEn,
        actualizadoEn,
      ];
}
