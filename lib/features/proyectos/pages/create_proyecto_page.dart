import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/models/organizacion.dart';
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
  int? _categoriaId;
  List<Map<String, dynamic>> _categorias = [];
  bool _isLoading = false;
  bool _loadingCategorias = true;

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
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      final categorias = await funcionarioRepo.getCategoriasProyectos();
      setState(() {
        _categorias = categorias;
        _loadingCategorias = false;
      });
    } catch (e) {
      setState(() {
        _loadingCategorias = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando categorías: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
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

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una categoría')),
      );
      return;
    }
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
        'categoria_proyecto_id': _categoriaId,
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
      };

      await funcionarioRepo.createProyecto(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proyecto creado exitosamente')),
        );
        Modular.to.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear proyecto: $e')),
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
                    // Categoría
                    DropdownButtonFormField<int>(
                      value: _categoriaId,
                      decoration: InputDecoration(
                        labelText: 'Categoría *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _categorias.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat['id_categoria_proy'] as int,
                          child: Text(cat['nombre'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _categoriaId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona una categoría';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Proyecto *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Ubicación
                    TextFormField(
                      controller: _ubicacionController,
                      decoration: InputDecoration(
                        labelText: 'Ubicación',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          suffixIcon: const Icon(Icons.calendar_today),
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
                          labelText: 'Fecha de Fin',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: const Icon(Icons.calendar_today),
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

