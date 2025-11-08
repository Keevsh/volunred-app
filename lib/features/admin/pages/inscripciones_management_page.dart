import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/inscripcion.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class InscripcionesManagementPage extends StatefulWidget {
  const InscripcionesManagementPage({super.key});

  @override
  State<InscripcionesManagementPage> createState() => _InscripcionesManagementPageState();
}

class _InscripcionesManagementPageState extends State<InscripcionesManagementPage> {
  String _filtroEstado = 'todos'; // 'todos', 'activo', 'inactivo'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<AdminBloc>().add(LoadInscripcionesRequested());
  }

  List<Inscripcion> _filtrarInscripciones(List<Inscripcion> inscripciones) {
    if (_filtroEstado == 'todos') {
      return inscripciones;
    }
    return inscripciones.where((insc) => insc.estado == _filtroEstado).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: BlocListener<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is InscripcionUpdated || state is InscripcionDeleted) {
            _loadData();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state is InscripcionUpdated
                      ? 'Inscripción actualizada'
                      : 'Inscripción eliminada',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                        'Inscripciones',
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

              // Filtros
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
                      _buildFilterButton('Todos', 'todos'),
                      _buildFilterButton('Activas', 'activo'),
                      _buildFilterButton('Inactivas', 'inactivo'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Lista de inscripciones
              Expanded(
                child: BlocBuilder<AdminBloc, AdminState>(
                  builder: (context, state) {
                    if (state is AdminLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is InscripcionesLoaded) {
                      final inscripcionesFiltradas = _filtrarInscripciones(state.inscripciones);
                      if (inscripcionesFiltradas.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildInscripcionesList(inscripcionesFiltradas);
                    }
                    return _buildEmptyState();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _filtroEstado == value;
    return Expanded(
      child: Material(
        color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            setState(() {
              _filtroEstado = value;
            });
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

  Widget _buildInscripcionesList(List<Inscripcion> inscripciones) {
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: inscripciones.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final inscripcion = inscripciones[index];
          return _buildInscripcionCard(inscripcion);
        },
      ),
    );
  }

  Widget _buildInscripcionCard(Inscripcion inscripcion) {
    final usuarioNombre = inscripcion.usuario != null
        ? '${inscripcion.usuario!['nombres'] ?? ''} ${inscripcion.usuario!['apellidos'] ?? ''}'.trim()
        : 'Usuario #${inscripcion.usuarioId}';
    final usuarioEmail = inscripcion.usuario != null
        ? inscripcion.usuario!['email'] ?? ''
        : '';
    final organizacionNombre = inscripcion.organizacion != null
        ? inscripcion.organizacion!['nombre'] ?? 'Organización #${inscripcion.organizacionId}'
        : 'Organización #${inscripcion.organizacionId}';

    final fechaStr = '${inscripcion.fechaRecepcion.day}/${inscripcion.fechaRecepcion.month}/${inscripcion.fechaRecepcion.year}';

    Color estadoColor = const Color(0xFF86868B);
    String estadoTexto = inscripcion.estado;
    if (inscripcion.estado == 'activo') {
      estadoColor = const Color(0xFF34C759);
      estadoTexto = 'Aprobada';
    } else if (inscripcion.estado == 'inactivo') {
      estadoColor = Colors.red;
      estadoTexto = 'Rechazada';
    } else if (inscripcion.estado == 'pendiente') {
      estadoColor = Colors.orange;
      estadoTexto = 'Pendiente';
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showDetailsDialog(inscripcion),
        borderRadius: BorderRadius.circular(12),
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
                      color: const Color(0xFFFF9500).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Color(0xFFFF9500),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usuarioNombre,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D1D1F),
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (usuarioEmail.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            usuarioEmail,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF86868B),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          organizacionNombre,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF86868B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      estadoTexto,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: estadoColor,
                      ),
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF86868B)),
                    itemBuilder: (context) => [
                      if (inscripcion.estado == 'activo' || inscripcion.estado == 'pendiente')
                        const PopupMenuItem(
                          value: 'rechazar',
                          child: Row(
                            children: [
                              Icon(Icons.close_rounded, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Rechazar', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      if (inscripcion.estado == 'inactivo' || inscripcion.estado == 'pendiente')
                        const PopupMenuItem(
                          value: 'aprobar',
                          child: Row(
                            children: [
                              Icon(Icons.check_rounded, size: 20, color: Colors.green),
                              SizedBox(width: 12),
                              Text('Aprobar', style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'aprobar') {
                        _aprobarInscripcion(inscripcion);
                      } else if (value == 'rechazar') {
                        _rechazarInscripcion(inscripcion);
                      } else if (value == 'delete') {
                        _confirmDelete(inscripcion);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF86868B)),
                        const SizedBox(width: 4),
                        Text(
                          'Recibida: $fechaStr',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF86868B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (inscripcion.motivoRechazo != null && inscripcion.motivoRechazo!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Motivo: ${inscripcion.motivoRechazo}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
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
              color: const Color(0xFFFF9500).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add_rounded,
              size: 64,
              color: Color(0xFFFF9500),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay inscripciones',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Las inscripciones aparecerán aquí',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }

  void _aprobarInscripcion(Inscripcion inscripcion) {
    context.read<AdminBloc>().add(
          UpdateInscripcionRequested(
            id: inscripcion.idInscripcion,
            estado: 'activo',
            motivoRechazo: null,
          ),
        );
  }

  void _rechazarInscripcion(Inscripcion inscripcion) {
    final motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Inscripción'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingrese el motivo del rechazo:'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (motivoController.text.isNotEmpty) {
                context.read<AdminBloc>().add(
                      UpdateInscripcionRequested(
                        id: inscripcion.idInscripcion,
                        estado: 'inactivo',
                        motivoRechazo: motivoController.text,
                      ),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(Inscripcion inscripcion) {
    final usuarioNombre = inscripcion.usuario != null
        ? '${inscripcion.usuario!['nombres'] ?? ''} ${inscripcion.usuario!['apellidos'] ?? ''}'.trim()
        : 'Usuario #${inscripcion.usuarioId}';
    final usuarioEmail = inscripcion.usuario != null
        ? inscripcion.usuario!['email'] ?? ''
        : '';
    final organizacionNombre = inscripcion.organizacion != null
        ? inscripcion.organizacion!['nombre'] ?? 'Organización #${inscripcion.organizacionId}'
        : 'Organización #${inscripcion.organizacionId}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de Inscripción'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Usuario', usuarioNombre),
              if (usuarioEmail.isNotEmpty) _buildDetailRow('Email', usuarioEmail),
              _buildDetailRow('Organización', organizacionNombre),
              _buildDetailRow(
                'Fecha Recepción',
                '${inscripcion.fechaRecepcion.day}/${inscripcion.fechaRecepcion.month}/${inscripcion.fechaRecepcion.year}',
              ),
              _buildDetailRow('Estado', inscripcion.estado),
              if (inscripcion.motivoRechazo != null && inscripcion.motivoRechazo!.isNotEmpty)
                _buildDetailRow('Motivo Rechazo', inscripcion.motivoRechazo!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1D1D1F),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Inscripcion inscripcion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Inscripción'),
        content: const Text('¿Está seguro que desea eliminar esta inscripción?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<AdminBloc>().add(DeleteInscripcionRequested(inscripcion.idInscripcion));
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

