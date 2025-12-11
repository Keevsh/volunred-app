import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:path_provider/path_provider.dart';

import '../models/archivo_digital.dart';

/// Widget para previsualizar fotos y videos en pantalla completa
class MediaPreviewDialog extends StatefulWidget {
  final ArchivoDigital archivo;

  const MediaPreviewDialog({
    super.key,
    required this.archivo,
  });

  /// Muestra el diálogo de previsualización
  static Future<void> show(BuildContext context, ArchivoDigital archivo) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => MediaPreviewDialog(archivo: archivo),
    );
  }

  @override
  State<MediaPreviewDialog> createState() => _MediaPreviewDialogState();
}

class _MediaPreviewDialogState extends State<MediaPreviewDialog> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;
  File? _tempVideoFile;

  @override
  void initState() {
    super.initState();
    if (widget.archivo.esVideo) {
      _initializeVideo();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _initializeVideo() async {
    try {
      // Decodificar el video base64 y guardarlo temporalmente
      final bytes = base64Decode(widget.archivo.contenidoBase64);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/temp_video_${widget.archivo.idArchivo}.${_getExtension(widget.archivo.nombreArchivo)}',
      );
      await tempFile.writeAsBytes(bytes);
      _tempVideoFile = tempFile;

      _videoController = VideoPlayerController.file(tempFile);
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error al reproducir video',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error al cargar el video: $e';
        });
      }
    }
  }

  String _getExtension(String filename) {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last : 'mp4';
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    // Eliminar archivo temporal
    _tempVideoFile?.delete().catchError((_) => File(''));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(
            widget.archivo.esImagen ? Icons.image : Icons.videocam,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.archivo.nombreArchivo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Cargando...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (widget.archivo.esImagen) {
      return _buildImagePreview();
    } else if (widget.archivo.esVideo) {
      return _buildVideoPreview();
    }

    return const Center(
      child: Text(
        'Tipo de archivo no soportado',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildImagePreview() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.memory(
          base64Decode(widget.archivo.contenidoBase64),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Error al cargar la imagen',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_chewieController == null) {
      return const Center(
        child: Text(
          'Error al inicializar el reproductor',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }
}

/// Widget para mostrar thumbnail de video con botón de play
class VideoThumbnailWidget extends StatelessWidget {
  final ArchivoDigital archivo;
  final VoidCallback? onTap;

  const VideoThumbnailWidget({
    super.key,
    required this.archivo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Fondo con gradiente
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[800]!,
                    Colors.black,
                  ],
                ),
              ),
            ),
            // Icono de video
            const Icon(
              Icons.movie,
              size: 40,
              color: Colors.white24,
            ),
            // Botón de play
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(230),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(76),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow,
                size: 32,
                color: Colors.black87,
              ),
            ),
            // Badge de video
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'VIDEO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para mostrar thumbnail de imagen con zoom
class ImageThumbnailWidget extends StatelessWidget {
  final ArchivoDigital archivo;
  final VoidCallback? onTap;

  const ImageThumbnailWidget({
    super.key,
    required this.archivo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            base64Decode(archivo.contenidoBase64),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 48),
              );
            },
          ),
          // Overlay con icono de zoom
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.zoom_in,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
