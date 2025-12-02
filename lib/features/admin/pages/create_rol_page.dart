import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class CreateRolPage extends StatefulWidget {
  const CreateRolPage({super.key});

  @override
  State<CreateRolPage> createState() => _CreateRolPageState();
}

class _CreateRolPageState extends State<CreateRolPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final nombre = _nombreController.text.trim();
    final descripcion = _descripcionController.text.trim();

    context.read<AdminBloc>().add(
      CreateRolRequested(
        nombre: nombre,
        descripcion: descripcion.isEmpty ? null : descripcion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is RolCreated) {
          Navigator.of(context).pop(true); // Retornar true para indicar éxito
        } else if (state is AdminError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF007AFF),
                    ),
                    const Expanded(
                      child: Text(
                        'Nuevo Rol',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        disabledBackgroundColor: const Color(0xFFE5E5EA),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Crear'),
                    ),
                  ],
                ),
              ),
              // Formulario
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre del rol
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'NOMBRE DEL ROL',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF86868B),
                                  letterSpacing: -0.08,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _nombreController,
                                decoration: const InputDecoration(
                                  hintText: 'admin, coordinador, voluntario',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFC7C7CC),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    borderSide: BorderSide(
                                      color: Color(0xFFE5E5EA),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    borderSide: BorderSide(
                                      color: Color(0xFFE5E5EA),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    borderSide: BorderSide(
                                      color: Color(0xFF007AFF),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                textCapitalization: TextCapitalization.none,
                                autocorrect: false,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'El nombre es obligatorio';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'Mínimo 3 caracteres';
                                  }
                                  if (value.trim().length > 50) {
                                    return 'Máximo 50 caracteres';
                                  }
                                  if (!RegExp(
                                    r'^[a-z0-9_]+$',
                                  ).hasMatch(value.trim())) {
                                    return 'Solo minúsculas, números y guiones bajos';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Solo letras minúsculas, números y guiones bajos',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF86868B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Descripción
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DESCRIPCIÓN (OPCIONAL)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF86868B),
                                  letterSpacing: -0.08,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _descripcionController,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Describe las funciones de este rol',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFC7C7CC),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    borderSide: BorderSide(
                                      color: Color(0xFFE5E5EA),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    borderSide: BorderSide(
                                      color: Color(0xFFE5E5EA),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    borderSide: BorderSide(
                                      color: Color(0xFF007AFF),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                maxLines: 4,
                                maxLength: 200,
                                validator: (value) {
                                  if (value != null &&
                                      value.trim().length > 200) {
                                    return 'Máximo 200 caracteres';
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
