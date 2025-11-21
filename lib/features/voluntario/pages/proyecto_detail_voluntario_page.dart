import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/participacion.dart';
import '../../../core/models/inscripcion.dart';
import '../../../core/models/organizacion.dart';
import '../../../core/widgets/image_base64_widget.dart';

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

      // Obtener el perfil del voluntario para conocer el usuario_id
      final perfil = await _repository.getStoredPerfil();

      // Verificar si ya hay una participación PARA ESTE USUARIO en este proyecto
      try {
        final participaciones = await _repository.getParticipaciones();

        _participacion = participaciones.firstWhere(
          (part) {
            if (part.proyectoId != widget.proyectoId) {
              return false;
            }

            // Si la participación viene con la relación de inscripción, usamos el usuario_id de ahí
            final inscripcionMap = part.inscripcion;
            if (perfil != null && inscripcionMap != null && inscripcionMap['usuario_id'] != null) {
              final usuarioIdInscripcion = int.tryParse(inscripcionMap['usuario_id'].toString());
              if (usuarioIdInscripcion != null && usuarioIdInscripcion == perfil.usuarioId) {
                return true;
              }
            }

            return false;
          },
          orElse: () => throw Exception('No encontrada'),
        );
      } catch (e) {
        _participacion = null;
      }

      // Verificar si hay inscripción aprobada en la organización del proyecto PARA ESTE USUARIO
      if (proyecto.organizacionId != null && perfil != null) {
        try {
          final inscripciones = await _repository.getInscripciones();
          _inscripcionAprobada = inscripciones.firstWhere(
            (ins) =>
                ins.organizacionId == proyecto.organizacionId &&
                ins.usuarioId == perfil.usuarioId &&
                ins.estado == 'APROBADO',
            orElse: () => throw Exception('No encontrada'),
          );
        } catch (e) {
          _inscripcionAprobada = null;
        }
      } else {
        _inscripcionAprobada = null;
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
        'estado': 'PROGRAMADA',
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
                          // Header de organización estilo red social (avatar más grande y textos alineados)
                          FutureBuilder<Organizacion?>(
                            future: _loadOrganizacion(_proyecto!.organizacionId),
                            builder: (context, snapshot) {
                              String organizacionNombre = 'Organización';
                              String? logo;
                              if (snapshot.hasData && snapshot.data != null) {
                                organizacionNombre = snapshot.data!.nombre;
                                logo = snapshot.data!.logo;
                              } else if (_proyecto!.organizacion != null && _proyecto!.organizacion is Map) {
                                final orgMap = _proyecto!.organizacion as Map;
                                organizacionNombre = orgMap['nombre']?.toString() ?? 
                                                     orgMap['nombre_legal']?.toString() ?? 
                                                     orgMap['nombre_corto']?.toString() ?? 
                                                     'Organización';
                                if (orgMap['logo'] != null) {
                                  logo = orgMap['logo']?.toString();
                                }
                              }

                              Widget avatar;
                              if (logo != null && logo.isNotEmpty) {
                                if (logo.startsWith('http')) {
                                  avatar = CircleAvatar(
                                    radius: 24,
                                    backgroundImage: NetworkImage(logo),
                                  );
                                } else {
                                  final base64Data = logo.contains(',') ? logo.split(',').last : logo;
                                  avatar = CircleAvatar(
                                    radius: 24,
                                    backgroundColor: colorScheme.primaryContainer,
                                    child: ClipOval(
                                      child: ImageBase64Widget(
                                        base64String: base64Data,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                avatar = CircleAvatar(
                                  radius: 24,
                                  backgroundColor: colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.business,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                );
                              }

                              return InkWell(
                                onTap: () {
                                  Modular.to.pushNamed('/voluntario/organizaciones/${_proyecto!.organizacionId}');
                                },
                                borderRadius: BorderRadius.circular(999),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      avatar,
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              organizacionNombre,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Ver perfil de organización',
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.more_vert,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Imagen principal del proyecto (con fallback elegante)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _proyecto!.imagen != null && _proyecto!.imagen!.isNotEmpty
                                ? ImageBase64Widget(
                                    base64String: _proyecto!.imagen!,
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 220,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          colorScheme.primaryContainer,
                                          colorScheme.secondaryContainer,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.volunteer_activism,
                                        size: 64,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // Título y texto principal (tipo post)
                          Text(
                            _proyecto!.nombre,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_proyecto!.objetivo != null && _proyecto!.objetivo!.isNotEmpty) ...[
                            Text(_proyecto!.objetivo!, style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 24),
                          ] else ...[
                            const SizedBox(height: 16),
                          ],

                          // Chips de estado y categorías
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
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
                              if (_proyecto!.categoriasProyectos != null && _proyecto!.categoriasProyectos!.isNotEmpty)
                                ..._proyecto!.categoriasProyectos!.map((catProy) {
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
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Timeline de fechas e información de ubicación
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Línea de tiempo',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Columna visual del timeline
                                  Column(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Container(
                                        width: 2,
                                        height: 24,
                                        color: colorScheme.primary.withOpacity(0.4),
                                      ),
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _proyecto!.fechaFin != null
                                              ? colorScheme.primary
                                              : colorScheme.outlineVariant,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  // Contenido de fechas
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Inicio', style: theme.textTheme.labelMedium),
                                        const SizedBox(height: 4),
                                        Text(
                                          _proyecto!.fechaInicio != null
                                              ? '${_proyecto!.fechaInicio!.day}/${_proyecto!.fechaInicio!.month}/${_proyecto!.fechaInicio!.year}'
                                              : 'No especificada',
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                        const SizedBox(height: 16),
                                        Text('Fin', style: theme.textTheme.labelMedium),
                                        const SizedBox(height: 4),
                                        Text(
                                          _proyecto!.fechaFin != null
                                              ? '${_proyecto!.fechaFin!.day}/${_proyecto!.fechaFin!.month}/${_proyecto!.fechaFin!.year}'
                                              : 'No especificada',
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_proyecto!.ubicacion != null && _proyecto!.ubicacion!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 20, color: colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _proyecto!.ubicacion!,
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Acciones de participación
                          if (_participacion != null)
                            ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.secondary,
                                    ],
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: colorScheme.onPrimary.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: colorScheme.onPrimary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ya estás participando',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Gestiona tu participación y revisa detalles desde aquí.',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onPrimary.withOpacity(0.9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () {
                                  Modular.to.pushNamed('/voluntario/participaciones/${_participacion!.idParticipacion}');
                                },
                                icon: const Icon(Icons.visibility),
                                label: const Text('Ver detalles de tu participación'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size(double.infinity, 48),
                                  backgroundColor: colorScheme.surface,
                                  foregroundColor: colorScheme.primary,
                                ),
                              ),
                            ]
                          else if (_inscripcionAprobada != null)
                            ...[
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
                            ]
                          else
                            ...[
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

