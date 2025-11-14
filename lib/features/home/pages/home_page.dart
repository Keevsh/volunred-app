import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/repositories/organizacion_repository.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/services/profile_check_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/models/organizacion.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/inscripcion.dart';
import '../../../core/models/dashboard.dart';
import 'dart:convert';

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
  int? _usuarioId;

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
        _usuarioId = usuario.idUsuario;
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
          }
        } catch (e) {
          print('❌ Error verificando perfil en home: $e');
        }
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
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
                _buildActivitiesView(),
                _buildProfileView(),
              ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
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
                  label: 'Actividades',
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
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 100,
            backgroundColor: colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'VolunRed',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  Modular.to.pushNamed('/voluntario/proyectos');
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          
          // Carrusel de Organizaciones
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Organizaciones',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Modular.to.pushNamed('/voluntario/organizaciones');
                        },
                        child: const Text('Ver todas'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 140,
                  child: FutureBuilder<List<Organizacion>>(
                    future: _loadOrganizaciones(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildOrganizacionesSkeleton();
                      }
                      
                      if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      final organizaciones = snapshot.data!;
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: organizaciones.length,
                        itemBuilder: (context, index) {
                          final org = organizaciones[index];
                          return _buildOrganizacionCarouselCard(org, theme, colorScheme);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          
          // Título de Proyectos
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Proyectos Destacados',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Modular.to.pushNamed('/voluntario/proyectos');
                    },
                    child: const Text('Ver todos'),
                  ),
                ],
              ),
            ),
          ),
          
          // Lista de proyectos
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: FutureBuilder<List<Proyecto>>(
              future: _loadProyectosVoluntario(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildProyectosSkeleton();
                }
                
                if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
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
                                Modular.to.pushNamed('/voluntario/proyectos');
                              },
                              child: const Text('Ver Todos los Proyectos'),
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
                        child: _buildProyectoCardWithImage(proyecto, theme, colorScheme),
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
  
  // Tarjeta de organización para el carrusel
  Widget _buildOrganizacionCarouselCard(Organizacion org, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          Modular.to.pushNamed('/voluntario/organizaciones/${org.idOrganizacion}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Icono circular
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer,
                image: org.logo != null && org.logo!.isNotEmpty
                    ? DecorationImage(
                        image: org.logo!.startsWith('http')
                            ? NetworkImage(org.logo!)
                            : MemoryImage(base64Decode(org.logo!.split(',').last)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: org.logo != null && org.logo!.isNotEmpty
                  ? null
                  : Icon(
                      Icons.business,
                      size: 30,
                      color: colorScheme.onPrimaryContainer,
                    ),
            ),
            const SizedBox(height: 8),
            // Nombre
            Text(
              org.nombre,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  // Tarjeta de proyecto con imagen
  Widget _buildProyectoCardWithImage(Proyecto proyecto, ThemeData theme, ColorScheme colorScheme) {
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => Modular.to.pushNamed('/voluntario/proyectos/${proyecto.idProyecto}'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.volunteer_activism,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),
                  // Badge de categoría si existe
                  if (proyecto.categoriasProyectos != null && proyecto.categoriasProyectos!.isNotEmpty)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (() {
                            if (proyecto.categoriasProyectos!.first is Map) {
                              final m = proyecto.categoriasProyectos!.first as Map;
                              return m['categoria']?['nombre']?.toString() ??
                                     m['nombre']?.toString() ??
                                     'Proyecto';
                            }
                            return 'Proyecto';
                          })(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
                  // Nombre del proyecto
                  Text(
                    proyecto.nombre,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Organización
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          organizacionNombre,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Objetivo
                  if (proyecto.objetivo != null && proyecto.objetivo!.isNotEmpty)
                    Text(
                      proyecto.objetivo!,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  // Info adicional
                  Row(
                    children: [
                      if (proyecto.ubicacion != null && proyecto.ubicacion!.isNotEmpty) ...[
                        Icon(Icons.location_on, size: 16, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
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
                        const SizedBox(width: 12),
                      ],
                      if (proyecto.fechaInicio != null) ...[
                        Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${proyecto.fechaInicio!.day}/${proyecto.fechaInicio!.month}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Botón de acción
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Modular.to.pushNamed('/voluntario/proyectos/${proyecto.idProyecto}'),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Ver proyecto'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProyectoCard(Proyecto proyecto, ThemeData theme, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Modular.to.pushNamed('/proyectos/${proyecto.idProyecto}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.volunteer_activism,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proyecto.nombre,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (proyecto.organizacion != null)
                          Text(
                            proyecto.organizacion is Map
                                ? (proyecto.organizacion as Map)['nombre']?.toString() ?? 'Organización'
                                : 'Organización',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ],
              ),
              if (proyecto.objetivo != null && proyecto.objetivo!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  proyecto.objetivo!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (proyecto.ubicacion != null && proyecto.ubicacion!.isNotEmpty)
                    Chip(
                      avatar: Icon(Icons.location_on, size: 16, color: colorScheme.onSurfaceVariant),
                      label: Text(proyecto.ubicacion!),
                      labelStyle: theme.textTheme.labelSmall,
                    ),
                  if (proyecto.fechaInicio != null)
                    Chip(
                      avatar: Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurfaceVariant),
                      label: Text(
                        '${proyecto.fechaInicio!.day}/${proyecto.fechaInicio!.month}/${proyecto.fechaInicio!.year}',
                      ),
                      labelStyle: theme.textTheme.labelSmall,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => Modular.to.pushNamed('/voluntario/proyectos/${proyecto.idProyecto}'),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Ver proyecto'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
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

  // ========== VISTA ACTIVIDADES VOLUNTARIO ==========
  Widget _buildActivitiesView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividades'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Explorar Organizaciones
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.business, color: colorScheme.onPrimaryContainer),
              ),
              title: const Text('Explorar Organizaciones'),
              subtitle: const Text('Descubre organizaciones y únete'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Modular.to.pushNamed('/voluntario/organizaciones');
              },
            ),
          ),
          const SizedBox(height: 12),
          
          // Explorar Proyectos
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(Icons.work_outline, color: colorScheme.onSecondaryContainer),
              ),
              title: const Text('Explorar Proyectos'),
              subtitle: const Text('Encuentra proyectos de voluntariado'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Modular.to.pushNamed('/voluntario/proyectos');
              },
            ),
          ),
          const SizedBox(height: 12),
          
          // Mis Participaciones
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.tertiaryContainer,
                child: Icon(Icons.handshake_outlined, color: colorScheme.onTertiaryContainer),
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
          
          // Experiencias
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.history_edu, color: colorScheme.onPrimaryContainer),
              ),
              title: const Text('Mis Experiencias'),
              subtitle: const Text('Gestiona tus experiencias de voluntariado'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Modular.to.pushNamed('/experiencias');
              },
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
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar y nombre
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Opciones
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.person_outline, color: colorScheme.primary),
                    title: const Text('Mi Perfil'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.settings_outlined, color: colorScheme.primary),
                    title: const Text('Configuración'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: colorScheme.primary),
                    title: const Text('Ayuda'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Cerrar sesión
            FilledButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar Sesión'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== SKELETONS ==========
  Widget _buildOrganizacionesSkeleton() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5, // Mostrar 5 skeletons
      itemBuilder: (context, index) {
        return Container(
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Skeleton para el círculo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 8),
              // Skeleton para el texto
              Container(
                height: 12,
                width: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 4),
              Container(
                height: 10,
                width: 60,
                color: Colors.grey[300],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProyectosSkeleton() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Skeleton para la imagen
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Skeleton para el título
                    Container(
                      height: 20,
                      width: double.infinity,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    // Skeleton para la organización
                    Container(
                      height: 16,
                      width: 150,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    // Skeleton para la descripción
                    Container(
                      height: 14,
                      width: double.infinity,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 14,
                      width: 200,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    // Skeleton para la info adicional
                    Row(
                      children: [
                        Container(
                          height: 12,
                          width: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(width: 16),
                        Container(
                          height: 12,
                          width: 60,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Skeleton para el botón
                    Container(
                      height: 40,
                      width: double.infinity,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: 3, // Mostrar 3 skeletons de proyectos
      ),
    );
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
  
  Future<List<Organizacion>> _loadOrganizaciones() async {
    try {
      if (!_isFuncionario && !_isAdmin) {
        final voluntarioRepo = Modular.get<VoluntarioRepository>();
        final organizaciones = await voluntarioRepo.getOrganizaciones();
        // Filtrar solo organizaciones activas y mostrar solo las primeras 10 para el carrusel
        final organizacionesActivas = organizaciones.where((org) => org.estado == 'activo').toList();
        return organizacionesActivas.take(10).toList();
      }
      return [];
    } catch (e) {
      print('Error cargando organizaciones: $e');
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
}
