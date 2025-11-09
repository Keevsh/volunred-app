import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/models/categoria.dart';
import '../../../core/theme/app_theme.dart';

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
    try {
      setState(() {
        _loadingCategorias = true;
        _errorCategorias = null;
      });
      
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      final categorias = await funcionarioRepo.getCategorias();
      
      setState(() {
        _categorias = categorias;
        _loadingCategorias = false;
      });
    } catch (e) {
      setState(() {
        _loadingCategorias = false;
        _errorCategorias = 'Error cargando categorías: $e';
      });
      
      if (mounted) {
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
    
    if (picked != null) {
      setState(() {
        if (isInicio) {
          _fechaInicio = picked;
          // Si la fecha de fin es anterior a la nueva fecha de inicio, resetearla
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

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_fechaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una fecha de inicio')),
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
        'fecha_inicio': _fechaInicio!.toIso8601String().split('T')[0],
        if (_fechaFin != null) 'fecha_fin': _fechaFin!.toIso8601String().split('T')[0],
        'estado': 'activo',
        if (_categoriasSeleccionadas.isNotEmpty) 
          'categorias_ids': _categoriasSeleccionadas,
      };

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
      appBar: AppBar(
        title: const Text('Crear Proyecto'),
        elevation: 0,
      ),
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
                            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorCategorias!,
                                style: TextStyle(color: colorScheme.onErrorContainer),
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
                            Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No hay categorías disponibles',
                                style: TextStyle(color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categorias.map((categoria) {
                          final isSelected = _categoriasSeleccionadas.contains(categoria.idCategoria);
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
