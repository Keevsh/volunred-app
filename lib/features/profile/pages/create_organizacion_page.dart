import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:volunred_app/core/models/perfil_funcionario.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/organizacion_repository.dart';
import '../../../core/theme/app_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCategorias();
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
      print('📋 Primera categoría: ${categorias.isNotEmpty ? categorias.first : "ninguna"}');
      
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
        break;
      case 1:
        isValid = _formKey2.currentState?.validate() ?? false;
        break;
      case 2:
        isValid = _formKey3.currentState?.validate() ?? false;
        if (isValid) {
          await _submitAll();
          return;
        }
        break;
    }

    if (isValid && _currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
      
      // Obtener usuario actual
      final usuario = await authRepo.getStoredUser();
      if (usuario == null) {
        throw Exception('Usuario no encontrado');
      }

      // 1. Crear organización
      // Mapear campos al formato esperado por la API
      // Nota: id_categoria_organizacion no se puede enviar en la creación, debe asignarse después con una actualización
      final orgData = {
        'nombre_legal': _razonSocialController.text.trim(), // Requerido: nombre legal de la organización
        if (_nombreOrgController.text.trim().isNotEmpty)
          'nombre_corto': _nombreOrgController.text.trim(), // Opcional: nombre común/corto
        'correo': _emailOrgController.text.trim(), // Requerido: correo electrónico
        if (_direccionController.text.trim().isNotEmpty)
          'direccion': _direccionController.text.trim(), // Opcional: dirección
        if (_telefonoOrgController.text.trim().isNotEmpty)
          'telefono': _telefonoOrgController.text.trim(), // Opcional: teléfono
        'estado': 'activo', // Estado por defecto
      };
      
      print('📦 Creando organización: $orgData');
      final organizacion = await orgRepo.createOrganizacion(orgData);
      print('✅ Organización creada: ${organizacion.nombre.isNotEmpty ? organizacion.nombre : organizacion.razonSocial ?? "Organización"}');
      
      // Nota: La categoría no se puede asignar durante la creación ni inmediatamente después
      // La categoría deberá ser asignada posteriormente por un administrador o mediante otro proceso
      if (_categoriaSeleccionada != null) {
        print('ℹ️ Categoría seleccionada: $_categoriaSeleccionada (se asignará posteriormente)');
      }

      // 2. Crear perfil de funcionario con todos los datos requeridos
      print('👤 Creando perfil de funcionario...');
      PerfilFuncionario? perfil;
      
      try {
        final perfilData = <String, dynamic>{
          'usuario_id': usuario.idUsuario, // Requerido por el backend
          'organizacion_id': organizacion.idOrganizacion, // Requerido por el backend
          'fecha_ingreso': DateTime.now().toIso8601String().split('T')[0], // Formato YYYY-MM-DD
          'estado': 'activo',
        };
        
        // Agregar cargo si se proporcionó
        if (_cargoController.text.trim().isNotEmpty) {
          perfilData['cargo'] = _cargoController.text.trim();
        }
        
        // Agregar area (departamento se mapea a area según la API)
        if (_departamentoController.text.trim().isNotEmpty) {
          perfilData['area'] = _departamentoController.text.trim();
        }
        
        print('📤 Datos del perfil de funcionario: $perfilData');
        
        perfil = await orgRepo.createPerfilFuncionario(perfilData);
        print('✅ Perfil de funcionario creado exitosamente: ${perfil.idPerfilFuncionario}');
      } catch (e) {
        print('⚠️ Error al crear perfil de funcionario: $e');
        // Intentar obtener el perfil si ya existe
        try {
          final perfilExistente = await orgRepo.getPerfilFuncionarioByUsuario(usuario.idUsuario);
          if (perfilExistente != null) {
            print('✅ Perfil de funcionario ya existe: ${perfilExistente.idPerfilFuncionario}');
            perfil = perfilExistente;
            
            // Actualizar con los datos nuevos si faltan
            final updateData = <String, dynamic>{};
            bool needsUpdate = false;
            
            if (_cargoController.text.trim().isNotEmpty && perfilExistente.cargo != _cargoController.text.trim()) {
              updateData['cargo'] = _cargoController.text.trim();
              needsUpdate = true;
            }
            if (_departamentoController.text.trim().isNotEmpty && 
                (perfilExistente.area != _departamentoController.text.trim() && 
                 perfilExistente.departamento != _departamentoController.text.trim())) {
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
              perfil = await orgRepo.updatePerfilFuncionario(perfilExistente.idPerfilFuncionario, updateData);
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
          message: '¡Organización creada exitosamente!',
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
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
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
          const Expanded(
            child: Text(
              'Solicitar Organización',
              style: TextStyle(
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
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF86868B),
              ),
            ),
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
              hint: 'Av. Principal 123, Ciudad',
              icon: Icons.location_on,
              required: true,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _telefonoOrgController,
              label: 'Teléfono',
              hint: '02-2345678',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _emailOrgController,
              label: 'Email de Contacto',
              hint: 'contacto@organizacion.org',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              required: true,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _sitioWebController,
              label: 'Sitio Web (opcional)',
              hint: 'https://organizacion.org',
              icon: Icons.language,
              keyboardType: TextInputType.url,
            ),
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
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF86868B),
              ),
            ),
            const SizedBox(height: 24),
            
            _buildTextField(
              controller: _rucController,
              label: 'RUC',
              hint: '1234567890001',
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
              hint: 'Fundación Ayuda Social',
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      hint: const Text('Selecciona una categoría'),
                      items: _categorias.map((cat) {
                        print('📋 Mapeando categoría: $cat');
                        return DropdownMenuItem<int>(
                          value: cat['id_categoria_org'] as int, // Corregido: era id_categoria_organizacion
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat['nombre'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (cat['descripcion'] != null)
                                Text(
                                  cat['descripcion'] as String,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF86868B)),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
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
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF86868B),
              ),
            ),
            const SizedBox(height: 24),
            
            _buildTextField(
              controller: _cargoController,
              label: 'Tu Cargo',
              hint: 'Ej: Director de Proyectos',
              icon: Icons.work,
              required: true,
            ),
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _departamentoController,
              label: 'Departamento',
              hint: 'Ej: Gestión de Voluntariado',
              icon: Icons.corporate_fare,
              required: true,
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF007AFF).withOpacity(0.3)),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            maxLines: maxLines ?? 1,
            maxLength: maxLength,
            keyboardType: keyboardType,
            validator: validator ?? (value) {
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
                  : Text(_currentStep == 2 ? 'Crear Organización' : 'Continuar'),
            ),
          ),
        ],
      ),
    );
  }
}
