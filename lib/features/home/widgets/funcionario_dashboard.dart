import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../../../core/repositories/funcionario_repository.dart';
import '../../../core/models/organizacion.dart';
import '../../../core/models/proyecto.dart';
import '../../../core/models/inscripcion.dart';
import '../../../core/widgets/image_base64_widget.dart';
import 'package:intl/intl.dart';

class FuncionarioDashboard extends StatefulWidget {
  const FuncionarioDashboard({super.key});

  @override
  State<FuncionarioDashboard> createState() => _FuncionarioDashboardState();
}

class _FuncionarioDashboardState extends State<FuncionarioDashboard> {
  final FuncionarioRepository _repository = Modular.get<FuncionarioRepository>();

  Organizacion? _organizacion;
  List<Proyecto> _proyectos = [];
  List<Inscripcion> _inscripciones = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final org = await _repository.getMiOrganizacion();
      final proyectos = await _repository.getProyectos();
      final inscripciones = await _repository.getInscripcionesPendientes();

      setState(() {
        _organizacion = org;
        _proyectos = proyectos;
        _inscripciones = inscripciones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFF8F9FA),
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Header con saludo y perfil
            _buildWelcomeHeader(theme),

            // Tarjeta de organización
            SliverToBoxAdapter(
              child: _buildOrganizacionCard(theme),
            ),

            // Estadísticas rápidas
            SliverToBoxAdapter(
              child: _buildQuickStats(theme),
            ),

            // Botón de acción principal
            SliverToBoxAdapter(
              child: _buildPrimaryAction(theme),
            ),

            // Proyectos destacados
            _buildFeaturedProjects(theme),

            // Solicitudes pendientes
            if (_inscripciones.isNotEmpty) _buildPendingRequests(theme),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola 👋',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  _organizacion?.nombre ?? 'Organización',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            if (_inscripciones.isNotEmpty)
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF1976D2),
                      size: 24,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5252),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _inscripciones.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizacionCard(ThemeData theme) {
    if (_organizacion == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner superior
          Container(
            height: 100,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          // Contenido
          Transform.translate(
            offset: const Offset(0, -30),
            child: Column(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child: (_organizacion!.logo != null && _organizacion!.logo!.isNotEmpty)
                          ? ImageBase64Widget(
                              base64String: _organizacion!.logo!,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                                ),
                              ),
                              child: const Icon(
                                Icons.apartment_rounded,
                                size: 35,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Nombre
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _organizacion!.nombre,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                // Badge activo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Activa',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Info chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (_organizacion!.direccion != null && _organizacion!.direccion!.isNotEmpty)
                        _buildInfoChip(Icons.location_on_outlined, _organizacion!.direccion!),
                      if (_organizacion!.email != null && _organizacion!.email!.isNotEmpty)
                        _buildInfoChip(Icons.email_outlined, _organizacion!.email!),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF757575)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF424242),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    final proyectosActivos = _proyectos.where((p) => p.estado == 'activo').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Proyectos',
              proyectosActivos.toString(),
              Icons.folder_open_rounded,
              const Color(0xFF1976D2),
              const Color(0xFFE3F2FD),
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Solicitudes',
              _inscripciones.length.toString(),
              Icons.inbox_rounded,
              _inscripciones.isNotEmpty ? const Color(0xFFFF5252) : const Color(0xFF4CAF50),
              _inscripciones.isNotEmpty ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color bgColor,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: const Color(0xFF1976D2),
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: () => Modular.to.pushNamed('/proyectos/create'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_circle_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Crear Nuevo Proyecto',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedProjects(ThemeData theme) {
    if (_proyectos.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  size: 48,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay proyectos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crea tu primer proyecto para comenzar',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF9E9E9E),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Proyectos Destacados',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navegar a todos los proyectos
                  },
                  child: const Text('Ver todos'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 240,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _proyectos.length > 5 ? 5 : _proyectos.length,
              itemBuilder: (context, index) {
                return _buildProyectoCard(_proyectos[index], theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProyectoCard(Proyecto proyecto, ThemeData theme) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Modular.to.pushNamed('/proyectos/${proyecto.idProyecto}'),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen
              Stack(
                children: [
                  if (proyecto.imagen != null && proyecto.imagen!.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: ImageBase64Widget(
                        base64String: proyecto.imagen!,
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 140,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.folder_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  // Badge de estado
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: proyecto.estado == 'activo'
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF9E9E9E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        proyecto.estado.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Contenido
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proyecto.nombre,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (proyecto.fechaFin != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Color(0xFF757575),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy').format(proyecto.fechaFin!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingRequests(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Text(
                  'Solicitudes Pendientes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _inscripciones.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: _inscripciones
                  .take(3)
                  .map((inscripcion) => _buildInscripcionCard(inscripcion, theme))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInscripcionCard(Inscripcion inscripcion, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3F2FD), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nueva solicitud',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Solicitud #${inscripcion.idInscripcion}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF4CAF50),
              ),
              iconSize: 24,
              onPressed: () async {
                try {
                  await _repository.aprobarInscripcion(inscripcion.idInscripcion);
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Solicitud aprobada')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.cancel_rounded,
                color: Color(0xFFFF5252),
              ),
              iconSize: 24,
              onPressed: () async {
                try {
                  await _repository.rechazarInscripcion(
                    inscripcion.idInscripcion,
                    'Rechazado desde dashboard',
                  );
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Solicitud rechazada')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
