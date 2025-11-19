import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/image_base64_widget.dart';

class ProyectoDetailPage extends StatefulWidget {
  final int proyectoId;

  const ProyectoDetailPage({
    super.key,
    required this.proyectoId,
  });

  @override
  State<ProyectoDetailPage> createState() => _ProyectoDetailPageState();
}

class _ProyectoDetailPageState extends State<ProyectoDetailPage> {
  Proyecto? _proyecto;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProyecto();
  }

  Future<void> _loadProyecto() async {
    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      final proyecto = await funcionarioRepo.getProyectoById(widget.proyectoId);
      setState(() {
        _proyecto = proyecto;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Proyecto'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
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
                        'Error al cargar proyecto',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadProyecto,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _proyecto == null
                  ? const Center(child: Text('Proyecto no encontrado'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Imagen principal del proyecto
                          if (_proyecto!.imagen != null && _proyecto!.imagen!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: ImageBase64Widget(
                                base64String: _proyecto!.imagen!,
                                width: double.infinity,
                                height: 250,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          // Nombre
                          Text(
                            _proyecto!.nombre,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Estado
                          Chip(
                            label: Text(_proyecto!.estado.toUpperCase()),
                            backgroundColor: _proyecto!.estado == 'activo'
                                ? colorScheme.primaryContainer
                                : colorScheme.errorContainer,
                          ),
                          const SizedBox(height: 24),

                          // Organización
                          if (_proyecto!.organizacion != null) ...[
                            Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerHighest,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Logo de la organización
                                    if (_proyecto!.organizacion!['logo'] != null && 
                                        _proyecto!.organizacion!['logo'].toString().isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: ImageBase64Widget(
                                          base64String: _proyecto!.organizacion!['logo'].toString(),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.business,
                                          size: 30,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    const SizedBox(width: 16),
                                    // Información de la organización
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Organización',
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _proyecto!.organizacion!['nombre']?.toString() ??
                                                _proyecto!.organizacion!['nombre_legal']?.toString() ??
                                                _proyecto!.organizacion!['nombre_corto']?.toString() ??
                                                'Organización',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Objetivo
                          if (_proyecto!.objetivo != null && _proyecto!.objetivo!.isNotEmpty) ...[
                            Text(
                              'Objetivo',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _proyecto!.objetivo!,
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Ubicación
                          if (_proyecto!.ubicacion != null && _proyecto!.ubicacion!.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 20, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  _proyecto!.ubicacion!,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Categorías
                          if (_proyecto!.categoriasProyectos != null && 
                              _proyecto!.categoriasProyectos!.isNotEmpty) ...[
                            Text(
                              'Categorías',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _proyecto!.categoriasProyectos!.map((catProy) {
                                String categoriaNombre = 'Categoría';
                                if (catProy is Map) {
                                  if (catProy['categoria'] is Map) {
                                    categoriaNombre = catProy['categoria']['nombre']?.toString() ?? 'Categoría';
                                  } else {
                                    categoriaNombre = catProy['nombre']?.toString() ?? 'Categoría';
                                  }
                                }
                                return Chip(
                                  label: Text(categoriaNombre),
                                  avatar: Icon(
                                    Icons.label,
                                    size: 18,
                                    color: colorScheme.primary,
                                  ),
                                  backgroundColor: colorScheme.primaryContainer,
                                  labelStyle: TextStyle(
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Fechas
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fecha de Inicio',
                                      style: theme.textTheme.labelMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _proyecto!.fechaInicio != null
                                          ? '${_proyecto!.fechaInicio!.day}/${_proyecto!.fechaInicio!.month}/${_proyecto!.fechaInicio!.year}'
                                          : 'No especificada',
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                              if (_proyecto!.fechaFin != null)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fecha de Fin',
                                        style: theme.textTheme.labelMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_proyecto!.fechaFin!.day}/${_proyecto!.fechaFin!.month}/${_proyecto!.fechaFin!.year}',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }
}

