import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/programa.dart';
import '../../../core/models/aplicacion.dart';
import '../../../core/models/modulo.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class ProgramasManagementPage extends StatefulWidget {
  const ProgramasManagementPage({super.key});

  @override
  State<ProgramasManagementPage> createState() => _ProgramasManagementPageState();
}

class _ProgramasManagementPageState extends State<ProgramasManagementPage> {
  String _selectedView = 'programas'; // 'programas', 'aplicaciones', 'modulos'
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _loadData() {
    final bloc = BlocProvider.of<AdminBloc>(context);
    if (_selectedView == 'programas') {
      bloc.add(LoadProgramasRequested());
    } else if (_selectedView == 'aplicaciones') {
      bloc.add(LoadAplicacionesRequested());
    } else {
      bloc.add(LoadModulosRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header simple estilo Apple
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF1D1D1F),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Programas',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: _loadData,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF1D1D1F),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tabs de selección
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildTabButton('Programas', 'programas'),
                    _buildTabButton('Aplicaciones', 'aplicaciones'),
                    _buildTabButton('Módulos', 'modulos'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Contenido dinámico según la pestaña
            Expanded(
              child: BlocBuilder<AdminBloc, AdminState>(
                builder: (context, state) {
                  if (state is AdminLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (_selectedView == 'programas' && state is ProgramasLoaded) {
                    return _buildProgramasList(state.programas);
                  }
                  
                  if (_selectedView == 'aplicaciones' && state is AplicacionesLoaded) {
                    return _buildAplicacionesList(state.aplicaciones);
                  }
                  
                  if (_selectedView == 'modulos' && state is ModulosLoaded) {
                    return _buildModulosList(state.modulos);
                  }
                  
                  return _buildEmptyState();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTabButton(String label, String value) {
    final isSelected = _selectedView == value;
    return Expanded(
      child: Material(
        color: isSelected ? const Color(0xFF5856D6) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedView = value;
            });
            _loadData();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF86868B),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildProgramasList(List<Programa> programas) {
    if (programas.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: programas.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final programa = programas[index];
        return _buildProgramaCard(programa);
      },
    );
  }
  
  Widget _buildProgramaCard(Programa programa) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF5856D6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.extension_rounded,
                color: Color(0xFF5856D6),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    programa.nombre,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (programa.descripcion != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      programa.descripcion!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF86868B),
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAplicacionesList(List<Aplicacion> aplicaciones) {
    if (aplicaciones.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: aplicaciones.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final aplicacion = aplicaciones[index];
        return _buildAplicacionCard(aplicacion);
      },
    );
  }
  
  Widget _buildAplicacionCard(Aplicacion aplicacion) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.widgets_rounded,
                color: Color(0xFF007AFF),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aplicacion.nombre,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    aplicacion.modulo?.nombre ?? 'Sin módulo',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF86868B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: aplicacion.estado == 'activo' 
                    ? const Color(0xFF34C759).withOpacity(0.1)
                    : const Color(0xFF8E8E93).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                aplicacion.estado == 'activo' ? 'Activo' : 'Inactivo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: aplicacion.estado == 'activo' 
                      ? const Color(0xFF34C759) 
                      : const Color(0xFF8E8E93),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildModulosList(List<Modulo> modulos) {
    if (modulos.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: modulos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final modulo = modulos[index];
        return _buildModuloCard(modulo);
      },
    );
  }
  
  Widget _buildModuloCard(Modulo modulo) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.dashboard_rounded,
                color: Color(0xFF34C759),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modulo.nombre,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1D1F),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${modulo.idModulo}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF86868B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: modulo.estado == 'activo' 
                    ? const Color(0xFF34C759).withOpacity(0.1)
                    : const Color(0xFF8E8E93).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                modulo.estado == 'activo' ? 'Activo' : 'Inactivo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: modulo.estado == 'activo' 
                      ? const Color(0xFF34C759) 
                      : const Color(0xFF8E8E93),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF5856D6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.apps_rounded,
              size: 64,
              color: Color(0xFF5856D6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay elementos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los elementos aparecerán aquí',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }
}
