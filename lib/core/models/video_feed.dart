import 'package:equatable/equatable.dart';

/// Información del proyecto asociado a un video del feed
class VideoProyectoInfo extends Equatable {
  final int idProyecto;
  final String nombre;
  final String? objetivo;
  final String? ubicacion;
  final String estado;
  final String? organizacionNombre;
  final String? imagenProyecto;

  const VideoProyectoInfo({
    required this.idProyecto,
    required this.nombre,
    this.objetivo,
    this.ubicacion,
    required this.estado,
    this.organizacionNombre,
    this.imagenProyecto,
  });

  factory VideoProyectoInfo.fromJson(Map<String, dynamic> json) {
    return VideoProyectoInfo(
      idProyecto: json['id_proyecto'] is int
          ? json['id_proyecto'] as int
          : int.tryParse(json['id_proyecto'].toString()) ?? 0,
      nombre: json['nombre']?.toString() ?? 'Proyecto',
      objetivo: json['objetivo']?.toString(),
      ubicacion: json['ubicacion']?.toString(),
      estado: json['estado']?.toString() ?? 'activo',
      organizacionNombre: json['organizacion_nombre']?.toString(),
      imagenProyecto: json['imagen_proyecto']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        idProyecto,
        nombre,
        objetivo,
        ubicacion,
        estado,
        organizacionNombre,
        imagenProyecto,
      ];
}

/// Item individual del feed de videos
class VideoFeedItem extends Equatable {
  final int idArchivo;
  final String nombreArchivo;
  final String mimeType;
  final String? contenidoBase64; // Opcional: solo viene cuando se pide el video individual
  final DateTime creadoEn;
  final VideoProyectoInfo proyecto;

  const VideoFeedItem({
    required this.idArchivo,
    required this.nombreArchivo,
    required this.mimeType,
    this.contenidoBase64,
    required this.creadoEn,
    required this.proyecto,
  });

  /// Indica si el video tiene contenido cargado
  bool get tieneContenido => contenidoBase64 != null && contenidoBase64!.isNotEmpty;

  /// Crea una copia del item con el contenido base64
  VideoFeedItem copyWithContenido(String contenido) {
    return VideoFeedItem(
      idArchivo: idArchivo,
      nombreArchivo: nombreArchivo,
      mimeType: mimeType,
      contenidoBase64: contenido,
      creadoEn: creadoEn,
      proyecto: proyecto,
    );
  }

  factory VideoFeedItem.fromJson(Map<String, dynamic> json) {
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

    return VideoFeedItem(
      idArchivo: json['id_archivo'] is int
          ? json['id_archivo'] as int
          : int.tryParse(json['id_archivo'].toString()) ?? 0,
      nombreArchivo: json['nombre_archivo']?.toString() ?? 'video.mp4',
      mimeType: json['mime_type']?.toString() ?? 'video/mp4',
      contenidoBase64: json['contenido_base64']?.toString(),
      creadoEn: creadoEn,
      proyecto: json['proyecto'] is Map<String, dynamic>
          ? VideoProyectoInfo.fromJson(json['proyecto'] as Map<String, dynamic>)
          : VideoProyectoInfo(
              idProyecto: 0,
              nombre: 'Proyecto desconocido',
              estado: 'activo',
            ),
    );
  }

  /// Obtiene la URI de datos para reproducir el video
  String? get videoDataUri => contenidoBase64 != null 
      ? 'data:$mimeType;base64,$contenidoBase64' 
      : null;

  @override
  List<Object?> get props => [
        idArchivo,
        nombreArchivo,
        mimeType,
        creadoEn,
        proyecto,
      ];
}

/// Respuesta paginada del feed de videos
class VideoFeedResponse extends Equatable {
  final List<VideoFeedItem> items;
  final int total;
  final int pagina;
  final int limite;
  final bool tieneMas;

  const VideoFeedResponse({
    required this.items,
    required this.total,
    required this.pagina,
    required this.limite,
    required this.tieneMas,
  });

  factory VideoFeedResponse.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];

    return VideoFeedResponse(
      items: itemsList
          .whereType<Map<String, dynamic>>()
          .map((item) => VideoFeedItem.fromJson(item))
          .toList(),
      total: json['total'] is int
          ? json['total'] as int
          : int.tryParse(json['total'].toString()) ?? 0,
      pagina: json['pagina'] is int
          ? json['pagina'] as int
          : int.tryParse(json['pagina'].toString()) ?? 1,
      limite: json['limite'] is int
          ? json['limite'] as int
          : int.tryParse(json['limite'].toString()) ?? 10,
      tieneMas: json['tiene_mas'] == true,
    );
  }

  @override
  List<Object?> get props => [items, total, pagina, limite, tieneMas];
}
