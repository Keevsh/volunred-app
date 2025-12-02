import 'package:equatable/equatable.dart';

class PerfilFuncionario extends Equatable {
  final int idPerfilFuncionario;
  final int idUsuario;
  final int idOrganizacion;
  final String? cargo;
  final String?
  area; // Campo requerido por la API (anteriormente era 'departamento')
  final String? departamento; // Mantenido para compatibilidad
  final DateTime? fechaIngreso; // Campo requerido por la API
  final String estado;
  final String? fotoPerfil; // Foto de perfil en formato base64
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  // Relaciones opcionales
  final Map<String, dynamic>? usuario;
  final Map<String, dynamic>? organizacion;

  const PerfilFuncionario({
    required this.idPerfilFuncionario,
    required this.idUsuario,
    required this.idOrganizacion,
    this.cargo,
    this.area,
    this.departamento,
    this.fechaIngreso,
    required this.estado,
    this.fotoPerfil,
    required this.creadoEn,
    this.actualizadoEn,
    this.usuario,
    this.organizacion,
  });

  factory PerfilFuncionario.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to safely get string value
      String? _getString(dynamic value) {
        if (value == null) return null;
        return value.toString();
      }

      // Helper function to safely get int value
      int _getInt(dynamic value, {int defaultValue = 0}) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        return int.tryParse(value.toString()) ?? defaultValue;
      }

      // Handle creado_en - might be missing
      DateTime creadoEn;
      final creadoEnValue = json['creado_en'];
      if (creadoEnValue != null && creadoEnValue is String) {
        try {
          creadoEn = DateTime.parse(creadoEnValue);
        } catch (e) {
          creadoEn = DateTime.now();
        }
      } else {
        creadoEn = DateTime.now();
      }

      // Handle actualizado_en
      DateTime? actualizadoEn;
      final actualizadoEnValue = json['actualizado_en'];
      if (actualizadoEnValue != null && actualizadoEnValue is String) {
        try {
          actualizadoEn = DateTime.parse(actualizadoEnValue);
        } catch (e) {
          actualizadoEn = null;
        }
      }

      // Handle fecha_ingreso
      DateTime? fechaIngreso;
      final fechaIngresoValue = json['fecha_ingreso'];
      if (fechaIngresoValue != null && fechaIngresoValue is String) {
        try {
          fechaIngreso = DateTime.parse(fechaIngresoValue);
        } catch (e) {
          fechaIngreso = null;
        }
      }

      // Safely parse id_perfil_funcionario (puede venir como id_perfil_funcionario o id_funcionario)
      final idPerfilValue =
          json['id_perfil_funcionario'] ?? json['id_funcionario'];
      if (idPerfilValue == null) {
        throw Exception(
          'id_perfil_funcionario or id_funcionario is required but was null',
        );
      }
      final idPerfil = _getInt(idPerfilValue);
      if (idPerfil == 0) {
        throw Exception('id_perfil_funcionario cannot be 0');
      }

      // Safely parse id_usuario (puede venir como id_usuario o usuario_id)
      final idUsuarioValue = json['id_usuario'] ?? json['usuario_id'];
      if (idUsuarioValue == null) {
        throw Exception('id_usuario or usuario_id is required but was null');
      }
      final idUsuario = _getInt(idUsuarioValue);
      if (idUsuario == 0) {
        throw Exception('id_usuario cannot be 0');
      }

      // Safely parse id_organizacion (puede venir como id_organizacion o organizacion_id)
      final idOrgValue = json['id_organizacion'] ?? json['organizacion_id'];
      if (idOrgValue == null) {
        throw Exception(
          'id_organizacion or organizacion_id is required but was null',
        );
      }
      final idOrg = _getInt(idOrgValue);
      if (idOrg == 0) {
        throw Exception('id_organizacion cannot be 0');
      }

      // Obtener 'area' o 'departamento' (la API usa 'area')
      final areaValue =
          _getString(json['area']) ?? _getString(json['departamento']);

      // Manejar estado: puede venir como string ('activo', 'inactivo'), boolean (true/false) o número (1, 0)
      String estadoValue = 'activo';
      final estadoJson = json['estado'];
      if (estadoJson != null) {
        if (estadoJson is String) {
          estadoValue = estadoJson;
        } else if (estadoJson is bool) {
          // Si es boolean, true = activo, false = inactivo
          estadoValue = estadoJson ? 'activo' : 'inactivo';
        } else if (estadoJson is int) {
          // Si es número, 1 = activo, 0 = inactivo
          estadoValue = estadoJson == 1 ? 'activo' : 'inactivo';
        } else {
          estadoValue = estadoJson.toString();
        }
      }

      return PerfilFuncionario(
        idPerfilFuncionario: idPerfil,
        idUsuario: idUsuario,
        idOrganizacion: idOrg,
        cargo: _getString(json['cargo']),
        area: areaValue,
        departamento: _getString(
          json['departamento'],
        ), // Mantenido para compatibilidad
        fechaIngreso: fechaIngreso,
        estado: estadoValue,
        fotoPerfil: _getString(json['foto_perfil']),
        creadoEn: creadoEn,
        actualizadoEn: actualizadoEn,
        usuario: json['usuario'] is Map
            ? json['usuario'] as Map<String, dynamic>?
            : null,
        organizacion: json['organizacion'] is Map
            ? json['organizacion'] as Map<String, dynamic>?
            : null,
      );
    } catch (e, stackTrace) {
      throw Exception(
        'Error parsing PerfilFuncionario from JSON: $e\nJSON: $json\nStackTrace: $stackTrace',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id_perfil_funcionario': idPerfilFuncionario,
      'id_usuario': idUsuario,
      'id_organizacion': idOrganizacion,
      if (cargo != null) 'cargo': cargo,
      if (area != null) 'area': area, // La API espera 'area'
      if (departamento != null && area == null)
        'departamento': departamento, // Solo si no hay 'area'
      if (fechaIngreso != null)
        'fecha_ingreso': fechaIngreso!.toUtc().toIso8601String().replaceAll(
          RegExp(r'\.\d+'),
          '',
        ),
      'estado': estado,
      if (fotoPerfil != null) 'foto_perfil': fotoPerfil,
      'creado_en': creadoEn.toIso8601String(),
      if (actualizadoEn != null)
        'actualizado_en': actualizadoEn!.toIso8601String(),
      if (usuario != null) 'usuario': usuario,
      if (organizacion != null) 'organizacion': organizacion,
    };
  }

  @override
  List<Object?> get props => [
    idPerfilFuncionario,
    idUsuario,
    idOrganizacion,
    cargo,
    area,
    departamento,
    fechaIngreso,
    estado,
    fotoPerfil,
    creadoEn,
    actualizadoEn,
  ];
}
