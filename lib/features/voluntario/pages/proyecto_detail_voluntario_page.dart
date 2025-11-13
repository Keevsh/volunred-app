import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/participacion.dart';
import '../../../core/models/inscripcion.dart';
import '../../../core/models/organizacion.dart';

class ProyectoDetailVoluntarioPage extends StatefulWidget {
  final int proyectoId;

  const ProyectoDetailVoluntarioPage({
    super.key,
    required this.proyectoId,
  });

  @override
  State<ProyectoDetailVoluntarioPage> createState() => _ProyectoDetailVoluntarioPageState();
}

class _ProyectoDetailVoluntarioPageState extends State<ProyectoDetailVoluntarioPage> {
  final VoluntarioRepository _repository = Modular.get<VoluntarioRepository>();
  Proyecto? _proyecto;
  Participacion? _participacion;
  Inscripcion? _inscripcionAprobada;
  bool _isLoading = true;
  String? _error;
  bool _isParticipando = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final proyecto = await _repository.getProyectoById(widget.proyectoId);
      
      // Verificar si ya hay una participación
      try {
        final participaciones = await _repository.getParticipaciones();
        _participacion = participaciones.firstWhere(
          (part) => part.proyectoId == widget.proyectoId,
          orElse: () => throw Exception('No encontrada'),
        );
      } catch (e) {
        _participacion = null;
      }

      // Verificar si hay inscripción aprobada en la organización del proyecto
      if (proyecto.organizacionId != null) {
        try {
          final inscripciones = await _repository.getInscripciones();
          _inscripcionAprobada = inscripciones.firstWhere(
            (ins) => ins.organizacionId == proyecto.organizacionId && ins.estado == 'APROBADO',
            orElse: () => throw Exception('No encontrada'),
          );
        } catch (e) {
          _inscripcionAprobada = null;
        }
      }

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

  Future<void> _participar() async {
    if (_proyecto == null || _inscripcionAprobada == null) return;

    setState(() {
      _isParticipando = true;
    });

    try {
      await _repository.createParticipacion({
        'inscripcion_id': _inscripcionAprobada!.idInscripcion,
        'proyecto_id': widget.proyectoId,
        'estado': 'programada',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Participación creada exitosamente'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
        _loadData(); // Recargar para actualizar el estado
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al participar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isParticipando = false;
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
        title: const Text('Detalles del Proyecto'),
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
                      Text('Error al cargar proyecto', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(_error!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadData,
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
                          // Imagen placeholder
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.volunteer_activism,
                                size: 64,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Nombre y estado
                          Text(
                            _proyecto!.nombre,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(_proyecto!.estado.toUpperCase()),
                            backgroundColor: _proyecto!.estado == 'activo'
                                ? colorScheme.primaryContainer
                                : colorScheme.errorContainer,
                            labelStyle: TextStyle(
                              color: _proyecto!.estado == 'activo'
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Organización (destacada)
                          FutureBuilder<Organizacion?>(
                            future: _loadOrganizacion(_proyecto!.organizacionId),
                            builder: (context, snapshot) {
                              String organizacionNombre = 'Organización';
                              if (snapshot.hasData && snapshot.data != null) {
                                organizacionNombre = snapshot.data!.nombre;
                              } else if (_proyecto!.organizacion != null && _proyecto!.organizacion is Map) {
                                final orgMap = _proyecto!.organizacion as Map;
                                organizacionNombre = orgMap['nombre']?.toString() ?? 
                                                     orgMap['nombre_legal']?.toString() ?? 
                                                     orgMap['nombre_corto']?.toString() ?? 
                                                     'Organización';
                              }
                              
                              return Card(
                                color: colorScheme.secondaryContainer,
                                child: InkWell(
                                  onTap: () {
                                    Modular.to.pushNamed('/voluntario/organizaciones/${_proyecto!.organizacionId}');
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: colorScheme.onSecondaryContainer.withOpacity(0.2),
                                          child: Icon(
                                            Icons.business,
                                            color: colorScheme.onSecondaryContainer,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Organización',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: colorScheme.onSecondaryContainer,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                organizacionNombre,
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onSecondaryContainer,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: colorScheme.onSecondaryContainer,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
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
                            Text(_proyecto!.objetivo!, style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 24),
                          ],

                          // Ubicación
                          if (_proyecto!.ubicacion != null && _proyecto!.ubicacion!.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 20, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(_proyecto!.ubicacion!, style: theme.textTheme.bodyLarge),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Categorías
                          if (_proyecto!.categoriasProyectos != null && _proyecto!.categoriasProyectos!.isNotEmpty) ...[
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
                                  }
                                }
                                return Chip(
                                  label: Text(categoriaNombre),
                                  avatar: Icon(Icons.label, size: 18, color: colorScheme.primary),
                                  backgroundColor: colorScheme.primaryContainer,
                                  labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
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
                                    Text('Fecha de Inicio', style: theme.textTheme.labelMedium),
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
                                      Text('Fecha de Fin', style: theme.textTheme.labelMedium),
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
                          const SizedBox(height: 24),

                          // Estado de participación
                          if (_participacion != null) ...[
                            Card(
                              color: colorScheme.primaryContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: colorScheme.onPrimaryContainer),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Ya estás participando en este proyecto',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () {
                                Modular.to.pushNamed('/voluntario/participaciones/${_participacion!.idParticipacion}');
                              },
                              icon: const Icon(Icons.visibility),
                              label: const Text('Ver Detalles de Participación'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ] else if (_inscripcionAprobada != null) ...[
                            FilledButton(
                              onPressed: _isParticipando ? null : _participar,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                minimumSize: const Size(double.infinity, 48),
                              ),
                              child: _isParticipando
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Participar en este Proyecto'),
                            ),
                          ] else ...[
                            Card(
                              color: colorScheme.errorContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning, color: colorScheme.onErrorContainer),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Debes tener una inscripción aprobada en la organización para participar',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }
  
  Future<Organizacion?> _loadOrganizacion(int organizacionId) async {
    try {
      return await _repository.getOrganizacionById(organizacionId);
    } catch (e) {
      print('Error cargando organización: $e');
      return null;
    }
  }
}

