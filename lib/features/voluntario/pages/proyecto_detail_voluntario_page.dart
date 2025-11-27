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
  Future<List<Map<String, dynamic>>>? _futureProjectTasks;

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

            // Si la participación viene con la relación de inscripción, usamos el voluntarioId de ahí
            final inscripcionMap = part.inscripcion;
            if (perfil != null && inscripcionMap != null) {
              // Intentar con usuario_id o voluntarioId
              final usuarioId = inscripcionMap['usuario_id'] ?? inscripcionMap['voluntarioId'];
              if (usuarioId != null) {
                final usuarioIdInscripcion = int.tryParse(usuarioId.toString());
                if (usuarioIdInscripcion != null && usuarioIdInscripcion == perfil.usuarioId) {
                  return true;
                }
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
                ins.estado == 'aceptada',
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
        if (_participacion != null) {
          _futureProjectTasks = _repository.getMyTasks(proyectoId: widget.proyectoId);
        } else {
          _futureProjectTasks = null;
        }
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
        'estado': 'en_curso',
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
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _proyecto?.nombre ?? 'Proyecto',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 56, color: colorScheme.error),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar el proyecto',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _loadData,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _proyecto == null
                  ? const Center(child: Text('Proyecto no encontrado'))
                  : SafeArea(
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagen principal full-width sin bordes redondeados
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: _proyecto!.imagen != null && _proyecto!.imagen!.isNotEmpty
                                      ? ImageBase64Widget(
                                          base64String: _proyecto!.imagen!,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
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
                                          child: Icon(
                                            Icons.volunteer_activism,
                                            size: 56,
                                            color: colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _proyecto!.nombre,
                                              style: theme.textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _proyecto!.estado == 'activo'
                                                  ? colorScheme.primaryContainer
                                                  : colorScheme.errorContainer,
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              _proyecto!.estado.toUpperCase(),
                                              style: theme.textTheme.labelSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.6,
                                                color: _proyecto!.estado == 'activo'
                                                    ? colorScheme.onPrimaryContainer
                                                    : colorScheme.onErrorContainer,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (_proyecto!.categoriasProyectos != null &&
                                              _proyecto!.categoriasProyectos!.isNotEmpty)
                                            Flexible(
                                              child: Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: _proyecto!.categoriasProyectos!.take(2).map((catProy) {
                                                  String categoriaNombre = 'Categoría';
                                                  if (catProy is Map && catProy['categoria'] is Map) {
                                                    categoriaNombre =
                                                        catProy['categoria']['nombre']?.toString() ?? 'Categoría';
                                                  }
                                                  return Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: colorScheme.secondaryContainer,
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: Text(
                                                      categoriaNombre,
                                                      style: theme.textTheme.labelSmall?.copyWith(
                                                        color: colorScheme.onSecondaryContainer,
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (_proyecto!.objetivo != null && _proyecto!.objetivo!.isNotEmpty)
                                        Text(
                                          _proyecto!.objetivo!,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            height: 1.5,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),

                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20),

                                  // Organización
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
                                            radius: 22,
                                            backgroundImage: NetworkImage(logo),
                                          );
                                        } else {
                                          final base64Data = logo.contains(',') ? logo.split(',').last : logo;
                                          avatar = CircleAvatar(
                                            radius: 22,
                                            backgroundColor: colorScheme.primaryContainer,
                                            child: ClipOval(
                                              child: ImageBase64Widget(
                                                base64String: base64Data,
                                                width: 44,
                                                height: 44,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        avatar = CircleAvatar(
                                          radius: 22,
                                          backgroundColor: colorScheme.primaryContainer,
                                          child: Icon(
                                            Icons.business,
                                            color: colorScheme.onPrimaryContainer,
                                          ),
                                        );
                                      }

                                      return Material(
                                        color: colorScheme.surface,
                                        borderRadius: BorderRadius.circular(18),
                                        child: InkWell(
                                          onTap: () {
                                            Modular.to.pushNamed(
                                              '/voluntario/organizaciones/${_proyecto!.organizacionId}',
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(18),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
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
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Ver perfil de la organización',
                                                        style: theme.textTheme.labelSmall?.copyWith(
                                                          color: colorScheme.onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.chevron_right,
                                                  size: 20,
                                                  color: colorScheme.onSurfaceVariant,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 20),

                                  // Fechas y ubicación
                                  Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Detalles',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(Icons.event, size: 18, color: colorScheme.primary),
                                            const SizedBox(width: 8),
                                            Text('Inicio', style: theme.textTheme.bodyMedium),
                                            const Spacer(),
                                            Text(
                                              _proyecto!.fechaInicio != null
                                                  ? '${_proyecto!.fechaInicio!.day}/${_proyecto!.fechaInicio!.month}/${_proyecto!.fechaInicio!.year}'
                                                  : 'No especificada',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.event_busy, size: 18, color: colorScheme.primary),
                                            const SizedBox(width: 8),
                                            Text('Fin', style: theme.textTheme.bodyMedium),
                                            const Spacer(),
                                            Text(
                                              _proyecto!.fechaFin != null
                                                  ? '${_proyecto!.fechaFin!.day}/${_proyecto!.fechaFin!.month}/${_proyecto!.fechaFin!.year}'
                                                  : 'No especificada',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_proyecto!.ubicacion != null && _proyecto!.ubicacion!.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.location_on, size: 18, color: colorScheme.primary),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _proyecto!.ubicacion!,
                                                  style: theme.textTheme.bodyMedium,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Insights placeholder
                                  Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Insights del proyecto',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Inscritos', style: theme.textTheme.labelSmall),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Próximamente',
                                                    style: theme.textTheme.bodyMedium?.copyWith(
                                                      color: colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Reseñas', style: theme.textTheme.labelSmall),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Próximamente',
                                                    style: theme.textTheme.bodyMedium?.copyWith(
                                                      color: colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Puntaje', style: theme.textTheme.labelSmall),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.star_border, size: 18, color: colorScheme.primary),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Próx.',
                                                        style: theme.textTheme.bodyMedium?.copyWith(
                                                          color: colorScheme.onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Sección de tareas (solo si está participando)
                                  if (_participacion != null && _futureProjectTasks != null) ...[
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(22),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            colorScheme.primaryContainer.withOpacity(0.18),
                                            colorScheme.secondaryContainer.withOpacity(0.10),
                                          ],
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Mis tareas en este proyecto',
                                                      style: theme.textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Revisa rápidamente qué tienes pendiente y toca para ver el detalle.',
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        color: colorScheme.onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              FilledButton.tonal(
                                                onPressed: () {
                                                  Modular.to.pushNamed('/voluntario/tareas');
                                                },
                                                style: FilledButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 8,
                                                  ),
                                                  minimumSize: const Size(0, 0),
                                                ),
                                                child: const Text('Ver todas'),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          FutureBuilder<List<Map<String, dynamic>>>(
                                            future: _futureProjectTasks,
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return const Center(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(20),
                                                    child: CircularProgressIndicator(),
                                                  ),
                                                );
                                              }

                                              if (snapshot.hasError) {
                                                return Padding(
                                                  padding: const EdgeInsets.all(12),
                                                  child: Text(
                                                    'Error al cargar tus tareas. Intenta nuevamente más tarde.',
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: colorScheme.error,
                                                    ),
                                                  ),
                                                );
                                              }

                                              final tareas = snapshot.data ?? [];

                                              if (tareas.isEmpty) {
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(10),
                                                        decoration: BoxDecoration(
                                                          color: colorScheme.surface.withOpacity(0.9),
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                        child: Icon(
                                                          Icons.task_alt,
                                                          color: colorScheme.primary,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              'Aún no tienes tareas asignadas',
                                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              'Cuando la organización te asigne tareas, aparecerán aquí.',
                                                              style: theme.textTheme.bodySmall?.copyWith(
                                                                color: colorScheme.onSurfaceVariant,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }

                                              return Column(
                                                children: tareas.take(3).map((tarea) {
                                                  final estado = tarea['estado']?.toString() ?? 'pendiente';
                                                  final titulo = tarea['titulo']?.toString() ?? 'Sin título';
                                                  final tareaId = tarea['id'] ?? tarea['tarea_id'] ?? tarea['tareaId'];
                                                  final descripcion =
                                                      tarea['descripcion']?.toString() ?? tarea['descripcion_tarea']?.toString();
                                                  final fechaLimite = tarea['fecha_limite']?.toString() ??
                                                      tarea['fechaLimite']?.toString();

                                                  Color chipColor;
                                                  Color chipTextColor;
                                                  String estadoLabel;
                                                  IconData? estadoIcon;

                                                  switch (estado.toLowerCase()) {
                                                    case 'pendiente':
                                                      chipColor = colorScheme.errorContainer;
                                                      chipTextColor = colorScheme.onErrorContainer;
                                                      estadoLabel = 'Pendiente';
                                                      estadoIcon = Icons.schedule;
                                                      break;
                                                    case 'en_progreso':
                                                    case 'en progreso':
                                                      chipColor = colorScheme.tertiaryContainer;
                                                      chipTextColor = colorScheme.onTertiaryContainer;
                                                      estadoLabel = 'En progreso';
                                                      estadoIcon = Icons.timelapse;
                                                      break;
                                                    case 'completada':
                                                    case 'completado':
                                                      chipColor = colorScheme.primaryContainer;
                                                      chipTextColor = colorScheme.onPrimaryContainer;
                                                      estadoLabel = 'Completada';
                                                      estadoIcon = Icons.check_circle;
                                                      break;
                                                    default:
                                                      chipColor = colorScheme.surfaceVariant;
                                                      chipTextColor = colorScheme.onSurfaceVariant;
                                                      estadoLabel = estado.isNotEmpty ? estado : 'Sin estado';
                                                  }

                                                  return Container(
                                                    margin: const EdgeInsets.only(bottom: 10),
                                                    child: Material(
                                                      color: colorScheme.surface.withOpacity(0.95),
                                                      borderRadius: BorderRadius.circular(18),
                                                      child: InkWell(
                                                        onTap: () {
                                                          print('👆 Click en tarea: id=$tareaId');
                                                          if (tareaId != null) {
                                                            print('✅ Navegando a /voluntario/tareas/$tareaId');
                                                            Modular.to.pushNamed('/voluntario/tareas/$tareaId');
                                                          } else {
                                                            print('❌ tareaId es null, no se puede navegar');
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: const Text('Error: ID de tarea no disponible'),
                                                                backgroundColor: colorScheme.error,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        borderRadius: BorderRadius.circular(18),
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(14),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Row(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Expanded(
                                                                    child: Text(
                                                                      titulo,
                                                                      style: theme.textTheme.bodyLarge?.copyWith(
                                                                        fontWeight: FontWeight.w600,
                                                                      ),
                                                                      maxLines: 2,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 8),
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal: 10,
                                                                      vertical: 4,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: chipColor,
                                                                      borderRadius: BorderRadius.circular(999),
                                                                    ),
                                                                    child: Row(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        if (estadoIcon != null) ...[
                                                                          Icon(
                                                                            estadoIcon,
                                                                            size: 14,
                                                                            color: chipTextColor,
                                                                          ),
                                                                          const SizedBox(width: 4),
                                                                        ],
                                                                        Text(
                                                                          estadoLabel,
                                                                          style: theme.textTheme.labelSmall?.copyWith(
                                                                            color: chipTextColor,
                                                                            fontWeight: FontWeight.w600,
                                                                            letterSpacing: 0.4,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              if (descripcion != null && descripcion.isNotEmpty) ...[
                                                                const SizedBox(height: 6),
                                                                Text(
                                                                  descripcion,
                                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                                    color: colorScheme.onSurfaceVariant,
                                                                  ),
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ],
                                                              const SizedBox(height: 8),
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    fechaLimite != null && fechaLimite.isNotEmpty
                                                                        ? Icons.event
                                                                        : Icons.info_outline,
                                                                    size: 16,
                                                                    color: colorScheme.primary,
                                                                  ),
                                                                  const SizedBox(width: 6),
                                                                  Expanded(
                                                                    child: Text(
                                                                      fechaLimite != null && fechaLimite.isNotEmpty
                                                                          ? 'Entrega: $fechaLimite'
                                                                          : 'Sin fecha límite definida',
                                                                      style: theme.textTheme.labelSmall?.copyWith(
                                                                        color: colorScheme.onSurfaceVariant,
                                                                      ),
                                                                      maxLines: 1,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(width: 8),
                                                                  Icon(
                                                                    Icons.chevron_right,
                                                                    size: 18,
                                                                    color: colorScheme.onSurfaceVariant,
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ],
                              ),
                            ),
                          ),
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
