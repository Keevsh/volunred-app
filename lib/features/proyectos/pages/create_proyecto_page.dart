import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/models/categoria.dart';
import '../../../core/config/api_config.dart';

// Widget optimizado para categorías que solo se reconstruye cuando cambian las categorías
class _CategoriasSelector extends StatelessWidget {
  final List<Categoria> categorias;
  final List<int> categoriasSeleccionadas;
  final Function(int) onToggle;
  final ColorScheme colorScheme;

  const _CategoriasSelector({
    required this.categorias,
    required this.categoriasSeleccionadas,
    required this.onToggle,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categorias.map((categoria) {
        final isSelected = categoriasSeleccionadas.contains(
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
          onSelected: (_) => onToggle(categoria.idCategoria),
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
    );
  }
}

class CreateProyectoPage extends StatefulWidget {
  const CreateProyectoPage({super.key});

  @override
  State<CreateProyectoPage> createState() => _CreateProyectoPageState();
}

class _CreateProyectoPageState extends State<CreateProyectoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _objetivoController = TextEditingController();
  final _ubicacionController = TextEditingController();

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  List<int> _categoriasSeleccionadas = [];
  List<Categoria> _categorias = [];
  bool _isLoading = false;
  bool _loadingCategorias = true;
  String? _errorCategorias;
  bool _participacionPublica = false;

  // Variables para la imagen
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _objetivoController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    if (!mounted) return;

    _loadingCategorias = true;
    _errorCategorias = null;
    setState(() {});

    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      final categorias = await funcionarioRepo.getCategorias();

      if (mounted) {
        _categorias = categorias;
        _loadingCategorias = false;
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        _loadingCategorias = false;
        _errorCategorias = 'Error cargando categorías: $e';
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorCategorias!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null && mounted) {
      if (isInicio) {
        _fechaInicio = picked;
        // Si la fecha de fin es anterior a la nueva fecha de inicio, resetearla
        if (_fechaFin != null && _fechaFin!.isBefore(picked)) {
          _fechaFin = null;
        }
      } else {
        _fechaFin = picked;
      }
      setState(() {}); // Rebuild mínimo
    }
  }

  void _toggleCategoria(int categoriaId) {
    // Optimización: solo actualizar si realmente cambia
    if (_categoriasSeleccionadas.contains(categoriaId)) {
      _categoriasSeleccionadas.remove(categoriaId);
    } else {
      _categoriasSeleccionadas.add(categoriaId);
    }
    setState(() {}); // Rebuild mínimo
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
        // Actualizar UI inmediatamente con la imagen seleccionada
        _selectedImage = pickedFile;
        setState(() {});

        // Convertir imagen a base64 en background (no bloquea UI)
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        final mimeType = _getMimeType(pickedFile.path);

        _imageBase64 = 'data:$mimeType;base64,$base64String';

        print('📸 Imagen seleccionada: ${pickedFile.name}');
        print('📊 Tamaño: ${bytes.length} bytes');
        print(
          '🔄 Base64 generado (primeros 50 chars): ${_imageBase64!.substring(0, 50)}...',
        );
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

  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // fallback
    }
  }

  void _removeImage() {
    _selectedImage = null;
    _imageBase64 = null;
    setState(() {}); // Rebuild mínimo
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

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una fecha de inicio'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();

      final data = {
        'nombre': _nombreController.text.trim(),
        'objetivo': _objetivoController.text.trim().isEmpty
            ? null
            : _objetivoController.text.trim(),
        'ubicacion': _ubicacionController.text.trim().isEmpty
            ? null
            : _ubicacionController.text.trim(),
        'fecha_inicio': _fechaInicio!.toUtc().toIso8601String(),
        if (_fechaFin != null)
          'fecha_fin': _fechaFin!.toUtc().toIso8601String(),
        'estado': 'activo',
        'participacion_publica': _participacionPublica,
        if (_categoriasSeleccionadas.isNotEmpty)
          'categorias_ids': _categoriasSeleccionadas,
        if (_imageBase64 != null) 'imagen': _imageBase64,
      };

      print('🚀 Enviando datos al backend para crear proyecto:');
      print('📦 Data: $data');
      print('🔍 Tipos de datos en el mapa:');
      data.forEach((key, value) {
        print('   $key: ${value.runtimeType} = $value');
      });
      print(
        '📅 Fecha inicio formateada: ${_fechaInicio!.toUtc().toIso8601String()}',
      );
      if (_fechaFin != null) {
        print(
          '📅 Fecha fin formateada: ${_fechaFin!.toUtc().toIso8601String()}',
        );
      }
      print('📋 Categorías seleccionadas: $_categoriasSeleccionadas');
      print('🌐 Endpoint: ${ApiConfig.proyectos}');
      print('🔄 Enviando petición HTTP POST...');

      await funcionarioRepo.createProyecto(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Proyecto creado exitosamente'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
        Modular.to.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear proyecto: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Proyecto'), elevation: 0),
      body: _loadingCategorias
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Proyecto *',
                        hintText: 'Ej: Reforestación Urbana 2025',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        prefixIcon: Icon(Icons.title),
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
                      decoration: const InputDecoration(
                        labelText: 'Objetivo',
                        hintText: 'Descripción del objetivo del proyecto',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Ubicación
                    TextFormField(
                      controller: _ubicacionController,
                      decoration: const InputDecoration(
                        labelText: 'Ubicación',
                        hintText: 'Ej: Zona Sur, La Paz',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Imagen del proyecto
                    Text(
                      'Imagen del Proyecto (Opcional)',
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

                    if (_selectedImage != null) ...[
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline,
                            width: 1,
                          ),
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
                              label: const Text('Cambiar imagen'),
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
                            color: colorScheme.surfaceContainerHighest
                                .withOpacity(0.3),
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
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Fecha de inicio
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha de Inicio *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _fechaInicio != null
                              ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'
                              : 'Seleccionar fecha',
                          style: TextStyle(
                            color: _fechaInicio != null
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fecha de fin
                    InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha de Fin (Opcional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.event),
                        ),
                        child: Text(
                          _fechaFin != null
                              ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'
                              : 'Seleccionar fecha (opcional)',
                          style: TextStyle(
                            color: _fechaFin != null
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Categorías
                    Text(
                      'Categorías (Opcional)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecciona una o más categorías para clasificar tu proyecto',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_errorCategorias != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorCategorias!,
                                style: TextStyle(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _loadCategorias,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    else if (_categorias.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No hay categorías disponibles',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _CategoriasSelector(
                        categorias: _categorias,
                        categoriasSeleccionadas: _categoriasSeleccionadas,
                        onToggle: _toggleCategoria,
                        colorScheme: colorScheme,
                      ),

                    if (_categoriasSeleccionadas.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_categoriasSeleccionadas.length} categoría(s) seleccionada(s)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Participación Pública
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Participación Pública',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'Permitir que cualquier voluntario se una sin necesidad de estar inscrito en la organización',
                        ),
                        value: _participacionPublica,
                        onChanged: (value) {
                          setState(() {
                            _participacionPublica = value;
                          });
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón crear
                    FilledButton(
                      onPressed: _isLoading ? null : _handleCreate,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Crear Proyecto'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
