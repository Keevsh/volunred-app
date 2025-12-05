import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:image_picker/image_picker.dart';
import 'package:volunred_app/core/models/perfil_funcionario.dart';
import '../../../core/models/organizacion.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/organizacion_repository.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/theme/app_widgets.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/image_base64_widget.dart';

class CreateOrganizacionPage extends StatefulWidget {
  const CreateOrganizacionPage({super.key});

  @override
  State<CreateOrganizacionPage> createState() => _CreateOrganizacionPageState();
}

class _CreateOrganizacionPageState extends State<CreateOrganizacionPage> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Controladores Paso 1: Información Básica
  final _nombreOrgController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoOrgController = TextEditingController();
  final _emailOrgController = TextEditingController();
  final _sitioWebController = TextEditingController();

  // Controladores Paso 2: Información Legal
  final _rucController = TextEditingController();
  final _razonSocialController = TextEditingController();
  int? _categoriaSeleccionada;
  List<Map<String, dynamic>> _categorias = [];

  // Controladores Paso 3: Tu Información
  final _cargoController = TextEditingController();
  final _departamentoController = TextEditingController();

  // Form keys
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  bool _isEditing = false;
  Organizacion? _organizacionExistente;
  PerfilFuncionario? _perfilFuncionarioExistente;
  String? _logoBase64;
  String? _fotoPerfilBase64;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategorias();
    _loadOrganizacionExistente();
  }

  Future<void> _loadOrganizacionExistente() async {
    try {
      final authRepo = Modular.get<AuthRepository>();
      final usuario = await authRepo.getStoredUser();

      // Solo intentar cargar si el usuario es funcionario Y tiene una organización
      if (usuario != null && usuario.isFuncionario) {
        final funcionarioRepo = Modular.get<FuncionarioRepository>();
        try {
          final perfil = await funcionarioRepo.getMiPerfil();
          print('✅ [LOAD ORG] Perfil del usuario actual encontrado: ID=${perfil.idPerfilFuncionario}, Usuario=${perfil.idUsuario}');
          
          final organizacion = await funcionarioRepo.getMiOrganizacion();
          print('✅ [LOAD ORG] Organización cargada: ID=${organizacion.idOrganizacion}, Nombre=${organizacion.nombre}');

          // Validaciones estrictas: debe tener ID válido (> 0)
          if (organizacion.idOrganizacion > 0 &&
              organizacion.nombre.isNotEmpty) {
            
            setState(() {
              _organizacionExistente = organizacion;
              _perfilFuncionarioExistente = perfil;
              _isEditing = true;

              // Cargar datos existentes en los campos
              _nombreOrgController.text = organizacion.nombre;
              _descripcionController.text = organizacion.descripcion ?? '';
              _direccionController.text = organizacion.direccion ?? '';
              _telefonoOrgController.text = organizacion.telefono ?? '';
              _emailOrgController.text = organizacion.email;
              _sitioWebController.text = organizacion.sitioWeb ?? '';
              _rucController.text = organizacion.ruc ?? '';
              _razonSocialController.text =
                  organizacion.razonSocial ?? organizacion.nombre;
              // Solo establecer categoria si es válida (no 0)
              _categoriaSeleccionada = (organizacion.idCategoriaOrganizacion != 0) 
                  ? organizacion.idCategoriaOrganizacion 
                  : null;
              _logoBase64 = organizacion.logo;

              // Cargar datos del perfil de funcionario
              if (perfil.cargo != null) {
                _cargoController.text = perfil.cargo!;
              }
              if (perfil.departamento != null) {
                _departamentoController.text = perfil.departamento!;
              }
              _fotoPerfilBase64 = perfil.fotoPerfil;
            });
            print('✅ [LOAD ORG] Organización existente cargada para EDICIÓN: ${organizacion.nombre}');
          } else {
            print('ℹ️ [LOAD ORG] Organización inválida (ID: ${organizacion.idOrganizacion}), iniciando en modo CREACIÓN');
          }
        } catch (e) {
          // Es NORMAL que falle para usuarios NUEVOS
          print('ℹ️ [LOAD ORG] Usuario NUEVO - No existe organización: ${e.toString()}');
          print('✨ [LOAD ORG] Iniciando en modo CREACIÓN (empty form)');
        }
      }
    } catch (e) {
      print('⚠️ Error verificando organización existente: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nombreOrgController.dispose();
    _descripcionController.dispose();
    _direccionController.dispose();
    _telefonoOrgController.dispose();
    _emailOrgController.dispose();
    _sitioWebController.dispose();
    _rucController.dispose();
    _razonSocialController.dispose();
    _cargoController.dispose();
    _departamentoController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    print('📋 Iniciando carga de categorías...');
    try {
      final repo = Modular.get<OrganizacionRepository>();
      print('📋 Repositorio obtenido: $repo');

      final categorias = await repo.getCategoriasOrganizaciones();
      print('📋 Categorías recibidas: ${categorias.length}');
      print(
        '📋 Primera categoría: ${categorias.isNotEmpty ? categorias.first : "ninguna"}',
      );

      setState(() {
        _categorias = categorias;
      });
      print('✅ Categorías cargadas exitosamente: ${_categorias.length}');
    } catch (e, stackTrace) {
      print('❌ Error cargando categorías: $e');
      print('❌ Stack trace: $stackTrace');
      if (mounted) {
        AppWidgets.showStyledSnackBar(
          context: context,
          message: 'Error al cargar categorías: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _nextStep() async {
    bool isValid = false;

    switch (_currentStep) {
      case 0:
        isValid = _formKey1.currentState?.validate() ?? false;
        print('🔍 Paso 1 validación: $isValid');
        if (!isValid) {
          print('❌ Paso 1 falló validación. Campos requeridos:');
          print('   - Nombre: ${_nombreOrgController.text.isNotEmpty}');
          print('   - Descripción: ${_descripcionController.text.isNotEmpty}');
          print('   - Dirección: ${_direccionController.text.isNotEmpty}');
          print('   - Email: ${_emailOrgController.text.isNotEmpty}');
        }
        break;
      case 1:
        isValid = _formKey2.currentState?.validate() ?? false;
        print('🔍 Paso 2 validación: $isValid');
        if (!isValid) {
          print('❌ Paso 2 falló validación. Campos requeridos:');
          print(
            '   - RUC: ${_rucController.text.isNotEmpty && _rucController.text.length == 13}',
          );
          print('   - Razón Social: ${_razonSocialController.text.isNotEmpty}');
          print('   - Categoría: ${_categoriaSeleccionada != null}');
        }
        break;
      case 2:
        isValid = _formKey3.currentState?.validate() ?? false;
        print('🔍 Paso 3 validación: $isValid');
        if (!isValid) {
          print('❌ Paso 3 falló validación. Campos requeridos:');
          print('   - Cargo: ${_cargoController.text.isNotEmpty}');
          print(
            '   - Departamento: ${_departamentoController.text.isNotEmpty}',
          );
        }
        if (isValid) {
          await _submitAll();
          return;
        }
        break;
    }

    if (isValid && _currentStep < 2) {
      print('✅ Avanzando de paso $_currentStep a ${_currentStep + 1}');
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (!isValid) {
      print(
        '❌ No se puede avanzar: validación falló para paso ${_currentStep + 1}',
      );
      // Mostrar mensaje de error si la validación falló
      String errorMessage = 'Por favor, completa todos los campos obligatorios';
      switch (_currentStep) {
        case 0:
          errorMessage = 'Completa la información básica de la organización';
          break;
        case 1:
          errorMessage = 'Completa la información legal de la organización';
          break;
        case 2:
          errorMessage = 'Completa tu información personal';
          break;
      }

      if (mounted) {
        AppWidgets.showStyledSnackBar(
          context: context,
          message: errorMessage,
          isError: true,
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitAll() async {
    setState(() => _isLoading = true);

    try {
      final authRepo = Modular.get<AuthRepository>();
      final orgRepo = Modular.get<OrganizacionRepository>();
      final funcionarioRepo = Modular.get<FuncionarioRepository>();

      // Obtener usuario actual
      final usuario = await authRepo.getStoredUser();
      if (usuario == null) {
        throw Exception('Usuario no encontrado');
      }

      Organizacion organizacion;

      // Si estamos editando, actualizar la organización existente
      if (_isEditing && _organizacionExistente != null) {
        print('📝 Actualizando organización existente...');
        final orgData = {
          'nombre_legal': _razonSocialController.text.trim(),
          if (_nombreOrgController.text.trim().isNotEmpty)
            'nombre_corto': _nombreOrgController.text.trim(),
          'correo': _emailOrgController.text.trim(),
          if (_direccionController.text.trim().isNotEmpty)
            'direccion': _direccionController.text.trim(),
          if (_telefonoOrgController.text.trim().isNotEmpty)
            'telefono': _telefonoOrgController.text.trim(),
          if (_sitioWebController.text.trim().isNotEmpty)
            'sitio_web': _sitioWebController.text.trim(),
          if (_rucController.text.trim().isNotEmpty)
            'ruc': _rucController.text.trim(),
          if (_descripcionController.text.trim().isNotEmpty)
            'descripcion': _descripcionController.text.trim(),
          if (_categoriaSeleccionada != null)
            'id_categoria_organizacion': _categoriaSeleccionada,
          if (_logoBase64 != null && _logoBase64!.isNotEmpty)
            'logo': _logoBase64,
        };

        organizacion = await orgRepo.updateOrganizacion(
          _organizacionExistente!.idOrganizacion,
          orgData,
        );
        print('✅ Organización actualizada: ${organizacion.nombre}');
      } else {
        // Crear nueva organización
        final orgData = {
          'nombre_legal': _razonSocialController.text.trim(),
          if (_nombreOrgController.text.trim().isNotEmpty)
            'nombre_corto': _nombreOrgController.text.trim(),
          'correo': _emailOrgController.text.trim(),
          if (_direccionController.text.trim().isNotEmpty)
            'direccion': _direccionController.text.trim(),
          if (_telefonoOrgController.text.trim().isNotEmpty)
            'telefono': _telefonoOrgController.text.trim(),
          if (_sitioWebController.text.trim().isNotEmpty)
            'sitio_web': _sitioWebController.text.trim(),
          if (_rucController.text.trim().isNotEmpty)
            'ruc': _rucController.text.trim(),
          if (_descripcionController.text.trim().isNotEmpty)
            'descripcion': _descripcionController.text.trim(),
          'estado': 'activo',
          if (_logoBase64 != null && _logoBase64!.isNotEmpty)
            'logo': _logoBase64,
        };

        print(
          '🚀 [ORGANIZACIÓN] Enviando datos al backend para crear organización:',
        );
        print('📦 [ORGANIZACIÓN] Data: $orgData');
        print('🏢 Nombre legal: ${_razonSocialController.text.trim()}');
        print('📧 Correo: ${_emailOrgController.text.trim()}');
        if (_categoriaSeleccionada != null) {
          print('🏷️ Categoría seleccionada: $_categoriaSeleccionada');
        }

        organizacion = await orgRepo.createOrganizacion(orgData);
        print('✅ Organización creada: ${organizacion.nombre}');

        // Si hay categoría seleccionada, actualizar la organización
        if (_categoriaSeleccionada != null) {
          try {
            organizacion = await orgRepo.updateOrganizacion(
              organizacion.idOrganizacion,
              {'id_categoria_organizacion': _categoriaSeleccionada},
            );
            print('✅ Categoría asignada a la organización');
          } catch (e) {
            print('⚠️ No se pudo asignar la categoría: $e');
          }
        }
      }

      // 2. Actualizar o crear perfil de funcionario
      print(
        '👤 ${_isEditing && _perfilFuncionarioExistente != null ? "Actualizando" : "Creando"} perfil de funcionario...',
      );
      PerfilFuncionario? perfil;

      try {
        // Si ya existe un perfil previo (incluso en modo creación), actualizarlo
        // para que apunte a la nueva organización
        if (_perfilFuncionarioExistente != null) {
          print('🔄 IMPORTANTE: Perfil previo detectado. Actualizando para nueva organización...');
          final perfilData = <String, dynamic>{
            // CRUCIAL: Actualizar la organización del perfil a la nueva
            'organizacion_id': organizacion.idOrganizacion,
          };

          // Actualizar campos personales si existen
          if (_cargoController.text.trim().isNotEmpty) {
            perfilData['cargo'] = _cargoController.text.trim();
          }

          if (_departamentoController.text.trim().isNotEmpty) {
            perfilData['area'] = _departamentoController.text.trim();
          }

          if (_fotoPerfilBase64 != null && _fotoPerfilBase64!.isNotEmpty) {
            perfilData['foto_perfil'] = _fotoPerfilBase64;
          }

          print('📤 Actualizando perfil existente con nueva organización: $perfilData');
          perfil = await funcionarioRepo.updatePerfilFuncionario(
            _perfilFuncionarioExistente!.idPerfilFuncionario,
            perfilData,
          );
          print(
            '✅ Perfil de funcionario ACTUALIZADO a nueva organización: ${perfil.idPerfilFuncionario} -> Org ID: ${perfil.idOrganizacion}',
          );
        } else {
          // SOLO crear nuevo perfil si NO existe uno previo
          print('✨ Ningún perfil previo. Creando nuevo perfil de funcionario...');
          final perfilData = <String, dynamic>{
            'usuario_id': usuario.idUsuario,
            'organizacion_id': organizacion.idOrganizacion,
            'fecha_ingreso': DateTime.now()
                .toUtc()
                .toIso8601String()
                .replaceAll(RegExp(r'\.\d+'), ''),
            'estado': 'activo',
          };

          if (_cargoController.text.trim().isNotEmpty) {
            perfilData['cargo'] = _cargoController.text.trim();
          }

          if (_departamentoController.text.trim().isNotEmpty) {
            perfilData['area'] = _departamentoController.text.trim();
          }

          if (_fotoPerfilBase64 != null && _fotoPerfilBase64!.isNotEmpty) {
            perfilData['foto_perfil'] = _fotoPerfilBase64;
          }

          print('📤 Creando nuevo perfil de funcionario: $perfilData');
          perfil = await orgRepo.createPerfilFuncionario(perfilData);
          print(
            '✅ Nuevo perfil de funcionario creado: ${perfil.idPerfilFuncionario}',
          );
        }
      } catch (e) {
        print(
          '⚠️ Error al ${_isEditing && _perfilFuncionarioExistente != null ? "actualizar" : "crear"} perfil de funcionario: $e',
        );
        // Intentar obtener el perfil si ya existe
        try {
          final perfilExistente = await orgRepo.getPerfilFuncionarioByUsuario(
            usuario.idUsuario,
          );
          if (perfilExistente != null) {
            print(
              '✅ Perfil de funcionario ya existe: ${perfilExistente.idPerfilFuncionario}',
            );
            perfil = perfilExistente;

            // Actualizar con los datos nuevos si faltan
            final updateData = <String, dynamic>{};
            bool needsUpdate = false;

            if (_cargoController.text.trim().isNotEmpty &&
                perfilExistente.cargo != _cargoController.text.trim()) {
              updateData['cargo'] = _cargoController.text.trim();
              needsUpdate = true;
            }
            if (_departamentoController.text.trim().isNotEmpty &&
                (perfilExistente.area != _departamentoController.text.trim() &&
                    perfilExistente.departamento !=
                        _departamentoController.text.trim())) {
              updateData['area'] = _departamentoController.text.trim();
              needsUpdate = true;
            }

            // Verificar si necesita organizacion_id
            if (perfilExistente.idOrganizacion != organizacion.idOrganizacion) {
              updateData['organizacion_id'] = organizacion.idOrganizacion;
              needsUpdate = true;
            }

            if (needsUpdate) {
              print('📝 Actualizando perfil existente: $updateData');
              perfil = await orgRepo.updatePerfilFuncionario(
                perfilExistente.idPerfilFuncionario,
                updateData,
              );
              print('✅ Perfil de funcionario actualizado');
            }
          }
        } catch (e2) {
          print('⚠️ No se pudo obtener ni actualizar perfil: $e2');
          // Continuamos aunque falle, la organización ya está creada
        }
      }

      if (mounted) {
        AppWidgets.showStyledSnackBar(
          context: context,
          message: _isEditing
              ? '¡Organización actualizada exitosamente!'
              : '¡Organización creada exitosamente!',
          isError: false,
        );

        // Redirigir al home (el home verificará que el perfil existe)
        Future.delayed(const Duration(seconds: 1), () {
          Modular.to.navigate('/home/');
        });
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        AppWidgets.showStyledSnackBar(
          context: context,
          message: 'Error: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [_buildStep1(), _buildStep2(), _buildStep3()],
              ),
            ),
            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: _currentStep == 0
                ? () => Navigator.of(context).pop()
                : _previousStep,
            icon: const Icon(Icons.arrow_back_rounded),
            color: const Color(0xFF007AFF),
          ),
          Expanded(
            child: Text(
              _isEditing ? 'Editar Organización' : 'Solicitar Organización',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= _currentStep
                      ? const Color(0xFF007AFF)
                      : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i < 2) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paso 1: Información Básica',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuéntanos sobre tu organización',
              style: TextStyle(fontSize: 15, color: Color(0xFF86868B)),
            ),
            const SizedBox(height: 24),
            _buildLogoSelector(),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _nombreOrgController,
              label: 'Nombre de la Organización',
              hint: 'Ej: Fundación Ayuda Social',
              icon: Icons.business,
              required: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _descripcionController,
              label: 'Descripción',
              hint: 'Describe los objetivos y actividades de tu organización',
              icon: Icons.description,
              maxLines: 4,
              required: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _direccionController,
              label: 'Dirección',
              hint: 'Dirección completa',
              icon: Icons.location_on,
              required: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _telefonoOrgController,
              label: 'Teléfono',
              hint: 'Número de teléfono',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _emailOrgController,
              label: 'Email de Contacto',
              hint: 'email@ejemplo.com',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              required: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El email es obligatorio';
                }
                // Validación básica de email
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Ingresa un email válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _sitioWebController,
              label: 'Sitio Web (opcional)',
              hint: 'https://www.ejemplo.com',
              icon: Icons.language,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24), // Add bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paso 2: Información Legal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Datos legales de tu organización',
              style: TextStyle(fontSize: 15, color: Color(0xFF86868B)),
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _rucController,
              label: 'RUC',
              hint: 'Número de RUC',
              icon: Icons.badge,
              keyboardType: TextInputType.number,
              maxLength: 13,
              required: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El RUC es obligatorio';
                }
                if (value.length != 13) {
                  return 'El RUC debe tener 13 dígitos';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _razonSocialController,
              label: 'Razón Social',
              hint: 'Nombre legal de la organización',
              icon: Icons.article,
              required: true,
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5EA)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categoría de Organización',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_categorias.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownButtonFormField<int>(
                      value: _categoriaSeleccionada,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      hint: const Text('Selecciona una categoría'),
                      isExpanded: true,
                      items: _categorias
                          .where((cat) {
                            // Filtrar: solo categorías con ID válido
                            final id = cat['id_categoria'];
                            return id != null && 
                                   id != 0 && 
                                   id is int || int.tryParse(id.toString()) != null;
                          })
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                            final cat = entry.value;
                            final categoryId = cat['id_categoria'] is int
                                ? cat['id_categoria'] as int
                                : int.tryParse(cat['id_categoria'].toString()) ?? 0;
                            
                            return DropdownMenuItem<int>(
                              value: categoryId,
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 300,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      cat['nombre'] as String? ?? 'Sin nombre',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (cat['descripcion'] != null)
                                      Text(
                                        cat['descripcion'] as String,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF86868B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        print('🎯 Categoría seleccionada: $value');
                        setState(() => _categoriaSeleccionada = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona una categoría';
                        }
                        return null;
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paso 3: Tu Información',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Información sobre tu rol en la organización',
              style: TextStyle(fontSize: 15, color: Color(0xFF86868B)),
            ),
            const SizedBox(height: 24),
            _buildFotoPerfilSelector(),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _cargoController,
              label: 'Tu Cargo',
              hint: 'Tu cargo en la organización',
              icon: Icons.work,
              required: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _departamentoController,
              label: 'Departamento',
              hint: 'Departamento al que perteneces',
              icon: Icons.corporate_fare,
              required: true,
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF007AFF).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: const Color(0xFF007AFF)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Una vez creada la organización, podrás gestionar proyectos y tareas de voluntariado.',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF007AFF).withOpacity(0.8),
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

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70, // Reducido de 85 a 70 para mejor compresión
      );

      if (image != null) {
        try {
          final base64 = await ImageUtils.convertXFileToBase64(image);
          setState(() {
            _logoBase64 = base64;
          });
        } catch (e) {
          AppWidgets.showStyledSnackBar(
            context: context,
            message: 'Error al procesar la imagen: $e',
            isError: true,
          );
        }
      }
    } catch (e) {
      AppWidgets.showStyledSnackBar(
        context: context,
        message: 'Error al seleccionar imagen: $e',
        isError: true,
      );
    }
  }

  Future<void> _pickFotoPerfil() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70, // Reducido de 85 a 70 para mejor compresión
      );

      if (image != null) {
        try {
          final base64 = await ImageUtils.convertXFileToBase64(image);
          setState(() {
            _fotoPerfilBase64 = base64;
          });
        } catch (e) {
          AppWidgets.showStyledSnackBar(
            context: context,
            message: 'Error al procesar la imagen: $e',
            isError: true,
          );
        }
      }
    } catch (e) {
      AppWidgets.showStyledSnackBar(
        context: context,
        message: 'Error al seleccionar imagen: $e',
        isError: true,
      );
    }
  }

  Widget _buildLogoSelector() {
    return Center(
      child: Column(
        children: [
          const Text(
            '🏢 Logo de la Organización',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickLogo,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5EA), width: 2),
              ),
              child: _logoBase64 != null && _logoBase64!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ImageBase64Widget(
                        base64String: _logoBase64!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Agregar logo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _pickLogo, child: const Text('Cambiar logo')),
        ],
      ),
    );
  }

  Widget _buildFotoPerfilSelector() {
    return Center(
      child: Column(
        children: [
          const Text(
            '📷 Foto de Perfil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E5EA), width: 3),
                ),
                child: ClipOval(
                  child:
                      _fotoPerfilBase64 != null && _fotoPerfilBase64!.isNotEmpty
                      ? ImageBase64Widget(
                          base64String: _fotoPerfilBase64!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Color(0xFF86868B),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _pickFotoPerfil,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _pickFotoPerfil,
            child: const Text('Cambiar foto'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int? maxLines,
    int? maxLength,
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            required ? '$label *' : label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF86868B),
              letterSpacing: -0.08,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFC7C7CC)),
              prefixIcon: Icon(icon, color: const Color(0xFF86868B)),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE5E5EA)),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE5E5EA)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF007AFF), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            maxLines: maxLines ?? 1,
            maxLength: maxLength,
            keyboardType: keyboardType,
            validator:
                validator ??
                (value) {
                  if (required && (value == null || value.trim().isEmpty)) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF007AFF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Atrás'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: FilledButton(
              onPressed: _isLoading ? null : _nextStep,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF007AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _currentStep == 2
                          ? (_isEditing
                                ? 'Actualizar Organización'
                                : 'Crear Organización')
                          : 'Continuar',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
