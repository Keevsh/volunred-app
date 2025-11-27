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
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.pop(context),
            color: const Color(0xFF1976D2),
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
                                // Imagen principal con hero animation
                                Hero(
                                  tag: 'proyecto_${_proyecto!.idProyecto}',
                                  child: Container(
                                    height: 320,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(32),
                                        bottomRight: Radius.circular(32),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(32),
                                        bottomRight: Radius.circular(32),
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          _proyecto!.imagen != null && _proyecto!.imagen!.isNotEmpty
                                              ? ImageBase64Widget(
                                                  base64String: _proyecto!.imagen!,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  decoration: const BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Color(0xFF1976D2),
                                                        Color(0xFF42A5F5),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.volunteer_activism_rounded,
                                                    size: 80,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                          // Gradient overlay
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.6),
                                                ],
                                                stops: const [0.5, 1.0],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(0, -40),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(24),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.08),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _proyecto!.nombre,
                                                style: theme.textTheme.headlineSmall?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -0.5,
                                                  color: const Color(0xFF1A1A1A),
                                                  height: 1.2,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _proyecto!.estado == 'activo'
                                                          ? const Color(0xFF1976D2)
                                                          : const Color(0xFFEF5350),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 6,
                                                          height: 6,
                                                          decoration: const BoxDecoration(
                                                            color: Colors.white,
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          _proyecto!.estado.toUpperCase(),
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w700,
                                                            letterSpacing: 0.8,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (_proyecto!.categoriasProyectos != null &&
                                                      _proyecto!.categoriasProyectos!.isNotEmpty)
                                                    ..._proyecto!.categoriasProyectos!.take(2).map((catProy) {
                                                      String categoriaNombre = 'Categoría';
                                                      if (catProy is Map && catProy['categoria'] is Map) {
                                                        categoriaNombre =
                                                            catProy['categoria']['nombre']?.toString() ?? 'Categoría';
                                                      }
                                                      return Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFE3F2FD),
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        child: Text(
                                                          categoriaNombre,
                                                          style: const TextStyle(
                                                            color: Color(0xFF1976D2),
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                ],
                                              ),
                                              if (_proyecto!.objetivo != null && _proyecto!.objetivo!.isNotEmpty) ...[
                                                const SizedBox(height: 16),
                                                Text(
                                                  _proyecto!.objetivo!,
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: const Color(0xFF616161),
                                                    height: 1.6,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),

                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
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

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.06),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              Modular.to.pushNamed(
                                                '/voluntario/organizaciones/${_proyecto!.organizacionId}',
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(20),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  avatar,
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          organizacionNombre,
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w700,
                                                            color: Color(0xFF1A1A1A),
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          'Ver perfil de la organización',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFE3F2FD),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: const Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 16,
                                                      color: Color(0xFF1976D2),
                                                    ),
                                                  ),
                                                ],
                                              ),
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
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Detalles del Proyecto',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        _buildDetailRow(
                                          Icons.calendar_today_rounded,
                                          'Fecha de Inicio',
                                          _proyecto!.fechaInicio != null
                                              ? '${_proyecto!.fechaInicio!.day}/${_proyecto!.fechaInicio!.month}/${_proyecto!.fechaInicio!.year}'
                                              : 'No especificada',
                                          theme,
                                        ),
                                        const SizedBox(height: 16),
                                        _buildDetailRow(
                                          Icons.event_available_rounded,
                                          'Fecha de Fin',
                                          _proyecto!.fechaFin != null
                                              ? '${_proyecto!.fechaFin!.day}/${_proyecto!.fechaFin!.month}/${_proyecto!.fechaFin!.year}'
                                              : 'No especificada',
                                          theme,
                                        ),
                                        if (_proyecto!.ubicacion != null && _proyecto!.ubicacion!.isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          _buildDetailRow(
                                            Icons.location_on_rounded,
                                            'Ubicación',
                                            _proyecto!.ubicacion!,
                                            theme,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  const SizedBox(height: 20),

                                  // Sección de tareas (solo si está participando)
                                  if (_participacion != null && _futureProjectTasks != null) ...[
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF1976D2),
                                            Color(0xFF42A5F5),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF1976D2).withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Mis Tareas',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.w800,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      'Revisa rápidamente qué tienes pendiente',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white.withOpacity(0.9),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.3),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () {
                                                      Modular.to.pushNamed('/voluntario/tareas');
                                                    },
                                                    borderRadius: BorderRadius.circular(16),
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 10,
                                                      ),
                                                      child: Text(
                                                        'Ver todas',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
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
                                                    margin: const EdgeInsets.only(bottom: 12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(20),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.08),
                                                          blurRadius: 12,
                                                          offset: const Offset(0, 4),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      borderRadius: BorderRadius.circular(20),
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

                Widget _buildDetailRow(IconData icon, String label, String value, ThemeData theme) {
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: const Color(0xFF1976D2),
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
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              value,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              }
