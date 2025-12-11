import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/models/video_feed.dart';
import '../../../core/repositories/voluntario_repository.dart';

class VideoFeedPage extends StatefulWidget {
  final bool isActive;
  
  const VideoFeedPage({super.key, this.isActive = true});

  @override
  State<VideoFeedPage> createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<VideoFeedPage> with WidgetsBindingObserver {
  final VoluntarioRepository _repository = Modular.get<VoluntarioRepository>();
  final PageController _pageController = PageController();

  List<VideoFeedItem> _videos = [];
  int _pagina = 1;
  bool _tieneMas = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentIndex = 0;
  bool _isVisible = true;

  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, String> _tempFilePaths = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Inicializar _isVisible basado en el parámetro isActive
    _isVisible = widget.isActive;
    _cargarVideos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pausarTodosLosVideos();
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _limpiarArchivosTemporal();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pausar cuando la app va al background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pausarTodosLosVideos();
    } else if (state == AppLifecycleState.resumed && _isVisible) {
      // Reanudar solo si el widget está visible
      _reanudarVideoActual();
    }
  }

  @override
  void didUpdateWidget(VideoFeedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Detectar cambio en isActive desde el padre (HomePage)
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _isVisible = true;
        _reanudarVideoActual();
      } else {
        _isVisible = false;
        _pausarTodosLosVideos();
      }
    }
  }

  void _pausarTodosLosVideos() {
    for (final controller in _controllers.values) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  void _reanudarVideoActual() {
    if (_controllers.containsKey(_currentIndex)) {
      final controller = _controllers[_currentIndex]!;
      if (controller.value.isInitialized && !controller.value.isPlaying) {
        controller.play();
      }
    }
  }

  Future<void> _limpiarArchivosTemporal() async {
    for (final path in _tempFilePaths.values) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error eliminando archivo temporal: $e');
      }
    }
  }

  Future<void> _cargarVideos({bool refresh = false}) async {
    if (_isLoadingMore) return;
    if (!refresh && !_tieneMas && _pagina > 1) return;

    setState(() {
      if (refresh) {
        _isLoading = true;
        _pagina = 1;
      } else if (_pagina > 1) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
      }
      _error = null;
    });

    try {
      final response = await _repository.getFeedVideos(
        pagina: refresh ? 1 : _pagina,
        limite: 2, // Cargar solo 2 videos a la vez para optimizar
        orden: 'aleatorio',
      );

      if (!mounted) return;

      setState(() {
        if (refresh || _pagina == 1) {
          _videos = response.items;
        } else {
          _videos.addAll(response.items);
        }
        _tieneMas = response.tieneMas;
        _pagina = (refresh ? 1 : _pagina) + 1;
        _isLoading = false;
        _isLoadingMore = false;
      });

      // Pre-cargar el primer video
      if (_videos.isNotEmpty && !_controllers.containsKey(0)) {
        _inicializarVideo(0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _inicializarVideo(int index) async {
    if (index < 0 || index >= _videos.length) return;
    if (_controllers.containsKey(index)) return;

    final video = _videos[index];

    try {
      // Decodificar base64 y guardar como archivo temporal
      final bytes = base64Decode(video.contenidoBase64);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/video_${video.idArchivo}.mp4');
      await tempFile.writeAsBytes(bytes);

      _tempFilePaths[index] = tempFile.path;

      final controller = VideoPlayerController.file(tempFile);
      await controller.initialize();
      controller.setLooping(true);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controllers[index] = controller;
      });

      // Si es el video actual Y el widget está visible, reproducirlo
      if (index == _currentIndex && _isVisible) {
        controller.play();
      }
    } catch (e) {
      print('Error inicializando video $index: $e');
    }
  }

  void _onPageChanged(int index) {
    // Pausar video anterior
    if (_controllers.containsKey(_currentIndex)) {
      _controllers[_currentIndex]!.pause();
    }

    setState(() {
      _currentIndex = index;
    });

    // Reproducir video actual solo si está visible
    if (_controllers.containsKey(index)) {
      if (_isVisible) {
        _controllers[index]!.play();
      }
    } else {
      _inicializarVideo(index);
    }

    // Pre-cargar siguiente video
    if (index + 1 < _videos.length && !_controllers.containsKey(index + 1)) {
      _inicializarVideo(index + 1);
    }

    // Cargar más videos si estamos cerca del final
    if (index >= _videos.length - 2 && _tieneMas && !_isLoadingMore) {
      _cargarVideos();
    }

    // Limpiar videos lejanos para liberar memoria
    _limpiarVideosLejanos(index);
  }

  void _limpiarVideosLejanos(int currentIndex) {
    final keysToRemove = <int>[];
    for (final key in _controllers.keys) {
      // Solo mantener el video actual y el siguiente (más agresivo)
      if ((key - currentIndex).abs() > 1) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _controllers[key]?.dispose();
      _controllers.remove(key);
      // También eliminar archivo temporal
      if (_tempFilePaths.containsKey(key)) {
        try {
          File(_tempFilePaths[key]!).delete();
        } catch (e) {
          // Ignorar errores al eliminar
        }
        _tempFilePaths.remove(key);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _videos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Cargando videos...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_error != null && _videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                'Error al cargar videos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _cargarVideos(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              'No hay videos disponibles',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los proyectos aún no tienen videos',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _cargarVideos(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _cargarVideos(refresh: true),
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videos.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          return _buildVideoItem(index);
        },
      ),
    );
  }

  Widget _buildVideoItem(int index) {
    final video = _videos[index];
    final controller = _controllers[index];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video o placeholder
        if (controller != null && controller.value.isInitialized)
          GestureDetector(
            onTap: () {
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
              setState(() {});
            },
            child: Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          )
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),

        // Indicador de pausa
        if (controller != null &&
            controller.value.isInitialized &&
            !controller.value.isPlaying)
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.play_arrow,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),

        // Overlay con información del proyecto
        Positioned(
          left: 16,
          right: 80,
          bottom: 100,
          child: _buildProjectInfo(video),
        ),

        // Botones laterales
        Positioned(
          right: 12,
          bottom: 120,
          child: _buildSideButtons(video),
        ),

        // Indicador de carga de más videos
        if (_isLoadingMore && index == _videos.length - 1)
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildProjectInfo(VideoFeedItem video) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nombre del proyecto
        Text(
          video.proyecto.nombre,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 10, color: Colors.black)],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // Organización
        if (video.proyecto.organizacionNombre != null)
          Row(
            children: [
              const Icon(Icons.business, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  video.proyecto.organizacionNombre!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

        // Ubicación
        if (video.proyecto.ubicacion != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  video.proyecto.ubicacion!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],

        // Objetivo
        if (video.proyecto.objetivo != null) ...[
          const SizedBox(height: 8),
          Text(
            video.proyecto.objetivo!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              shadows: [Shadow(blurRadius: 8, color: Colors.black)],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildSideButtons(VideoFeedItem video) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón ver proyecto
        _buildSideButton(
          icon: Icons.visibility,
          label: 'Ver',
          onTap: () {
            _pausarTodosLosVideos();
            Modular.to.pushNamed('/voluntario/proyectos/${video.proyecto.idProyecto}').then((_) {
              // Reanudar cuando vuelva de ver el proyecto
              if (mounted && widget.isActive) {
                _reanudarVideoActual();
              }
            });
          },
        ),
        const SizedBox(height: 20),

        // Botón compartir (placeholder)
        _buildSideButton(
          icon: Icons.share,
          label: 'Compartir',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Función de compartir próximamente'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // Botón info
        _buildSideButton(
          icon: Icons.info_outline,
          label: 'Info',
          onTap: () {
            _mostrarInfoProyecto(video);
          },
        ),
      ],
    );
  }

  Widget _buildSideButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              shadows: [Shadow(blurRadius: 8, color: Colors.black)],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarInfoProyecto(VideoFeedItem video) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              video.proyecto.nombre,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (video.proyecto.organizacionNombre != null) ...[
              Row(
                children: [
                  Icon(Icons.business, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      video.proyecto.organizacionNombre!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (video.proyecto.ubicacion != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      video.proyecto.ubicacion!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: _getEstadoColor(video.proyecto.estado)),
                const SizedBox(width: 8),
                Text(
                  _getEstadoLabel(video.proyecto.estado),
                  style: TextStyle(
                    fontSize: 14,
                    color: _getEstadoColor(video.proyecto.estado),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (video.proyecto.objetivo != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Objetivo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                video.proyecto.objetivo!,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pausarTodosLosVideos();
                  Modular.to.pushNamed('/voluntario/proyectos/${video.proyecto.idProyecto}').then((_) {
                    if (mounted && widget.isActive) {
                      _reanudarVideoActual();
                    }
                  });
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Ver proyecto completo'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return const Color(0xFF4CAF50);
      case 'en_progreso':
        return const Color(0xFF2196F3);
      case 'completado':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFFFF9800);
    }
  }

  String _getEstadoLabel(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return 'Activo';
      case 'en_progreso':
        return 'En progreso';
      case 'completado':
        return 'Completado';
      default:
        return estado;
    }
  }
}
