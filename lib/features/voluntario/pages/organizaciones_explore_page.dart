import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/models/organizacion.dart';

class OrganizacionesExplorePage extends StatefulWidget {
  const OrganizacionesExplorePage({super.key});

  @override
  State<OrganizacionesExplorePage> createState() => _OrganizacionesExplorePageState();
}

class _OrganizacionesExplorePageState extends State<OrganizacionesExplorePage> {
  final VoluntarioRepository _repository = Modular.get<VoluntarioRepository>();
  List<Organizacion> _organizaciones = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrganizaciones();
  }

  Future<void> _loadOrganizaciones() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final organizaciones = await _repository.getOrganizaciones();
      setState(() {
        _organizaciones = organizaciones;
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
        title: const Text('Explorar Organizaciones'),
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
                      Text('Error al cargar organizaciones', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(_error!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadOrganizaciones,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _organizaciones.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.business_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text('No hay organizaciones disponibles', style: theme.textTheme.titleLarge),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrganizaciones,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _organizaciones.length,
                        itemBuilder: (context, index) {
                          final org = _organizaciones[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.primaryContainer,
                                child: Icon(Icons.business, color: colorScheme.onPrimaryContainer),
                              ),
                              title: Text(
                                org.nombre,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (org.razonSocial != null && org.razonSocial != org.nombre) ...[
                                    Text(org.razonSocial!, style: theme.textTheme.bodyMedium),
                                    const SizedBox(height: 4),
                                  ],
                                  if (org.direccion != null)
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 16, color: colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(org.direccion!, style: theme.textTheme.bodySmall),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              trailing: org.estado == 'activo'
                                  ? Chip(
                                      label: const Text('Activa'),
                                      backgroundColor: colorScheme.primaryContainer,
                                      labelStyle: TextStyle(color: colorScheme.onPrimaryContainer, fontSize: 12),
                                    )
                                  : null,
                              onTap: () {
                                Modular.to.pushNamed('/voluntario/organizaciones/${org.idOrganizacion}');
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

