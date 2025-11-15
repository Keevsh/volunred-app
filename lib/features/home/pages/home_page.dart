import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/models/organizacion.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/inscripcion.dart';
import '../../../core/models/perfil_voluntario.dart';
import '../../../core/widgets/image_base64_widget.dart';
import 'dart:convert';
import 'dart:ui';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _userName = 'Usuario';
  bool _isAdmin = false;
  bool _isFuncionario = false;
  int _selectedProjectTab = 0;
  bool _isProfileLoading = true;
  PerfilVoluntario? _perfilVoluntario;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authRepo = Modular.get<AuthRepository>();
    final usuario = await authRepo.getStoredUser();
    if (usuario != null) {
      setState(() {
        _userName = usuario.nombres;
        _isAdmin = usuario.isAdmin;
        _isFuncionario = usuario.isFuncionario;
        _isProfileLoading = false;
      });
      
      if (!usuario.isAdmin) {
        try {
          if (usuario.isFuncionario) {
            final tienePerfil = await authRepo.tienePerfilFuncionario();
            if (!tienePerfil && mounted) {
              Future.microtask(() {
                Modular.to.navigate('/profile/funcionario-options');
              });
              return;
            }
          } else if (usuario.isVoluntario) {
            final perfilVolJson = await StorageService.getString(ApiConfig.perfilVoluntarioKey);
            if (perfilVolJson == null && mounted) {
              Future.microtask(() {
                Modular.to.navigate('/profile/create');
              });
              return;
            }
            // Cargar el perfil del voluntario para mostrar en la vista
            await _loadPerfilVoluntario();
          }
        } catch (e) {
          print('❌ Error verificando perfil en home: $e');
        }
      }
    } else {
      setState(() {
        _isProfileLoading = false;
      });
    }
  }

  Future<void> _loadPerfilVoluntario() async {
    try {
      final perfilVolJson = await StorageService.getString(ApiConfig.perfilVoluntarioKey);
      if (perfilVolJson != null) {
        final perfilMap = jsonDecode(perfilVolJson) as Map<String, dynamic>;
        setState(() {
          _perfilVoluntario = PerfilVoluntario.fromJson(perfilMap);
        });
      }
    } catch (e) {
      print('❌ Error cargando perfil del voluntario: $e');
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authRepo = Modular.get<AuthRepository>();
      await authRepo.logout();
      if (mounted) {
        Modular.to.navigate('/auth/');
      }
    }
  }

  // ========== HELPERS ==========
  Future<Organizacion?> _loadOrganizacion() async {
    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      return await funcionarioRepo.getMiOrganizacion();
    } catch (e) {
      print('Error cargando organización: $e');
      return null;
    }
  }

  Future<List<Proyecto>> _loadProyectosOrganizacion() async {
    try {
      if (_isFuncionario) {
        final funcionarioRepo = Modular.get<FuncionarioRepository>();
        return await funcionarioRepo.getProyectos();
      }
      return [];
    } catch (e) {
      print('Error cargando proyectos: $e');
      return [];
    }
  }

  Future<List<Proyecto>> _loadProyectosVoluntario() async {
    try {
      if (!_isFuncionario && !_isAdmin) {
        final voluntarioRepo = Modular.get<VoluntarioRepository>();
        final proyectos = await voluntarioRepo.getProyectos();
        // Filtrar solo proyectos activos y mostrar solo los primeros 6
        final proyectosActivos = proyectos.where((p) => p.estado == 'activo').toList();
        return proyectosActivos.take(6).toList();
      }
      return [];
    } catch (e) {
      print('Error cargando proyectos: $e');
      return [];
    }
  }

  Future<List<Inscripcion>> _loadInscripcionesOrganizacion() async {
    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      return await funcionarioRepo.getInscripciones();
    } catch (e) {
      print('Error cargando inscripciones: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _loadFuncionarioStats() async {
    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      final dashboard = await funcionarioRepo.getDashboard();
      return {
        'proyectos': dashboard.totalProyectos,
        'inscripciones_pendientes': dashboard.inscripcionesPendientes,
        'voluntarios': dashboard.totalParticipaciones,
      };
    } catch (e) {
      print('Error cargando estadísticas: $e');
      return {'proyectos': 0, 'inscripciones_pendientes': 0, 'voluntarios': 0};
    }
  }

  // Tarjeta de proyecto horizontal para carrusel
  Widget _buildProyectoCardHorizontal(Proyecto proyecto, ThemeData theme, ColorScheme colorScheme) {
    // Obtener nombre de organización
    String organizacionNombre = 'Organización';
    if (proyecto.organizacion != null && proyecto.organizacion is Map) {
      final orgMap = proyecto.organizacion as Map;
      organizacionNombre = orgMap['nombre']?.toString() ??
                          orgMap['nombre_legal']?.toString() ??
                          orgMap['nombre_corto']?.toString() ??
                          'Organización';
    }

    return Card(
      elevation: 4,
      shadowColor: colorScheme.shadow.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: colorScheme.surface,
      child: InkWell(
        onTap: () => Modular.to.pushNamed('/voluntario/proyectos/${proyecto.idProyecto}'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contenedor de imagen superior - Más grande y prominente
            Container(
              height: 160, // Aumentado de 120 a 160
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              child: Stack(
                children: [
                  // Placeholder de imagen con gradiente más atractivo
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.2),
                          colorScheme.secondary.withOpacity(0.3),
                          colorScheme.tertiary.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.volunteer_activism,
                            size: 48, // Aumentado de 40 a 48
                            color: colorScheme.primary.withOpacity(0.6),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Imagen del proyecto',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Ícono de guardar en esquina superior derecha
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.bookmark_border,
                        size: 22,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Contenido de la tarjeta
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título del proyecto
                  Text(
                    proyecto.nombre,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: -0.3,
                      color: colorScheme.onSurface,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Información de organización
                  Row(
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 16,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          organizacionNombre,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Ubicación
                  if (proyecto.ubicacion != null && proyecto.ubicacion!.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            proyecto.ubicacion!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  // Fecha
                  if (proyecto.fechaInicio != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${proyecto.fechaInicio!.day}/${proyecto.fechaInicio!.month}/${proyecto.fechaInicio!.year}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, IconData icon, ColorScheme colorScheme, ThemeData theme) {
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 18),
      selected: false, // TODO: Implementar estado de selección
      onSelected: (selected) {
        // TODO: Implementar filtrado por categoría
        Modular.to.pushNamed('/voluntario/proyectos', arguments: {'categoria': label});
      },
      backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fondo gris claro
      body: IndexedStack(
        index: _currentIndex,
        children: _isFuncionario
            ? [
                _buildFuncionarioHomeView(),
                _buildFuncionarioProyectosView(),
                _buildFuncionarioInscripcionesView(),
                _buildProfileView(),
              ]
            : [
                _buildHomeView(),
                _buildExplorarView(),
                _buildMiActividadView(),
                _buildProfileView(),
              ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) async {
          setState(() => _currentIndex = index);
          // Recargar perfil cuando se selecciona la pestaña del perfil
          if (index == 3 && !_isAdmin) {
            await _loadPerfilVoluntario();
          }
        },
        destinations: _isFuncionario
            ? const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder),
                  label: 'Proyectos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_add_outlined),
                  selectedIcon: Icon(Icons.person_add),
                  label: 'Inscripciones',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ]
            : const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: 'Explorar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.handshake_outlined),
                  selectedIcon: Icon(Icons.handshake),
                  label: 'Mi Actividad',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Perfil',
                ),
              ],
      ),
    );
  }

  // ========== VISTA HOME VOLUNTARIO - MATERIAL 3 ==========
  Widget _buildHomeView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return RefreshIndicator(
      onRefresh: () async {
        await _loadUserData();
        setState(() {});
      },
      child: CustomScrollView(
        slivers: [
          // Header superior con ubicación, búsqueda y notificaciones
          SliverAppBar(
            floating: true,
            pinned: false,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            toolbarHeight: 120, // Aumentar altura para incluir barra de búsqueda
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ubicación
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nueva York, NY', // TODO: Obtener ubicación real
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Barra de búsqueda prominente
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar proyectos...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onTap: () {
                      Modular.to.pushNamed('/voluntario/proyectos');
                    },
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: colorScheme.onSurface,
                ),
                onPressed: () {},
              ),
            ],
          ),

          // Banner principal grande
          SliverToBoxAdapter(
            child: Container(
              height: 280,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.8),
                    colorScheme.primary.withOpacity(0.6),
                    colorScheme.secondary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.3),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Haz la Diferencia Hoy!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Descubre cientos de proyectos y únete a comunidades que transforman vidas.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Modular.to.pushNamed('/voluntario/proyectos');
                        },
                        icon: const Icon(Icons.location_on),
                        label: const Text('Ver proyectos en Nueva York'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600, // Color acento vibrante
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Más de 5000 voluntarios registrados',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Chips de Categorías de Proyectos
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text(
                    '¿Qué tipo de voluntariado buscas?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCategoryChip('Cerca de ti', Icons.location_on_outlined, colorScheme, theme),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Virtual', Icons.computer_outlined, colorScheme, theme),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Animales', Icons.pets_outlined, colorScheme, theme),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Educación', Icons.school_outlined, colorScheme, theme),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Fin de semana', Icons.calendar_view_week_outlined, colorScheme, theme),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Medio ambiente', Icons.eco_outlined, colorScheme, theme),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Salud', Icons.local_hospital_outlined, colorScheme, theme),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Carrusel de Proyectos Populares
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Proyectos Populares',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _currentIndex = 1); // Ir a pestaña Explorar
                    },
                    child: const Text('Ver todos'),
                  ),
                ],
              ),
            ),
          ),
          
          // Carrusel horizontal de proyectos
          SliverToBoxAdapter(
            child: SizedBox(
              height: 280,
              child: FutureBuilder<List<Proyecto>>(
                future: _loadProyectosVoluntario(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                    return Center(
                      child: Card(
                        margin: const EdgeInsets.all(24),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.explore_outlined,
                                size: 64,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Explora proyectos',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Descubre nuevas oportunidades de voluntariado',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () {
                                  setState(() => _currentIndex = 1);
                                },
                                child: const Text('Ver Todos los Proyectos'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  
                  final proyectos = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: proyectos.length,
                    itemBuilder: (context, index) {
                      final proyecto = proyectos[index];
                      return Container(
                        width: 300,
                        margin: const EdgeInsets.only(right: 16),
                        child: _buildProyectoCardHorizontal(proyecto, theme, colorScheme),
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

  


  // ========== VISTA FUNCIONARIO - MATERIAL 3 ==========
  Widget _buildFuncionarioHomeView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return RefreshIndicator(
      onRefresh: () async {
        await _loadUserData();
        setState(() {});
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            title: Text('Mi Organización', style: theme.textTheme.titleLarge),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => Modular.to.pushNamed('/proyectos/create'),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
            ],
          ),
          
          // Información de organización
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildOrganizacionCard(theme, colorScheme),
            ),
          ),
          
          // Estadísticas
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildStatsSection(theme, colorScheme),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          
          // Lista de proyectos
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: FutureBuilder<List<Proyecto>>(
              future: _loadProyectosOrganizacion(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tienes proyectos aún',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: () => Modular.to.pushNamed('/proyectos/create'),
                              icon: const Icon(Icons.add),
                              label: const Text('Crear Proyecto'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final proyecto = snapshot.data![index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildProyectoCardCompact(proyecto, theme, colorScheme),
                      );
                    },
                    childCount: snapshot.data!.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrganizacionCard(ThemeData theme, ColorScheme colorScheme) {
    return FutureBuilder<Organizacion?>(
      future: _loadOrganizacion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        if (snapshot.hasError || snapshot.data == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes organización',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Modular.to.pushNamed('/profile/create-organizacion'),
                    child: const Text('Crear Organización'),
                  ),
                ],
              ),
            ),
          );
        }
        
        final org = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.business,
                    size: 40,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  org.nombre,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (org.email.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    org.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (org.direccion != null && org.direccion!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          org.direccion!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatsSection(ThemeData theme, ColorScheme colorScheme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadFuncionarioStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {
          'proyectos': 0,
          'inscripciones_pendientes': 0,
          'voluntarios': 0,
        };
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  count: '${stats['proyectos'] ?? 0}',
                  label: 'Proyectos',
                  icon: Icons.folder,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                _buildStatItem(
                  count: '${stats['inscripciones_pendientes'] ?? 0}',
                  label: 'Pendientes',
                  icon: Icons.person_add,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                _buildStatItem(
                  count: '${stats['voluntarios'] ?? 0}',
                  label: 'Voluntarios',
                  icon: Icons.people,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatItem({
    required String count,
    required String label,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  
  Widget _buildProyectoCardCompact(Proyecto proyecto, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.secondaryContainer,
          child: Icon(
            Icons.folder,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(
          proyecto.nombre,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: proyecto.objetivo != null && proyecto.objetivo!.isNotEmpty
            ? Text(
                proyecto.objetivo!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              )
            : null,
        trailing: Chip(
          label: Text(proyecto.estado),
          backgroundColor: proyecto.estado == 'activo'
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          labelStyle: TextStyle(
            color: proyecto.estado == 'activo'
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: () => Modular.to.pushNamed('/proyectos/${proyecto.idProyecto}'),
      ),
    );
  }

  // ========== VISTA PROYECTOS FUNCIONARIO ==========
  Widget _buildFuncionarioProyectosView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Proyectos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Modular.to.pushNamed('/proyectos/create'),
          ),
        ],
      ),
      body: FutureBuilder<List<Proyecto>>(
        future: _loadProyectosOrganizacion(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final proyectos = snapshot.data ?? [];
          
          if (proyectos.isEmpty) {
            return Center(
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 64,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes proyectos',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea tu primer proyecto para comenzar',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => Modular.to.pushNamed('/proyectos/create'),
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Proyecto'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: proyectos.length,
            itemBuilder: (context, index) {
              final proyecto = proyectos[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildProyectoCardCompact(proyecto, theme, colorScheme),
              );
            },
          );
        },
      ),
    );
  }

  // ========== VISTA INSCRIPCIONES FUNCIONARIO ==========
  Widget _buildFuncionarioInscripcionesView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscripciones'),
      ),
      body: FutureBuilder<List<Inscripcion>>(
        future: _loadInscripcionesOrganizacion(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final inscripciones = snapshot.data ?? [];
          
          if (inscripciones.isEmpty) {
            return Center(
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_add_outlined,
                        size: 64,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay inscripciones',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Las solicitudes de voluntarios aparecerán aquí',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: inscripciones.length,
            itemBuilder: (context, index) {
              final inscripcion = inscripciones[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildInscripcionCard(inscripcion, theme, colorScheme),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildInscripcionCard(Inscripcion inscripcion, ThemeData theme, ColorScheme colorScheme) {
    final usuario = inscripcion.usuario;
    final nombreUsuario = usuario != null 
        ? '${usuario['nombres'] ?? ''} ${usuario['apellidos'] ?? ''}'.trim()
        : 'Usuario ${inscripcion.usuarioId}';
    
    final estadoColor = inscripcion.estado.toUpperCase() == 'APROBADO' 
        ? colorScheme.primaryContainer
        : inscripcion.estado.toUpperCase() == 'RECHAZADO'
            ? colorScheme.errorContainer
            : colorScheme.tertiaryContainer;
    
    final estadoTextColor = inscripcion.estado.toUpperCase() == 'APROBADO' 
        ? colorScheme.onPrimaryContainer
        : inscripcion.estado.toUpperCase() == 'RECHAZADO'
            ? colorScheme.onErrorContainer
            : colorScheme.onTertiaryContainer;
    
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : 'U',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          nombreUsuario,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (usuario?['email'] != null) ...[
              const SizedBox(height: 4),
              Text(usuario!['email']),
            ],
            const SizedBox(height: 8),
            Chip(
              label: Text(inscripcion.estado),
              backgroundColor: estadoColor,
              labelStyle: TextStyle(
                color: estadoTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: inscripcion.estado.toUpperCase() == 'PENDIENTE'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check),
                    color: colorScheme.primary,
                    onPressed: () => _aprobarInscripcion(inscripcion.idInscripcion),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: colorScheme.error,
                    onPressed: () => _rechazarInscripcion(inscripcion.idInscripcion),
                  ),
                ],
              )
            : const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  Future<void> _aprobarInscripcion(int id) async {
    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      await funcionarioRepo.aprobarInscripcion(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscripción aprobada exitosamente')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _rechazarInscripcion(int id) async {
    final motivoController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Inscripción'),
        content: TextField(
          controller: motivoController,
          decoration: const InputDecoration(
            labelText: 'Motivo del rechazo',
            hintText: 'Ingresa el motivo...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed == true && motivoController.text.isNotEmpty) {
      try {
        final funcionarioRepo = Modular.get<FuncionarioRepository>();
        await funcionarioRepo.rechazarInscripcion(id, motivoController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inscripción rechazada')),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  // ========== VISTA EXPLORAR VOLUNTARIO ==========
  Widget _buildExplorarView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar Proyectos'),
        actions: [
          // Toggle entre vista de lista y mapa
          IconButton(
            icon: Icon(_showMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() => _showMapView = !_showMapView);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFiltersBottomSheet(context),
          ),
        ],
      ),
      body: _showMapView ? _buildMapView(theme, colorScheme) : _buildListView(theme, colorScheme),
    );
  }

  bool _showMapView = false;

  Widget _buildListView(ThemeData theme, ColorScheme colorScheme) {
    return FutureBuilder<List<Proyecto>>(
      future: _loadProyectosVoluntario(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_outlined,
                      size: 64,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay proyectos disponibles',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Los proyectos aparecerán aquí cuando estén disponibles',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final proyectos = snapshot.data!;
        return _buildTinderView(proyectos, theme, colorScheme);
      },
    );
  }

  Widget _buildTinderView(List<Proyecto> proyectos, ThemeData theme, ColorScheme colorScheme) {
    final PageController _pageController = PageController();

    // Agregar listener para actualizar el índice actual
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentProyectoIndex) {
        setState(() {
          _currentProyectoIndex = page;
        });
      }
    });

    return Stack(
      children: [
        // PageView para swipe entre proyectos
        PageView.builder(
          controller: _pageController,
          itemCount: proyectos.length,
          itemBuilder: (context, index) {
            final proyecto = proyectos[index];
            return _buildProyectoCardTinder(proyecto, theme, colorScheme);
          },
        ),

        // Indicador de progreso
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (_currentProyectoIndex + 1) / proyectos.length,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ),
        ),

        // Contador de proyectos
        Positioned(
          top: 32,
          right: 16,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentProyectoIndex + 1}/${proyectos.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),

        // Botones de navegación
        Positioned(
          bottom: 32,
          left: 24,
          right: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botón anterior
              FloatingActionButton(
                onPressed: _currentProyectoIndex > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.onSurface,
                elevation: 4,
                child: Icon(
                  Icons.arrow_back,
                  color: _currentProyectoIndex > 0
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant.withOpacity(0.3),
                ),
              ),

              // Botón "No me interesa"
              FloatingActionButton.extended(
                onPressed: () {
                  if (_currentProyectoIndex < proyectos.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
                elevation: 4,
                icon: const Icon(Icons.close),
                label: const Text('Pasar'),
              ),

              // Botón "Me interesa"
              FloatingActionButton.extended(
                onPressed: () {
                  // Navegar al detalle del proyecto
                  final proyecto = proyectos[_currentProyectoIndex];
                  Modular.to.pushNamed('/voluntario/proyectos/${proyecto.idProyecto}');
                },
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 4,
                icon: const Icon(Icons.favorite),
                label: const Text('Me interesa'),
              ),

              // Botón siguiente
              FloatingActionButton(
                onPressed: _currentProyectoIndex < proyectos.length - 1
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.onSurface,
                elevation: 4,
                child: Icon(
                  Icons.arrow_forward,
                  color: _currentProyectoIndex < proyectos.length - 1
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _currentProyectoIndex = 0;

  // Tarjeta de proyecto para vista Tinder
  Widget _buildProyectoCardTinder(Proyecto proyecto, ThemeData theme, ColorScheme colorScheme) {
    // Obtener nombre de organización
    String organizacionNombre = 'Organización';
    if (proyecto.organizacion != null && proyecto.organizacion is Map) {
      final orgMap = proyecto.organizacion as Map;
      organizacionNombre = orgMap['nombre']?.toString() ??
                          orgMap['nombre_legal']?.toString() ??
                          orgMap['nombre_corto']?.toString() ??
                          'Organización';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surface,
          ),
          child: Column(
            children: [
              // Imagen del proyecto (ocupa la mayor parte)
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: proyecto.imagen != null && proyecto.imagen!.isNotEmpty
                      ? Image(
                          image: proyecto.imagen!.startsWith('http')
                              ? NetworkImage(proyecto.imagen!)
                              : MemoryImage(base64Decode(proyecto.imagen!.split(',').last)),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 64,
                                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Imagen no disponible',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.volunteer_activism,
                                size: 80,
                                color: colorScheme.primary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Proyecto de Voluntariado',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              // Información del proyecto
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Estado del proyecto
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: proyecto.estado == 'activo'
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.shadow.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              proyecto.estado.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 0.5,
                                color: proyecto.estado == 'activo'
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Nombre del proyecto
                        Text(
                          proyecto.nombre,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            letterSpacing: -0.8,
                            color: colorScheme.onSurface,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 16),

                        // Organización
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.business,
                                  size: 24,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Organización',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      organizacionNombre,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Objetivo
                        if (proyecto.objetivo != null && proyecto.objetivo!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Objetivo',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  proyecto.objetivo!,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 16,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Información adicional
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              if (proyecto.ubicacion != null && proyecto.ubicacion!.isNotEmpty) ...[
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 22,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Ubicación',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              proyecto.ubicacion!,
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: colorScheme.onSurface,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (proyecto.fechaInicio != null) const SizedBox(width: 20),
                              ],
                              if (proyecto.fechaInicio != null) ...[
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 22,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Fecha',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            '${proyecto.fechaInicio!.day}/${proyecto.fechaInicio!.month}/${proyecto.fechaInicio!.year}',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView(ThemeData theme, ColorScheme colorScheme) {
    return Stack(
      children: [
        // Placeholder para mapa - En producción usar google_maps_flutter
        Container(
          color: colorScheme.surfaceContainerHighest,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 80,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Vista de Mapa',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Próximamente: Encuentra proyectos cerca de ti',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        // Botón flotante para cambiar a vista de lista
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            onPressed: () {
              setState(() => _showMapView = false);
            },
            child: const Icon(Icons.list),
          ),
        ),
      ],
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
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                      // TODO: Limpiar filtros
                      Navigator.pop(context);
                    },
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Contenido scrolleable
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Categorías
                    Text(
                      'Categorías',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Animales'),
                          selected: false,
                          onSelected: (selected) {},
                        ),
                        FilterChip(
                          label: const Text('Educación'),
                          selected: false,
                          onSelected: (selected) {},
                        ),
                        FilterChip(
                          label: const Text('Medio Ambiente'),
                          selected: false,
                          onSelected: (selected) {},
                        ),
                        FilterChip(
                          label: const Text('Salud'),
                          selected: false,
                          onSelected: (selected) {},
                        ),
                        FilterChip(
                          label: const Text('Virtual'),
                          selected: false,
                          onSelected: (selected) {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Distancia
                    Text(
                      'Distancia máxima',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // TODO: Implementar slider para distancia
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Slider de distancia - Próximamente'),
                    ),

                    const SizedBox(height: 24),

                    // Fecha
                    Text(
                      'Disponibilidad',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Esta semana'),
                          selected: false,
                          onSelected: (selected) {},
                        ),
                        FilterChip(
                          label: const Text('Este mes'),
                          selected: false,
                          onSelected: (selected) {},
                        ),
                        FilterChip(
                          label: const Text('Fin de semana'),
                          selected: false,
                          onSelected: (selected) {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              // TODO: Aplicar filtros
                              Navigator.pop(context);
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Aplicar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== VISTA MI ACTIVIDAD VOLUNTARIO ==========
  Widget _buildMiActividadView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Actividad'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mis Participaciones
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.handshake_outlined, color: colorScheme.onPrimaryContainer),
              ),
              title: const Text('Mis Participaciones'),
              subtitle: const Text('Ver proyectos en los que participas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Modular.to.pushNamed('/voluntario/participaciones');
              },
            ),
          ),
          const SizedBox(height: 12),
          
          // Mis Experiencias
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(Icons.history_edu, color: colorScheme.onSecondaryContainer),
              ),
              title: const Text('Mis Experiencias'),
              subtitle: const Text('Gestiona tus experiencias de voluntariado'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Modular.to.pushNamed('/experiencias');
              },
            ),
          ),
          const SizedBox(height: 12),
          
          // Certificados
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.tertiaryContainer,
                child: Icon(Icons.verified_outlined, color: colorScheme.onTertiaryContainer),
              ),
              title: const Text('Certificados'),
              subtitle: const Text('Descarga tus certificados de participación'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  // ========== VISTA PERFIL ==========
  Widget _buildProfileView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isProfileLoading ? _buildProfileSkeleton(theme, colorScheme) : CustomScrollView(
        slivers: [
          // Header con portada (Cover Photo)
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withOpacity(0.8),
                      colorScheme.secondary.withOpacity(0.6),
                      colorScheme.tertiary.withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Patrón de fondo sutil
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/pattern.png'), // TODO: Agregar imagen de patrón
                              repeat: ImageRepeat.repeat,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Elementos decorativos
                    Positioned(
                      top: 40,
                      right: 20,
                      child: Icon(
                        Icons.volunteer_activism,
                        size: 60,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Icon(
                        Icons.favorite,
                        size: 40,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  // TODO: Compartir perfil
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función de compartir próximamente')),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.settings, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'configuracion':
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Configuración próximamente')),
                      );
                      break;
                    case 'ayuda':
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Centro de Ayuda próximamente')),
                      );
                      break;
                    case 'sobre':
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sobre la App próximamente')),
                      );
                      break;
                    case 'cerrar_sesion':
                      _handleLogout();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'configuracion',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined),
                        SizedBox(width: 12),
                        Text('Configuración'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'ayuda',
                    child: Row(
                      children: [
                        Icon(Icons.help_outline),
                        SizedBox(width: 12),
                        Text('Centro de Ayuda'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'sobre',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 12),
                        Text('Sobre la App'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'cerrar_sesion',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Color(0xFFD32F2F)),
                        SizedBox(width: 12),
                        Text('Cerrar Sesión', style: TextStyle(color: Color(0xFFD32F2F))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Contenido principal
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              child: Column(
                children: [
                  // Avatar grande
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.secondary,
                                colorScheme.tertiary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _perfilVoluntario?.fotoPerfil != null && _perfilVoluntario!.fotoPerfil!.isNotEmpty
                              ? CircularImageBase64Widget(
                                  base64String: _perfilVoluntario!.fotoPerfil!,
                                  size: 120,
                                  backgroundColor: colorScheme.surface,
                                )
                              : CircleAvatar(
                                  radius: 60,
                                  backgroundColor: colorScheme.surface,
                                  child: Text(
                                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.shadow.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Nombre y verificación
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _userName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.verified,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Estado y ubicación
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Nueva York, NY',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.outline,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Voluntario desde 2023',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Biografía - SIN CONTENEDOR BLANCO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.edit_note,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sobre mí',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _perfilVoluntario?.bio != null && _perfilVoluntario!.bio!.isNotEmpty
                              ? _perfilVoluntario!.bio!
                              : 'Apasionado por el voluntariado y el impacto social. Creo en el poder de las comunidades para transformar vidas. Especializado en proyectos ambientales y educativos. ¡Siempre dispuesto a ayudar! 🌱📚',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Estadísticas mejoradas - SIN CONTENEDOR BLANCO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Text(
                          'Mi Impacto',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildEnhancedStatItem(
                              count: '127',
                              label: 'Horas\nVoluntariado',
                              icon: Icons.access_time,
                              color: colorScheme.primary,
                              theme: theme,
                            ),
                            _buildEnhancedStatItem(
                              count: '8',
                              label: 'Proyectos\nCompletados',
                              icon: Icons.check_circle,
                              color: colorScheme.secondary,
                              theme: theme,
                            ),
                            _buildEnhancedStatItem(
                              count: '342',
                              label: 'Personas\nImpactadas',
                              icon: Icons.people,
                              color: colorScheme.tertiary,
                              theme: theme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Organizaciones inscritas - SIN CONTENEDOR BLANCO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 24,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Organizaciones',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '3 inscritas',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildOrganizationItem(
                          name: 'Fundación Verde Esperanza',
                          role: 'Voluntario Ambiental',
                          since: '2023',
                          colorScheme: colorScheme,
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        _buildOrganizationItem(
                          name: 'Centro Educativo Futuro',
                          role: 'Mentor Educativo',
                          since: '2024',
                          colorScheme: colorScheme,
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        _buildOrganizationItem(
                          name: 'Refugio Animal Amigo',
                          role: 'Cuidador de Animales',
                          since: '2024',
                          colorScheme: colorScheme,
                          theme: theme,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Insignias mejoradas - Carrusel horizontal - SIN CONTENEDOR BLANCO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.emoji_events,
                              size: 24,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Logros e Insignias',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '4/4 desbloqueadas',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Carrusel horizontal de insignias
                        SizedBox(
                          height: 180,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            children: [
                              _buildCarouselBadge(
                                icon: Icons.star,
                                title: 'Líder Comunitario',
                                description: '5 proyectos completados',
                                color: colorScheme.primary,
                                earned: true,
                                level: 'ORO',
                                progress: 1.0,
                                theme: theme,
                              ),
                              const SizedBox(width: 16),
                              _buildCarouselBadge(
                                icon: Icons.pets,
                                title: 'Amigo de los Animales',
                                description: '3 proyectos de refugio',
                                color: colorScheme.secondary,
                                earned: true,
                                level: 'PLATA',
                                progress: 1.0,
                                theme: theme,
                              ),
                              const SizedBox(width: 16),
                              _buildCarouselBadge(
                                icon: Icons.eco,
                                title: 'Guardián Ambiental',
                                description: '2 proyectos ambientales',
                                color: colorScheme.tertiary,
                                earned: true,
                                level: 'BRONCE',
                                progress: 1.0,
                                theme: theme,
                              ),
                              const SizedBox(width: 16),
                              _buildCarouselBadge(
                                icon: Icons.school,
                                title: 'Educador',
                                description: '¡Participa en 1 proyecto educativo!',
                                color: colorScheme.outline,
                                earned: false,
                                level: 'PRÓXIMO',
                                progress: 0.0,
                                theme: theme,
                              ),
                              const SizedBox(width: 16),
                              _buildCarouselBadge(
                                icon: Icons.volunteer_activism,
                                title: 'Super Voluntario',
                                description: 'Completa 10 proyectos',
                                color: colorScheme.primary,
                                earned: false,
                                level: 'LEYENDA',
                                progress: 0.4,
                                theme: theme,
                              ),
                              const SizedBox(width: 16),
                              _buildCarouselBadge(
                                icon: Icons.celebration,
                                title: 'Inspirador',
                                description: 'Motiva a 5 voluntarios nuevos',
                                color: colorScheme.secondary,
                                earned: false,
                                level: 'ÉPICO',
                                progress: 0.2,
                                theme: theme,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Indicador de progreso general
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progreso General',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    '75%',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: 0.75,
                                  backgroundColor: colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '¡Solo 1 insignia más para completar tu colección!',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Proyectos - SIN CONTENEDOR BLANCO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mis Proyectos',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment<int>(
                              value: 0,
                              label: Text('Futuros'),
                              icon: Icon(Icons.schedule),
                            ),
                            ButtonSegment<int>(
                              value: 1,
                              label: Text('Completados'),
                              icon: Icon(Icons.check_circle),
                            ),
                          ],
                          selected: {_selectedProjectTab},
                          onSelectionChanged: (Set<int> newSelection) {
                            setState(() {
                              _selectedProjectTab = newSelection.first;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _selectedProjectTab == 0
                            ? _buildFutureProjects()
                            : _buildCompletedProjects(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Acciones sociales - SIN CONTENEDOR BLANCO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSocialAction(
                          icon: Icons.edit,
                          label: 'Editar Perfil',
                          color: colorScheme.primary,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Editar perfil próximamente')),
                            );
                          },
                        ),
                        _buildSocialAction(
                          icon: Icons.share,
                          label: 'Compartir',
                          color: colorScheme.secondary,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Compartir perfil próximamente')),
                            );
                          },
                        ),
                        _buildSocialAction(
                          icon: Icons.message,
                          label: 'Mensajes',
                          color: colorScheme.tertiary,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mensajes próximamente')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatItem({
    required String count,
    required String label,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOrganizationItem({
    required String name,
    required String role,
    required String since,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.business,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Miembro desde $since',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.verified,
            color: colorScheme.primary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselBadge({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool earned,
    required String level,
    required double progress,
    required ThemeData theme,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: earned ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: earned ? color.withOpacity(0.3) : theme.colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: earned ? [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        gradient: earned ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.05),
            color.withOpacity(0.02),
          ],
        ) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono con fondo circular y progreso
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: earned ? color.withOpacity(0.15) : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: earned ? color.withOpacity(0.3) : theme.colorScheme.outline.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Opacity(
                  opacity: earned ? 1.0 : 0.4,
                  child: Icon(
                    icon,
                    size: 32,
                    color: earned ? color : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (!earned && progress > 0)
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.7)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Nivel de la insignia
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: earned ? color.withOpacity(0.1) : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: earned ? color.withOpacity(0.2) : theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Text(
              level,
              style: theme.textTheme.labelSmall?.copyWith(
                color: earned ? color : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Título
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: earned ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Descripción
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              fontSize: 9,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Barra de progreso para insignias no obtenidas
          if (!earned && progress > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.6)),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSocialAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFutureProjects() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Placeholder para proyectos futuros
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.schedule,
                size: 64,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Proyectos Inscritos',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Aquí aparecerán los proyectos en los que te has inscrito',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedProjects() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Placeholder para proyectos completados
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                size: 64,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Proyectos Completados',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Aquí aparecerán los proyectos que has completado',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========== SKELETONS PARA CARGA ==========
  Widget _buildProfileSkeleton(ThemeData theme, ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Header con portada (Cover Photo) - Skeleton
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: colorScheme.surfaceContainerHighest,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: Stack(
                  children: [
                    // Skeleton animado para el header
                    Positioned.fill(
                      child: _buildShimmerEffect(
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.surfaceContainerHighest.withOpacity(0.8),
                                colorScheme.surfaceContainerHighest.withOpacity(0.6),
                                colorScheme.surfaceContainerHighest.withOpacity(0.4),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.transparent),
                onPressed: null,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.settings, color: Colors.transparent),
                onSelected: (value) {},
                itemBuilder: (BuildContext context) => [],
              ),
            ],
          ),

          // Contenido principal con skeletons
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              child: Column(
                children: [
                  // Avatar skeleton
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surfaceContainerHighest,
                          ),
                          child: _buildShimmerEffect(
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Nombre skeleton
                  Container(
                    height: 32,
                    width: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildShimmerEffect(
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Estado y ubicación skeleton
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 16,
                        width: 120,
                        child: _buildShimmerEffect(
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        height: 16,
                        width: 140,
                        child: _buildShimmerEffect(
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Biografía skeleton
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 20,
                          width: 100,
                          child: _buildShimmerEffect(
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 16,
                          width: double.infinity,
                          child: _buildShimmerEffect(
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 16,
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: _buildShimmerEffect(
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 16,
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: _buildShimmerEffect(
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Estadísticas skeleton
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Container(
                          height: 24,
                          width: 120,
                          child: _buildShimmerEffect(
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatSkeleton(),
                            _buildStatSkeleton(),
                            _buildStatSkeleton(),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Organizaciones skeleton
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 24,
                              width: 24,
                              child: _buildShimmerEffect(
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 24,
                              width: 120,
                              child: _buildShimmerEffect(
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              height: 16,
                              width: 80,
                              child: _buildShimmerEffect(
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildOrganizationSkeleton(),
                        const SizedBox(height: 12),
                        _buildOrganizationSkeleton(),
                        const SizedBox(height: 12),
                        _buildOrganizationSkeleton(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Insignias skeleton
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 24,
                              width: 24,
                              child: _buildShimmerEffect(
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 24,
                              width: 160,
                              child: _buildShimmerEffect(
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              height: 20,
                              width: 100,
                              child: _buildShimmerEffect(
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Carrusel de insignias skeleton
                        SizedBox(
                          height: 180,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            children: [
                              _buildBadgeSkeleton(),
                              const SizedBox(width: 16),
                              _buildBadgeSkeleton(),
                              const SizedBox(width: 16),
                              _buildBadgeSkeleton(),
                              const SizedBox(width: 16),
                              _buildBadgeSkeleton(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Progreso skeleton
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    height: 16,
                                    width: 120,
                                    child: _buildShimmerEffect(
                                      Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 16,
                                    width: 40,
                                    child: _buildShimmerEffect(
                                      Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 8,
                                width: double.infinity,
                                child: _buildShimmerEffect(
                                  Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 12,
                                width: 200,
                                child: _buildShimmerEffect(
                                  Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Proyectos skeleton
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 24,
                          width: 140,
                          child: _buildShimmerEffect(
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 40,
                          width: double.infinity,
                          child: _buildShimmerEffect(
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 120,
                          width: double.infinity,
                          child: _buildShimmerEffect(
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Acciones sociales skeleton
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSocialActionSkeleton(),
                        _buildSocialActionSkeleton(),
                        _buildSocialActionSkeleton(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect(Widget child) {
    return ShimmerContainer(child: child);
  }

  Widget _buildStatSkeleton() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          child: _buildShimmerEffect(
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 20,
          width: 50,
          child: _buildShimmerEffect(
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 12,
          width: 60,
          child: _buildShimmerEffect(
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizationSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            child: _buildShimmerEffect(
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 150,
                  child: _buildShimmerEffect(
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 14,
                  width: 100,
                  child: _buildShimmerEffect(
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  height: 12,
                  width: 80,
                  child: _buildShimmerEffect(
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 20,
            height: 20,
            child: _buildShimmerEffect(
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeSkeleton() {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            child: _buildShimmerEffect(
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 12,
            width: 80,
            child: _buildShimmerEffect(
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 11,
            width: 100,
            child: _buildShimmerEffect(
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 9,
            width: 90,
            child: _buildShimmerEffect(
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialActionSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            child: _buildShimmerEffect(
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 12,
            width: 60,
            child: _buildShimmerEffect(
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== WIDGET PARA EFECTO SHIMMER ==========
class ShimmerContainer extends StatefulWidget {
  final Widget child;

  const ShimmerContainer({super.key, required this.child});

  @override
  State<ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<ShimmerContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.4),
                Colors.white.withOpacity(0.1),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(_animation.value, 0),
              end: Alignment(_animation.value + 1, 0),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
