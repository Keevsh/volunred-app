import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

import '../../../core/models/aptitud.dart';
import '../../../core/models/experiencia_voluntario.dart';
import '../../../core/models/participacion.dart';
import '../../../core/models/perfil_voluntario.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/widgets/image_base64_widget.dart';

class VoluntarioProfileViewPage extends StatefulWidget {
  final int perfilVolId;
  final String? initialName;

  const VoluntarioProfileViewPage({
    super.key,
    required this.perfilVolId,
    this.initialName,
  });

  @override
  State<VoluntarioProfileViewPage> createState() => _VoluntarioProfileViewPageState();
}

class _VoluntarioProfileViewPageState extends State<VoluntarioProfileViewPage> {
  final VoluntarioRepository _repository = Modular.get<VoluntarioRepository>();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  PerfilVoluntario? _perfil;
  List<Aptitud> _aptitudes = [];
  List<ExperienciaVoluntario> _experiencias = [];
  List<Participacion> _participaciones = [];

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
      final perfilFuture = _repository.getPerfilById(widget.perfilVolId);
      final aptitudesFuture = _repository.getAptitudesByVoluntario(widget.perfilVolId);
      final experienciasFuture = _repository.getExperiencias();
      final participacionesFuture = _repository.getParticipaciones();

      final results = await Future.wait([
        perfilFuture,
        aptitudesFuture,
        experienciasFuture,
        participacionesFuture,
      ]);

      final perfil = results[0] as PerfilVoluntario;
      final aptitudes = results[1] as List<Aptitud>;
      final experiencias = (results[2] as List<ExperienciaVoluntario>)
          .where((exp) => exp.perfilVolId == widget.perfilVolId)
          .toList();
      final participaciones = (results[3] as List<Participacion>)
          .where((p) => _matchesPerfil(p, widget.perfilVolId))
          .toList();

      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _aptitudes = aptitudes;
        _experiencias = experiencias;
        _participaciones = participaciones;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'No se pudo cargar la información del voluntario. Intenta nuevamente.';
      });
    }
  }

  bool _matchesPerfil(Participacion participacion, int perfilId) {
    if (participacion.perfilVolId != null && participacion.perfilVolId == perfilId) {
      return true;
    }

    final inscripcion = participacion.inscripcion;
    if (inscripcion != null) {
      final perfilVol = inscripcion['perfil_voluntario'];
      if (perfilVol is Map) {
        final fromPerfil = perfilVol['id_perfil_voluntario'];
        if (fromPerfil != null && int.tryParse(fromPerfil.toString()) == perfilId) {
          return true;
        }
      }

      final perfilDirect = inscripcion['perfil_vol_id'];
      if (perfilDirect != null && int.tryParse(perfilDirect.toString()) == perfilId) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Perfil del voluntario'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState(colorScheme)
                : _buildProfileContent(colorScheme),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.error_outline, size: 64, color: colorScheme.error),
        const SizedBox(height: 16),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ],
    );
  }

  Widget _buildProfileContent(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final nombreUsuario = _buildNombreVoluntario();
    final email = _perfil?.usuario?['email']?.toString() ?? 'Sin email';
    final telefono = _perfil?.usuario?['telefono']?.toString();
    final disponibilidad = _perfil?.disponibilidad;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(colorScheme),
                const SizedBox(height: 16),
                Text(
                  nombreUsuario,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                if (telefono != null && telefono.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    telefono,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildRoleBadge(colorScheme),
                const SizedBox(height: 24),
                _buildStatsRow(theme, colorScheme),
                const SizedBox(height: 24),
                _buildInfoCard(
                  title: 'Biografía',
                  child: Text(
                    _perfil?.bio?.isNotEmpty == true
                        ? _perfil!.bio!
                        : 'Este voluntario aún no ha agregado una biografía.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _perfil?.bio?.isNotEmpty == true
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (disponibilidad != null && disponibilidad.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Disponibilidad',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: disponibilidad
                          .split(',')
                          .map((d) => d.trim())
                          .where((d) => d.isNotEmpty)
                          .map((slot) => Chip(
                                label: Text(slot),
                                backgroundColor:
                                    colorScheme.secondary.withOpacity(0.1),
                                labelStyle: TextStyle(
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
                if (_aptitudes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Aptitudes',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _aptitudes
                          .map(
                            (apt) => Chip(
                              label: Text(apt.nombre),
                              avatar: Icon(
                                Icons.check_circle,
                                color: colorScheme.primary,
                                size: 18,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                if (_experiencias.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Experiencias de voluntariado',
                    child: Column(
                      children: _experiencias
                          .map(_buildExperienceTile)
                          .toList(),
                    ),
                  ),
                ],
                if (_participaciones.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: 'Participaciones recientes',
                    child: Column(
                      children: _participaciones
                          .take(5)
                          .map(_buildParticipationTile)
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _buildNombreVoluntario() {
    final usuario = _perfil?.usuario;
    if (usuario != null) {
      final nombres = usuario['nombres']?.toString() ?? '';
      final apellidos = usuario['apellidos']?.toString() ?? '';
      final full = '$nombres $apellidos'.trim();
      if (full.isNotEmpty) return full;
    }
    return widget.initialName ?? 'Voluntario';
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    if (_perfil?.fotoPerfil != null && _perfil!.fotoPerfil!.isNotEmpty) {
      return CircularImageBase64Widget(
        base64String: _perfil!.fotoPerfil,
        size: 120,
        borderColor: colorScheme.primary,
        borderWidth: 3,
      );
    }

    final nombre = _buildNombreVoluntario();
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'V';
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          inicial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.volunteer_activism, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Voluntario verificado',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, ColorScheme colorScheme) {
    final participacionesActivas =
        _participaciones.where((p) => p.estado.toUpperCase() == 'PROGRAMADA').length;

    return Row(
      children: [
        Expanded(
          child: _buildStatColumn(
            title: 'Participaciones',
            value: _participaciones.length.toString(),
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatColumn(
            title: 'Activas',
            value: participacionesActivas.toString(),
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatColumn(
            title: 'Aptitudes',
            value: _aptitudes.length.toString(),
            color: const Color(0xFFFFA000),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn({required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildExperienceTile(ExperienciaVoluntario exp) {
    final orgNombre = exp.organizacion != null
        ? (exp.organizacion!['nombre'] ?? exp.organizacion!['nombre_legal'] ?? 'Organización')
            .toString()
        : 'Organización';
    final periodo = _formatPeriodo(exp.fechaInicio, exp.fechaFin);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.work_outline, color: Color(0xFF1976D2)),
        ),
        title: Text(
          exp.area,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(orgNombre),
            Text(
              periodo,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationTile(Participacion participacion) {
    final proyectoNombre = participacion.proyecto != null
        ? (participacion.proyecto!['nombre'] ?? 'Proyecto').toString()
        : 'Proyecto';
    final estado = participacion.estado.toUpperCase();

    Color estadoColor;
    switch (estado) {
      case 'EN_PROGRESO':
        estadoColor = const Color(0xFF1976D2);
        break;
      case 'COMPLETADO':
        estadoColor = const Color(0xFF4CAF50);
        break;
      case 'RECHAZADO':
      case 'CANCELADO':
        estadoColor = const Color(0xFFFF6B6B);
        break;
      default:
        estadoColor = const Color(0xFFFFA000);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: estadoColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.volunteer_activism, color: estadoColor),
        ),
        title: Text(
          proyectoNombre,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Estado: ${estado[0]}${estado.substring(1).toLowerCase()}',
          style: TextStyle(color: estadoColor.darken(0.2)),
        ),
      ),
    );
  }

  String _formatPeriodo(DateTime inicio, DateTime? fin) {
    final inicioStr = _dateFormat.format(inicio);
    final finStr = fin != null ? _dateFormat.format(fin) : 'Actualidad';
    return '$inicioStr • $finStr';
  }
}

extension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
