import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/models/participacion.dart';
import '../../../core/models/perfil_voluntario.dart';

class ParticipacionesPage extends StatefulWidget {
  const ParticipacionesPage({super.key});

  @override
  State<ParticipacionesPage> createState() => _ParticipacionesPageState();
}

class _ParticipacionesPageState extends State<ParticipacionesPage> {
  final VoluntarioRepository _repository = Modular.get<VoluntarioRepository>();
  List<Participacion> _participaciones = [];
  PerfilVoluntario? _perfil;
  bool _isLoading = true;
  String? _error;

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
      final perfil = await _repository.getStoredPerfil();
      if (perfil == null) {
        throw Exception('No tienes un perfil de voluntario');
      }

      final participaciones = await _repository.getParticipaciones();
      
      // Filtrar solo las participaciones del usuario actual
      final participacionesUsuario = participaciones.where((part) {
        if (part.inscripcion != null) {
          final usuarioId = part.inscripcion!['usuario_id'];
          return usuarioId == perfil.usuarioId;
        }
        return false;
      }).toList();

      setState(() {
        _perfil = perfil;
        _participaciones = participacionesUsuario;
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
        title: const Text('Mis Participaciones'),
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
                      Text('Error al cargar participaciones', style: theme.textTheme.titleLarge),
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
              : _participaciones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text('No tienes participaciones', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text('Explora proyectos para participar', style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () {
                              Modular.to.pushNamed('/voluntario/proyectos');
                            },
                            child: const Text('Explorar Proyectos'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _participaciones.length,
                        itemBuilder: (context, index) {
                          final participacion = _participaciones[index];
                          final proyecto = participacion.proyecto;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                Modular.to.pushNamed('/voluntario/participaciones/${participacion.idParticipacion}');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            proyecto?['nombre']?.toString() ?? 'Proyecto',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Chip(
                                          label: Text(participacion.estado.toUpperCase()),
                                          backgroundColor: _getEstadoColor(participacion.estado, colorScheme),
                                          labelStyle: TextStyle(
                                            color: _getEstadoTextColor(participacion.estado, colorScheme),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (participacion.rolAsignado != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.person, size: 16, color: colorScheme.onSurfaceVariant),
                                          const SizedBox(width: 4),
                                          Text('Rol: ${participacion.rolAsignado}', style: theme.textTheme.bodyMedium),
                                        ],
                                      ),
                                    ],
                                    if (participacion.horasComprometidasSemana != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 16, color: colorScheme.onSurfaceVariant),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${participacion.horasComprometidasSemana} horas/semana',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Color _getEstadoColor(String estado, ColorScheme colorScheme) {
    switch (estado.toLowerCase()) {
      case 'programada':
        return colorScheme.primaryContainer;
      case 'en_progreso':
        return colorScheme.tertiaryContainer;
      case 'completado':
        return colorScheme.secondaryContainer;
      case 'ausente':
        return colorScheme.errorContainer;
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }

  Color _getEstadoTextColor(String estado, ColorScheme colorScheme) {
    switch (estado.toLowerCase()) {
      case 'programada':
        return colorScheme.onPrimaryContainer;
      case 'en_progreso':
        return colorScheme.onTertiaryContainer;
      case 'completado':
        return colorScheme.onSecondaryContainer;
      case 'ausente':
        return colorScheme.onErrorContainer;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }
}

