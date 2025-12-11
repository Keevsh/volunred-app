import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/models/archivo_digital.dart';
import '../../../core/widgets/media_preview_dialog.dart';

class ProyectoGaleriaPage extends StatefulWidget {
  final int proyectoId;
  final String proyectoNombre;

  const ProyectoGaleriaPage({
    super.key,
    required this.proyectoId,
    required this.proyectoNombre,
  });

  @override
  State<ProyectoGaleriaPage> createState() => _ProyectoGaleriaPageState();
}

class _ProyectoGaleriaPageState extends State<ProyectoGaleriaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ArchivoDigital> _archivos = [];
  bool _isLoading = true;
  String? _error;

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
      final repository = Modular.get<VoluntarioRepository>();
      final archivos = await repository.getArchivosDigitalesProyecto(
        widget.proyectoId,
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

  List<ArchivoDigital> _filtrarPorTipo(String tipo) {
    return _archivos.where((a) => a.tipoMedia == tipo).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Galería',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.proyectoNombre,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
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
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar la galería',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _loadArchivos,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGaleria('imagen'),
                _buildGaleria('video'),
                _buildGaleria('documento'),
                _buildGaleria(null),
              ],
            ),
    );
  }

  Widget _buildGaleria(String? tipoFiltro) {
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
      child: InkWell(
        onTap: (archivo.esImagen || archivo.esVideo)
            ? () => MediaPreviewDialog.show(context, archivo)
            : () => _verArchivoDetalle(archivo),
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
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(ArchivoDigital archivo) {
    if (archivo.esImagen) {
      return ImageThumbnailWidget(
        archivo: archivo,
        onTap: () => MediaPreviewDialog.show(context, archivo),
      );
    } else if (archivo.esVideo) {
      return VideoThumbnailWidget(
        archivo: archivo,
        onTap: () => MediaPreviewDialog.show(context, archivo),
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getTipoIcon(archivo.tipoMedia),
              size: 48,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 8),
            Text(
              archivo.mimeType.split('/').last.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'imagen':
        return Icons.image;
      case 'video':
        return Icons.video_library;
      case 'audio':
        return Icons.audio_file;
      case 'documento':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _verArchivoDetalle(ArchivoDigital archivo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getTipoIcon(archivo.tipoMedia),
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        archivo.nombreArchivo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ],
                ),
              ),
              // Contenido
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview
                      if (archivo.esImagen)
                        Image.memory(
                          base64Decode(archivo.contenidoBase64),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 300,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 64),
                              ),
                            );
                          },
                        )
                      else if (archivo.esVideo)
                        Container(
                          height: 300,
                          color: Colors.black,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_circle_outline,
                                  size: 80,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Vista previa de video no disponible',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getTipoIcon(archivo.tipoMedia),
                                  size: 64,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  archivo.mimeType,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Información
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Tipo', archivo.tipoMedia),
                            const Divider(),
                            _buildInfoRow('Formato', archivo.mimeType),
                            const Divider(),
                            _buildInfoRow(
                              'Fecha',
                              _formatDate(archivo.creadoEn),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Botón cerrar
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
