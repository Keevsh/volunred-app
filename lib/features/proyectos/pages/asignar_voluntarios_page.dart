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
  final FuncionarioRepository _repository = Modular.get<FuncionarioRepository>();
  late Future<List<PerfilVoluntario>> _futureVoluntarios;
  late Future<List<AsignacionTarea>> _futureAsignaciones;
  Set<int> _idsAsignados = {};
  bool _isAssigning = false;
  String _searchQuery = '';
  bool _tieneParticipantes = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _futureVoluntarios = _fetchEligibleVoluntarios();
    _futureAsignaciones = _repository.getAsignacionesByTarea(widget.tareaId).then((asignaciones) {
      setState(() {
        _idsAsignados = asignaciones.map((a) => a.perfilVolId).toSet();
      });
      return asignaciones;
    });
  }

  Future<List<PerfilVoluntario>> _fetchEligibleVoluntarios() async {
    final tarea = await _repository.getTareaById(widget.tareaId);
    final List<Participacion> participaciones =
        await _repository.getParticipacionesByProyecto(tarea.proyectoId);

    final participanteUserIds = _extractParticipanteUserIds(participaciones);

    if (mounted) {
      setState(() {
        _tieneParticipantes = participanteUserIds.isNotEmpty;
      });
    }

    if (participanteUserIds.isEmpty) {
      return [];
    }

    final voluntarios = await _repository.getVoluntariosDeMiOrganizacion();
    return voluntarios
        .where((voluntario) => participanteUserIds.contains(voluntario.usuarioId))
        .toList();
  }

  Set<int> _extractParticipanteUserIds(List<Participacion> participaciones) {
    final usuarioIds = <int>{};
    for (final participacion in participaciones) {
      final inscripcion = participacion.inscripcion;
      if (inscripcion == null) continue;

      final rawUserId =
          inscripcion['usuario_id'] ?? inscripcion['usuarioId'] ?? inscripcion['voluntarioId'];
      if (rawUserId == null) continue;

      final parsedId = rawUserId is int ? rawUserId : int.tryParse(rawUserId.toString());
      if (parsedId != null) {
        usuarioIds.add(parsedId);
      }
    }
    return usuarioIds;
  }

  Future<void> _refresh() async {
    setState(_loadData);
    await Future.wait([_futureVoluntarios, _futureAsignaciones]);
  }

  Future<void> _asignarVoluntario(PerfilVoluntario voluntario) async {
    setState(() {
      _isAssigning = true;
    });

    try {
      await _repository.asignarTareaVoluntario(
        widget.tareaId,
        {
          'perfil_vol_id': voluntario.idPerfilVoluntario,
          'titulo': widget.tareaNombre,
          'descripcion': 'Asignación desde app móvil',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${voluntario.usuario?['nombres'] ?? 'Voluntario'} asignado exitosamente'),
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
                              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
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
                    final nombres = v.usuario?['nombres']?.toString().toLowerCase() ?? '';
                    final apellidos = v.usuario?['apellidos']?.toString().toLowerCase() ?? '';
                    final email = v.usuario?['email']?.toString().toLowerCase() ?? '';
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
                              Icon(Icons.people_outline, size: 64, color: colorScheme.primary),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? (_tieneParticipantes
                                        ? 'No hay voluntarios disponibles'
                                        : 'No hay voluntarios participando en este proyecto')
                                    : 'No se encontraron voluntarios',
                                style: theme.textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
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
                      final isAsignado = _idsAsignados.contains(voluntario.idPerfilVoluntario);

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
