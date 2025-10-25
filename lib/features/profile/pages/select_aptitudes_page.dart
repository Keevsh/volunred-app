import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/models/aptitud.dart';
import '../../../core/repositories/voluntario_repository.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class SelectAptitudesPage extends StatefulWidget {
  const SelectAptitudesPage({super.key});

  @override
  State<SelectAptitudesPage> createState() => _SelectAptitudesPageState();
}

class _SelectAptitudesPageState extends State<SelectAptitudesPage> {
  final Set<int> _selectedAptitudes = {};

  @override
  void initState() {
    super.initState();
    // Cargar aptitudes al iniciar
    BlocProvider.of<ProfileBloc>(context).add(LoadAptitudesRequested());
  }

  Future<void> _handleAsignarAptitudes() async {
    if (_selectedAptitudes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una aptitud'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final voluntarioRepo = Modular.get<VoluntarioRepository>();
    final perfil = await voluntarioRepo.getStoredPerfil();

    if (perfil != null) {
      BlocProvider.of<ProfileBloc>(context).add(
        AsignarAptitudesRequested(
          perfil.idPerfilVoluntario,
          _selectedAptitudes.toList(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona tus Aptitudes'),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is AptitudesAsignadas) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            // Navegar a home
            Modular.to.navigate('/home/');
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AptitudesLoaded) {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: state.aptitudes.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final aptitud = state.aptitudes[index];
                      final isSelected =
                          _selectedAptitudes.contains(aptitud.idAptitud);

                      return _AptitudCard(
                        aptitud: aptitud,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedAptitudes.remove(aptitud.idAptitud);
                            } else {
                              _selectedAptitudes.add(aptitud.idAptitud);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '${_selectedAptitudes.length} aptitud(es) seleccionada(s)',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _handleAsignarAptitudes,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Guardar y Continuar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Modular.to.navigate('/home/');
                        },
                        child: const Text('Omitir por ahora'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return const Center(child: Text('Error al cargar aptitudes'));
        },
      ),
    );
  }
}

class _AptitudCard extends StatelessWidget {
  final Aptitud aptitud;
  final bool isSelected;
  final VoidCallback onTap;

  const _AptitudCard({
    required this.aptitud,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue[50] : null,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          aptitud.nombre,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: aptitud.descripcion != null
            ? Text(aptitud.descripcion!)
            : null,
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : const Icon(Icons.circle_outlined),
        onTap: onTap,
      ),
    );
  }
}
