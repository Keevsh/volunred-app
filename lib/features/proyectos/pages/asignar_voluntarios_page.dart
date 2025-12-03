import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/models/perfil_voluntario.dart';
import '../../../core/models/asignacion_tarea.dart';
import '../../../core/models/participacion.dart';

class AsignarVoluntariosPage extends StatefulWidget {
  final int tareaId;
  final String tareaNombre;

  const AsignarVoluntariosPage({
    super.key,
    required this.tareaId,
    required this.tareaNombre,
  });

  @override
  State<AsignarVoluntariosPage> createState() => _AsignarVoluntariosPageState();
}

class _AsignarVoluntariosPageState extends State<AsignarVoluntariosPage> {
  final FuncionarioRepository _repository =
      Modular.get<FuncionarioRepository>();
  late Future<List<PerfilVoluntario>> _futureVoluntarios;
  late Future<List<AsignacionTarea>> _futureAsignaciones;
  Set<int> _idsAsignados = {};
  bool _isAssigning = false;
  String _searchQuery = '';
  bool _tieneParticipantes = true;

  // Mapas para almacenar los datos de participación necesarios
  final Map<int, int> _usuarioToParticipacionMap =
      {}; // usuarioId -> participacionId
  final Map<int, int> _usuarioToPerfilVolMap = {}; // usuarioId -> perfilVolId
  final Map<int, Participacion> _participaciones =
      {}; // participacionId -> Participacion

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _futureVoluntarios = _fetchEligibleVoluntarios();
    _futureAsignaciones = _repository
        .getAsignacionesByTarea(widget.tareaId)
        .then((asignaciones) {
          setState(() {
            _idsAsignados = asignaciones.map((a) => a.perfilVolId).toSet();
          });
          return asignaciones;
        });
  }

  Future<List<PerfilVoluntario>> _fetchEligibleVoluntarios() async {
    print('🔍 Obteniendo tarea ${widget.tareaId}...');
    final tarea = await _repository.getTareaById(widget.tareaId);
    print(
      '✅ Tarea obtenida: ${tarea.nombre}, proyecto_id: ${tarea.proyectoId}',
    );

    print('🔍 Obteniendo participaciones del proyecto ${tarea.proyectoId}...');
    final List<Participacion> participaciones = await _repository
        .getParticipacionesByProyecto(tarea.proyectoId);
    print('✅ Participaciones obtenidas: ${participaciones.length}');

    final participanteUserIds = _extractParticipanteUserIds(participaciones);

    if (mounted) {
      setState(() {
        _tieneParticipantes = participanteUserIds.isNotEmpty;
      });
    }

    if (participanteUserIds.isEmpty) {
      print('⚠️ No hay participantes en el proyecto');
      return [];
    }

    print('🔍 Obteniendo voluntarios de la organización...');
    final voluntarios = await _repository.getVoluntariosDeMiOrganizacion();
    print('✅ Voluntarios de la organización: ${voluntarios.length}');

    final filtrados = voluntarios.where((voluntario) {
      final participa = participanteUserIds.contains(voluntario.usuarioId);
      if (participa) {
        print('✅ Voluntario ${voluntario.usuarioId} participa en el proyecto');
      }
      return participa;
    }).toList();

    print('📊 Voluntarios elegibles para asignar: ${filtrados.length}');
    return filtrados;
  }

  Set<int> _extractParticipanteUserIds(List<Participacion> participaciones) {
    final usuarioIds = <int>{};
    _usuarioToParticipacionMap.clear(); // Limpiar mapas anteriores
    _usuarioToPerfilVolMap.clear();
    _participaciones.clear();

    print('🔍 Analizando ${participaciones.length} participaciones...');

    for (final participacion in participaciones) {
      print('📝 Participación ${participacion.idParticipacion}:');
      print('   - Estado: "${participacion.estado}"');
      print('   - perfil_vol_id: ${participacion.perfilVolId}');
      print('   - inscripcion_id: ${participacion.inscripcionId}');

      // Guardar la participación completa
      _participaciones[participacion.idParticipacion] = participacion;

      // Aceptar participaciones que no estén eliminadas o rechazadas
      // El usuario podrá aprobar las que estén en otros estados
      final estadoUpper = participacion.estado.toUpperCase();
      if (estadoUpper == 'ELIMINADA' || estadoUpper == 'RECHAZADA') {
        print(
          '⏭️ Participación ${participacion.idParticipacion} está ${participacion.estado}, se omite',
        );
        continue;
      }

      // El perfil_vol_id viene directamente en el objeto Participacion
      final perfilVolId = participacion.perfilVolId;
      if (perfilVolId == null) {
        print(
          '⚠️ Participación ${participacion.idParticipacion} no tiene perfil_vol_id',
        );
        continue;
      }

      final inscripcion = participacion.inscripcion;
      if (inscripcion == null) {
        print(
          '⚠️ Participación ${participacion.idParticipacion} no tiene inscripción',
        );
        continue;
      }

      print('   - inscripcion keys: ${inscripcion.keys.toList()}');

      // Extraer usuario_id: intentar desde perfil_voluntario.usuario
      int? usuarioId;

      // Primero intentar desde perfil_voluntario.usuario (nuevo esquema)
      if (inscripcion['perfil_voluntario'] is Map) {
        final perfilVol = inscripcion['perfil_voluntario'] as Map<String, dynamic>;
        if (perfilVol['usuario'] is Map) {
          final usuario = perfilVol['usuario'] as Map<String, dynamic>;
          print('   - usuario object keys: ${usuario.keys.toList()}');
          final rawUsuarioId = usuario['id_usuario'] ?? usuario['idUsuario'];
          if (rawUsuarioId != null) {
            usuarioId = rawUsuarioId is int
                ? rawUsuarioId
                : int.tryParse(rawUsuarioId.toString());
            print('   - usuario_id encontrado en perfil_voluntario.usuario: $usuarioId');
          }
        }
      }

      // Fallback: intentar desde objeto usuario anidado directo (legacy)
      if (usuarioId == null && inscripcion['usuario'] is Map) {
        final usuario = inscripcion['usuario'] as Map<String, dynamic>;
        print('   - usuario object keys (legacy): ${usuario.keys.toList()}');
        final rawUsuarioId = usuario['id_usuario'] ?? usuario['idUsuario'];
        if (rawUsuarioId != null) {
          usuarioId = rawUsuarioId is int
              ? rawUsuarioId
              : int.tryParse(rawUsuarioId.toString());
          print('   - usuario_id encontrado en objeto legacy: $usuarioId');
        }
      }

      if (usuarioId != null && usuarioId > 0) {
        usuarioIds.add(usuarioId);
        // Guardar los mapeos necesarios para la asignación
        _usuarioToParticipacionMap[usuarioId] = participacion.idParticipacion;
        _usuarioToPerfilVolMap[usuarioId] = perfilVolId;
        print(
          '✅ Usuario $usuarioId participa en el proyecto (participación ${participacion.idParticipacion}, perfil_vol $perfilVolId)',
        );
      } else {
        print(
          '⚠️ No se pudo extraer usuario_id de la participación ${participacion.idParticipacion}',
        );
      }
    }

    print(
      '📋 Total de usuarios participantes encontrados: ${usuarioIds.length}',
    );
    return usuarioIds;
  }

  Future<void> _refresh() async {
    setState(_loadData);
    await Future.wait([_futureVoluntarios, _futureAsignaciones]);
  }

  Future<void> _aprobarParticipacion(int participacionId) async {
    try {
      print('📝 Aprobando participación $participacionId...');
      await _repository.updateParticipacion(participacionId, {
        'estado': 'APROBADA',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Participación aprobada exitosamente'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        // Recargar datos
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aprobar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _asignarVoluntario(PerfilVoluntario voluntario) async {
    setState(() {
      _isAssigning = true;
    });

    try {
      // Obtener participacion_id y perfil_vol_id del voluntario
      final participacionId = _usuarioToParticipacionMap[voluntario.usuarioId];
      final perfilVolId = _usuarioToPerfilVolMap[voluntario.usuarioId];

      if (participacionId == null || perfilVolId == null) {
        throw Exception(
          'No se encontró la participación aprobada del voluntario en este proyecto',
        );
      }

      print('📤 Asignando tarea ${widget.tareaId} al voluntario:');
      print('   - perfil_vol_id: $perfilVolId');
      print('   - participacion_id: $participacionId');

      await _repository.asignarTareaVoluntario(widget.tareaId, {
        'perfil_vol_id': perfilVolId,
        'participacion_id': participacionId,
        'titulo': widget.tareaNombre,
        'descripcion': 'Asignación desde app móvil',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${voluntario.usuario?['nombres'] ?? 'Voluntario'} asignado exitosamente',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Asignar Voluntarios'),
            Text(
              widget.tareaNombre,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar voluntario...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<PerfilVoluntario>>(
                future: _futureVoluntarios,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: colorScheme.error,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Error al cargar voluntarios',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                snapshot.error.toString(),
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  final voluntarios = snapshot.data ?? [];
                  final filteredVoluntarios = voluntarios.where((v) {
                    if (_searchQuery.isEmpty) return true;
                    final nombres =
                        v.usuario?['nombres']?.toString().toLowerCase() ?? '';
                    final apellidos =
                        v.usuario?['apellidos']?.toString().toLowerCase() ?? '';
                    final email =
                        v.usuario?['email']?.toString().toLowerCase() ?? '';
                    return nombres.contains(_searchQuery) ||
                        apellidos.contains(_searchQuery) ||
                        email.contains(_searchQuery);
                  }).toList();

                  if (filteredVoluntarios.isEmpty) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                _tieneParticipantes
                                    ? Icons.people_outline
                                    : Icons.group_off,
                                size: 64,
                                color: _tieneParticipantes
                                    ? colorScheme.primary
                                    : colorScheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? (_tieneParticipantes
                                          ? 'No hay voluntarios disponibles'
                                          : 'No hay voluntarios participando en este proyecto')
                                    : 'No se encontraron voluntarios',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (!_tieneParticipantes &&
                                  _searchQuery.isEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Solo puedes asignar tareas a voluntarios con participaciones APROBADAS en este proyecto.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Verifica que las participaciones de los voluntarios estén en estado "APROBADA" (no "programada", "en_progreso", etc.).',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    itemCount: filteredVoluntarios.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final voluntario = filteredVoluntarios[index];
                      final usuario = voluntario.usuario;
                      final nombres = usuario?['nombres']?.toString() ?? '';
                      final apellidos = usuario?['apellidos']?.toString() ?? '';
                      final email = usuario?['email']?.toString() ?? '';
                      final bio = voluntario.bio ?? '';
                      final isAsignado = _idsAsignados.contains(
                        voluntario.idPerfilVoluntario,
                      );

                      // Obtener la participación del voluntario
                      final participacionId =
                          _usuarioToParticipacionMap[voluntario.usuarioId];
                      final participacion = participacionId != null
                          ? _participaciones[participacionId]
                          : null;
                      final estadoParticipacion =
                          participacion?.estado.toUpperCase() ?? '';
                      final isAprobada = estadoParticipacion == 'APROBADA';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAsignado
                              ? colorScheme.primaryContainer
                              : colorScheme.secondaryContainer,
                          child: Text(
                            nombres.isNotEmpty ? nombres[0].toUpperCase() : 'V',
                            style: TextStyle(
                              color: isAsignado
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        title: Text('$nombres $apellidos'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (email.isNotEmpty) Text(email),
                            if (bio.isNotEmpty)
                              Text(
                                bio,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                        trailing: isAsignado
                            ? Chip(
                                label: const Text('Asignado'),
                                backgroundColor: colorScheme.primaryContainer,
                                labelStyle: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              )
                            : !isAprobada
                            ? FilledButton.icon(
                                onPressed: participacionId != null
                                    ? () =>
                                          _aprobarParticipacion(participacionId)
                                    : null,
                                icon: const Icon(Icons.check_circle, size: 18),
                                label: const Text('Aprobar'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: colorScheme.tertiary,
                                  foregroundColor: colorScheme.onTertiary,
                                ),
                              )
                            : FilledButton.icon(
                                onPressed: _isAssigning
                                    ? null
                                    : () => _asignarVoluntario(voluntario),
                                icon: const Icon(Icons.person_add, size: 18),
                                label: const Text('Asignar'),
                              ),
                        isThreeLine: bio.isNotEmpty,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
