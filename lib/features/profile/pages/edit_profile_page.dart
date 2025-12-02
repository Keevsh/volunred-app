import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/perfil_voluntario.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/image_base64_widget.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();

  final List<String> _disponibilidadOptions = [
    'Lunes a Viernes',
    'Fines de semana',
    'Mañanas',
    'Tardes',
    'Noches',
    'Flexible',
  ];

  final Set<String> _selectedDisponibilidad = {};

  bool _isLoading = true;
  bool _isSaving = false;
  PerfilVoluntario? _perfil;
  Map<String, dynamic>? _usuario;
  String? _fotoPerfilBase64;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final voluntarioRepo = Modular.get<VoluntarioRepository>();
      final authRepo = Modular.get<AuthRepository>();
      final usuario = await authRepo.getStoredUser();

      if (usuario != null) {
        final perfil = await voluntarioRepo.getPerfilByUsuario(
          usuario.idUsuario,
        );
        if (perfil != null && mounted) {
          setState(() {
            _perfil = perfil;
            _usuario = {
              'nombres': usuario.nombres,
              'apellidos': usuario.apellidos,
              'telefono': usuario.telefono?.toString() ?? '',
              'email': usuario.email,
            };
            _bioController.text = perfil.bio ?? '';
            _nombreController.text = usuario.nombres;
            _apellidoController.text = usuario.apellidos;
            _telefonoController.text = usuario.telefono?.toString() ?? '';
            _fotoPerfilBase64 = perfil.fotoPerfil;

            if (perfil.disponibilidad != null &&
                perfil.disponibilidad!.isNotEmpty) {
              final disponibilidadList = perfil.disponibilidad!
                  .split(',')
                  .map((e) => e.trim())
                  .toList();
              for (var disp in disponibilidadList) {
                if (_disponibilidadOptions.contains(disp)) {
                  _selectedDisponibilidad.add(disp);
                }
              }
            }
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          _showSnackBar('No se encontró el perfil');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error al cargar perfil: $e');
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final base64 = await ImageUtils.convertXFileToBase64(image);
        setState(() {
          _fotoPerfilBase64 = base64;
        });
      }
    } catch (e) {
      _showSnackBar('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_perfil == null) return;

    setState(() => _isSaving = true);

    try {
      final voluntarioRepo = Modular.get<VoluntarioRepository>();

      final disponibilidad = _selectedDisponibilidad.isEmpty
          ? null
          : _selectedDisponibilidad.join(', ');

      final datosActualizacion = <String, dynamic>{
        'bio': _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        'disponibilidad': disponibilidad,
      };

      if (_fotoPerfilBase64 != null && _fotoPerfilBase64!.isNotEmpty) {
        datosActualizacion['foto_perfil'] = _fotoPerfilBase64;
      }

      datosActualizacion.removeWhere((key, value) => value == null);

      await voluntarioRepo.updatePerfil(
        _perfil!.idPerfilVoluntario,
        datosActualizacion,
      );

      _showSnackBar('Perfil actualizado exitosamente', isError: false);

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) Modular.to.pop(true);
      });
    } catch (e) {
      _showSnackBar('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Guardar',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Foto de perfil
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.3),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child:
                                  _fotoPerfilBase64 != null &&
                                      _fotoPerfilBase64!.isNotEmpty
                                  ? ImageBase64Widget(
                                      base64String: _fotoPerfilBase64!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.person,
                                        size: 60,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _pickImage,
                        child: Text(
                          'Cambiar foto',
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sección: Información Personal
                    _buildSectionHeader(
                      'Información Personal',
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 16),

                    // Nombres (solo lectura)
                    _buildReadOnlyField(
                      label: 'Nombres',
                      value: _nombreController.text,
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),

                    // Apellidos (solo lectura)
                    _buildReadOnlyField(
                      label: 'Apellidos',
                      value: _apellidoController.text,
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),

                    // Email (solo lectura)
                    _buildReadOnlyField(
                      label: 'Email',
                      value: _usuario?['email'] ?? '',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 12),

                    // Teléfono (solo lectura)
                    _buildReadOnlyField(
                      label: 'Teléfono',
                      value: _telefonoController.text.isEmpty
                          ? 'No registrado'
                          : _telefonoController.text,
                      icon: Icons.phone_outlined,
                    ),

                    const SizedBox(height: 32),

                    // Sección: Sobre mí
                    _buildSectionHeader('Sobre mí', Icons.edit_note),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      maxLength: 250,
                      decoration: InputDecoration(
                        hintText:
                            'Cuéntanos sobre ti, tus intereses y motivaciones...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sección: Disponibilidad
                    _buildSectionHeader('Disponibilidad', Icons.schedule),
                    const SizedBox(height: 8),
                    Text(
                      'Selecciona los horarios en los que puedes participar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _disponibilidadOptions.map((option) {
                        final isSelected = _selectedDisponibilidad.contains(
                          option,
                        );
                        return FilterChip(
                          label: Text(option),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDisponibilidad.add(option);
                              } else {
                                _selectedDisponibilidad.remove(option);
                              }
                            });
                          },
                          selectedColor: colorScheme.primary.withOpacity(0.2),
                          checkmarkColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline.withOpacity(0.5),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 40),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Guardar Cambios',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Botón cancelar
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Modular.to.pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline,
            size: 16,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
