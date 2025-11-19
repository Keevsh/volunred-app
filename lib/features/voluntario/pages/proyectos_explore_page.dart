import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/categoria.dart';
import '../../../core/widgets/image_base64_widget.dart';

class ProyectosExplorePage extends StatefulWidget {
  const ProyectosExplorePage({super.key});

  @override
  State<ProyectosExplorePage> createState() => _ProyectosExplorePageState();
}

class _ProyectosExplorePageState extends State<ProyectosExplorePage> {
  final VoluntarioRepository _repository = Modular.get<VoluntarioRepository>();
  List<Proyecto> _proyectos = [];
  List<Categoria> _categorias = [];
  List<int> _categoriasSeleccionadas = [];
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
      final proyectos = await _repository.getProyectos();
      final categorias = await _repository.getCategorias();
      setState(() {
        _proyectos = proyectos;
        _categorias = categorias;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Proyecto> get _proyectosFiltrados {
    if (_categoriasSeleccionadas.isEmpty) return _proyectos;
    
    return _proyectos.where((proyecto) {
      if (proyecto.categoriasProyectos == null || proyecto.categoriasProyectos!.isEmpty) {
        return false;
      }
      
      // Verificar si el proyecto tiene alguna de las categorías seleccionadas
      for (var catProy in proyecto.categoriasProyectos!) {
        if (catProy is Map) {
          final categoriaId = catProy['categoria_id'] ?? catProy['categoria']?['id_categoria'];
          if (categoriaId != null && _categoriasSeleccionadas.contains(categoriaId)) {
            return true;
          }
        }
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar Proyectos'),
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
                      Text('Error al cargar proyectos', style: theme.textTheme.titleLarge),
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
              : Column(
                  children: [
                    // Filtros de categorías
                    if (_categorias.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: colorScheme.surfaceContainerHighest,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filtrar por categorías',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _categorias.map((categoria) {
                                final isSelected = _categoriasSeleccionadas.contains(categoria.idCategoria);
                                return FilterChip(
                                  selected: isSelected,
                                  label: Text(categoria.nombre),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _categoriasSeleccionadas.add(categoria.idCategoria);
                                      } else {
                                        _categoriasSeleccionadas.remove(categoria.idCategoria);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            if (_categoriasSeleccionadas.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _categoriasSeleccionadas.clear();
                                  });
                                },
                                child: const Text('Limpiar filtros'),
                              ),
                          ],
                        ),
                      ),
                    
                    // Lista de proyectos
                    Expanded(
                      child: _proyectosFiltrados.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_outlined, size: 64, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(height: 16),
                                  Text(
                                    _categoriasSeleccionadas.isNotEmpty
                                        ? 'No hay proyectos con las categorías seleccionadas'
                                        : 'No hay proyectos disponibles',
                                    style: theme.textTheme.titleLarge,
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 200, // Ancho máximo de cada tarjeta
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.2, // Ajustado para dar más altura
                                ),
                                itemCount: _proyectosFiltrados.length,
                                shrinkWrap: false, // Asegurar que no se encoja
                                physics: const AlwaysScrollableScrollPhysics(), // Física de scroll consistente
                                itemBuilder: (context, index) {
                                  final proyecto = _proyectosFiltrados[index];
                                  return Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () {
                                        Modular.to.pushNamed('/voluntario/proyectos/${proyecto.idProyecto}');
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Imagen del proyecto
                                          if (proyecto.imagen != null && proyecto.imagen!.isNotEmpty)
                                            ImageBase64Widget(
                                              base64String: proyecto.imagen!,
                                              width: double.infinity,
                                              height: 120,
                                              fit: BoxFit.cover,
                                            )
                                          else
                                            Container(
                                              width: double.infinity,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    colorScheme.primary.withOpacity(0.2),
                                                    colorScheme.secondary.withOpacity(0.3),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.volunteer_activism,
                                                size: 40,
                                                color: colorScheme.primary.withOpacity(0.6),
                                              ),
                                            ),
                                          // Contenido de la tarjeta
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  proyecto.nombre,
                                                  style: theme.textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                // Logo y nombre de organización
                                                if (proyecto.organizacion != null)
                                                  Row(
                                                    children: [
                                                      if (proyecto.organizacion!['logo'] != null &&
                                                          proyecto.organizacion!['logo'].toString().isNotEmpty)
                                                        ClipRRect(
                                                          borderRadius: BorderRadius.circular(3),
                                                          child: ImageBase64Widget(
                                                            base64String: proyecto.organizacion!['logo'].toString(),
                                                            width: 16,
                                                            height: 16,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        )
                                                      else
                                                        Container(
                                                          width: 16,
                                                          height: 16,
                                                          decoration: BoxDecoration(
                                                            color: colorScheme.primaryContainer,
                                                            borderRadius: BorderRadius.circular(3),
                                                          ),
                                                          child: Icon(
                                                            Icons.business,
                                                            size: 10,
                                                            color: colorScheme.onPrimaryContainer,
                                                          ),
                                                        ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          proyecto.organizacion!['nombre']?.toString() ??
                                                              proyecto.organizacion!['nombre_legal']?.toString() ??
                                                              'Organización',
                                                          style: theme.textTheme.bodySmall?.copyWith(
                                                            fontSize: 11,
                                                            color: colorScheme.onSurfaceVariant,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                const SizedBox(height: 8),
                                                Chip(
                                                  label: Text(
                                                    proyecto.estado.toUpperCase(),
                                                    style: const TextStyle(fontSize: 10),
                                                  ),
                                                  backgroundColor: proyecto.estado == 'activo'
                                                      ? colorScheme.primaryContainer
                                                      : colorScheme.errorContainer,
                                                  labelStyle: TextStyle(
                                                    color: proyecto.estado == 'activo'
                                                        ? colorScheme.onPrimaryContainer
                                                        : colorScheme.onErrorContainer,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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

