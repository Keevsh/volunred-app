import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/models/archivo_digital.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/services/media_service.dart';

class ProyectoMediaPage extends StatefulWidget {
  final Proyecto proyecto;

  const ProyectoMediaPage({super.key, required this.proyecto});

  @override
  State<ProyectoMediaPage> createState() => _ProyectoMediaPageState();
}

class _ProyectoMediaPageState extends State<ProyectoMediaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ArchivoDigital> _archivos = [];
  bool _isLoading = true;
  String? _error;
  bool _isUploading = false;
  int _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadArchivos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadArchivos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      final archivos = await funcionarioRepo.getArchivosDigitalesProyecto(
        widget.proyecto.idProyecto,
      );
      if (!mounted) return;
      setState(() {
        _archivos = archivos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _subirFoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    // Comprimir imagen manualmente
    final compressedFile = await _comprimirImagen(File(image.path));

    if (compressedFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al procesar la imagen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await _procesarArchivo(
      compressedFile,
      tipoMedia: 'imagen',
      mimeType: 'image/jpeg',
    );
  }

  /// Comprime una imagen a un tamaño manejable
  Future<File?> _comprimirImagen(File imageFile) async {
    try {
      // Leer imagen
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return null;

      // Redimensionar si es muy grande
      const maxDimension = 1024; // Máximo 1024px
      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width > image.height) {
          image = img.copyResize(image, width: maxDimension);
        } else {
          image = img.copyResize(image, height: maxDimension);
        }
      }

      // Comprimir a JPEG con calidad 60%
      final compressedBytes = img.encodeJpg(image, quality: 60);

      // Guardar en archivo temporal
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(compressedBytes);

      final originalSize = bytes.length / 1024; // KB
      final compressedSize = compressedBytes.length / 1024; // KB
      print('📸 Original: ${originalSize.toStringAsFixed(1)} KB');
      print('📸 Comprimido: ${compressedSize.toStringAsFixed(1)} KB');
      print(
        '📸 Reducción: ${((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)}%',
      );

      return tempFile;
    } catch (e) {
      print('❌ Error comprimiendo imagen: $e');
      return null;
    }
  }

  Future<void> _subirVideo() async {
    // Mostrar advertencia sobre tamaño de videos
    final continuar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subir Video'),
        content: const Text(
          '⚠️ Límite de tamaño: 20 MB\n\n'
          '✅ El video se comprimirá automáticamente:\n\n'
          '📱 Conversión automática:\n'
          '• Comprime a 720p\n'
          '• Reduce calidad inteligentemente\n'
          '• Mantiene audio de buena calidad\n\n'
          '💡 Tip: Máximo 60 segundos',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Seleccionar Video'),
          ),
        ],
      ),
    );

    if (continuar != true) return;

    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );

    if (video == null) return;

    final videoFile = File(video.path);

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    // Mostrar diálogo de compresión y progreso
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.cloud_upload, color: Colors.blue),
              const SizedBox(width: 12),
              Text(_uploadProgress < 100 ? 'Procesando video...' : '¡Listo!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _uploadProgress / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 16),
              Text(
                _uploadProgress == 0
                    ? 'Comprimiendo video...'
                    : _uploadProgress < 100
                    ? 'Subiendo: $_uploadProgress%'
                    : '✅ Video subido exitosamente',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (_uploadProgress > 0 && _uploadProgress < 100) ...[
                const SizedBox(height: 8),
                Text(
                  'Subiendo en chunks de 1 MB',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    try {
      final mediaService = MediaService();

      // Obtener el token de autenticación
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';

      print(
        '🔐 DEBUG: Token recuperado: ${token.isNotEmpty ? "SÍ (${token.length} chars)" : "NO"}',
      );

      await mediaService.subirVideoAlProyecto(
        videoFile: videoFile,
        proyectoId: widget.proyecto.idProyecto,
        jwtToken: token,
        nombreArchivo: 'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
        onProgress: (progreso) {
          setState(() {
            _uploadProgress = progreso;
          });
        },
      );

      if (!mounted) return;

      // Esperar un momento para que se vea el 100%
      await Future.delayed(const Duration(milliseconds: 500));

      Navigator.pop(context); // Cerrar diálogo de progreso

      // Recargar archivos
      await _loadArchivos();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Video subido exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('📋 CATCH ERROR EN WIDGET: $e');
      print('📋 Error type: ${e.runtimeType}');
      if (e is Exception) {
        print('📋 Exception message: ${e.toString()}');
      }

      if (!mounted) return;
      Navigator.pop(context); // Cerrar diálogo de progreso

      String errorMsg = e.toString();
      // Extraer mensaje más legible
      if (errorMsg.contains('Exception:')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $errorMsg'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
      });
    }
  }

  Future<void> _subirDocumento() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'],
      withData: false, // No cargar en memoria automáticamente
    );

    if (result == null) return;

    final file = File(result.files.single.path!);

    // Verificar tamaño antes de procesar
    final fileSize = await file.length();
    const maxSize = 5 * 1024 * 1024; // 5 MB (mismo límite que fotos)

    if (fileSize > maxSize) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Documento demasiado grande (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB).\n'
            'Máximo: 5 MB',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final extension = result.files.single.extension?.toLowerCase();

    String mimeType = 'application/octet-stream';
    if (extension == 'pdf') mimeType = 'application/pdf';
    if (extension == 'docx') {
      mimeType =
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (extension == 'xlsx') {
      mimeType =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (extension == 'pptx') {
      mimeType =
          'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }

    await _procesarArchivo(file, tipoMedia: 'documento', mimeType: mimeType);
  }

  Future<void> _procesarArchivo(
    File file, {
    required String tipoMedia,
    required String mimeType,
  }) async {
    setState(() => _isUploading = true);

    try {
      // Verificar tamaño del archivo según tipo
      final fileSize = await file.length();
      final maxSize = tipoMedia == 'video' ? 50 * 1024 * 1024 : 5 * 1024 * 1024;

      if (fileSize > maxSize) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Archivo demasiado grande (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB).\n'
              'Máximo permitido: ${tipoMedia == "video" ? "50 MB" : "5 MB"}',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );

        setState(() => _isUploading = false);
        return;
      }

      // Leer archivo y convertir a base64
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      // Verificar tamaño del base64 (aprox 1.37x el tamaño original)
      final base64Size = base64String.length;
      print('📊 Tamaño archivo: ${(fileSize / 1024).toStringAsFixed(1)} KB');
      print('📊 Tamaño base64: ${(base64Size / 1024).toStringAsFixed(1)} KB');
      print(
        '📊 Tamaño estimado request: ${((base64Size + 500) / 1024).toStringAsFixed(1)} KB',
      );

      // Obtener nombre del archivo
      final fileName = file.path.split('/').last;

      if (!mounted) return;

      // Mostrar progreso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Subiendo ${(fileSize / 1024).toStringAsFixed(0)} KB...',
                ),
              ),
            ],
          ),
          duration: const Duration(minutes: 2),
        ),
      );

      // Subir al backend
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      await funcionarioRepo.subirArchivoDigital(
        proyectoId: widget.proyecto.idProyecto,
        nombreArchivo: fileName,
        contenidoBase64: base64String,
        mimeType: mimeType,
        tipoMedia: tipoMedia,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('$tipoMedia subido correctamente'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      await _loadArchivos();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();

      String errorMessage = 'Error al subir archivo';
      if (e.toString().contains('413') || e.toString().contains('too large')) {
        errorMessage =
            '⚠️ Archivo demasiado grande para el servidor\n\n'
            'El límite del servidor es menor al esperado.\n'
            'Intenta con una foto más pequeña o de menor resolución.';
      } else if (e.toString().contains('timeout')) {
        errorMessage =
            'La subida tardó demasiado.\n'
            'Verifica tu conexión e intenta con un archivo más pequeño.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _eliminarArchivo(ArchivoDigital archivo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar "${archivo.nombreArchivo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      await funcionarioRepo.deleteArchivoDigital(archivo.idArchivo);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Archivo eliminado'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadArchivos();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<ArchivoDigital> _filtrarPorTipo(String tipo) {
    return _archivos.where((a) => a.tipoMedia == tipo).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Media - ${widget.proyecto.nombre}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.image), text: 'Fotos'),
            Tab(icon: Icon(Icons.video_library), text: 'Videos'),
            Tab(icon: Icon(Icons.description), text: 'Documentos'),
            Tab(icon: Icon(Icons.grid_on), text: 'Todo'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMediaGrid('imagen'),
                _buildMediaGrid('video'),
                _buildMediaGrid('documento'),
                _buildMediaGrid(null), // Todos
              ],
            ),
      floatingActionButton: _isUploading
          ? const CircularProgressIndicator()
          : SpeedDial(
              children: [
                SpeedDialChild(
                  child: const Icon(Icons.photo_camera),
                  label: 'Subir Foto',
                  onTap: _subirFoto,
                ),
                SpeedDialChild(
                  child: const Icon(Icons.videocam),
                  label: 'Subir Video',
                  onTap: _subirVideo,
                ),
                SpeedDialChild(
                  child: const Icon(Icons.upload_file),
                  label: 'Subir Documento',
                  onTap: _subirDocumento,
                ),
              ],
            ),
    );
  }

  Widget _buildMediaGrid(String? tipoFiltro) {
    final archivos = tipoFiltro == null
        ? _archivos
        : _filtrarPorTipo(tipoFiltro);

    if (archivos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay archivos',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: archivos.length,
      itemBuilder: (context, index) {
        final archivo = archivos[index];
        return _buildMediaCard(archivo);
      },
    );
  }

  Widget _buildMediaCard(ArchivoDigital archivo) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildPreview(archivo)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  archivo.nombreArchivo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _getTipoIcon(archivo.tipoMedia),
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        archivo.tipoMedia,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      onPressed: () => _eliminarArchivo(archivo),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ArchivoDigital archivo) {
    if (archivo.esImagen) {
      return Image.memory(
        base64Decode(archivo.contenidoBase64),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 48),
          );
        },
      );
    } else if (archivo.esVideo) {
      return Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.play_circle_outline,
              size: 64,
              color: Colors.white,
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'VIDEO',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (archivo.esDocumento) {
      return Container(
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getDocumentIcon(archivo.mimeType),
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            Text(
              _getExtension(archivo.nombreArchivo).toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.insert_drive_file, size: 48),
      );
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'imagen':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      case 'documento':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  IconData _getDocumentIcon(String mimeType) {
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word')) return Icons.description;
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) {
      return Icons.table_chart;
    }
    if (mimeType.contains('powerpoint') || mimeType.contains('presentation')) {
      return Icons.slideshow;
    }
    return Icons.insert_drive_file;
  }

  String _getExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last : '';
  }
}

// Speed Dial personalizado simple
class SpeedDial extends StatefulWidget {
  final List<SpeedDialChild> children;

  const SpeedDial({super.key, required this.children});

  @override
  State<SpeedDial> createState() => _SpeedDialState();
}

class _SpeedDialState extends State<SpeedDial>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ..._isOpen
            ? widget.children.reversed.map((child) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.white,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(child.label),
                        ),
                      ),
                      const SizedBox(width: 16),
                      FloatingActionButton(
                        mini: true,
                        onPressed: () {
                          child.onTap();
                          _toggle();
                        },
                        child: child.child,
                      ),
                    ],
                  ),
                );
              }).toList()
            : [],
        FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _animation,
          ),
        ),
      ],
    );
  }
}

class SpeedDialChild {
  final Widget child;
  final String label;
  final VoidCallback onTap;

  const SpeedDialChild({
    required this.child,
    required this.label,
    required this.onTap,
  });
}
