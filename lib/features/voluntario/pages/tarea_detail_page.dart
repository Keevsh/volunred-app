import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/image_base64_widget.dart';

class TareaDetailPage extends StatefulWidget {
  final int tareaId;

  const TareaDetailPage({super.key, required this.tareaId});

  @override
  State<TareaDetailPage> createState() => _TareaDetailPageState();
}

class _TareaDetailPageState extends State<TareaDetailPage> {
  final VoluntarioRepository _repository = Modular.get<VoluntarioRepository>();

  Map<String, dynamic>? _tareaDetail;
  List<Map<String, dynamic>> _evidencias = [];
  bool _isLoading = true;
  bool _isLoadingEvidencias = false;
  bool _isUpdating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadTareaDetail();
    await _loadEvidencias();
  }

  Future<void> _loadTareaDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic>? detail;
      try {
        detail = await _repository.getMyTaskDetail(widget.tareaId);
      } catch (e) {
        final tarea = await _repository.getTareaById(widget.tareaId);
        detail = tarea.toJson();
      }

      if (mounted) {
        setState(() {
          _tareaDetail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadEvidencias() async {
    setState(() => _isLoadingEvidencias = true);

    try {
      final evidencias = await _repository.getMyTaskEvidences(widget.tareaId);
      if (mounted) {
        setState(() {
          _evidencias = evidencias;
          _isLoadingEvidencias = false;
        });
      }
    } catch (e) {
      print('Error cargando evidencias: $e');
      if (mounted) {
        setState(() => _isLoadingEvidencias = false);
      }
    }
  }

  Future<void> _updateEstado(String nuevoEstado) async {
    setState(() => _isUpdating = true);

    try {
      try {
        await _repository.updateMyTaskStatus(widget.tareaId, nuevoEstado);
      } catch (e) {
        await _repository.updateTarea(widget.tareaId, {'estado': nuevoEstado});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Estado actualizado a ${_getEstadoLabel(nuevoEstado)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadTareaDetail();
      }
    } catch (e) {
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
        setState(() => _isUpdating = false);
      }
    }
  }

  void _showEstadoDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final currentEstado =
        _tareaDetail?['estado']?.toString().toLowerCase().replaceAll(
          ' ',
          '_',
        ) ??
        'pendiente';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
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
                  color: colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Cambiar Estado',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Estado actual: ${_getEstadoLabel(currentEstado)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            _buildEstadoOption(
              icon: Icons.play_circle_filled,
              label: 'En Progreso',
              description: 'Comenzar a trabajar en esta tarea',
              color: Colors.orange,
              isSelected: currentEstado == 'en_progreso',
              isDisabled: currentEstado == 'completada',
              onTap: () {
                Navigator.pop(context);
                _updateEstado('en_progreso');
              },
            ),

            const SizedBox(height: 12),

            _buildEstadoOption(
              icon: Icons.check_circle,
              label: 'Completada',
              description: 'Marcar la tarea como terminada',
              color: Colors.green,
              isSelected: currentEstado == 'completada',
              isDisabled: false,
              onTap: () {
                Navigator.pop(context);
                _updateEstado('completada');
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showCrearEvidenciaSheet() {
    final colorScheme = Theme.of(context).colorScheme;
    final comentarioController = TextEditingController();
    String? fotoBase64;
    XFile? selectedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Icon(Icons.add_photo_alternate, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Crear Evidencia',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Selector de imagen
              Text(
                'Foto (opcional)',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              if (selectedImage != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(selectedImage!.path),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () {
                          setModalState(() {
                            selectedImage = null;
                            fotoBase64 = null;
                          });
                        },
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 800,
                            maxHeight: 800,
                            imageQuality: 50,
                          );
                          if (image != null) {
                            try {
                              final base64 =
                                  await ImageUtils.convertXFileToBase64(image);
                              setModalState(() {
                                selectedImage = image;
                                fotoBase64 = base64;
                              });
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galería'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                            source: ImageSource.camera,
                            maxWidth: 800,
                            maxHeight: 800,
                            imageQuality: 50,
                          );
                          if (image != null) {
                            try {
                              final base64 =
                                  await ImageUtils.convertXFileToBase64(image);
                              setModalState(() {
                                selectedImage = image;
                                fotoBase64 = base64;
                              });
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Cámara'),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Comentario
              Text(
                'Comentario *',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: comentarioController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe el avance o resultado de la tarea...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    if (comentarioController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('El comentario es obligatorio'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    try {
                      await _repository.createMyTaskEvidence(
                        widget.tareaId,
                        comentario: comentarioController.text.trim(),
                        fotoBase64: fotoBase64,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Evidencia creada exitosamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadEvidencias();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al crear evidencia: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Evidencia'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEstadoLabel(String estado) {
    switch (estado.toLowerCase().replaceAll(' ', '_')) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_progreso':
        return 'En Progreso';
      case 'completada':
        return 'Completada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return estado;
    }
  }

  Widget _buildEstadoOption({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required bool isSelected,
    required bool isDisabled,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey.withOpacity(0.2)
                    : color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDisabled ? Colors.grey : color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDisabled ? Colors.grey : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDisabled
                          ? Colors.grey
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Color _getEstadoColor(String estado, ColorScheme colorScheme) {
    switch (estado.toLowerCase().replaceAll(' ', '_')) {
      case 'pendiente':
        return Colors.orange;
      case 'en_progreso':
        return Colors.blue;
      case 'completada':
        return Colors.green;
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Tarea'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar tarea',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadData,
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
                  // Título
                  Text(
                    _tareaDetail!['titulo']?.toString() ??
                        _tareaDetail!['nombre']?.toString() ??
                        'Sin título',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Estado
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getEstadoColor(
                        _tareaDetail!['estado']?.toString() ?? 'pendiente',
                        colorScheme,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getEstadoLabel(
                        _tareaDetail!['estado']?.toString() ?? 'pendiente',
                      ),
                      style: TextStyle(
                        color: _getEstadoColor(
                          _tareaDetail!['estado']?.toString() ?? 'pendiente',
                          colorScheme,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
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

                  // Información
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
                              _tareaDetail!['prioridad']
                                  .toString()
                                  .toUpperCase(),
                              theme,
                            ),
                          if (_tareaDetail!['fecha_inicio'] != null ||
                              _tareaDetail!['fechaAsignacion'] != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Fecha inicio',
                              _formatDate(
                                _tareaDetail!['fecha_inicio']?.toString() ??
                                    _tareaDetail!['fechaAsignacion']
                                        ?.toString() ??
                                    '',
                              ),
                              theme,
                            ),
                          ],
                          if (_tareaDetail!['fecha_fin'] != null ||
                              _tareaDetail!['fechaVencimiento'] != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.event,
                              'Fecha fin',
                              _formatDate(
                                _tareaDetail!['fecha_fin']?.toString() ??
                                    _tareaDetail!['fechaVencimiento']
                                        ?.toString() ??
                                    '',
                              ),
                              theme,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // EVIDENCIAS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Evidencias',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _showCrearEvidenciaSheet,
                        icon: const Icon(Icons.add_photo_alternate, size: 18),
                        label: const Text('Crear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_isLoadingEvidencias)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_evidencias.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 48,
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay evidencias',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Agrega fotos y comentarios de tu avance',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _evidencias.length,
                      itemBuilder: (context, index) {
                        final evidencia = _evidencias[index];
                        return _buildEvidenciaCard(
                          evidencia,
                          theme,
                          colorScheme,
                        );
                      },
                    ),

                  const SizedBox(height: 32),

                  // Botón cambiar estado
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isUpdating ? null : _showEstadoDialog,
                      icon: _isUpdating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.swap_horiz),
                      label: Text(
                        _isUpdating ? 'Actualizando...' : 'Cambiar Estado',
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildEvidenciaCard(
    Map<String, dynamic> evidencia,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final foto = evidencia['foto']?.toString();
    final comentario = evidencia['comentario']?.toString() ?? '';
    final fecha =
        evidencia['creado_en']?.toString() ?? evidencia['fecha']?.toString();
    final tipoRaw = evidencia['tipo']?.toString() ?? '';
    final tipo = tipoRaw.isEmpty ? 'EVIDENCIA' : tipoRaw.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (foto != null && foto.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: ImageBase64Widget(
                base64String: foto,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: tipo + fecha
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            foto != null && foto.isNotEmpty
                                ? Icons.photo_library_outlined
                                : Icons.notes_outlined,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tipo,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (fecha != null)
                      Text(
                        _formatDate(fecha),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Comentario
                Text(
                  comentario,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
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
        Text(value, style: theme.textTheme.bodyMedium),
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
