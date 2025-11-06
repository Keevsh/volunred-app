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
    return Organizacion(
      idOrganizacion: json['id_organizacion'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String,
      sitioWeb: json['sitio_web'] as String?,
      idCategoriaOrganizacion: json['id_categoria_organizacion'] as int,
      ruc: json['ruc'] as String?,
      razonSocial: json['razon_social'] as String?,
      estado: json['estado'] as String,
      creadoEn: DateTime.parse(json['creado_en'] as String),
      actualizadoEn: json['actualizado_en'] != null
          ? DateTime.parse(json['actualizado_en'] as String)
          : null,
      categoriaOrganizacion: json['categoria_organizacion'] as Map<String, dynamic>?,
    );
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
