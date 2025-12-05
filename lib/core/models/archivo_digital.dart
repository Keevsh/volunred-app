import 'package:equatable/equatable.dart';

class ArchivoDigital extends Equatable {
  final int idArchivo;
  final int proyectoId;
  final String nombreArchivo;
  final String contenidoBase64;
  final String mimeType;
  final String tipoMedia; // "imagen", "video", "audio", "documento"
  final DateTime creadoEn;
  final Map<String, dynamic>? proyecto;

  const ArchivoDigital({
    required this.idArchivo,
    required this.proyectoId,
    required this.nombreArchivo,
    required this.contenidoBase64,
    required this.mimeType,
    required this.tipoMedia,
    required this.creadoEn,
    this.proyecto,
  });

  factory ArchivoDigital.fromJson(Map<String, dynamic> json) {
    return ArchivoDigital(
      idArchivo: json['id_archivo'] is int
          ? json['id_archivo'] as int
          : int.tryParse(json['id_archivo'].toString()) ?? 0,
      proyectoId: json['proyecto_id'] is int
          ? json['proyecto_id'] as int
          : int.tryParse(json['proyecto_id'].toString()) ?? 0,
      nombreArchivo: json['nombre_archivo']?.toString() ?? '',
      contenidoBase64: json['contenido_base64']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? 'application/octet-stream',
      tipoMedia: json['tipo_media']?.toString() ?? 'documento',
      creadoEn: json['creado_en'] != null
          ? DateTime.tryParse(json['creado_en'].toString()) ?? DateTime.now()
          : DateTime.now(),
      proyecto: json['proyecto'] is Map
          ? json['proyecto'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_archivo': idArchivo,
      'proyecto_id': proyectoId,
      'nombre_archivo': nombreArchivo,
      'contenido_base64': contenidoBase64,
      'mime_type': mimeType,
      'tipo_media': tipoMedia,
      'creado_en': creadoEn.toIso8601String(),
      if (proyecto != null) 'proyecto': proyecto,
    };
  }

  // Helpers para determinar tipo de archivo
  bool get esImagen => tipoMedia == 'imagen';
  bool get esVideo => tipoMedia == 'video';
  bool get esAudio => tipoMedia == 'audio';
  bool get esDocumento => tipoMedia == 'documento';

  // Helper para obtener URL base64 completa
  String get dataUrl => 'data:$mimeType;base64,$contenidoBase64';

  @override
  List<Object?> get props => [
        idArchivo,
        proyectoId,
        nombreArchivo,
        mimeType,
        tipoMedia,
        creadoEn,
      ];
}
