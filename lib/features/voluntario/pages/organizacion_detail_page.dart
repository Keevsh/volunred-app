import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/models/organizacion.dart';
import '../../../core/models/inscripcion.dart';
import '../../../core/models/proyecto.dart';
import 'dart:convert';

class OrganizacionDetailPage extends StatefulWidget {
  final int organizacionId;

  const OrganizacionDetailPage({super.key, required this.organizacionId});

  @override
  State<OrganizacionDetailPage> createState() => _OrganizacionDetailPageState();
}

class _OrganizacionDetailPageState extends State<OrganizacionDetailPage> {
  final VoluntarioRepository _repository = Modular.get<VoluntarioRepository>();
  Organizacion? _organizacion;
  Inscripcion? _inscripcion;
  bool _isLoading = true;
  String? _error;
  bool _isInscribiendo = false;
  int _inscripcionesCount = 0;
  int _proyectosCount = 0;

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
      final organizacion = await _repository.getOrganizacionById(
        widget.organizacionId,
      );

      // Obtener el perfil del voluntario actual
      final perfil = await _repository.getStoredPerfil();

      // Verificar inscripciones SOLO del usuario actual
      try {
        final inscripciones = await _repository.getInscripciones();

        // Contar todas las inscripciones de esta organización (para estadísticas)
        final inscripcionesOrg = inscripciones
            .where((ins) => ins.organizacionId == widget.organizacionId)
            .toList();
        _inscripcionesCount = inscripcionesOrg.length;

        // Buscar la inscripción del usuario actual en esta organización
        if (perfil != null) {
          _inscripcion = inscripciones.firstWhere(
            (ins) =>
                ins.organizacionId == widget.organizacionId &&
                ins.perfilVolId == perfil.idPerfilVoluntario,
            orElse: () => throw StateError('No encontrada'),
          );
        } else {
          _inscripcion = null;
        }
      } catch (e) {
        _inscripcion = null;
      }

      setState(() {
        _organizacion = organizacion;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Muestra el modal de confirmación antes de inscribirse
  Future<void> _mostrarConfirmacionInscripcion() async {
    if (_organizacion == null) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Icono y título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.privacy_tip_outlined,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Solicitar inscripción',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Aviso de privacidad
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Información importante',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Al inscribirte a "${_organizacion!.nombre}", la organización podrá ver tu información de perfil, incluyendo:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPrivacyItem(Icons.person, 'Tu nombre completo', theme),
                  _buildPrivacyItem(
                    Icons.email,
                    'Tu correo electrónico',
                    theme,
                  ),
                  _buildPrivacyItem(
                    Icons.phone,
                    'Tu número de teléfono',
                    theme,
                  ),
                  _buildPrivacyItem(
                    Icons.badge,
                    'Tu perfil de voluntario',
                    theme,
                  ),
                  _buildPrivacyItem(
                    Icons.star,
                    'Tus aptitudes y experiencias',
                    theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Nota sobre el proceso
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.schedule,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tu solicitud quedará pendiente hasta que la organización la revise y apruebe.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Acepto, inscribirme'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _inscribirse();
    }
  }

  Widget _buildPrivacyItem(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _inscribirse() async {
    if (_organizacion == null) return;

    setState(() {
      _isInscribiendo = true;
    });

    try {
      // Obtener usuario_id del storage o del perfil
      final perfil = await _repository.getStoredPerfil();
      if (perfil == null) {
        throw Exception('No tienes un perfil de voluntario. Crea uno primero.');
      }

      // Verificar si ya existe una inscripción para este usuario y organización
      try {
        final inscripciones = await _repository.getInscripciones();
        final inscripcionExistente = inscripciones.firstWhere(
          (ins) =>
              ins.perfilVolId == perfil.idPerfilVoluntario &&
              ins.organizacionId == widget.organizacionId,
          orElse: () => throw StateError('No existe'),
        );

        // Si ya existe una inscripción
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ya tienes una inscripción ${inscripcionExistente.estado.toLowerCase()} para esta organización',
              ),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          );
        }
        return;
      } catch (e) {
        // No existe inscripción, continuar con la creación
      }

      final data = {
        'perfil_vol_id': perfil.idPerfilVoluntario,
        'organizacion_id': widget.organizacionId,
        'estado': 'pendiente', // El backend espera minúsculas
      };

      print(
        '🚀 [VOLUNTARIO] Enviando datos al backend para crear inscripción:',
      );
      print('📦 [VOLUNTARIO] Data: $data');
      print('👤 Perfil Vol ID: ${perfil.idPerfilVoluntario}');
      print('🏢 Organización ID: ${widget.organizacionId}');
      print('📅 Fecha recepción: será asignada automáticamente por el backend');

      await _repository.createInscripcion(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Solicitud enviada! La organización revisará tu inscripción.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Recargar para actualizar el estado
      }
    } catch (e) {
      if (mounted) {
        // Limpiar el mensaje de error (remover "Exception: " prefix)
        String errorMessage = e.toString().replaceFirst('Exception: ', '');

        // Verificar si es un error de inscripción duplicada (409)
        final bool isDuplicateError =
            errorMessage.toLowerCase().contains('ya existe') ||
            errorMessage.toLowerCase().contains('pendiente') ||
            errorMessage.toLowerCase().contains('solicitud');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: isDuplicateError
                ? Colors.orange
                : Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );

        // Si ya existe una inscripción pendiente, recargar datos para actualizar UI
        if (isDuplicateError) {
          _loadData();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInscribiendo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Quitamos el título y usamos un perfil tipo red social con banner propio
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar organización',
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
                    onPressed: _loadData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : _organizacion == null
          ? const Center(child: Text('Organización no encontrada'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header superior tipo Instagram (nombre centrado, botón atrás, menú)
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            color: colorScheme.onSurface,
                            onPressed: () => Modular.to.pop(),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                _organizacion!.nombre,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 48,
                          ), // espacio para balancear con el IconButton izquierdo
                        ],
                      ),
                    ),
                  ),

                  // Contenido principal estilo perfil Instagram
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fila avatar + estadísticas
                        Row(
                          children: [
                            // Avatar con indicador de estado (sin sombra)
                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: colorScheme.surface,
                                    child: CircleAvatar(
                                      radius: 46,
                                      backgroundColor:
                                          colorScheme.primaryContainer,
                                      backgroundImage:
                                          _organizacion!.logo != null &&
                                              _organizacion!.logo!.isNotEmpty
                                          ? MemoryImage(
                                              base64Decode(
                                                _organizacion!.logo!
                                                    .split(',')
                                                    .last,
                                              ),
                                            )
                                          : null,
                                      child:
                                          (_organizacion!.logo == null ||
                                              _organizacion!.logo!.isEmpty)
                                          ? Icon(
                                              Icons.business,
                                              size: 38,
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                            )
                                          : null,
                                    ),
                                  ),
                                  if (_organizacion!.estado.toLowerCase() ==
                                      'activo')
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Container(
                                          margin: const EdgeInsets.all(1.5),
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Stats a la derecha
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatItem(
                                    theme,
                                    'Inscripciones',
                                    _inscripcionesCount > 0
                                        ? '$_inscripcionesCount'
                                        : '0',
                                  ),
                                  _buildStatItem(
                                    theme,
                                    'Funcionarios',
                                    '-', // No tenemos datos en esta pantalla
                                  ),
                                  _buildStatItem(
                                    theme,
                                    'Proyectos',
                                    _proyectosCount > 0
                                        ? '$_proyectosCount'
                                        : '0',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Nombre, razón social y ubicación debajo del banner
                        Text(
                          _organizacion!.nombre,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_organizacion!.razonSocial != null &&
                            _organizacion!.razonSocial !=
                                _organizacion!.nombre) ...[
                          const SizedBox(height: 4),
                          Text(
                            _organizacion!.razonSocial!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (_organizacion!.direccion != null &&
                            _organizacion!.direccion!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _organizacion!.direccion!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Botones estilo Instagram: Inscribirse/Inscrito y Contacto
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed:
                                    _inscripcion == null && !_isInscribiendo
                                    ? _mostrarConfirmacionInscripcion
                                    : null,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isInscribiendo
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _inscripcion == null
                                            ? 'Inscribirse'
                                            : 'Inscrito',
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    showDragHandle: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(24),
                                      ),
                                    ),
                                    builder: (context) {
                                      return Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Contacto',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 12),
                                            if (_organizacion!.email.isNotEmpty)
                                              ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                leading: Icon(
                                                  Icons.email,
                                                  color: colorScheme.primary,
                                                ),
                                                title: const Text('Correo'),
                                                subtitle: Text(
                                                  _organizacion!.email,
                                                ),
                                              ),
                                            if (_organizacion!.telefono !=
                                                    null &&
                                                _organizacion!
                                                    .telefono!
                                                    .isNotEmpty)
                                              ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                leading: Icon(
                                                  Icons.phone,
                                                  color: colorScheme.primary,
                                                ),
                                                title: const Text('Teléfono'),
                                                subtitle: Text(
                                                  _organizacion!.telefono!,
                                                ),
                                              ),
                                            if (_organizacion!.direccion !=
                                                    null &&
                                                _organizacion!
                                                    .direccion!
                                                    .isNotEmpty)
                                              ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                leading: Icon(
                                                  Icons.location_on,
                                                  color: colorScheme.primary,
                                                ),
                                                title: const Text('Dirección'),
                                                subtitle: Text(
                                                  _organizacion!.direccion!,
                                                ),
                                              ),
                                            if (_organizacion!.sitioWeb !=
                                                    null &&
                                                _organizacion!
                                                    .sitioWeb!
                                                    .isNotEmpty)
                                              ListTile(
                                                contentPadding: EdgeInsets.zero,
                                                leading: Icon(
                                                  Icons.language,
                                                  color: colorScheme.primary,
                                                ),
                                                title: const Text('Sitio Web'),
                                                subtitle: Text(
                                                  _organizacion!.sitioWeb!,
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Contacto'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Chip de categoría (sin chip de estado, el estado se indica con el punto verde)
                        if (_organizacion!.categoriaOrganizacion != null) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                avatar: Icon(
                                  Icons.category,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                label: Text(
                                  _organizacion!
                                          .categoriaOrganizacion!['nombre']
                                          ?.toString() ??
                                      'Categoría',
                                ),
                                backgroundColor: colorScheme.primaryContainer,
                                labelStyle: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Descripción tipo bio
                        if (_organizacion!.descripcion != null &&
                            _organizacion!.descripcion!.isNotEmpty) ...[
                          Text(
                            _organizacion!.descripcion!,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                  // Estado de inscripción
                  if (_inscripcion != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        color: _inscripcion!.estado == 'APROBADO'
                            ? colorScheme.primaryContainer
                            : _inscripcion!.estado == 'RECHAZADO'
                            ? colorScheme.errorContainer
                            : colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _inscripcion!.estado == 'APROBADO'
                                        ? Icons.check_circle
                                        : _inscripcion!.estado == 'RECHAZADO'
                                        ? Icons.cancel
                                        : Icons.pending,
                                    color: _inscripcion!.estado == 'APROBADO'
                                        ? colorScheme.onPrimaryContainer
                                        : _inscripcion!.estado == 'RECHAZADO'
                                        ? colorScheme.onErrorContainer
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Estado de Inscripción: ${_inscripcion!.estado}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              _inscripcion!.estado == 'APROBADO'
                                              ? colorScheme.onPrimaryContainer
                                              : _inscripcion!.estado ==
                                                    'RECHAZADO'
                                              ? colorScheme.onErrorContainer
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                              if (_inscripcion!.motivoRechazo != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Motivo: ${_inscripcion!.motivoRechazo}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 24),

                  // Tabs simples sobre la sección de proyectos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.grid_on,
                          size: 18,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Proyectos',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Info',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FutureBuilder<List<Proyecto>>(
                      future: _loadProyectosOrganizacion(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError ||
                            snapshot.data == null ||
                            snapshot.data!.isEmpty) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.folder_open_outlined,
                                    size: 48,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No hay proyectos disponibles',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final proyectos = snapshot.data!;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                          itemCount: proyectos.length,
                          itemBuilder: (context, index) {
                            final proyecto = proyectos[index];
                            return _buildProyectoGridCard(
                              proyecto,
                              context,
                              theme,
                              colorScheme,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildProyectoGridCard(
    Proyecto proyecto,
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final estado = proyecto.estado.toLowerCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Modular.to.pushNamed(
              '/voluntario/proyectos/${proyecto.idProyecto}',
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen superior
              Stack(
                children: [
                  if (proyecto.imagen != null && proyecto.imagen!.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: proyecto.imagen!.startsWith('http')
                          ? Image.network(
                              proyecto.imagen!,
                              width: double.infinity,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildImagePlaceholder(colorScheme);
                              },
                            )
                          : Image.memory(
                              base64Decode(proyecto.imagen!.split(',').last),
                              width: double.infinity,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildImagePlaceholder(colorScheme);
                              },
                            ),
                    )
                  else
                    _buildImagePlaceholder(colorScheme),
                  // Badge de estado
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: estado == 'activo'
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        estado.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            proyecto.nombre,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (proyecto.objetivo != null &&
                              proyecto.objetivo!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              proyecto.objetivo!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF757575),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                      if (proyecto.ubicacion != null &&
                          proyecto.ubicacion!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: Color(0xFF9E9E9E),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                proyecto.ubicacion!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF9E9E9E),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(ColorScheme colorScheme) {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Center(
        child: Icon(Icons.volunteer_activism, size: 40, color: Colors.white),
      ),
    );
  }

  Future<List<Proyecto>> _loadProyectosOrganizacion() async {
    try {
      final proyectos = await _repository.getProyectos();
      // Filtrar proyectos de esta organización
      final proyectosOrg = proyectos
          .where((p) => p.organizacionId == widget.organizacionId)
          .toList();
      _proyectosCount = proyectosOrg.length;
      return proyectosOrg;
    } catch (e) {
      print('Error cargando proyectos de la organización: $e');
      return [];
    }
  }

  Widget _buildStatItem(ThemeData theme, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
