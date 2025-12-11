import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/categoria.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/image_base64_widget.dart';

class EditProyectoPage extends StatefulWidget {
  final int proyectoId;

  const EditProyectoPage({super.key, required this.proyectoId});

  @override
  State<EditProyectoPage> createState() => _EditProyectoPageState();
}

class _EditProyectoPageState extends State<EditProyectoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _objetivoController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final FuncionarioRepository _repository = Modular.get<FuncionarioRepository>();

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _estado = 'activo';
  List<int> _categoriasSeleccionadas = [];
  List<Categoria> _categorias = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _loadingCategorias = true;
  String? _error;
  bool _participacionPublica = false;

  // Variables para la imagen
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  String? _imageBase64;
  String? _imagenActual;
  bool _eliminarImagen = false;

  final List<String> _estadosDisponibles = [
    'planificacion',
    'activo',
    'en_progreso',
    'completado',
    'cancelado',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _objetivoController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Cargar proyecto y categorías en paralelo
      final results = await Future.wait([
        _repository.getProyectoById(widget.proyectoId),
        _repository.getCategorias(),
      ]);

      final proyecto = results[0] as Proyecto;
      final categorias = results[1] as List<Categoria>;

      if (!mounted) return;

      // Llenar los campos con los datos del proyecto
      _nombreController.text = proyecto.nombre;
      _objetivoController.text = proyecto.objetivo ?? '';
      _ubicacionController.text = proyecto.ubicacion ?? '';
      _fechaInicio = proyecto.fechaInicio;
      _fechaFin = proyecto.fechaFin;
      _estado = proyecto.estado.toLowerCase();
      _participacionPublica = proyecto.participacionPublica;
      _imagenActual = proyecto.imagen;

      // Extraer categorías seleccionadas
      if (proyecto.categoriasProyectos != null) {
        _categoriasSeleccionadas = proyecto.categoriasProyectos!
            .map((cat) {
              if (cat is Map) {
                final catData = cat['categoria'] ?? cat;
                return catData['id_categoria'] as int?;
              }
              return null;
            })
            .whereType<int>()
            .toList();
      }

      setState(() {
        _categorias = categorias;
        _isLoading = false;
        _loadingCategorias = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _loadingCategorias = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isInicio) async {
    final initialDate = isInicio
        ? (_fechaInicio ?? DateTime.now())
        : (_fechaFin ?? _fechaInicio ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (picked != null && mounted) {
      setState(() {
        if (isInicio) {
          _fechaInicio = picked;
          if (_fechaFin != null && _fechaFin!.isBefore(picked)) {
            _fechaFin = null;
          }
        } else {
          _fechaFin = picked;
        }
      });
    }
  }

  void _toggleCategoria(int categoriaId) {
    setState(() {
      if (_categoriasSeleccionadas.contains(categoriaId)) {
        _categoriasSeleccionadas.remove(categoriaId);
      } else {
        _categoriasSeleccionadas.add(categoriaId);
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = pickedFile;
          _eliminarImagen = false;
        });

        try {
          final base64Compressed = await ImageUtils.convertXFileToBase64(pickedFile);
          final isValidSize = ImageUtils.isValidBase64Size(base64Compressed);
          
          if (!isValidSize) {
            _imageBase64 = null;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('La imagen es demasiado grande (máx. 5MB).'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          } else {
            _imageBase64 = base64Compressed;
          }
        } catch (e) {
          _imageBase64 = null;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error procesando la imagen: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageBase64 = null;
      _eliminarImagen = true;
    });
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una fecha de inicio')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = <String, dynamic>{
        'nombre': _nombreController.text.trim(),
        'objetivo': _objetivoController.text.trim().isEmpty
            ? null
            : _objetivoController.text.trim(),
        'ubicacion': _ubicacionController.text.trim().isEmpty
            ? null
            : _ubicacionController.text.trim(),
        'fecha_inicio': _fechaInicio!.toIso8601String().split('T')[0],
        'estado': _estado,
        'participacion_publica': _participacionPublica,
      };

      if (_fechaFin != null) {
        data['fecha_fin'] = _fechaFin!.toIso8601String().split('T')[0];
      }

      if (_categoriasSeleccionadas.isNotEmpty) {
        data['categorias_ids'] = _categoriasSeleccionadas;
      }

      // Manejo de imagen
      if (_imageBase64 != null) {
        data['imagen'] = _imageBase64;
      } else if (_eliminarImagen) {
        data['imagen'] = null;
      }

      await _repository.updateProyecto(widget.proyectoId, data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Proyecto actualizado exitosamente'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Modular.to.pop(true); // Retornar true para indicar que hubo cambios
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar proyecto: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getEstadoLabel(String estado) {
    switch (estado.toLowerCase()) {
      case 'planificacion':
        return 'Planificación';
      case 'activo':
        return 'Activo';
      case 'en_progreso':
        return 'En Progreso';
      case 'completado':
        return 'Completado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Editar Proyecto'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isLoading && !_isSaving)
            TextButton.icon(
              onPressed: _handleSave,
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _buildBody(theme, colorScheme),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('Error al cargar el proyecto', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen del proyecto
            _buildImageSection(theme, colorScheme),
            const SizedBox(height: 24),

            // Nombre
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre del Proyecto *',
                hintText: 'Ej: Reforestación Urbana 2025',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Objetivo
            TextFormField(
              controller: _objetivoController,
              decoration: InputDecoration(
                labelText: 'Objetivo',
                hintText: 'Descripción del objetivo del proyecto',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Ubicación
            TextFormField(
              controller: _ubicacionController,
              decoration: InputDecoration(
                labelText: 'Ubicación',
                hintText: 'Ej: Zona Sur, La Paz',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),

            // Estado
            DropdownButtonFormField<String>(
              value: _estado,
              decoration: InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.flag),
              ),
              items: _estadosDisponibles.map((estado) {
                return DropdownMenuItem(
                  value: estado,
                  child: Text(_getEstadoLabel(estado)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _estado = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Fechas
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha Inicio *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _fechaInicio != null
                            ? _formatDate(_fechaInicio!)
                            : 'Seleccionar',
                        style: TextStyle(
                          color: _fechaInicio != null
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha Fin',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.event),
                      ),
                      child: Text(
                        _fechaFin != null
                            ? _formatDate(_fechaFin!)
                            : 'Opcional',
                        style: TextStyle(
                          color: _fechaFin != null
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Participación pública
            SwitchListTile(
              title: const Text('Participación Pública'),
              subtitle: const Text(
                'Los voluntarios pueden unirse sin inscripción previa',
              ),
              value: _participacionPublica,
              onChanged: (value) {
                setState(() => _participacionPublica = value);
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            // Categorías
            Text(
              'Categorías',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_loadingCategorias)
              const Center(child: CircularProgressIndicator())
            else if (_categorias.isEmpty)
              Text(
                'No hay categorías disponibles',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categorias.map((categoria) {
                  final isSelected = _categoriasSeleccionadas.contains(
                    categoria.idCategoria,
                  );
                  return FilterChip(
                    selected: isSelected,
                    label: Text(categoria.nombre),
                    avatar: isSelected
                        ? Icon(
                            Icons.check_circle,
                            size: 18,
                            color: colorScheme.onPrimaryContainer,
                          )
                        : null,
                    onSelected: (_) => _toggleCategoria(categoria.idCategoria),
                    selectedColor: colorScheme.primaryContainer,
                    checkmarkColor: colorScheme.onPrimaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 32),

            // Botón guardar
            FilledButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Guardando...' : 'Guardar Cambios'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imagen del Proyecto',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Agrega una imagen representativa de tu proyecto',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),

        // Mostrar imagen seleccionada, actual o placeholder
        if (_selectedImage != null) ...[
          // Nueva imagen seleccionada
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_selectedImage!.path),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('Cambiar'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _removeImage,
                icon: Icon(Icons.delete, color: colorScheme.error),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                ),
              ),
            ],
          ),
        ] else if (_imagenActual != null && !_eliminarImagen) ...[
          // Imagen actual del proyecto
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ImageBase64Widget(
                base64String: _imagenActual!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('Cambiar'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _removeImage,
                icon: Icon(Icons.delete, color: colorScheme.error),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                ),
              ),
            ],
          ),
        ] else ...[
          // Placeholder para seleccionar imagen
          InkWell(
            onTap: _showImageSourceDialog,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seleccionar imagen',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
