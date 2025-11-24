import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../voluntario/pages/proyectos_explore_page.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/models/organizacion.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/inscripcion.dart';
import '../../../core/models/perfil_voluntario.dart';
import '../../../core/widgets/image_base64_widget.dart';
import '../widgets/funcionario_dashboard.dart';
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
  Map<String, dynamic>? _perfilFuncionario;
  Organizacion? _organizacionFuncionario;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Precargar imágenes usadas en el carrusel de voluntarios para que se muestren sin saltos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      const imagePaths = [
        'assets/images/voluntarios.jpg',
        'assets/images/lapaz.jpg',
        'assets/images/animal.jpg',
      ];
      for (final path in imagePaths) {
        precacheImage(AssetImage(path), context);
      }
    });
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
          
          // Cargar perfil de funcionario si corresponde
          if (usuario.isFuncionario) {
            await _loadPerfilFuncionario();
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
      // Obtener siempre la versión más reciente del perfil desde la API
      final authRepo = Modular.get<AuthRepository>();
      final voluntarioRepo = Modular.get<VoluntarioRepository>();
      final usuario = await authRepo.getStoredUser();

      if (usuario != null) {
        final perfil = await voluntarioRepo.getPerfilByUsuario(usuario.idUsuario);
        if (!mounted) return;
        setState(() {
          _perfilVoluntario = perfil;
        });
      }
    } catch (e) {
      print('❌ Error cargando perfil del voluntario: $e');
    }
  }

  Future<void> _loadPerfilFuncionario() async {
    try {
      final authRepo = Modular.get<AuthRepository>();
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      final usuario = await authRepo.getStoredUser();

      if (usuario != null) {
        // Cargar perfil de funcionario desde storage
        final perfilJson = await StorageService.getString(ApiConfig.perfilFuncionarioKey);
        if (perfilJson != null) {
          final perfil = jsonDecode(perfilJson);
          // Cargar organización
          try {
            final organizacion = await funcionarioRepo.getMiOrganizacion();
            if (!mounted) return;
            setState(() {
              _perfilFuncionario = perfil;
              _organizacionFuncionario = organizacion;
            });
          } catch (e) {
            print('❌ Error cargando organización: $e');
            if (!mounted) return;
            setState(() {
              _perfilFuncionario = perfil;
            });
          }
        }
      }
    } catch (e) {
      print('❌ Error cargando perfil del funcionario: $e');
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
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Modular.to.pushNamed('/voluntario/proyectos/${proyecto.idProyecto}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen simple arriba
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: proyecto.imagen != null && proyecto.imagen!.isNotEmpty
                    ? ImageBase64Widget(
                        base64String: proyecto.imagen!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: colorScheme.surfaceVariant,
                        child: Center(
                          child: Icon(
                            Icons.volunteer_activism,
                            size: 40,
                            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ),
              ),
            ),

            // Contenido textual limpio
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    proyecto.nombre,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Organización
                  Row(
                    children: [
                      if (proyecto.organizacion != null &&
                          proyecto.organizacion!['logo'] != null &&
                          proyecto.organizacion!['logo'].toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: ImageBase64Widget(
                            base64String: proyecto.organizacion!['logo'].toString(),
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.business,
                            size: 14,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          organizacionNombre,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Fila ubicación + fecha
                  Row(
                    children: [
                      if (proyecto.ubicacion != null && proyecto.ubicacion!.isNotEmpty) ...[
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.9),
                        ),
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
                      ],
                      if (proyecto.fechaInicio != null) ...[
                        if (proyecto.ubicacion != null && proyecto.ubicacion!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: colorScheme.outline.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${proyecto.fechaInicio!.day}/${proyecto.fechaInicio!.month}/${proyecto.fechaInicio!.year}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Chip de estado discreto
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: proyecto.estado.toLowerCase() == 'activo'
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        proyecto.estado.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: proyecto.estado.toLowerCase() == 'activo'
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                          letterSpacing: 0.4,
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
            if (_isFuncionario) {
              await _loadPerfilFuncionario();
            } else {
              await _loadPerfilVoluntario();
            }
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
          // Header superior con saludo, búsqueda y notificaciones
          SliverAppBar(
            floating: true,
            pinned: false,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            toolbarHeight: 150, // Un poco más alto para dar aire al saludo
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Saludo al usuario con más estilo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.waving_hand_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, $_userName',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Encuentra proyectos que encajen contigo',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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

          // Carrusel de organizaciones destacadas (logos redondos tipo historias)
          SliverToBoxAdapter(
            child: FutureBuilder<List<Proyecto>>(
              future: _loadProyectosVoluntario(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildOrganizacionesCarouselSkeleton(colorScheme);
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Construir lista única de organizaciones a partir de los proyectos
                final proyectos = snapshot.data!;
                final List<Map<String, dynamic>> organizaciones = [];
                final Set<int> orgIds = {};

                for (final p in proyectos) {
                  if (p.organizacion != null) {
                    final org = p.organizacion!;
                    final id = org['id_organizacion'] is int
                        ? org['id_organizacion'] as int
                        : int.tryParse(org['id_organizacion']?.toString() ?? '') ?? -1;

                    if (id != -1 && !orgIds.contains(id)) {
                      orgIds.add(id);
                      organizaciones.add(org);
                    }
                  }
                }

                if (organizaciones.isEmpty) {
                  return const SizedBox.shrink();
                }

                return SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: organizaciones.length,
                    itemBuilder: (context, index) {
                      final org = organizaciones[index];
                      final nombre = (org['nombre'] ?? org['nombre_legal'] ?? org['nombre_corto'] ?? 'Org').toString();
                      final logo = org['logo']?.toString();
                      final idOrg = org['id_organizacion'] is int
                          ? org['id_organizacion'] as int
                          : int.tryParse(org['id_organizacion']?.toString() ?? '') ?? -1;

                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(40),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          overlayColor: MaterialStateProperty.all(Colors.transparent),
                          onTap: () {
                            if (idOrg != -1) {
                              Modular.to.pushNamed('/voluntario/organizaciones/$idOrg');
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.surface,
                                ),
                                child: ClipOval(
                                  child: (logo != null && logo.isNotEmpty)
                                      ? ImageBase64Widget(
                                          base64String: logo,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(
                                          Icons.business,
                                          size: 32,
                                          color: colorScheme.primary,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  nombre,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Banner principal grande
          SliverToBoxAdapter(
            child: Container(
              height: 280,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                        label: const Text('Ver proyectos en Santa Cruz'),
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
              height: 300,
              child: FutureBuilder<List<Proyecto>>(
                future: _loadProyectosVoluntario(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildProyectosCarouselSkeleton(theme, colorScheme);
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
    return const FuncionarioDashboard();
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

  // Stats compactas estilo Instagram (Proyectos, Horas, Personas)
  Widget _buildIgStatItem(
      String label, String value, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
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
      backgroundColor: colorScheme.surfaceContainerLow,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Mis Proyectos'),
            backgroundColor: colorScheme.surface,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton.icon(
                  onPressed: () => Modular.to.pushNamed('/proyectos/create'),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Nuevo'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Gestiona tus proyectos y tareas',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          FutureBuilder<List<Proyecto>>(
            future: _loadProyectosOrganizacion(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              final proyectos = snapshot.data ?? [];
              
              if (proyectos.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.folder_open_rounded,
                            size: 80,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No tienes proyectos',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea tu primer proyecto para comenzar',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => Modular.to.pushNamed('/proyectos/create'),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Crear Proyecto'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final proyecto = proyectos[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildProyectoCardCompact(proyecto, theme, colorScheme),
                      );
                    },
                    childCount: proyectos.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ========== VISTA INSCRIPCIONES FUNCIONARIO ==========
  Widget _buildFuncionarioInscripcionesView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Solicitudes'),
            backgroundColor: colorScheme.surface,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Revisa y gestiona las solicitudes de inscripción',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          FutureBuilder<List<Inscripcion>>(
            future: _loadInscripcionesOrganizacion(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              final inscripciones = snapshot.data ?? [];
              final pendientes = inscripciones.where((i) => i.estado.toUpperCase() == 'PENDIENTE').toList();
              final procesadas = inscripciones.where((i) => i.estado.toUpperCase() != 'PENDIENTE').toList();
              
              if (inscripciones.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_add_rounded,
                            size: 80,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No hay solicitudes',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Las solicitudes de voluntarios aparecerán aquí',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0 && pendientes.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Text(
                                    'Pendientes',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colorScheme.error,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      pendientes.length.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...pendientes.map((inscripcion) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildInscripcionCard(inscripcion, theme, colorScheme),
                            )),
                            if (procesadas.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'Procesadas',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...procesadas.map((inscripcion) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildInscripcionCard(inscripcion, theme, colorScheme),
                              )),
                            ],
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    childCount: 1,
                  ),
                ),
              );
            },
          ),
        ],
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
    // Usar directamente la vista de exploración tipo TikTok para proyectos de voluntario
    return const ProyectosExplorePage();
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
          // AppBar sencillo tipo Instagram (sin banner grande)
          SliverAppBar(
            pinned: true,
            backgroundColor: colorScheme.surface,
            elevation: 0,
            title: Text(
              _userName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función de compartir próximamente')),
                  );
                },
              ),
              PopupMenuButton<String>(
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

          // Encabezado de perfil tipo Instagram
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Foto de perfil circular grande al centro
                  Center(
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
                              ],
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.surface,
                            ),
                            child: _perfilVoluntario?.fotoPerfil != null && _perfilVoluntario!.fotoPerfil!.isNotEmpty
                                ? CircularImageBase64Widget(
                                    base64String: _perfilVoluntario!.fotoPerfil!,
                                    size: 96,
                                    backgroundColor: colorScheme.surface,
                                  )
                                : CircleAvatar(
                                    radius: 48,
                                    backgroundColor: colorScheme.surface,
                                    child: Text(
                                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.surface, width: 2),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Nombre y "rol"
                  Text(
                    _userName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isFuncionario ? 'Funcionario' : 'Voluntario',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_isFuncionario && _organizacionFuncionario != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _organizacionFuncionario!.nombre,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Stats al estilo Instagram
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildIgStatItem('Proyectos', '8', theme, colorScheme),
                      _buildIgStatItem('Horas', '127', theme, colorScheme),
                      _buildIgStatItem('Personas', '342', theme, colorScheme),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bio corta
                  if (_isFuncionario)
                    Text(
                      _perfilFuncionario?['cargo']?.toString() ?? 'Funcionario de la organización',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else if (_perfilVoluntario?.bio != null && _perfilVoluntario!.bio!.isNotEmpty)
                    Text(
                      _perfilVoluntario!.bio!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    Text(
                      'Agrega una biografía para que las organizaciones te conozcan mejor.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 16),

                  // Botón de editar perfil
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Editar perfil próximamente')),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar perfil'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ACERCA DE - ESTILO LINKEDIN
                  if (!_isFuncionario)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 24,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Acerca de',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _perfilVoluntario?.bio != null && _perfilVoluntario!.bio!.isNotEmpty
                                ? _perfilVoluntario!.bio!
                                : 'Apasionado por el voluntariado y el impacto social. Creo en el poder de las comunidades para transformar vidas. Especializado en proyectos ambientales y educativos. ¡Siempre dispuesto a ayudar! 🌱📚',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // INFORMACIÓN DE ORGANIZACIÓN - PARA FUNCIONARIOS
                  if (_isFuncionario && _organizacionFuncionario != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                                'Mi Organización',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_organizacionFuncionario!.logo != null && _organizacionFuncionario!.logo!.isNotEmpty)
                            Center(
                              child: ImageBase64Widget(
                                base64String: _organizacionFuncionario!.logo!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.contain,
                              ),
                            ),
                          if (_organizacionFuncionario!.logo != null && _organizacionFuncionario!.logo!.isNotEmpty)
                            const SizedBox(height: 16),
                          Text(
                            _organizacionFuncionario!.nombre,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (_organizacionFuncionario!.descripcion != null && _organizacionFuncionario!.descripcion!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _organizacionFuncionario!.descripcion!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                                height: 1.6,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          if (_organizacionFuncionario!.email.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.email_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 8),
                                Text(
                                  _organizacionFuncionario!.email,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          if (_organizacionFuncionario!.telefono != null && _organizacionFuncionario!.telefono!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.phone_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 8),
                                Text(
                                  _organizacionFuncionario!.telefono!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_organizacionFuncionario!.direccion != null && _organizacionFuncionario!.direccion!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _organizacionFuncionario!.direccion!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                  if (!_isFuncionario)
                    const SizedBox(height: 24),

                  // EXPERIENCIA - ESTILO LINKEDIN (solo voluntarios)
                  if (!_isFuncionario)
                    Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timeline,
                              size: 24,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Experiencia como Voluntario',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: colorScheme.primary,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Agregar experiencia próximamente')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildExperienceRoadmap(theme, colorScheme),
                      ],
                    ),
                  ),

                  if (!_isFuncionario)
                    const SizedBox(height: 24),

                  // ESTADÍSTICAS DE IMPACTO - ESTILO LINKEDIN (solo voluntarios)
                  if (!_isFuncionario)
                    Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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

                  if (!_isFuncionario)
                    const SizedBox(height: 24),

                  // ORGANIZACIONES - ESTILO LINKEDIN (solo voluntarios)
                  if (!_isFuncionario)
                    Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '3 inscritas',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
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

                  if (!_isFuncionario)
                    const SizedBox(height: 24),

                  // APTITUDES Y HABILIDADES - ESTILO LINKEDIN (solo voluntarios)
                  if (!_isFuncionario)
                    Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 24,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Aptitudes y Habilidades',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: colorScheme.primary,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Agregar aptitud próximamente')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSkillsSection(theme, colorScheme),
                      ],
                    ),
                  ),

                  if (!_isFuncionario)
                    const SizedBox(height: 24),

                  // LOGROS E INSIGNIAS - ESTILO LINKEDIN (solo voluntarios)
                  if (!_isFuncionario)
                    Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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

                        // Carrusel horizontal de fotos de voluntarios (assets/images)
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: 3,
                            itemBuilder: (context, index) {
                              final imagePaths = [
                                'assets/images/voluntarios.jpg',
                                'assets/images/lapaz.jpg',
                                'assets/images/animal.jpg',
                              ];

                              final path = imagePaths[index];

                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: AspectRatio(
                                    // Más alto que ancho
                                    aspectRatio: 3 / 4,
                                    child: Image.asset(
                                      path,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),


                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // PROYECTOS - ESTILO LINKEDIN
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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

                  // ACCIONES SOCIALES - ESTILO LINKEDIN
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

  // ========== ROADMAP DE EXPERIENCIA ==========
  Widget _buildExperienceRoadmap(ThemeData theme, ColorScheme colorScheme) {
    final experiences = [
      {
        'year': '2024',
        'title': 'Coordinador de Proyecto Ambiental',
        'organization': 'Fundación Verde Esperanza',
        'description': 'Lideré un equipo de 15 voluntarios en la reforestación de 500 hectáreas',
        'icon': Icons.eco,
        'color': colorScheme.primary,
      },
      {
        'year': '2023',
        'title': 'Mentor Educativo',
        'organization': 'Centro Educativo Futuro',
        'description': 'Apoyé a 50 estudiantes en programas de alfabetización digital',
        'icon': Icons.school,
        'color': colorScheme.secondary,
      },
      {
        'year': '2023',
        'title': 'Cuidador de Animales',
        'organization': 'Refugio Animal Amigo',
        'description': 'Cuidé de más de 200 animales en situación de abandono',
        'icon': Icons.pets,
        'color': colorScheme.tertiary,
      },
    ];

    return Column(
      children: experiences.asMap().entries.map((entry) {
        final index = entry.key;
        final exp = entry.value;
        final isLast = index == experiences.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line and dot
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: exp['color'] as Color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.surface,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (exp['color'] as Color).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 80,
                      color: colorScheme.outline.withOpacity(0.3),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Year badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (exp['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (exp['color'] as Color).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        exp['year'] as String,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: exp['color'] as Color,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Title and organization
                    Row(
                      children: [
                        Icon(
                          exp['icon'] as IconData,
                          size: 20,
                          color: exp['color'] as Color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exp['title'] as String,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                exp['organization'] as String,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Description
                    Text(
                      exp['description'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Action buttons
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ver detalles de ${exp['title']}')),
                            );
                          },
                          icon: Icon(
                            Icons.visibility,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          label: Text(
                            'Ver detalles',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Editar experiencia próximamente')),
                            );
                          },
                          icon: Icon(
                            Icons.edit,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ========== SECCIÓN DE APTITUDES ==========
  Widget _buildSkillsSection(ThemeData theme, ColorScheme colorScheme) {
    final skills = [
      {'name': 'Liderazgo', 'level': 'Avanzado', 'color': colorScheme.primary},
      {'name': 'Trabajo en Equipo', 'level': 'Experto', 'color': colorScheme.secondary},
      {'name': 'Comunicación', 'level': 'Avanzado', 'color': colorScheme.tertiary},
      {'name': 'Empatía', 'level': 'Experto', 'color': colorScheme.primary},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Skills grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) {
            final color = skill['color'] as Color;
            final level = skill['level'] as String;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    skill['name'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      level,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Add new skill button
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Agregar nueva aptitud próximamente')),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Agregar aptitud',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Skills insights
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.insights,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tus fortalezas destacadas',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Basado en tus experiencias y evaluaciones, destacas en habilidades de liderazgo y trabajo en equipo. Las organizaciones buscan voluntarios con tu perfil.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
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
          // Header con portada (Cover Photo) - Skeleton - ESTILO LINKEDIN
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: colorScheme.surfaceContainerHighest,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Banner skeleton
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                    ),
                  ),

                  // Avatar superpuesto skeleton
                  Positioned(
                    bottom: -60,
                    left: 24,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.surface,
                      ),
                      child: _buildShimmerEffect(
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ),

                  // Botón de editar foto skeleton
                  Positioned(
                    bottom: -20,
                    left: 140,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
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

          // Contenido principal con skeletons - ESTILO LINKEDIN
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  // Información del perfil skeleton
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre skeleton
                        Container(
                          height: 36,
                          width: 250,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: _buildShimmerEffect(
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),

                        // Título skeleton
                        Container(
                          height: 24,
                          width: 180,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: _buildShimmerEffect(
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),

                        // Ubicación y estado skeleton
                        Row(
                          children: [
                            Container(
                              height: 20,
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
                            const SizedBox(width: 16),
                            Container(
                              height: 20,
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
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Conexiones skeleton
                        Row(
                          children: [
                            Container(
                              height: 20,
                              width: 60,
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
                              height: 20,
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
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Botones skeleton
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                child: _buildShimmerEffect(
                                  Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 40,
                              width: 120,
                              child: _buildShimmerEffect(
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Acerca de skeleton
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    child: _buildShimmerEffect(
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Experiencia skeleton
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    child: _buildShimmerEffect(
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Habilidades skeleton
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    child: _buildShimmerEffect(
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Estadísticas skeleton
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    child: _buildShimmerEffect(
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

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

  // ========== SKELETONS PARA HOME VIEW ==========
  Widget _buildOrganizacionesCarouselSkeleton(ColorScheme colorScheme) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 5,
        itemBuilder: (context, index) {
          // Variar ligeramente el ancho para mayor realismo
          final nameWidth = 60.0 + (index % 3) * 10.0;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar circular skeleton más contrastado
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surfaceVariant,
                  ),
                  child: _buildShimmerEffect(
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Nombre de organización (2 líneas)
                Container(
                  height: 11,
                  width: nameWidth,
                  child: _buildShimmerEffect(
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 11,
                  width: nameWidth * 0.7,
                  child: _buildShimmerEffect(
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProyectosCarouselSkeleton(ThemeData theme, ColorScheme colorScheme) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 300,
          margin: const EdgeInsets.only(right: 16),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen skeleton con gradiente
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          colorScheme.surfaceContainerHighest,
                          colorScheme.surfaceContainerHighest.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: _buildShimmerEffect(
                      Container(
                        color: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ),
                // Contenido skeleton
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título skeleton (2 líneas)
                      Container(
                        height: 16,
                        width: double.infinity,
                        child: _buildShimmerEffect(
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 16,
                        width: 220,
                        child: _buildShimmerEffect(
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Organización skeleton
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _buildShimmerEffect(
                              Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            height: 13,
                            width: 140,
                            child: _buildShimmerEffect(
                              Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Ubicación y fecha skeleton
                      Row(
                        children: [
                          Container(
                            height: 12,
                            width: 90,
                            child: _buildShimmerEffect(
                              Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            height: 12,
                            width: 75,
                            child: _buildShimmerEffect(
                              Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Chip skeleton
                      Container(
                        height: 22,
                        width: 65,
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
              ],
            ),
          ),
        );
      },
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
      duration: const Duration(milliseconds: 1800), // Más suave
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: isDark ? [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ] : [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.5),
                Colors.white.withOpacity(0.7),
                Colors.white.withOpacity(0.5),
                Colors.white.withOpacity(0.3),
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              begin: Alignment(_animation.value - 1, -0.3),
              end: Alignment(_animation.value, 0.3),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
