import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/categoria.dart';
import '../../../core/widgets/image_base64_widget.dart';
import 'package:intl/intl.dart';

class VoluntarioDashboard extends StatefulWidget {
  final String userName;
  final String? photoBase64;

  const VoluntarioDashboard({
    super.key,
    required this.userName,
    this.photoBase64,
  });

  @override
  State<VoluntarioDashboard> createState() => _VoluntarioDashboardState();
}

class _VoluntarioDashboardState extends State<VoluntarioDashboard> {
  final VoluntarioRepository _repository = Modular.get<VoluntarioRepository>();

  List<Proyecto> _proyectos = [];
  List<Categoria> _categorias = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _filterSoloActivos = true;
  String? _filterCategoriaNombre;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final proyectos = await _repository.getProyectos();
      final categorias = await _repository.getCategorias();
      await _repository.getInscripciones();

      if (!mounted) return;
      setState(() {
        _proyectos = proyectos;
        _categorias = categorias;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Proyecto> _getFilteredProyectos() {
    var list = _proyectos;

    if (_filterSoloActivos) {
      list = list.where((p) => p.estado.toLowerCase() == 'activo').toList();
    }

    if (_filterCategoriaNombre != null && _filterCategoriaNombre!.isNotEmpty) {
      final categoriaLower = _filterCategoriaNombre!.toLowerCase();
      list = list.where((p) {
        final catMap =
            p.categoriaProyecto ??
            (p.categoriasProyectos != null &&
                    p.categoriasProyectos!.isNotEmpty &&
                    p.categoriasProyectos!.first is Map
                ? p.categoriasProyectos!.first as Map
                : null);
        final nombreCat = catMap != null
            ? (catMap['nombre'] ?? catMap['nombre_categoria'] ?? '')
                  .toString()
                  .toLowerCase()
            : '';
        return nombreCat.contains(categoriaLower);
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        final nombre = p.nombre.toLowerCase();
        final orgNombre =
            (p.organizacion != null
                    ? (p.organizacion!['nombre'] ??
                          p.organizacion!['nombre_legal'] ??
                          p.organizacion!['nombre_corto'] ??
                          '')
                    : '')
                .toString()
                .toLowerCase();
        final ubicacion = p.ubicacion?.toLowerCase() ?? '';
        return nombre.contains(q) ||
            orgNombre.contains(q) ||
            ubicacion.contains(q);
      }).toList();
    }

    return list;
  }

  List<Map<String, dynamic>> _getFilteredOrganizaciones() {
    final Map<int, Map<String, dynamic>> organizacionesMap = {};

    for (final proyecto in _proyectos) {
      if (proyecto.organizacion != null) {
        final org = proyecto.organizacion!;
        final id = org['id_organizacion'] is int
            ? org['id_organizacion'] as int
            : int.tryParse(org['id_organizacion']?.toString() ?? '');

        if (id != null && !organizacionesMap.containsKey(id)) {
          organizacionesMap[id] = org;
        }
      }
    }

    final organizaciones = organizacionesMap.values.toList();
    if (_searchQuery.isEmpty) return organizaciones;

    final q = _searchQuery.toLowerCase();
    return organizaciones.where((org) {
      final nombre = (org['nombre'] ??
              org['nombre_legal'] ??
              org['nombre_corto'] ??
              '')
          .toString()
          .toLowerCase();
      final razon = (org['razon_social'] ?? '').toString().toLowerCase();
      final direccion = (org['direccion'] ?? '').toString().toLowerCase();
      return nombre.contains(q) || razon.contains(q) || direccion.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasSearch = _searchQuery.trim().isNotEmpty;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFF8F9FA),
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SafeArea(
          top: true,
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // Header con saludo
              _buildWelcomeHeader(theme),

              // Barra de búsqueda
              SliverToBoxAdapter(child: _buildSearchBar(theme)),

              // Chips de categorías (si hay categorías disponibles)
              if (_categorias.isNotEmpty)
                SliverToBoxAdapter(child: _buildCategoryChips(theme)),

              if (hasSearch)
                _buildSearchResults(theme, colorScheme)
              else ...[
                // Organizaciones destacadas (carrusel horizontal)
                _buildOrganizacionesCarousel(theme),

                // Espacio extra entre organizaciones y banner
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Banner principal grande
                SliverToBoxAdapter(
                  child: _buildMainBanner(theme, colorScheme),
                ),

                // Proyectos destacados
                _buildFeaturedProjects(theme),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  void _showFiltersBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool soloActivosTemp = _filterSoloActivos;
        String? categoriaTemp = _filterCategoriaNombre;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filtros',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            soloActivosTemp = true;
                            categoriaTemp = null;
                          });
                        },
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    title: const Text('Solo proyectos activos'),
                    value: soloActivosTemp,
                    onChanged: (value) {
                      setModalState(() {
                        soloActivosTemp = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Categoría',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_categorias.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Todas'),
                          selected: categoriaTemp == null,
                          onSelected: (_) => setModalState(() => categoriaTemp = null),
                        ),
                        ..._categorias.map((cat) => ChoiceChip(
                              label: Text(cat.nombre),
                              selected: categoriaTemp == cat.nombre,
                              onSelected: (_) => setModalState(() {
                                categoriaTemp = categoriaTemp == cat.nombre ? null : cat.nombre;
                              }),
                            )),
                      ],
                    )
                  else
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Ej: Medio Ambiente, Educación...',
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      controller: TextEditingController(
                        text: categoriaTemp ?? '',
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          categoriaTemp = value.isEmpty ? null : value;
                        });
                      },
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _filterSoloActivos = soloActivosTemp;
                              _filterCategoriaNombre = categoriaTemp;
                            });
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Aplicar filtros'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWelcomeHeader(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${widget.userName} 👋',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Encuentra proyectos que te inspiren',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Modular.to.pushNamed('/profile/edit');
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                backgroundImage:
                    widget.photoBase64 != null && widget.photoBase64!.isNotEmpty
                    ? MemoryImage(
                        // photoBase64 puede venir con prefijo data:..., nos quedamos con la parte base64
                        const Base64Decoder().convert(
                          widget.photoBase64!.split(',').last,
                        ),
                      )
                    : null,
                child:
                    (widget.photoBase64 == null || widget.photoBase64!.isEmpty)
                    ? const Icon(Icons.person, color: Color(0xFF1976D2))
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          readOnly: false,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Buscar proyectos, organizaciones...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF9E9E9E),
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF1976D2),
              size: 24,
            ),
            suffixIcon: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showFiltersBottomSheet(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ThemeData theme) {
    final chips = [
      ChoiceChip(
        label: const Text('Todas'),
        selected: _filterCategoriaNombre == null,
        onSelected: (_) {
          setState(() => _filterCategoriaNombre = null);
        },
      ),
      ..._categorias.map((cat) {
        final selected = _filterCategoriaNombre == cat.nombre;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(cat.nombre),
            selected: selected,
            onSelected: (_) {
              setState(() => _filterCategoriaNombre = selected ? null : cat.nombre);
            },
          ),
        );
      }),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      ),
    );
  }

  Widget _buildOrganizacionesCarousel(ThemeData theme) {
    // Extraer organizaciones únicas de los proyectos
    final Map<int, Map<String, dynamic>> organizacionesMap = {};
    for (final proyecto in _proyectos) {
      if (proyecto.organizacion != null) {
        final org = proyecto.organizacion!;
        final id = org['id_organizacion'] is int
            ? org['id_organizacion'] as int
            : int.tryParse(org['id_organizacion']?.toString() ?? '') ?? -1;

        if (id != -1 && !organizacionesMap.containsKey(id)) {
          organizacionesMap[id] = org;
        }
      }
    }

    if (organizacionesMap.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final organizaciones = organizacionesMap.values.toList();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Organizaciones',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          SizedBox(
            height: 96,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: organizaciones.length > 10
                  ? 10
                  : organizaciones.length,
              itemBuilder: (context, index) {
                final org = organizaciones[index];
                final nombre = (org['nombre'] ?? org['nombre_legal'] ?? 'Org')
                    .toString();
                final logo = org['logo']?.toString();
                final idOrg = org['id_organizacion'] is int
                    ? org['id_organizacion'] as int
                    : int.tryParse(org['id_organizacion']?.toString() ?? '') ??
                          -1;

                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: InkWell(
                    onTap: () {
                      if (idOrg != -1) {
                        Modular.to.pushNamed(
                          '/voluntario/organizaciones/$idOrg',
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: (logo != null && logo.isNotEmpty)
                                ? ImageBase64Widget(
                                    base64String: logo,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF1976D2),
                                          Color(0xFF42A5F5),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.business_rounded,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            nombre,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF424242),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainBanner(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.9),
                  colorScheme.primary.withOpacity(0.75),
                  colorScheme.secondary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.35),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        '🎬 Descubre en video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Explora proyectos\nen acción',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Mira videos de proyectos y encuentra\ntu próxima oportunidad de voluntariado.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            Modular.to.pushNamed('/voluntario/feed');
                          },
                          icon: const Icon(Icons.play_circle_filled, size: 18),
                          label: const Text('Explorar Videos'),
                          style: FilledButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            elevation: 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.people_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+5K',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12), // Add a small SizedBox here
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedProjects(ThemeData theme) {
    final proyectosFiltrados = _getFilteredProyectos();

    if (proyectosFiltrados.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.explore_outlined,
                  size: 48,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay proyectos disponibles',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explora nuevas oportunidades de voluntariado',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF9E9E9E),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Proyectos Destacados',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Modular.to.pushNamed('/voluntario/proyectos'),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                // Un poco más ancho que alto para que la card no sea tan alta
                childAspectRatio: 0.9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: proyectosFiltrados.length > 6
                  ? 6
                  : proyectosFiltrados.length,
              itemBuilder: (context, index) {
                return _buildProyectoCardGrid(proyectosFiltrados[index], theme);
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildProyectoCardGrid(Proyecto proyecto, ThemeData theme) {
    final orgNombre = proyecto.organizacion != null
        ? (proyecto.organizacion!['nombre'] ??
                  proyecto.organizacion!['nombre_legal'] ??
                  'Organización')
              .toString()
        : 'Organización';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Modular.to.pushNamed(
            '/voluntario/proyectos/${proyecto.idProyecto}',
          ),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imagen
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    if (proyecto.imagen != null && proyecto.imagen!.isNotEmpty)
                      ImageBase64Widget(
                        base64String: proyecto.imagen!,
                        width: double.infinity,
                        height: 115,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        height: 115,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF667eea),
                              const Color(0xFF764ba2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.volunteer_activism_rounded,
                            size: 48,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    // Overlay gradient
                    Container(
                      height: 115,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                    // Badge
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: proyecto.estado == 'activo'
                                        ? const Color(0xFF4CAF50)
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  proyecto.estado == 'activo'
                                      ? 'Activo'
                                      : 'Inactivo',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido compacto
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      proyecto.nombre,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF212121),
                        fontSize: 15,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.business_rounded,
                          size: 14,
                          color: const Color(0xFF1976D2),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            orgNombre,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (proyecto.fechaFin != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.event_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM').format(proyecto.fechaFin!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSearchResults(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final proyectosFiltrados = _getFilteredProyectos();
    final organizacionesFiltradas = _getFilteredOrganizaciones();
    final hasResults =
        proyectosFiltrados.isNotEmpty || organizacionesFiltradas.isNotEmpty;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultados',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mostrando proyectos y organizaciones que coinciden con tu búsqueda',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            if (!hasResults)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_outlined,
                      size: 48,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sin coincidencias',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Prueba con otra palabra clave o revisa la ortografía.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            if (proyectosFiltrados.isNotEmpty) ...[
              Text(
                'Proyectos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: proyectosFiltrados.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildSearchProjectCard(
                    proyectosFiltrados[index],
                    theme,
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            if (organizacionesFiltradas.isNotEmpty) ...[
              Text(
                'Organizaciones',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: organizacionesFiltradas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildSearchOrganizationCard(
                    organizacionesFiltradas[index],
                    theme,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchProjectCard(Proyecto proyecto, ThemeData theme) {
    final orgNombre = proyecto.organizacion != null
        ? (proyecto.organizacion!['nombre'] ??
            proyecto.organizacion!['nombre_legal'] ??
            proyecto.organizacion!['nombre_corto'] ??
            '')
        : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Modular.to.pushNamed(
            '/voluntario/proyectos/${proyecto.idProyecto}',
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Imagen pequeña
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: proyecto.imagen != null && proyecto.imagen!.isNotEmpty
                        ? ImageBase64Widget(
                            base64String: proyecto.imagen!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF667eea),
                                  Color(0xFF764ba2),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.volunteer_activism_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proyecto.nombre,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.business_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              orgNombre.isNotEmpty
                                  ? orgNombre
                                  : 'Organización desconocida',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: proyecto.estado.toLowerCase() == 'activo'
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            proyecto.estado == 'activo'
                                ? 'Activo'
                                : 'Inactivo',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: proyecto.estado == 'activo'
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchOrganizationCard(
    Map<String, dynamic> organizacion,
    ThemeData theme,
  ) {
    final nombre = (organizacion['nombre'] ??
        organizacion['nombre_legal'] ??
        organizacion['nombre_corto'] ??
        'Organización desconocida');
    final idOng = organizacion['id_organizacion'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Modular.to.pushNamed('/voluntario/organizaciones/$idOng'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Ícono de organización
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF6B6B),
                        Color(0xFFFF8E72),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.business_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre.toString(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (organizacion['razon_social'] != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.description_rounded,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                organizacion['razon_social'].toString(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (organizacion['direccion'] != null)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                organizacion['direccion'].toString(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
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
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
