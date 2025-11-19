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

  Widget _buildProyectoCard(BuildContext context, Proyecto proyecto, ThemeData theme, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        Modular.to.pushNamed('/voluntario/proyectos/${proyecto.idProyecto}');
      },
      child: Container(
        color: colorScheme.surface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de fondo que ocupa toda la pantalla
            if (proyecto.imagen != null && proyecto.imagen!.isNotEmpty)
              ImageBase64Widget(
                base64String: proyecto.imagen!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.volunteer_activism,
                    size: 120,
                    color: colorScheme.onPrimaryContainer.withOpacity(0.3),
                  ),
                ),
              ),
            
            // Gradiente oscuro en la parte inferior para legibilidad
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),
            
            // Botones de acción en la derecha (estilo TikTok)
            Positioned(
              right: 12,
              bottom: 120,
              child: Column(
                children: [
                  // Botón de guardar/favorito
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.bookmark_border, color: Colors.white),
                      iconSize: 32,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Proyecto guardado'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botón de compartir
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      iconSize: 32,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Compartir proyecto'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Información del proyecto en la parte inferior
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Organización
                    if (proyecto.organizacion != null)
                      Row(
                        children: [
                          if (proyecto.organizacion!['logo'] != null &&
                              proyecto.organizacion!['logo'].toString().isNotEmpty)
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child: ImageBase64Widget(
                                  base64String: proyecto.organizacion!['logo'].toString(),
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: colorScheme.primaryContainer,
                              child: Icon(
                                Icons.business,
                                size: 18,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              proyecto.organizacion!['nombre']?.toString() ??
                                  proyecto.organizacion!['nombre_legal']?.toString() ??
                                  'Organización',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    
                    // Nombre del proyecto
                    Text(
                      proyecto.nombre,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Objetivo/descripción
                    if (proyecto.objetivo != null && proyecto.objetivo!.isNotEmpty)
                      Text(
                        proyecto.objetivo!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 12),
                    
                    // Chips de estado y ubicación
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (proyecto.estado == 'activo')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'ACTIVO',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (proyecto.ubicacion != null && proyecto.ubicacion!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  proyecto.ubicacion!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
    );
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
                    
                    // Feed vertical tipo TikTok
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
                          : PageView.builder(
                              scrollDirection: Axis.vertical,
                              itemCount: _proyectosFiltrados.length,
                              itemBuilder: (context, index) {
                                final proyecto = _proyectosFiltrados[index];
                                return _buildProyectoCard(context, proyecto, theme, colorScheme);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

