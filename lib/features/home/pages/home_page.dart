import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:volunred_app/core/widgets/skeleton_widget.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../voluntario/pages/video_feed_page.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/models/organizacion.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/inscripcion.dart';
import '../../../core/models/perfil_voluntario.dart';
import '../../../core/models/experiencia_voluntario.dart';
import '../../../core/models/aptitud.dart';
import '../../../core/models/participacion.dart';
import '../../../core/models/dto/voluntario_responses.dart';
import '../../../core/widgets/image_base64_widget.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../widgets/funcionario_dashboard.dart';
import '../widgets/funcionario_dashboard_desktop.dart';
import '../widgets/voluntario_dashboard.dart';
import '../widgets/mi_actividad_widget.dart';
import 'support_pages.dart';
import 'dart:convert';
import 'dart:typed_data';
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
  bool _isProfileLoading = true;
  PerfilVoluntario? _perfilVoluntario;
  Map<String, dynamic>? _perfilFuncionario;
  Organizacion? _organizacionFuncionario;
  List<Aptitud> _aptitudesVoluntario = [];
  bool _isLoadingAptitudes = false;
  String? _aptitudesError;
  List<ExperienciaVoluntario> _experienciasVoluntario = [];
  bool _isLoadingExperiencias = false;
  String? _experienciasError;
  List<ParticipacionVoluntario> _participacionesVoluntario = [];
  bool _isLoadingParticipaciones = false;
  Key _inscripcionesRefreshKey = UniqueKey();

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
            // Verificar si tiene perfil de funcionario (organización)
            final tienePerfil = await authRepo.tienePerfilFuncionario();
            
            if (!tienePerfil) {
              // Si no tiene perfil guardado, verificar si tiene organización en el backend
              try {
                final funcionarioRepo = Modular.get<FuncionarioRepository>();
                final organizacion = await funcionarioRepo.getMiOrganizacion();
                
                if (organizacion.idOrganizacion > 0) {
                  // Tiene organización, guardar el flag y permitir acceso
                  print('✅ Funcionario tiene organización: ${organizacion.nombre}');
                  await StorageService.saveString(
                    ApiConfig.tienePerfilFuncionarioKey,
                    'true',
                  );
                } else if (mounted) {
                  // No tiene organización, redirigir a opciones
                  Future.microtask(() {
                    Modular.to.navigate('/profile/funcionario-options');
                  });
                  return;
                }
              } catch (e) {
                print('❌ Error verificando organización: $e');
                // Si hay error verificando organización, redirigir a opciones
                if (mounted) {
                  Future.microtask(() {
                    Modular.to.navigate('/profile/funcionario-options');
                  });
                  return;
                }
              }
            }
          } else if (usuario.isVoluntario) {
            final perfilVolJson = await StorageService.getString(
              ApiConfig.perfilVoluntarioKey,
            );
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
        final perfil = await voluntarioRepo.getPerfilByUsuario(
          usuario.idUsuario,
        );
        
        // 🔍 DEBUG: Imprimir biografía
        print('📖 Bio del perfil: ${perfil?.bio}');
        print('📖 Bio es null: ${perfil?.bio == null}');
        print('📖 Bio está vacía: ${perfil?.bio?.isEmpty}');
        
        if (!mounted) return;
        setState(() {
          _perfilVoluntario = perfil;
        });

        if (perfil != null) {
          await _loadAptitudesVoluntario(perfil.idPerfilVoluntario);
          await _loadExperienciasVoluntario(perfil.idPerfilVoluntario);
          await _loadParticipacionesVoluntario(perfil.idPerfilVoluntario);
        }
      }
    } catch (e) {
      print('❌ Error cargando perfil del voluntario: $e');
    }
  }

  Future<void> _loadAptitudesVoluntario(int perfilVolId) async {
    try {
      setState(() {
        _isLoadingAptitudes = true;
        _aptitudesError = null;
      });

      final voluntarioRepo = Modular.get<VoluntarioRepository>();
      final aptitudes = await voluntarioRepo.getAptitudesByVoluntario(
        perfilVolId,
      );

      if (!mounted) return;
      setState(() {
        _aptitudesVoluntario = aptitudes;
        _isLoadingAptitudes = false;
      });
    } catch (e) {
      print('❌ Error cargando aptitudes del voluntario: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingAptitudes = false;
        _aptitudesError = 'No se pudieron cargar tus aptitudes';
      });
    }
  }

  Future<void> _loadExperienciasVoluntario(int perfilVolId) async {
    try {
      setState(() {
        _isLoadingExperiencias = true;
        _experienciasError = null;
      });

      final voluntarioRepo = Modular.get<VoluntarioRepository>();
      final todas = await voluntarioRepo.getExperiencias();
      final filtradas = todas
          .where((exp) => exp.perfilVolId == perfilVolId)
          .toList();

      if (!mounted) return;
      setState(() {
        _experienciasVoluntario = filtradas;
        _isLoadingExperiencias = false;
      });
    } catch (e) {
      print('❌ Error cargando experiencias del voluntario: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingExperiencias = false;
        _experienciasError = 'No se pudieron cargar tus experiencias';
      });
    }
  }

  Future<void> _loadParticipacionesVoluntario(int perfilVolId) async {
    try {
      setState(() {
        _isLoadingParticipaciones = true;
      });

      final voluntarioRepo = Modular.get<VoluntarioRepository>();
      // Usar getMyParticipaciones que incluye los datos del proyecto
      final participaciones = await voluntarioRepo.getMyParticipaciones();
      
      // Filtrar participaciones activas
      final activas = participaciones.where((p) => p.isActive || p.isPending).toList();

      print('✅ Participaciones cargadas: ${participaciones.length} total, ${activas.length} activas');
      for (var p in participaciones) {
        print('   - Participación ${p.idParticipacion}: estado=${p.estado}, proyecto=${p.proyecto?.nombre}');
      }

      if (!mounted) return;
      setState(() {
        _participacionesVoluntario = activas;
        _isLoadingParticipaciones = false;
      });
    } catch (e) {
      print('❌ Error cargando participaciones del voluntario: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingParticipaciones = false;
      });
    }
  }

  Future<void> _editarBiografia(BuildContext context) async {
    final bioController = TextEditingController(
      text: _perfilVoluntario?.bio ?? '',
    );

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Biografía'),
        content: TextField(
          controller: bioController,
          decoration: const InputDecoration(
            labelText: 'Biografía',
            hintText: 'Cuéntanos sobre ti...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          maxLength: 500,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (_perfilVoluntario == null) {
                Navigator.pop(context, false);
                return;
              }

              try {
                final voluntarioRepo = Modular.get<VoluntarioRepository>();
                final perfilActualizado = await voluntarioRepo.updatePerfil(
                  _perfilVoluntario!.idPerfilVoluntario,
                  {'bio': bioController.text.trim()},
                );

                if (!mounted) return;
                
                setState(() {
                  _perfilVoluntario = perfilActualizado;
                });

                Navigator.pop(context, true);
              } catch (e) {
                print('❌ Error actualizando biografía: $e');
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al actualizar: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context, false);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (resultado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biografía actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showAddExperienciaSheet() {
    final areaController = TextEditingController();
    final organizacionController = TextEditingController();
    final descripcionController = TextEditingController();
    DateTime? fechaInicio;
    DateTime? fechaFin;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Añadir Experiencia',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: organizacionController,
                    decoration: InputDecoration(
                      labelText: 'Organización *',
                      hintText: 'Ej: Fundación Verde',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: areaController,
                    decoration: InputDecoration(
                      labelText: 'Área / Rol *',
                      hintText: 'Ej: Voluntario Ambiental',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.work_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setSheetState(() {
                                fechaInicio = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Fecha inicio *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              fechaInicio != null
                                  ? '${fechaInicio!.day}/${fechaInicio!.month}/${fechaInicio!.year}'
                                  : 'Seleccionar',
                              style: TextStyle(
                                color: fechaInicio != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: fechaInicio ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setSheetState(() {
                                fechaFin = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Fecha fin',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.event),
                            ),
                            child: Text(
                              fechaFin != null
                                  ? '${fechaFin!.day}/${fechaFin!.month}/${fechaFin!.year}'
                                  : 'Opcional',
                              style: TextStyle(
                                color: fechaFin != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descripcionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Descripción (opcional)',
                      hintText: 'Describe brevemente tu experiencia...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (areaController.text.trim().isEmpty ||
                                  organizacionController.text.trim().isEmpty ||
                                  fechaInicio == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Completa los campos obligatorios (*)',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              setSheetState(() {
                                isLoading = true;
                              });

                              try {
                                final voluntarioRepo =
                                    Modular.get<VoluntarioRepository>();
                                await voluntarioRepo.createExperiencia({
                                  'perfil_vol_id':
                                      _perfilVoluntario!.idPerfilVoluntario,
                                  'organizacion_id': 1, // TODO: selector real
                                  'area': areaController.text.trim(),
                                  'descripcion':
                                      descripcionController.text.trim().isEmpty
                                      ? null
                                      : descripcionController.text.trim(),
                                  'fecha_inicio': fechaInicio!
                                      .toUtc()
                                      .toIso8601String()
                                      .replaceAll(RegExp(r'\.\d+'), ''),
                                  if (fechaFin != null)
                                    'fecha_fin': fechaFin!
                                        .toUtc()
                                        .toIso8601String()
                                        .replaceAll(RegExp(r'\.\d+'), ''),
                                });

                                if (!mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Experiencia agregada a tu perfil',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                // Recargar experiencias
                                await _loadExperienciasVoluntario(
                                  _perfilVoluntario!.idPerfilVoluntario,
                                );
                              } catch (e) {
                                setSheetState(() {
                                  isLoading = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Guardar Experiencia',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
  }

  Widget _buildRealOrganizationsSection(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (_isLoadingParticipaciones) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_participacionesVoluntario.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Aún no estás participando en ninguna organización.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: _participacionesVoluntario.map((participacion) {
        final proyecto = participacion.proyecto;
        String orgName = proyecto?.organizacion?.nombreCorto ?? proyecto?.organizacion?.nombreLegal ?? 'Organización';
        final proyectoNombre = proyecto?.nombre ?? 'Proyecto #${participacion.proyectoId}';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
                      orgName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      proyectoNombre,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Activo',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  int _getOrganizacionesCount() {
    final orgIds = <int>{};
    for (final p in _participacionesVoluntario) {
      final proyecto = p.proyecto;
      if (proyecto?.organizacion != null) {
        orgIds.add(proyecto!.organizacion!.idOrganizacion);
      }
    }
    return orgIds.length;
  }

  Widget _buildMyProjectsSection(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoadingParticipaciones) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_participacionesVoluntario.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Aún no estás participando en ningún proyecto.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: _participacionesVoluntario.map((participacion) {
        final proyecto = participacion.proyecto;
        final proyectoNombre = proyecto?.nombre ?? 'Proyecto #${participacion.proyectoId}';
        final proyectoDesc = proyecto?.objetivo ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_special,
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
                      proyectoNombre,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (proyectoDesc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        proyectoDesc,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getEstadoParticipacionColor(participacion.estado).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getEstadoParticipacionLabel(participacion.estado),
                  style: TextStyle(
                    color: _getEstadoParticipacionColor(participacion.estado),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getEstadoParticipacionColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'EN_PROGRESO':
      case 'ACTIVO':
        return Colors.green;
      case 'PROGRAMADA':
      case 'PENDIENTE':
        return Colors.orange;
      case 'COMPLETADO':
        return Colors.blue;
      case 'AUSENTE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoParticipacionLabel(String estado) {
    switch (estado.toUpperCase()) {
      case 'EN_PROGRESO':
        return 'En Progreso';
      case 'ACTIVO':
        return 'Activo';
      case 'PROGRAMADA':
        return 'Programada';
      case 'PENDIENTE':
        return 'Pendiente';
      case 'COMPLETADO':
        return 'Completado';
      case 'AUSENTE':
        return 'Ausente';
      default:
        return estado;
    }
  }

  Future<void> _loadPerfilFuncionario() async {
    if (!mounted) return;
    
    try {
      final authRepo = Modular.get<AuthRepository>();
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      final usuario = await authRepo.getStoredUser();

      if (usuario != null) {
        print('👤 Cargando perfil de funcionario para usuario: ${usuario.nombres}');
        
        // Cargar perfil de funcionario desde la API para obtener datos frescos
        try {
          final perfilAPI = await funcionarioRepo.getMiPerfil();
          print('✅ Perfil de funcionario obtenido de API: ID=${perfilAPI.idPerfilFuncionario}');
          
          if (!mounted) return;
          
          // Actualizar el storage con el perfil fresco
          await StorageService.saveString(
            ApiConfig.perfilFuncionarioKey,
            jsonEncode(perfilAPI.toJson()),
          );
          
          // Cargar organización
          try {
            final organizacion = await funcionarioRepo.getMiOrganizacion();
            if (!mounted) return;
            setState(() {
              _perfilFuncionario = perfilAPI.toJson();
              _organizacionFuncionario = organizacion;
            });
            print('✅ Perfil y organización cargados correctamente');
          } catch (e) {
            print('❌ Error cargando organización: $e');
            if (!mounted) return;
            setState(() {
              _perfilFuncionario = perfilAPI.toJson();
            });
          }
        } catch (e) {
          print('❌ Error cargando perfil de funcionario desde API: $e');
          // Fallback: intentar cargar desde storage
          final perfilJson = await StorageService.getString(
            ApiConfig.perfilFuncionarioKey,
          );
          if (perfilJson != null) {
            final perfil = jsonDecode(perfilJson);
            print('⚠️ Usando perfil de funcionario desde storage (fallback)');
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
        // Navegar a welcome y limpiar todo el stack de navegación
        Modular.to.navigate('/auth/welcome');
        // Limpiar el estado local
        setState(() {
          _userName = 'Usuario';
          _isAdmin = false;
          _isFuncionario = false;
          _perfilVoluntario = null;
          _perfilFuncionario = null;
          _organizacionFuncionario = null;
        });
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
        final proyectosActivos = proyectos
            .where((p) => p.estado == 'activo')
            .toList();
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

  Future<List<Participacion>> _loadParticipacionesOrganizacion() async {
    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      return await funcionarioRepo.getParticipaciones();
    } catch (e) {
      print('Error cargando participaciones: $e');
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
  Widget _buildProyectoCardHorizontal(
    Proyecto proyecto,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Obtener nombre de organización
    String organizacionNombre = 'Organización';
    if (proyecto.organizacion != null && proyecto.organizacion is Map) {
      final orgMap = proyecto.organizacion as Map;
      organizacionNombre =
          orgMap['nombre']?.toString() ??
          orgMap['nombre_legal']?.toString() ??
          orgMap['nombre_corto']?.toString() ??
          'Organización';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Modular.to.pushNamed(
          '/voluntario/proyectos/${proyecto.idProyecto}',
        ),
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
                        color: colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            Icons.volunteer_activism,
                            size: 40,
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.7,
                            ),
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
                            base64String: proyecto.organizacion!['logo']
                                .toString(),
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
                      if (proyecto.ubicacion != null &&
                          proyecto.ubicacion!.isNotEmpty) ...[
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
                        if (proyecto.ubicacion != null &&
                            proyecto.ubicacion!.isNotEmpty)
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: proyecto.estado.toLowerCase() == 'activo'
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
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

  Widget _buildCategoryChip(
    String label,
    IconData icon,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 18),
      selected: false, // TODO: Implementar estado de selección
      onSelected: (selected) {
        // TODO: Implementar filtrado por categoría
        Modular.to.pushNamed(
          '/voluntario/proyectos',
          arguments: {'categoria': label},
        );
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
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final shouldShowBottomNav = !(_isFuncionario && isDesktop);
    
    // Desktop layout para funcionario - usar el nuevo dashboard con su propio sidebar
    if (_isFuncionario && (isDesktop || isTablet) && screenWidth >= 900) {
      return const FuncionarioDashboardDesktop();
    }
    
    // Mobile layout
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
                // Usar Visibility para notificar al VideoFeedPage cuando está visible
                Visibility(
                  visible: true,
                  maintainState: true,
                  child: _VideoFeedWrapper(isActive: _currentIndex == 1),
                ),
                _buildMiActividadView(),
                _buildProfileView(),
              ],
      ),
      bottomNavigationBar: shouldShowBottomNav ? NavigationBar(
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
      ) : null,
    );
  }

  Widget _buildDesktopSidebar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final destinos = [
      ('Inicio', Icons.home_rounded, 0),
      ('Proyectos', Icons.folder_rounded, 1),
      ('Inscripciones', Icons.person_add_rounded, 2),
      ('Mi Organización', Icons.business_rounded, 3),
    ];

    return SizedBox(
      width: 280,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            right: BorderSide(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'VolunRed',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: destinos.length,
                  itemBuilder: (context, index) {
                    final (label, icon, idx) = destinos[index];
                    final isSelected = _currentIndex == idx;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: isSelected
                          ? BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            )
                          : null,
                      child: ListTile(
                        leading: Icon(
                          icon,
                          color: isSelected ? colorScheme.primary : Colors.grey[700],
                        ),
                        title: Text(
                          label,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? colorScheme.primary : Colors.grey[800],
                          ),
                        ),
                        onTap: () {
                          setState(() => _currentIndex = idx);
                        },
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_rounded),
                title: const Text('Mi Perfil'),
                onTap: () {
                  setState(() => _currentIndex = 4);
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== VISTA HOME VOLUNTARIO - MATERIAL 3 ==========
  Widget _buildHomeView() {
    return VoluntarioDashboard(
      userName: _userName,
      photoBase64: _perfilVoluntario?.fotoPerfil,
    );
  }

  // ========== VISTA FUNCIONARIO - MATERIAL 3 ==========
  Widget _buildFuncionarioHomeView() {
    return const FuncionarioDashboard();
  }

  // ========== VISTA EXPLORAR VOLUNTARIO ==========
  Widget _buildExplorarView() {
    // Usar el feed de videos estilo TikTok para explorar proyectos
    // Pasar isActive para pausar/reanudar videos según el tab actual
    return VideoFeedPage(
      key: const ValueKey('video_feed'),
      isActive: _currentIndex == 1,
    );
  }

  Widget _buildHomeViewOldBackup() {
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                        : int.tryParse(
                                org['id_organizacion']?.toString() ?? '',
                              ) ??
                              -1;

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: organizaciones.length,
                    itemBuilder: (context, index) {
                      final org = organizaciones[index];
                      final nombre =
                          (org['nombre'] ??
                                  org['nombre_legal'] ??
                                  org['nombre_corto'] ??
                                  'Org')
                              .toString();
                      final logo = org['logo']?.toString();
                      final idOrg = org['id_organizacion'] is int
                          ? org['id_organizacion'] as int
                          : int.tryParse(
                                  org['id_organizacion']?.toString() ?? '',
                                ) ??
                                -1;

                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(40),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          overlayColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                          onTap: () {
                            if (idOrg != -1) {
                              Modular.to.pushNamed(
                                '/voluntario/organizaciones/$idOrg',
                              );
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
                          backgroundColor:
                              Colors.orange.shade600, // Color acento vibrante
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
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
                      _buildCategoryChip(
                        'Cerca de ti',
                        Icons.location_on_outlined,
                        colorScheme,
                        theme,
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                        'Virtual',
                        Icons.computer_outlined,
                        colorScheme,
                        theme,
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                        'Animales',
                        Icons.pets_outlined,
                        colorScheme,
                        theme,
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                        'Educación',
                        Icons.school_outlined,
                        colorScheme,
                        theme,
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                        'Fin de semana',
                        Icons.calendar_view_week_outlined,
                        colorScheme,
                        theme,
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                        'Medio ambiente',
                        Icons.eco_outlined,
                        colorScheme,
                        theme,
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                        'Salud',
                        Icons.local_hospital_outlined,
                        colorScheme,
                        theme,
                      ),
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
                      setState(
                        () => _currentIndex = 1,
                      ); // Ir a pestaña Explorar
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

                  if (snapshot.hasError ||
                      snapshot.data == null ||
                      snapshot.data!.isEmpty) {
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
                        child: _buildProyectoCardHorizontal(
                          proyecto,
                          theme,
                          colorScheme,
                        ),
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
                    onPressed: () =>
                        Modular.to.pushNamed('/profile/create-organizacion'),
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
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
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
        final stats =
            snapshot.data ??
            {'proyectos': 0, 'inscripciones_pendientes': 0, 'voluntarios': 0};

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
          child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 24),
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
    String label,
    String value,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
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

  Widget _buildProyectoCardCompact(
    Proyecto proyecto,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final bool isActivo = proyecto.estado.toLowerCase() == 'activo';
    final imageBytes = _decodeProjectImage(proyecto.imagen);

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              Modular.to.pushNamed('/proyectos/${proyecto.idProyecto}'),
          child: Row(
            children: [
              // Image panel on the left
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageBytes != null)
                        Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildGradientBackgroundForProject(isActivo),
                        )
                      else
                        _buildGradientBackgroundForProject(isActivo),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content on the right
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and badge row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              proyecto.nombre,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A1A),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActivo
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF9800),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActivo ? 'Activo' : 'Inactivo',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Location
                      if (proyecto.ubicacion != null &&
                          proyecto.ubicacion!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                proyecto.ubicacion!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),
                      // Footer action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => Modular.to.pushNamed(
                              '/proyectos/${proyecto.idProyecto}',
                            ),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 16,
                            ),
                            label: const Text('Ver detalles'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              visualDensity: VisualDensity.compact,
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

  Widget _buildGradientBackgroundForProject(bool isActivo) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActivo
              ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
              : [const Color(0xFFFF9800), const Color(0xFFE65100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.folder_rounded, size: 48, color: Colors.white),
      ),
    );
  }

  Widget _buildProyectoListCard(
    Proyecto proyecto,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return _buildProyectoCardCompact(proyecto, theme, colorScheme);
  }

  Widget _buildModernStatCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color bgColor,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [iconColor, iconColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1A1A),
              fontSize: 26,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF757575),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Decode image safely with error handling
  Uint8List? _decodeProjectImage(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return null;
    }

    try {
      var cleaned = imageData.trim();
      final dataUriPrefix = RegExp(r'data:image\/[a-zA-Z]+;base64,');
      if (dataUriPrefix.hasMatch(cleaned)) {
        cleaned = cleaned.split(',').last;
      }
      return base64Decode(cleaned);
    } catch (e) {
      // Image is corrupted or invalid, return null to use gradient fallback
      return null;
    }
  }

  // ========== VISTA PROYECTOS FUNCIONARIO ==========
  Widget _buildFuncionarioProyectosView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: 72,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mis Proyectos',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestiona tus iniciativas y estados',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF1976D2),
                  iconSize: 26,
                  tooltip: 'Crear Proyecto',
                  onPressed: () {
                    Modular.to.pushNamed('/proyectos/create');
                  },
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: Colors.black.withOpacity(0.05),
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: FutureBuilder<List<Proyecto>>(
              future: _loadProyectosOrganizacion(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final proyectos = snapshot.data ?? [];

                if (proyectos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1976D2,
                                  ).withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.folder_open_rounded,
                              size: 80,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'No tienes proyectos',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Crea tu primer proyecto para comenzar\na gestionar actividades de voluntariado',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF757575),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          FilledButton.icon(
                            onPressed: () {
                              Modular.to.pushNamed('/proyectos/create');
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Crear mi primer Proyecto'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              backgroundColor: const Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final total = proyectos.length;
                final activos = proyectos
                    .where((p) => p.estado.toLowerCase() == 'activo')
                    .length;
                final inactivos = total - activos;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildModernStatCard(
                                'Total',
                                total.toString(),
                                Icons.folder_special_rounded,
                                const Color(0xFF1976D2),
                                const Color(0xFFE3F2FD),
                                theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernStatCard(
                                'Activos',
                                activos.toString(),
                                Icons.check_circle_rounded,
                                const Color(0xFF4CAF50),
                                const Color(0xFFE8F5E9),
                                theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernStatCard(
                                'Inactivos',
                                inactivos.toString(),
                                Icons.pause_circle_rounded,
                                const Color(0xFFFF9800),
                                const Color(0xFFFFF3E0),
                                theme,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Text(
                          'Proyectos',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          children: proyectos.map((proyecto) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildProyectoListCard(
                                proyecto,
                                theme,
                                colorScheme,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ========== VISTA INSCRIPCIONES FUNCIONARIO ==========
  Widget _buildFuncionarioOrganizacionView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Parse the cached perfil to get organizacion
    Map<String, dynamic>? organizacionData;
    if (_perfilFuncionario != null &&
        _perfilFuncionario!['organizacion'] != null) {
      organizacionData = _perfilFuncionario!['organizacion'];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: 72,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Solicitudes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inscripciones y participaciones pendientes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: Colors.black.withOpacity(0.05),
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: organizacionData == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.business,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No asignado a organización',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        // Organización Header Card
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  organizacionData['nombre'] ?? 'Organización',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (organizacionData['descripcion'] != null)
                                  Text(
                                    organizacionData['descripcion'],
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stats Section
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.folder,
                                        color: colorScheme.primary,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Proyectos',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '0',
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.people,
                                        color: const Color(0xFF4CAF50),
                                        size: 32,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Voluntarios',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '0',
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF4CAF50),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Información de Contacto
                        Text(
                          'Información de Contacto',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.white,
                          child: Column(
                            children: [
                              if (organizacionData['email'] != null)
                                ListTile(
                                  leading: Icon(
                                    Icons.email,
                                    color: colorScheme.primary,
                                  ),
                                  title: Text(
                                    organizacionData['email'],
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  trailing: const Icon(Icons.open_in_new,
                                      size: 18, color: Colors.grey),
                                  onTap: () {
                                    // TODO: Implement email action
                                  },
                                ),
                              if (organizacionData['telefono'] != null)
                                ListTile(
                                  leading: Icon(
                                    Icons.phone,
                                    color: colorScheme.primary,
                                  ),
                                  title: Text(
                                    organizacionData['telefono'],
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  trailing: const Icon(Icons.open_in_new,
                                      size: 18, color: Colors.grey),
                                  onTap: () {
                                    // TODO: Implement phone action
                                  },
                                ),
                              if (organizacionData['sitioWeb'] != null)
                                ListTile(
                                  leading: Icon(
                                    Icons.public,
                                    color: colorScheme.primary,
                                  ),
                                  title: Text(
                                    organizacionData['sitioWeb'],
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  trailing: const Icon(Icons.open_in_new,
                                      size: 18, color: Colors.grey),
                                  onTap: () {
                                    // TODO: Implement website action
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Ubicación
                        if (organizacionData['direccion'] != null) ...[
                          Text(
                            'Ubicación',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.white,
                            child: ListTile(
                              leading: Icon(
                                Icons.location_on,
                                color: colorScheme.primary,
                              ),
                              title: Text(
                                organizacionData['direccion'],
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshInscripciones() async {
    setState(() {
      _inscripcionesRefreshKey = UniqueKey();
    });
  }

  int? _safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String && value.isNotEmpty) {
      return int.tryParse(value);
    }
    return null;
  }

  void _openVoluntarioProfile(int? perfilVolId, {String? fallbackName}) {
    if (perfilVolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el perfil del voluntario')),
      );
      return;
    }

    Modular.to.pushNamed(
      '/profile/view-voluntario/$perfilVolId',
      arguments: {'initialName': fallbackName},
    );
  }

  Widget _buildFuncionarioInscripcionesView() {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _refreshInscripciones,
        color: const Color(0xFFFF6B6B),
        child: CustomScrollView(
          key: _inscripcionesRefreshKey,
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: 72,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Solicitudes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inscripciones y participaciones pendientes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: Colors.black.withOpacity(0.05),
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: FutureBuilder<List<Inscripcion>>(
              future: _loadInscripcionesOrganizacion(),
              builder: (context, snapshotInscripciones) {
                return FutureBuilder<List<Participacion>>(
                  future: _loadParticipacionesOrganizacion(),
                  builder: (context, snapshotParticipaciones) {
                    if (snapshotInscripciones.connectionState ==
                            ConnectionState.waiting ||
                        snapshotParticipaciones.connectionState ==
                            ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final inscripciones = snapshotInscripciones.data ?? [];
                    final participaciones = snapshotParticipaciones.data ?? [];

                    // Filter participation requests
                    final participacionesPendientes = participaciones
                        .where((p) => p.estado.toLowerCase() == 'pendiente')
                        .toList();

                    final inscripcionesPendientes = inscripciones
                        .where((i) => i.estado.toUpperCase() == 'PENDIENTE')
                        .toList();

                    final totalSolicitudes =
                        inscripciones.length + participacionesPendientes.length;

                    if (inscripciones.isEmpty &&
                        participacionesPendientes.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFE5E5),
                                      Color(0xFFFFBBBB),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF6B6B,
                                      ).withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.inbox_rounded,
                                  size: 80,
                                  color: Color(0xFFFF6B6B),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'No hay solicitudes',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Las solicitudes de voluntarios y\nparticipantes aparecerán aquí',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: const Color(0xFF757575),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildModernStatCard(
                                    'Total',
                                    totalSolicitudes.toString(),
                                    Icons.person_add_rounded,
                                    const Color(0xFFFF6B6B),
                                    const Color(0xFFFFE5E5),
                                    theme,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildModernStatCard(
                                    'Pendientes',
                                    (inscripcionesPendientes.length +
                                            participacionesPendientes.length)
                                        .toString(),
                                    Icons.hourglass_empty_rounded,
                                    const Color(0xFFFFA500),
                                    const Color(0xFFFFF3E0),
                                    theme,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildModernStatCard(
                                    'Aprobadas',
                                    inscripciones
                                        .where(
                                          (i) =>
                                              i.estado.toUpperCase() ==
                                              'APROBADO',
                                        )
                                        .length
                                        .toString(),
                                    Icons.check_circle_rounded,
                                    const Color(0xFF4CAF50),
                                    const Color(0xFFE8F5E9),
                                    theme,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (inscripciones.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    12,
                                  ),
                                  child: Text(
                                    'Solicitudes de Inscripción',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1A1A1A),
                                        ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    20,
                                  ),
                                  child: Column(
                                    children: inscripciones.map((inscripcion) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _buildInscripcionCardModern(
                                          inscripcion,
                                          theme,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          if (participacionesPendientes.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    12,
                                  ),
                                  child: Text(
                                    'Solicitudes de Participación',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1A1A1A),
                                        ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    20,
                                  ),
                                  child: Column(
                                    children: participacionesPendientes.map((
                                      participacion,
                                    ) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _buildParticipacionCardModern(
                                          participacion,
                                          theme,
                                        ),
                                      );
                                    }).toList(),
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
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildInscripcionCardModern(Inscripcion inscripcion, ThemeData theme) {
    // Buscar datos del usuario en múltiples lugares
    String nombreUsuario = 'Usuario';
    String email = 'Sin email';
    int? perfilVolIdForNav = inscripcion.perfilVolId;
    
    // 1. Intentar desde usuario_completo
    if (inscripcion.usuarioCompleto != null) {
      final nombres = inscripcion.usuarioCompleto!['nombres'] ?? '';
      final apellidos = inscripcion.usuarioCompleto!['apellidos'] ?? '';
      nombreUsuario = '$nombres $apellidos'.trim();
      email = inscripcion.usuarioCompleto!['email'] ?? 'Sin email';
    }
    // 2. Intentar desde usuario
    else if (inscripcion.usuario != null) {
      final nombres = inscripcion.usuario!['nombres'] ?? '';
      final apellidos = inscripcion.usuario!['apellidos'] ?? '';
      nombreUsuario = '$nombres $apellidos'.trim();
      email = inscripcion.usuario!['email'] ?? 'Sin email';
    }
    // 3. Intentar desde perfilVoluntario.usuario
    else if (inscripcion.perfilVoluntario != null) {
      final usuario = inscripcion.perfilVoluntario!['usuario'];
      perfilVolIdForNav ??= _safeInt(inscripcion.perfilVoluntario!['id_perfil_voluntario']) ??
          _safeInt(inscripcion.perfilVoluntario!['perfil_vol_id']);
      if (usuario != null && usuario is Map) {
        final nombres = usuario['nombres'] ?? '';
        final apellidos = usuario['apellidos'] ?? '';
        nombreUsuario = '$nombres $apellidos'.trim();
        email = usuario['email'] ?? 'Sin email';
      } else {
        // Si no hay usuario, mostrar info del perfil
        final bio = inscripcion.perfilVoluntario!['bio'];
        if (bio != null && bio.toString().isNotEmpty) {
          nombreUsuario = 'Voluntario #${inscripcion.perfilVolId}';
          email = bio.toString().length > 50 
              ? '${bio.toString().substring(0, 50)}...' 
              : bio.toString();
        }
      }
    }
    
    // Fallback final
    if (nombreUsuario.isEmpty || nombreUsuario == 'Usuario') {
      nombreUsuario = 'Voluntario #${inscripcion.perfilVolId}';
    }
    
    final iniciales = nombreUsuario.isNotEmpty && nombreUsuario != 'Usuario'
        ? nombreUsuario.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase()
        : 'U';

    Color estadoColor;
    String estadoText;
    IconData estadoIcon;

    switch (inscripcion.estado.toUpperCase()) {
      case 'APROBADO':
        estadoColor = const Color(0xFF4CAF50);
        estadoText = 'Aprobado';
        estadoIcon = Icons.check_circle_rounded;
        break;
      case 'RECHAZADO':
        estadoColor = const Color(0xFFFF6B6B);
        estadoText = 'Rechazado';
        estadoIcon = Icons.cancel_rounded;
        break;
      default:
        estadoColor = const Color(0xFFFFA500);
        estadoText = 'Pendiente';
        estadoIcon = Icons.hourglass_empty_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          onTap: () => _openVoluntarioProfile(
            perfilVolIdForNav,
            fallbackName: nombreUsuario,
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [estadoColor, estadoColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: estadoColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      iniciales,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombreUsuario,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF757575),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: estadoColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(estadoIcon, size: 14, color: estadoColor),
                      const SizedBox(width: 4),
                      Text(
                        estadoText,
                        style: TextStyle(
                          color: estadoColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParticipacionCardModern(
    Participacion participacion,
    ThemeData theme,
  ) {
    // Obtener nombre del voluntario desde los datos disponibles
    String nombreUsuario = 'Voluntario';
    String email = 'Sin email';
    
    // Intentar obtener de usuario_completo primero
    if (participacion.usuarioCompleto != null) {
      final nombres = participacion.usuarioCompleto!['nombres'] ?? '';
      final apellidos = participacion.usuarioCompleto!['apellidos'] ?? '';
      nombreUsuario = '$nombres $apellidos'.trim();
      email = participacion.usuarioCompleto!['email'] ?? 'Sin email';
    } 
    // Luego de usuario
    else if (participacion.usuario != null) {
      final nombres = participacion.usuario!['nombres'] ?? '';
      final apellidos = participacion.usuario!['apellidos'] ?? '';
      nombreUsuario = '$nombres $apellidos'.trim();
      email = participacion.usuario!['email'] ?? 'Sin email';
    }
    // Intentar desde la inscripción relacionada (usuario_completo / usuario)
    else if (participacion.inscripcion != null) {
      final inscripcion = participacion.inscripcion!;
      final usuarioCompleto = inscripcion['usuario_completo'];
      final usuarioBasico = inscripcion['usuario'];

      if (usuarioCompleto is Map) {
        final nombres = usuarioCompleto['nombres'] ?? '';
        final apellidos = usuarioCompleto['apellidos'] ?? '';
        nombreUsuario = '$nombres $apellidos'.trim();
        email = usuarioCompleto['email'] ?? 'Sin email';
      } else if (usuarioBasico is Map) {
        final nombres = usuarioBasico['nombres'] ?? '';
        final apellidos = usuarioBasico['apellidos'] ?? '';
        nombreUsuario = '$nombres $apellidos'.trim();
        email = usuarioBasico['email'] ?? 'Sin email';
      } else {
        final perfilVol = inscripcion['perfil_voluntario'];
        if (perfilVol is Map && perfilVol['usuario'] is Map) {
          final usuario = perfilVol['usuario'] as Map;
          final nombres = usuario['nombres'] ?? '';
          final apellidos = usuario['apellidos'] ?? '';
          nombreUsuario = '$nombres $apellidos'.trim();
          email = usuario['email'] ?? 'Sin email';
        }
      }
    }
    // Como último recurso usar el perfilVoluntario adjunto directamente en la participación
    else if (participacion.perfilVoluntario != null) {
      final usuario = participacion.perfilVoluntario!['usuario'];
      if (usuario is Map) {
        final nombres = usuario['nombres'] ?? '';
        final apellidos = usuario['apellidos'] ?? '';
        nombreUsuario = '$nombres $apellidos'.trim();
        email = usuario['email'] ?? 'Sin email';
      }
    }
    
    // Obtener nombre del proyecto
    String nombreProyecto = 'Proyecto #${participacion.proyectoId}';
    if (participacion.proyecto != null) {
      nombreProyecto = participacion.proyecto!['nombre'] ?? nombreProyecto;
    }
    int? perfilVolIdForNav = participacion.perfilVolId;
    perfilVolIdForNav ??= _safeInt(participacion.inscripcion?['perfil_vol_id']);
    if (perfilVolIdForNav == null) {
      final perfilVol = participacion.inscripcion?['perfil_voluntario'];
      if (perfilVol is Map) {
        perfilVolIdForNav = _safeInt(perfilVol['id_perfil_voluntario']) ??
            _safeInt(perfilVol['perfil_vol_id']);
      }
    }
    
    if (nombreUsuario.isEmpty) nombreUsuario = 'Voluntario';
    
    final iniciales = nombreUsuario.isNotEmpty
        ? nombreUsuario.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase()
        : 'V';

    Color estadoColor;
    String estadoText;
    IconData estadoIcon;

    switch (participacion.estado.toLowerCase()) {
      case 'aprobado':
      case 'aprobada':
      case 'aceptada':
        estadoColor = const Color(0xFF4CAF50);
        estadoText = 'Aceptada';
        estadoIcon = Icons.check_circle_rounded;
        break;
      case 'rechazado':
      case 'rechazada':
        estadoColor = const Color(0xFFFF6B6B);
        estadoText = 'Rechazada';
        estadoIcon = Icons.cancel_rounded;
        break;
      default:
        estadoColor = const Color(0xFF9C27B0);
        estadoText = 'Pendiente';
        estadoIcon = Icons.hourglass_empty_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [estadoColor, estadoColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: estadoColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          iniciales,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombreUsuario,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF757575),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nombreProyecto,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF9C27B0),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: estadoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: estadoColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(estadoIcon, size: 14, color: estadoColor),
                          const SizedBox(width: 4),
                          Text(
                            estadoText,
                            style: TextStyle(
                              color: estadoColor,
                              fontSize: 12,
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
      ),
    );
  }

  // ========== VISTA EXPLORAR PROYECTOS VOLUNTARIO ==========
  Widget _buildExplorarProyectosView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<List<Proyecto>>(
      future: _loadProyectosVoluntario(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
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

  Widget _buildTinderView(
    List<Proyecto> proyectos,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final PageController pageController = PageController();

    // Agregar listener para actualizar el índice actual
    pageController.addListener(() {
      final page = pageController.page?.round() ?? 0;
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
          controller: pageController,
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
                        pageController.previousPage(
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
                    pageController.nextPage(
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
                  Modular.to.pushNamed(
                    '/voluntario/proyectos/${proyecto.idProyecto}',
                  );
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
                        pageController.nextPage(
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
  Widget _buildProyectoCardTinder(
    Proyecto proyecto,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Obtener nombre de organización
    String organizacionNombre = 'Organización';
    if (proyecto.organizacion != null && proyecto.organizacion is Map) {
      final orgMap = proyecto.organizacion as Map;
      organizacionNombre =
          orgMap['nombre']?.toString() ??
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
          decoration: BoxDecoration(color: colorScheme.surface),
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
                              : MemoryImage(
                                  base64Decode(
                                    proyecto.imagen!.split(',').last,
                                  ),
                                ),
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
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Imagen no disponible',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withOpacity(0.7),
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
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.7),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
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
                            color: colorScheme.primaryContainer.withOpacity(
                              0.3,
                            ),
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
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            letterSpacing: 0.5,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      organizacionNombre,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
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
                        if (proyecto.objetivo != null &&
                            proyecto.objetivo!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withOpacity(0.5),
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
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
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
                            color: colorScheme.surfaceContainerHighest
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              if (proyecto.ubicacion != null &&
                                  proyecto.ubicacion!.isNotEmpty) ...[
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Ubicación',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                            ),
                                            Text(
                                              proyecto.ubicacion!,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        colorScheme.onSurface,
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
                                if (proyecto.fechaInicio != null)
                                  const SizedBox(width: 20),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Fecha',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                          ),
                                          Text(
                                            '${proyecto.fechaInicio!.day}/${proyecto.fechaInicio!.month}/${proyecto.fechaInicio!.year}',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
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
              // Navegar a la vista de lista de proyectos
              Modular.to.pushNamed('/voluntario/proyectos');
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
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.5,
                        ),
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
    return const MiActividadWidget();
  }

  Widget _buildMiActividadViewOld() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Actividad')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mis Participaciones
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.handshake_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
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
                child: Icon(
                  Icons.history_edu,
                  color: colorScheme.onSecondaryContainer,
                ),
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
                child: Icon(
                  Icons.verified_outlined,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
              title: const Text('Certificados'),
              subtitle: const Text(
                'Descarga tus certificados de participación',
              ),
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
      body: _isProfileLoading
          ? _buildProfileSkeleton(theme, colorScheme)
          : CustomScrollView(
              slivers: [
                // AppBar sencillo tipo Instagram (sin banner grande)
                SliverAppBar(
                  pinned: true,
                  backgroundColor: colorScheme.surface,
                  elevation: 0,
                  title: const Text(''),
                  actions: [
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'configuracion':
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ConfiguracionPage(),
                              ),
                            );
                            break;
                          case 'ayuda':
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const HelpCenterPage(),
                              ),
                            );
                            break;
                          case 'sobre':
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AboutPage(),
                              ),
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
                              Text(
                                'Cerrar Sesión',
                                style: TextStyle(color: Color(0xFFD32F2F)),
                              ),
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
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 25,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child:
                                    _perfilVoluntario?.fotoPerfil != null &&
                                        _perfilVoluntario!
                                            .fotoPerfil!
                                            .isNotEmpty
                                    ? CircularImageBase64Widget(
                                        base64String:
                                            _perfilVoluntario!.fotoPerfil!,
                                        size: 120,
                                        backgroundColor: colorScheme.surface,
                                      )
                                    : Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              colorScheme.primary.withOpacity(
                                                0.2,
                                              ),
                                              colorScheme.primaryContainer
                                                  .withOpacity(0.4),
                                            ],
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _userName.isNotEmpty
                                                ? _userName[0].toUpperCase()
                                                : 'U',
                                            style: TextStyle(
                                              fontSize: 52,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        colorScheme.primary,
                                        colorScheme.primary.withOpacity(0.8),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(
                                          0.5,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Nombre y "rol"
                        Text(
                          _userName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primaryContainer,
                                colorScheme.primaryContainer.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isFuncionario
                                    ? Icons.badge_rounded
                                    : Icons.volunteer_activism_rounded,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _isFuncionario ? 'Funcionario' : 'Voluntario',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isFuncionario &&
                            _organizacionFuncionario != null) ...[
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

                        // Stats al estilo Instagram - DATOS REALES
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildIgStatItem(
                              'Proyectos',
                              _participacionesVoluntario.length.toString(),
                              theme,
                              colorScheme,
                            ),
                            _buildIgStatItem(
                              'Aptitudes',
                              _aptitudesVoluntario.length.toString(),
                              theme,
                              colorScheme,
                            ),
                            _buildIgStatItem(
                              'Experiencias',
                              _experienciasVoluntario.length.toString(),
                              theme,
                              colorScheme,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Botón de editar perfil
                        FilledButton.icon(
                          onPressed: () {
                            Modular.to.pushNamed('/profile/edit');
                          },
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          label: const Text(
                            'Editar Perfil',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              letterSpacing: 0.3,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 32,
                            ),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: colorScheme.primary.withOpacity(0.4),
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
                                    Expanded(
                                      child: Text(
                                        'Acerca de',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        size: 20,
                                        color: colorScheme.primary,
                                      ),
                                      onPressed: () => _editarBiografia(context),
                                      tooltip: 'Editar biografía',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _perfilVoluntario?.bio != null &&
                                          _perfilVoluntario!.bio!.isNotEmpty
                                      ? _perfilVoluntario!.bio!
                                      : 'Sin biografía registrada. Toca el ícono de editar para agregar una.',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: _perfilVoluntario?.bio != null &&
                                            _perfilVoluntario!.bio!.isNotEmpty
                                        ? colorScheme.onSurface
                                        : colorScheme.onSurface.withOpacity(0.6),
                                    height: 1.6,
                                    fontStyle: _perfilVoluntario?.bio != null &&
                                            _perfilVoluntario!.bio!.isNotEmpty
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                  ),
                                ),

                                // Disponibilidad
                                if (_perfilVoluntario?.disponibilidad != null &&
                                    _perfilVoluntario!
                                        .disponibilidad!
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 20,
                                        color: colorScheme.secondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Disponibilidad',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.secondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _perfilVoluntario!.disponibilidad!
                                        .split(',')
                                        .map((d) => d.trim())
                                        .where((d) => d.isNotEmpty)
                                        .map((disponibilidad) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.secondary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: colorScheme.secondary
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                  color: colorScheme.secondary,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  disponibilidad,
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: colorScheme
                                                            .secondary,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),

                        // INFORMACIÓN DE ORGANIZACIÓN - PARA FUNCIONARIOS (Diseño horizontal compacto)
                        if (_isFuncionario && _organizacionFuncionario != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.outline.withOpacity(0.1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Título de sección
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.business_rounded,
                                        size: 20,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Mi Organización',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Contenido horizontal: Logo pequeño + Info
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Logo pequeño circular
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: colorScheme.primaryContainer
                                              .withOpacity(0.3),
                                          border: Border.all(
                                            color: colorScheme.primary
                                                .withOpacity(0.2),
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child:
                                              _organizacionFuncionario!.logo !=
                                                      null &&
                                                  _organizacionFuncionario!
                                                      .logo!
                                                      .isNotEmpty
                                              ? ImageBase64Widget(
                                                  base64String:
                                                      _organizacionFuncionario!
                                                          .logo!,
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                )
                                              : Icon(
                                                  Icons.business,
                                                  size: 30,
                                                  color: colorScheme.primary,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Información de la organización
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Nombre
                                            Text(
                                              _organizacionFuncionario!.nombre,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        colorScheme.onSurface,
                                                  ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),

                                            // Email
                                            if (_organizacionFuncionario!
                                                .email
                                                .isNotEmpty)
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.email_outlined,
                                                    size: 14,
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      _organizacionFuncionario!
                                                          .email,
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                            // Teléfono
                                            if (_organizacionFuncionario!
                                                        .telefono !=
                                                    null &&
                                                _organizacionFuncionario!
                                                    .telefono!
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.phone_outlined,
                                                    size: 14,
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _organizacionFuncionario!
                                                        .telefono!,
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ],

                                            // Dirección
                                            if (_organizacionFuncionario!
                                                        .direccion !=
                                                    null &&
                                                _organizacionFuncionario!
                                                    .direccion!
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    Icons.location_on_outlined,
                                                    size: 14,
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      _organizacionFuncionario!
                                                          .direccion!,
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
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

                                  // Descripción (si existe)
                                  if (_organizacionFuncionario!.descripcion !=
                                          null &&
                                      _organizacionFuncionario!
                                          .descripcion!
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colorScheme
                                            .surfaceContainerHighest
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _organizacionFuncionario!.descripcion!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: colorScheme.onSurface,
                                              height: 1.5,
                                            ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                        if (!_isFuncionario) const SizedBox(height: 24),

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
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
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
                                        _showAddExperienciaSheet();
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildExperienceRoadmap(theme, colorScheme),
                              ],
                            ),
                          ),

                        if (!_isFuncionario) const SizedBox(height: 24),

                        // RESUMEN DE PARTICIPACIÓN - DATOS REALES (solo voluntarios)
                        if (!_isFuncionario)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mi Resumen',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildEnhancedStatItem(
                                      count: _participacionesVoluntario.length
                                          .toString(),
                                      label: 'Proyectos\nActivos',
                                      icon: Icons.folder_special,
                                      color: colorScheme.primary,
                                      theme: theme,
                                    ),
                                    _buildEnhancedStatItem(
                                      count: _getOrganizacionesCount()
                                          .toString(),
                                      label: 'Organizaciones\nInscritas',
                                      icon: Icons.business,
                                      color: colorScheme.secondary,
                                      theme: theme,
                                    ),
                                    _buildEnhancedStatItem(
                                      count: _aptitudesVoluntario.length
                                          .toString(),
                                      label: 'Aptitudes\nRegistradas',
                                      icon: Icons.lightbulb,
                                      color: colorScheme.tertiary,
                                      theme: theme,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        if (!_isFuncionario) const SizedBox(height: 24),

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
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: colorScheme.primary,
                                      ),
                                      onPressed: () {
                                        Modular.to.pushNamed(
                                          '/profile/aptitudes',
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
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Icon(icon, color: color, size: 28),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required ColorScheme colorScheme,
    required ThemeData theme,
    bool? expanded,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        if (expanded == true)
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          )
        else
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
      ],
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
        color: earned
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: earned
              ? color.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: earned
            ? [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
        gradient: earned
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.05), color.withOpacity(0.02)],
              )
            : null,
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
                  color: earned
                      ? color.withOpacity(0.15)
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(
                          0.5,
                        ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: earned
                        ? color.withOpacity(0.3)
                        : theme.colorScheme.outline.withOpacity(0.2),
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                      color.withOpacity(0.7),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Nivel de la insignia
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: earned
                  ? color.withOpacity(0.1)
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: earned
                    ? color.withOpacity(0.2)
                    : theme.colorScheme.outline.withOpacity(0.1),
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
              color: earned
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
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
                valueColor: AlwaysStoppedAnimation<Color>(
                  color.withOpacity(0.6),
                ),
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
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
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

  // ========== ROADMAP DE EXPERIENCIA (DATOS REALES) ==========
  Widget _buildExperienceRoadmap(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoadingExperiencias) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_experienciasError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          _experienciasError!,
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
        ),
      );
    }

    if (_experienciasVoluntario.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Aún no registraste experiencias de voluntariado en tu perfil.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Ordenar por fecha de inicio descendente
    final experiences = List<ExperienciaVoluntario>.from(
      _experienciasVoluntario,
    )..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));

    return Column(
      children: experiences.asMap().entries.map((entry) {
        final index = entry.key;
        final exp = entry.value;
        final isLast = index == experiences.length - 1;

        final year = exp.fechaInicio.year.toString();
        final title = exp.area;
        final organizationName = exp.organizacion != null
            ? (exp.organizacion!['nombre'] ??
                      exp.organizacion!['nombre_legal'] ??
                      'Organización')
                  .toString()
            : 'Organización';
        final description = exp.descripcion ?? '';
        final color = colorScheme.primary;
        final icon = Icons.volunteer_activism_rounded;

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
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        year,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Title and organization
                    Row(
                      children: [
                        Icon(icon, size: 20, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                organizationName,
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
                      description,
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
                              SnackBar(content: Text('Ver detalles de $title')),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Editar experiencia próximamente',
                                ),
                              ),
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
    if (_isLoadingAptitudes) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_aptitudesError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          _aptitudesError!,
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
        ),
      );
    }

    if (_aptitudesVoluntario.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'Todavía no has agregado aptitudes a tu perfil. Toca el lápiz para comenzar.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _aptitudesVoluntario.map((aptitud) {
        final color = colorScheme.primary;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: color.withOpacity(0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                aptitud.nombre,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
              Text('Proyectos Inscritos', style: theme.textTheme.titleMedium),
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
              Text('Proyectos Completados', style: theme.textTheme.titleMedium),
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
          // Header con portada - Skeleton mejorado
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Banner skeleton con gradiente animado
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.surfaceContainerHighest,
                          colorScheme.surfaceContainerHigh,
                        ],
                      ),
                    ),
                    child: const SkeletonWidget(
                      width: double.infinity,
                      height: 280,
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
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const SkeletonWidget(
                        width: 120,
                        height: 120,
                        borderRadius: BorderRadius.all(Radius.circular(60)),
                      ),
                    ),
                  ),

                  // Botón de cámara skeleton
                  Positioned(
                    bottom: -20,
                    left: 130,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido principal - Skeletons mejorados
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  // Información del perfil
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre
                        SkeletonWidget(
                          width: 220,
                          height: 32,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 12),

                        // Subtítulo/Rol
                        SkeletonWidget(
                          width: 180,
                          height: 20,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(height: 8),

                        // Ubicación y estado
                        Row(
                          children: [
                            SkeletonWidget(
                              width: 130,
                              height: 18,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(width: 16),
                            SkeletonWidget(
                              width: 100,
                              height: 18,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: SkeletonWidget(
                                width: double.infinity,
                                height: 44,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SkeletonWidget(
                              width: 120,
                              height: 44,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Mi Resumen - Card con estadísticas
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonWidget(
                          width: 140,
                          height: 24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                SkeletonWidget(
                                  width: 48,
                                  height: 48,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                const SizedBox(height: 8),
                                SkeletonWidget(
                                  width: 40,
                                  height: 24,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 4),
                                SkeletonWidget(
                                  width: 70,
                                  height: 14,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                SkeletonWidget(
                                  width: 48,
                                  height: 48,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                const SizedBox(height: 8),
                                SkeletonWidget(
                                  width: 40,
                                  height: 24,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 4),
                                SkeletonWidget(
                                  width: 90,
                                  height: 14,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                SkeletonWidget(
                                  width: 48,
                                  height: 48,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                const SizedBox(height: 8),
                                SkeletonWidget(
                                  width: 40,
                                  height: 24,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 4),
                                SkeletonWidget(
                                  width: 80,
                                  height: 14,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Organizaciones Inscritas
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SkeletonWidget(
                              width: 24,
                              height: 24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(width: 12),
                            SkeletonWidget(
                              width: 180,
                              height: 20,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Lista de organizaciones skeleton
                        ...List.generate(
                          2,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                SkeletonWidget(
                                  width: 50,
                                  height: 50,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SkeletonWidget(
                                        width: double.infinity,
                                        height: 18,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      const SizedBox(height: 6),
                                      SkeletonWidget(
                                        width: 120,
                                        height: 14,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Aptitudes
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonWidget(
                          width: 120,
                          height: 20,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            6,
                            (index) => SkeletonWidget(
                              width: 80 + (index * 10).toDouble(),
                              height: 32,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Experiencias
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonWidget(
                          width: 140,
                          height: 20,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(
                          2,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonWidget(
                                  width: 200,
                                  height: 18,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 8),
                                SkeletonWidget(
                                  width: 150,
                                  height: 14,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 8),
                                SkeletonWidget(
                                  width: double.infinity,
                                  height: 14,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),
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

  Widget _buildShimmerEffect(Widget child) {
    return ShimmerContainer(child: child);
  }

  Widget _buildStatSkeleton() {
    return Column(
      children: [
        SizedBox(
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
        const SizedBox(height: 12),
        SizedBox(
          height: 16,
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
        SizedBox(
          height: 12,
          width: 70,
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
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
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
                SizedBox(
                  height: 16,
                  width: 150,
                  child: _buildShimmerEffect(
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 14,
                  width: 100,
                  child: _buildShimmerEffect(
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 12,
                  width: 80,
                  child: _buildShimmerEffect(
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
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
          SizedBox(
            width: 50,
            height: 50,
            child: _buildShimmerEffect(
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 12,
            width: 80,
            child: _buildShimmerEffect(
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 11,
            width: 100,
            child: _buildShimmerEffect(
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 9,
            width: 90,
            child: _buildShimmerEffect(
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
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
          SizedBox(
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
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: _buildShimmerEffect(
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.9,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Nombre de organización (2 líneas)
                SizedBox(
                  height: 11,
                  width: nameWidth,
                  child: _buildShimmerEffect(
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.9,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 11,
                  width: nameWidth * 0.7,
                  child: _buildShimmerEffect(
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.9,
                        ),
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

  Widget _buildProyectosCarouselSkeleton(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
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
                      Container(color: colorScheme.surfaceContainerHighest),
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
                      SizedBox(
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
                      SizedBox(
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
                              color: colorScheme.surfaceContainerHighest
                                  .withOpacity(0.7),
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
                          SizedBox(
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
                          SizedBox(
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
                              color: colorScheme.surfaceContainerHighest
                                  .withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
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
                      SizedBox(
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
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ]
                  : [
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

/// Wrapper para VideoFeedPage que maneja correctamente el estado activo
/// cuando se usa dentro de IndexedStack
class _VideoFeedWrapper extends StatefulWidget {
  final bool isActive;

  const _VideoFeedWrapper({required this.isActive});

  @override
  State<_VideoFeedWrapper> createState() => _VideoFeedWrapperState();
}

class _VideoFeedWrapperState extends State<_VideoFeedWrapper> {
  @override
  void didUpdateWidget(_VideoFeedWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Forzar rebuild del VideoFeedPage cuando cambia isActive
    if (oldWidget.isActive != widget.isActive) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return VideoFeedPage(
      key: ValueKey('video_feed_active_${widget.isActive}'),
      isActive: widget.isActive,
    );
  }
}
