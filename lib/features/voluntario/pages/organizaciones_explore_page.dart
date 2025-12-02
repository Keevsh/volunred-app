import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/models/organizacion.dart';
import 'dart:convert';

class OrganizacionesExplorePage extends StatefulWidget {
  const OrganizacionesExplorePage({super.key});

  @override
  State<OrganizacionesExplorePage> createState() =>
      _OrganizacionesExplorePageState();
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
                  Text(
                    'Error al cargar organizaciones',
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
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay organizaciones disponibles',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadOrganizaciones,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: _organizaciones.length,
                itemBuilder: (context, index) {
                  final org = _organizaciones[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () {
                        Modular.to.pushNamed(
                          '/voluntario/organizaciones/${org.idOrganizacion}',
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo/Icono circular
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primaryContainer,
                                image: org.logo != null && org.logo!.isNotEmpty
                                    ? DecorationImage(
                                        image: org.logo!.startsWith('http')
                                            ? NetworkImage(org.logo!)
                                            : MemoryImage(
                                                base64Decode(
                                                  org.logo!.split(',').last,
                                                ),
                                              ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: org.logo != null && org.logo!.isNotEmpty
                                  ? null
                                  : Icon(
                                      Icons.business,
                                      size: 40,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                            ),
                            const SizedBox(height: 12),
                            // Nombre
                            Text(
                              org.nombre,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Estado si está activo
                            if (org.estado == 'activo') ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Activa',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
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
}
