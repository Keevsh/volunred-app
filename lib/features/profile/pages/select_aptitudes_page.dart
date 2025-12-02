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
    _loadAptitudes();
  }

  Future<void> _loadAptitudes() async {
    // Obtener el perfil del usuario para cargar sus aptitudes asignadas
    final voluntarioRepo = Modular.get<VoluntarioRepository>();
    final perfil = await voluntarioRepo.getStoredPerfil();

    // Cargar aptitudes disponibles y las ya asignadas si hay perfil
    BlocProvider.of<ProfileBloc>(
      context,
    ).add(LoadAptitudesRequested(perfilVolId: perfil?.idPerfilVoluntario));
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
      appBar: AppBar(title: const Text('Selecciona tus Aptitudes')),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is AptitudesAsignadas) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
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
            // Si hay aptitudes asignadas y el estado está vacío, inicializar con las asignadas
            if (_selectedAptitudes.isEmpty &&
                state.aptitudesAsignadas.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _selectedAptitudes.addAll(
                    state.aptitudesAsignadas.map((a) => a.idAptitud),
                  );
                });
              });
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: state.aptitudes.length + 1,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Selecciona las aptitudes que mejor describen tus habilidades. Esto ayudará a las organizaciones a conocerte mejor.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        );
                      }

                      final aptitud = state.aptitudes[index - 1];
                      final isSelected = _selectedAptitudes.contains(
                        aptitud.idAptitud,
                      );
                      // Verificar si esta aptitud está asignada al perfil
                      final isAssigned = state.aptitudesAsignadas.any(
                        (a) => a.idAptitud == aptitud.idAptitud,
                      );

                      return _AptitudCard(
                        aptitud: aptitud,
                        isSelected: isSelected,
                        isAssigned: isAssigned,
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
  final bool isAssigned;
  final VoidCallback onTap;

  const _AptitudCard({
    required this.aptitud,
    required this.isSelected,
    this.isAssigned = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color bgColor;
    Color borderColor;

    if (isSelected) {
      bgColor = colorScheme.primary.withOpacity(0.08);
      borderColor = colorScheme.primary;
    } else if (isAssigned) {
      bgColor = Colors.green.withOpacity(0.06);
      borderColor = Colors.green.withOpacity(0.4);
    } else {
      bgColor = Colors.white;
      borderColor = Colors.grey.withOpacity(0.2);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withOpacity(0.12)
                    : colorScheme.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          aptitud.nombre,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isAssigned && !isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Ya en tu perfil',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (aptitud.descripcion != null &&
                      aptitud.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      aptitud.descripcion!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : isAssigned
                  ? Icons.check_circle_outline_rounded
                  : Icons.circle_outlined,
              color: isSelected
                  ? colorScheme.primary
                  : isAssigned
                  ? Colors.green[700]
                  : colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
