import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/models/organizacion.dart';
import '../../../core/models/inscripcion.dart';
import '../../../core/models/proyecto.dart';
import 'dart:convert';

class OrganizacionDetailPage extends StatefulWidget {
  final int organizacionId;

  const OrganizacionDetailPage({
    super.key,
    required this.organizacionId,
  });

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
      final organizacion = await _repository.getOrganizacionById(widget.organizacionId);
      
      // Verificar si ya hay una inscripción
      try {
        final inscripciones = await _repository.getInscripciones();
        _inscripcion = inscripciones.firstWhere(
          (ins) => ins.organizacionId == widget.organizacionId,
          orElse: () => throw Exception('No encontrada'),
        );
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
          (ins) => ins.usuarioId == perfil.usuarioId && 
                   ins.organizacionId == widget.organizacionId,
          orElse: () => throw StateError('No existe'),
        );
        
        // Si ya existe una inscripción
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ya tienes una inscripción ${inscripcionExistente.estado.toLowerCase()} para esta organización'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          );
        }
        return;
      } catch (e) {
        // No existe inscripción, continuar con la creación
      }

      final data = {
        'usuario_id': perfil.usuarioId,
        'organizacion_id': widget.organizacionId,
        'estado': 'pendiente', // El backend espera minúsculas
      };

      print('🚀 [VOLUNTARIO] Enviando datos al backend para crear inscripción:');
      print('📦 [VOLUNTARIO] Data: $data');
      print('👤 Usuario ID: ${perfil.usuarioId}');
      print('🏢 Organización ID: ${widget.organizacionId}');
      print('📅 Fecha recepción: será asignada automáticamente por el backend');

      await _repository.createInscripcion(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Inscripción enviada exitosamente'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
        _loadData(); // Recargar para actualizar el estado
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inscribirse: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
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
      appBar: AppBar(
        title: const Text('Detalles de Organización'),
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
                      Text('Error al cargar organización', style: theme.textTheme.titleLarge),
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
                  : _organizacion == null
                  ? const Center(child: Text('Organización no encontrada'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Imagen header
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.business,
                                    size: 80,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                // Badge de estado
                                if (_organizacion!.estado == 'activo')
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Chip(
                                      label: const Text('Activa'),
                                      backgroundColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Contenido
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nombre y razón social
                                Text(
                                  _organizacion!.nombre,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_organizacion!.razonSocial != null && _organizacion!.razonSocial != _organizacion!.nombre) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _organizacion!.razonSocial!,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                
                                // Descripción
                                if (_organizacion!.descripcion != null && _organizacion!.descripcion!.isNotEmpty) ...[
                                  Text(
                                    _organizacion!.descripcion!,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ],
                            ),
                          ),

                          // Información de contacto
                          if (_organizacion!.email.isNotEmpty || _organizacion!.telefono != null || _organizacion!.direccion != null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Información de Contacto',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      if (_organizacion!.email.isNotEmpty)
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(Icons.email, color: colorScheme.primary),
                                          title: const Text('Correo'),
                                          subtitle: Text(_organizacion!.email),
                                        ),
                                      if (_organizacion!.telefono != null && _organizacion!.telefono!.isNotEmpty)
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(Icons.phone, color: colorScheme.primary),
                                          title: const Text('Teléfono'),
                                          subtitle: Text(_organizacion!.telefono!),
                                        ),
                                      if (_organizacion!.direccion != null && _organizacion!.direccion!.isNotEmpty)
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(Icons.location_on, color: colorScheme.primary),
                                          title: const Text('Dirección'),
                                          subtitle: Text(_organizacion!.direccion!),
                                        ),
                                      if (_organizacion!.sitioWeb != null && _organizacion!.sitioWeb!.isNotEmpty)
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(Icons.language, color: colorScheme.primary),
                                          title: const Text('Sitio Web'),
                                          subtitle: Text(_organizacion!.sitioWeb!),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

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
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: _inscripcion!.estado == 'APROBADO'
                                                  ? colorScheme.onPrimaryContainer
                                                  : _inscripcion!.estado == 'RECHAZADO'
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

                          // Botón de acción
                          if (_inscripcion == null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: FilledButton(
                                onPressed: _isInscribiendo ? null : _inscribirse,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                                child: _isInscribiendo
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Inscribirse a esta Organización'),
                              ),
                            ),
                          const SizedBox(height: 24),
                          
                          // Proyectos de la organización
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Proyectos de la Organización',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
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
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                
                                if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
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
                                return Column(
                                  children: proyectos.map((proyecto) {
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          Modular.to.pushNamed('/voluntario/proyectos/${proyecto.idProyecto}');
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  image: proyecto.imagen != null && proyecto.imagen!.isNotEmpty
                                                      ? DecorationImage(
                                                          image: proyecto.imagen!.startsWith('http')
                                                              ? NetworkImage(proyecto.imagen!)
                                                              : MemoryImage(base64Decode(proyecto.imagen!.split(',').last)),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : null,
                                                ),
                                                child: proyecto.imagen != null && proyecto.imagen!.isNotEmpty
                                                    ? null
                                                    : Container(
                                                        decoration: BoxDecoration(
                                                          color: colorScheme.primaryContainer,
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Icon(
                                                          Icons.volunteer_activism,
                                                          color: colorScheme.onPrimaryContainer,
                                                        ),
                                                      ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            proyecto.nombre,
                                                            style: theme.textTheme.titleMedium?.copyWith(
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        if (proyecto.estado == 'activo')
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: colorScheme.primaryContainer,
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              'Activo',
                                                              style: theme.textTheme.labelSmall?.copyWith(
                                                                color: colorScheme.onPrimaryContainer,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    if (proyecto.objetivo != null && proyecto.objetivo!.isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        proyecto.objetivo!,
                                                        style: theme.textTheme.bodySmall?.copyWith(
                                                          color: colorScheme.onSurfaceVariant,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                    if (proyecto.ubicacion != null && proyecto.ubicacion!.isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.location_on,
                                                            size: 14,
                                                            color: colorScheme.onSurfaceVariant,
                                                          ),
                                                          const SizedBox(width: 2),
                                                          Expanded(
                                                            child: Text(
                                                              proyecto.ubicacion!,
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
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.chevron_right,
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
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
  
  Future<List<Proyecto>> _loadProyectosOrganizacion() async {
    try {
      final proyectos = await _repository.getProyectos();
      // Filtrar proyectos de esta organización
      return proyectos.where((p) => p.organizacionId == widget.organizacionId).toList();
    } catch (e) {
      print('Error cargando proyectos de la organización: $e');
      return [];
    }
  }

}