import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/models/bitacora_operacion.dart';
import '../../../core/models/bitacora_autor.dart';
import '../../../core/theme/app_widgets.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class BitacorasManagementPage extends StatefulWidget {
  final bool embedded;

  const BitacorasManagementPage({super.key, this.embedded = false});

  @override
  State<BitacorasManagementPage> createState() =>
      _BitacorasManagementPageState();
}

class _BitacorasManagementPageState extends State<BitacorasManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  List<BitacoraOperacion> _bitacorasOperaciones = [];
  List<BitacoraAutor> _bitacorasAutores = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    BlocProvider.of<AdminBloc>(context).add(LoadBitacorasOperacionesRequested());
    BlocProvider.of<AdminBloc>(context).add(LoadBitacorasAutoresRequested());
  }

  List<BitacoraOperacion> _getFilteredOperaciones() {
    if (_searchController.text.isEmpty) return _bitacorasOperaciones;
    final searchLower = _searchController.text.toLowerCase();
    return _bitacorasOperaciones.where((b) {
      return b.comentario.toLowerCase().contains(searchLower) ||
          b.nombreUsuario.toLowerCase().contains(searchLower);
    }).toList();
  }

  List<BitacoraAutor> _getFilteredAutores() {
    if (_searchController.text.isEmpty) return _bitacorasAutores;
    final searchLower = _searchController.text.toLowerCase();
    return _bitacorasAutores.where((b) {
      return b.comentario.toLowerCase().contains(searchLower) ||
          b.nombreUsuario.toLowerCase().contains(searchLower);
    }).toList();
  }

  void _showDeleteConfirmDialog({
    required String tipo,
    required int id,
    required String comentario,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de eliminar esta bitácora?\n\n"$comentario"\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tipo == 'operacion') {
                BlocProvider.of<AdminBloc>(context)
                    .add(DeleteBitacoraOperacionRequested(id));
              } else {
                BlocProvider.of<AdminBloc>(context)
                    .add(DeleteBitacoraAutorRequested(id));
              }
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(dynamic bitacora) {
    final isOperacion = bitacora is BitacoraOperacion;
    final id = isOperacion ? bitacora.idOperaciones : (bitacora as BitacoraAutor).idAutores;
    final comentario = bitacora.comentario;
    final estado = bitacora.estado;
    final creadoEn = bitacora.creadoEn;
    final nombreUsuario = bitacora.nombreUsuario;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isOperacion ? 'Bitácora de Operación #$id' : 'Bitácora de Autor #$id'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Usuario', nombreUsuario),
              const SizedBox(height: 12),
              _buildDetailRow('Comentario', comentario),
              const SizedBox(height: 12),
              _buildDetailRow('Estado', estado),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Fecha',
                DateFormat('dd/MM/yyyy HH:mm').format(creadoEn),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF86868B),
            fontWeight: FontWeight.w500,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: BlocConsumer<AdminBloc, AdminState>(
          listener: (context, state) {
            if (state is BitacoraOperacionDeleted ||
                state is BitacoraAutorDeleted) {
              AppWidgets.showStyledSnackBar(
                context: context,
                message: 'Bitácora eliminada correctamente',
                isError: false,
              );
              _loadData();
            } else if (state is AdminError) {
              AppWidgets.showStyledSnackBar(
                context: context,
                message: state.message,
                isError: true,
              );
            }
          },
          builder: (context, state) {
            if (state is BitacorasOperacionesLoaded) {
              _bitacorasOperaciones = state.bitacoras;
            }
            if (state is BitacorasAutoresLoaded) {
              _bitacorasAutores = state.bitacoras;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                if (!widget.embedded)
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
                            'Bitácoras',
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

                // Barra de búsqueda
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE5E5EA),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar en bitácoras...',
                        hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF8E8E93),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: Color(0xFF8E8E93),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF007AFF),
                    unselectedLabelColor: const Color(0xFF8E8E93),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.settings_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text('Operaciones (${_bitacorasOperaciones.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text('Autores (${_bitacorasAutores.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Content
                Expanded(
                  child: state is AdminLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOperacionesList(),
                            _buildAutoresList(),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOperacionesList() {
    final filtered = _getFilteredOperaciones();
    if (filtered.isEmpty) {
      return _buildEmptyState('operaciones');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bitacora = filtered[index];
        return _buildBitacoraCard(
          id: bitacora.idOperaciones,
          tipo: 'operacion',
          comentario: bitacora.comentario,
          estado: bitacora.estado,
          creadoEn: bitacora.creadoEn,
          nombreUsuario: bitacora.nombreUsuario,
          onTap: () => _showDetailDialog(bitacora),
          onDelete: () => _showDeleteConfirmDialog(
            tipo: 'operacion',
            id: bitacora.idOperaciones,
            comentario: bitacora.comentario,
          ),
        );
      },
    );
  }

  Widget _buildAutoresList() {
    final filtered = _getFilteredAutores();
    if (filtered.isEmpty) {
      return _buildEmptyState('autores');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bitacora = filtered[index];
        return _buildBitacoraCard(
          id: bitacora.idAutores,
          tipo: 'autor',
          comentario: bitacora.comentario,
          estado: bitacora.estado,
          creadoEn: bitacora.creadoEn,
          nombreUsuario: bitacora.nombreUsuario,
          onTap: () => _showDetailDialog(bitacora),
          onDelete: () => _showDeleteConfirmDialog(
            tipo: 'autor',
            id: bitacora.idAutores,
            comentario: bitacora.comentario,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String tipo) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 64,
              color: Color(0xFF007AFF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay bitácoras de $tipo',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Las acciones del sistema se registrarán aquí',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBitacoraCard({
    required int id,
    required String tipo,
    required String comentario,
    required String estado,
    required DateTime creadoEn,
    required String nombreUsuario,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    final estadoColor = estado == 'activo'
        ? const Color(0xFF34C759)
        : const Color(0xFF8E8E93);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  tipo == 'operacion'
                      ? Icons.settings_rounded
                      : Icons.person_rounded,
                  color: const Color(0xFF007AFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comentario,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1D1F),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: const Color(0xFF86868B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            nombreUsuario,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF86868B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(creadoEn),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF86868B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Badge de estado
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: estadoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  estado,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: estadoColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Botón eliminar
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFFF3B30),
                  size: 20,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
