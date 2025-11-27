import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/repositories/voluntario_repository.dart';

class TareaDetailPage extends StatefulWidget {
  final int tareaId;

  const TareaDetailPage({
    super.key,
    required this.tareaId,
  });

  @override
  State<TareaDetailPage> createState() => _TareaDetailPageState();
}

class _TareaDetailPageState extends State<TareaDetailPage> {
  final VoluntarioRepository _repository = Modular.get<VoluntarioRepository>();
  final TextEditingController _comentarioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  Map<String, dynamic>? _tareaDetail;
  bool _isLoading = true;
  String? _error;
  bool _isUpdating = false;
  List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _loadTareaDetail();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _loadTareaDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔍 Cargando detalle de tarea ID: ${widget.tareaId}');
      
      Map<String, dynamic>? detail;
      try {
        detail = await _repository.getMyTaskDetail(widget.tareaId);
        print('✅ Detalle de tarea cargado con getMyTaskDetail: $detail');
      } catch (e) {
        print('⚠️ getMyTaskDetail falló, intentando con getTareaById: $e');
        final tarea = await _repository.getTareaById(widget.tareaId);
        detail = tarea.toJson();
        print('✅ Detalle de tarea cargado con getTareaById: $detail');
      }
      
      setState(() {
        _tareaDetail = detail;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error cargando detalle de tarea: $e');
      print('❌ StackTrace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imágenes: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _pickCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedImages.add(photo);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al tomar foto: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _updateEstado(String nuevoEstado) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      print('🔄 Actualizando estado de tarea ${widget.tareaId} a $nuevoEstado');
      
      try {
        await _repository.updateMyTaskStatus(
          widget.tareaId,
          nuevoEstado,
          comentario: _comentarioController.text.isNotEmpty 
              ? _comentarioController.text 
              : null,
        );
        print('✅ Estado actualizado con updateMyTaskStatus');
      } catch (e) {
        print('⚠️ updateMyTaskStatus falló, intentando con updateTarea: $e');
        final data = <String, dynamic>{
          'estado': nuevoEstado,
        };
        if (_comentarioController.text.isNotEmpty) {
          data['comentario'] = _comentarioController.text;
        }
        await _repository.updateTarea(widget.tareaId, data);
        print('✅ Estado actualizado con updateTarea');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a ${nuevoEstado.toUpperCase()}'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
        _comentarioController.clear();
        _selectedImages.clear();
        _loadTareaDetail();
      }
    } catch (e) {
      print('❌ Error al actualizar estado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _showEstadoDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final currentEstado = _tareaDetail?['estado']?.toString().toLowerCase() ?? 'pendiente';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentEstado == 'pendiente')
              ListTile(
                leading: Icon(Icons.play_arrow, color: colorScheme.tertiary),
                title: const Text('Iniciar Tarea'),
                subtitle: const Text('Marcar como en progreso'),
                onTap: () {
                  Navigator.pop(context);
                  _updateEstado('en_progreso');
                },
              ),
            if (currentEstado == 'en_progreso' || currentEstado == 'en progreso')
              ListTile(
                leading: Icon(Icons.check_circle, color: colorScheme.primary),
                title: const Text('Completar Tarea'),
                subtitle: const Text('Marcar como completada'),
                onTap: () {
                  Navigator.pop(context);
                  _updateEstado('completada');
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado, ColorScheme colorScheme) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return colorScheme.errorContainer;
      case 'en_progreso':
      case 'en progreso':
        return colorScheme.tertiaryContainer;
      case 'completada':
      case 'completado':
        return colorScheme.primaryContainer;
      default:
        return colorScheme.surfaceVariant;
    }
  }

  Color _getEstadoTextColor(String estado, ColorScheme colorScheme) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return colorScheme.onErrorContainer;
      case 'en_progreso':
      case 'en progreso':
        return colorScheme.onTertiaryContainer;
      case 'completada':
      case 'completado':
        return colorScheme.onPrimaryContainer;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Tarea'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text('Error al cargar tarea', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadTareaDetail,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _tareaDetail == null
                  ? const Center(child: Text('Tarea no encontrada'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título y estado
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _tareaDetail!['titulo']?.toString() ?? 'Sin título',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Estado
                          Chip(
                            label: Text(
                              (_tareaDetail!['estado']?.toString() ?? 'pendiente').toUpperCase(),
                            ),
                            backgroundColor: _getEstadoColor(
                              _tareaDetail!['estado']?.toString() ?? 'pendiente',
                              colorScheme,
                            ),
                            labelStyle: TextStyle(
                              color: _getEstadoTextColor(
                                _tareaDetail!['estado']?.toString() ?? 'pendiente',
                                colorScheme,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Descripción
                          if (_tareaDetail!['descripcion'] != null &&
                              _tareaDetail!['descripcion'].toString().isNotEmpty) ...[
                            Text(
                              'Descripción',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _tareaDetail!['descripcion'].toString(),
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Información adicional
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Información',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_tareaDetail!['prioridad'] != null)
                                    _buildInfoRow(
                                      Icons.flag,
                                      'Prioridad',
                                      _tareaDetail!['prioridad'].toString().toUpperCase(),
                                      theme,
                                    ),
                                  if (_tareaDetail!['fechaAsignacion'] != null) ...[
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      Icons.calendar_today,
                                      'Asignada',
                                      _formatDate(_tareaDetail!['fechaAsignacion'].toString()),
                                      theme,
                                    ),
                                  ],
                                  if (_tareaDetail!['fechaVencimiento'] != null) ...[
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      Icons.event,
                                      'Vencimiento',
                                      _formatDate(_tareaDetail!['fechaVencimiento'].toString()),
                                      theme,
                                    ),
                                  ],
                                  if (_tareaDetail!['proyecto'] != null) ...[
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      Icons.folder,
                                      'Proyecto',
                                      (_tareaDetail!['proyecto'] as Map)['nombre']?.toString() ?? 'Proyecto',
                                      theme,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Comentario
                          Text(
                            'Agregar Comentario',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _comentarioController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Escribe un comentario sobre tu progreso...',
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Evidencias
                          Text(
                            'Evidencias',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickImages,
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Galería'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickCamera,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Cámara'),
                                ),
                              ),
                            ],
                          ),

                          // Preview de imágenes
                          if (_selectedImages.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(right: 12),
                                        width: 120,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: FileImage(File(_selectedImages[index].path)),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 16,
                                        child: IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () => _removeImage(index),
                                          style: IconButton.styleFrom(
                                            backgroundColor: colorScheme.error,
                                            foregroundColor: colorScheme.onError,
                                            padding: const EdgeInsets.all(4),
                                            minimumSize: const Size(32, 32),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // Botón de cambiar estado
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isUpdating ? null : _showEstadoDialog,
                              icon: _isUpdating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.update),
                              label: Text(_isUpdating ? 'Actualizando...' : 'Cambiar Estado'),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
