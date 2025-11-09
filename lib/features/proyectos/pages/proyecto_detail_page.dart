import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/theme/app_theme.dart';

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

