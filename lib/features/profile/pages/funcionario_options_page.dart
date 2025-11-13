import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/funcionario_repository.dart';

class FuncionarioOptionsPage extends StatefulWidget {
  const FuncionarioOptionsPage({super.key});

  @override
  State<FuncionarioOptionsPage> createState() => _FuncionarioOptionsPageState();
}

class _FuncionarioOptionsPageState extends State<FuncionarioOptionsPage> {
  bool _isLoading = false;

  Future<void> _checkExistingOrganization() async {
    setState(() => _isLoading = true);
    try {
      final funcionarioRepo = Modular.get<FuncionarioRepository>();
      final organizacion = await funcionarioRepo.getMiOrganizacion();
      
      if (mounted) {
        // Ya tiene organización, ir a crear perfil
        Modular.to.navigate('/profile/create-organizacion');
      }
    } catch (e) {
      // No tiene organización, mostrar opciones
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkExistingOrganization();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configura tu cuenta de funcionario',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Selecciona la opción que mejor se adapte a tu situación',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF86868B),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildOptionCard(
                      context,
                      title: 'Ya tengo una organización',
                      description: 'Si tu organización ya está registrada en la plataforma, puedes unirte a ella',
                      icon: Icons.business,
                      color: const Color(0xFF34C759),
                      onTap: () {
                        // TODO: Implementar búsqueda y unión a organización existente
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Funcionalidad en desarrollo. Por ahora, solicita una nueva organización.'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildOptionCard(
                      context,
                      title: 'Solicitar cuenta de organización',
                      description: 'Crea una nueva organización y gestiona tus propios proyectos de voluntariado',
                      icon: Icons.add_business,
                      color: const Color(0xFF007AFF),
                      onTap: () {
                        Modular.to.navigate('/profile/create-organizacion');
                      },
                    ),
                    const SizedBox(height: 32),
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
                          Icon(
                            Icons.info_outline,
                            color: const Color(0xFF007AFF),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Como funcionario podrás crear proyectos, gestionar voluntarios y generar reportes de impacto.',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Modular.to.navigate('/home/'),
            icon: const Icon(Icons.arrow_back_rounded),
            color: const Color(0xFF007AFF),
          ),
          const Expanded(
            child: Text(
              'Configuración de Funcionario',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF86868B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
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

