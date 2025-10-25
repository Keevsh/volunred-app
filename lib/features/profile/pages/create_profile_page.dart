import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/models/dto/request_models.dart';
import '../../../core/repositories/auth_repository.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _disponibilidadController = TextEditingController();
  
  final List<String> _disponibilidadOptions = [
    'Lunes a Viernes',
    'Fines de semana',
    'Mañanas',
    'Tardes',
    'Noches',
    'Flexible',
  ];
  
  final Set<String> _selectedDisponibilidad = {};
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bioController.dispose();
    _disponibilidadController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authRepo = Modular.get<AuthRepository>();
    final usuario = await authRepo.getStoredUser();

    if (usuario == null) {
      _showSnackBar('Error: Usuario no encontrado');
      return;
    }

    final disponibilidad = _selectedDisponibilidad.isEmpty
        ? _disponibilidadController.text.trim()
        : _selectedDisponibilidad.join(', ');

    BlocProvider.of<ProfileBloc>(context).add(
      CreatePerfilRequested(
        CreatePerfilVoluntarioRequest(
          usuarioId: usuario.idUsuario,
          bio: _bioController.text.trim(),
          disponibilidad: disponibilidad.isEmpty ? null : disponibilidad,
          estado: 'activo',
        ),
      ),
    );
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is PerfilCreated) {
            _showSnackBar('¡Perfil creado exitosamente!', isError: false);
            Future.delayed(const Duration(milliseconds: 500), () {
              Modular.to.navigate('/profile/aptitudes');
            });
          } else if (state is ProfileError) {
            _showSnackBar(state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is ProfileLoading;

          return SafeArea(
            child: Column(
              children: [
                _buildHeader(colorScheme),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildFormContent(isLoading, colorScheme),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_add_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crear tu Perfil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Cuéntanos sobre ti',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildProgressIndicator(true, 'Perfil'),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 2, color: Colors.white38)),
              const SizedBox(width: 8),
              _buildProgressIndicator(false, 'Aptitudes'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(bool isActive, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white38,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              isActive ? Icons.edit : Icons.check,
              size: 14,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent(bool isLoading, ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📝 Biografía',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuéntanos quién eres y qué te motiva a ser voluntario',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              maxLines: 5,
              maxLength: 250,
              enabled: !isLoading,
              decoration: InputDecoration(
                hintText:
                    'Ej: Soy estudiante de ingeniería ambiental apasionado por la conservación...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                counterText: '${_bioController.text.length}/250',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 32),
            const Text(
              '🗓️ Disponibilidad',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona tus horarios disponibles o escribe uno personalizado',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _disponibilidadOptions.map((option) {
                final isSelected = _selectedDisponibilidad.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: isLoading
                      ? null
                      : (selected) {
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
                          : Colors.grey[300]!,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('O escribe tu disponibilidad'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _disponibilidadController,
              enabled: !isLoading,
              decoration: InputDecoration(
                hintText: 'Ej: Tardes entre semana',
                prefixIcon: const Icon(Icons.schedule_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tu perfil será visible para organizaciones que busquen voluntarios.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _handleCreateProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        Modular.to.navigate('/profile/aptitudes');
                      },
                child: const Text('Omitir por ahora'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
