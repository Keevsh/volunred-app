import 'dart:convert';
import '../models/participacion.dart';

/// Utility para imprimir datos de participaciones de forma legible
class ParticipationLogger {
  /// Imprime una lista de participaciones de forma formateada
  static void printParticipaciones(List<Participacion> participaciones) {
    print('\n');
    print('╔════════════════════════════════════════════════════════════╗');
    print('║           📊 PARTICIPACIONES DEL BACKEND                   ║');
    print('╠════════════════════════════════════════════════════════════╣');
    print('║ Total de participaciones: ${participaciones.length}');
    print('╠════════════════════════════════════════════════════════════╣');

    for (int i = 0; i < participaciones.length; i++) {
      final p = participaciones[i];
      print('║');
      print('║ ┌─ Participación #${i + 1} ─────────────────────────────');
      print('║ │ ID: ${p.idParticipacion}');
      print('║ │ Estado: ${p.estado}');
      print('║ │ Proyecto ID: ${p.proyectoId}');
      if (p.inscripcionId != null) {
        print('║ │ Inscripción ID: ${p.inscripcionId}');
      }
      if (p.perfilVolId != null) {
        print('║ │ Perfil Voluntario ID: ${p.perfilVolId}');
      }
      if (p.usuarioId != null) {
        print('║ │ Usuario ID: ${p.usuarioId}');
      }
      if (p.rolAsignado != null) {
        print('║ │ Rol Asignado: ${p.rolAsignado}');
      }
      if (p.horasComprometidasSemana != null) {
        print('║ │ Horas/Semana: ${p.horasComprometidasSemana}');
      }
      print('║ │ Creado: ${p.creadoEn}');
      if (p.actualizadoEn != null) {
        print('║ │ Actualizado: ${p.actualizadoEn}');
      }

      // Mostrar datos de la inscripción si están disponibles
      if (p.inscripcion != null) {
        print('║ │');
        print('║ │ 📋 Datos de Inscripción:');
        _printMapIndented(p.inscripcion!, 4);
      }

      // Mostrar datos del proyecto si están disponibles
      if (p.proyecto != null) {
        print('║ │');
        print('║ │ 🎯 Datos del Proyecto:');
        _printMapIndented(p.proyecto!, 4);
      }

      print('║ └────────────────────────────────────────────────');
    }

    print('║');
    print('╚════════════════════════════════════════════════════════════╝\n');
  }

  /// Imprime un mapa de forma indentada
  static void _printMapIndented(
    Map<String, dynamic> map,
    int indent, [
    int maxDepth = 5,
    int currentDepth = 0,
  ]) {
    if (currentDepth >= maxDepth) {
      print('║ │${' ' * indent}[Máxima profundidad alcanzada]');
      return;
    }

    final indentStr = ' ' * indent;
    map.forEach((key, value) {
      if (value == null) {
        print('║ │${indentStr}$key: null');
      } else if (value is String) {
        // Filtrar base64 largo
        if (value.length > 100 && value.contains('base64')) {
          print('║ │${indentStr}$key: [BASE64 IMAGE - ${value.length} chars]');
        } else if (value.length > 200) {
          print('║ │${indentStr}$key: "${value.substring(0, 197)}..."');
        } else {
          print('║ │${indentStr}$key: "$value"');
        }
      } else if (value is int) {
        print('║ │${indentStr}$key: $value');
      } else if (value is double) {
        print('║ │${indentStr}$key: $value');
      } else if (value is bool) {
        print('║ │${indentStr}$key: $value');
      } else if (value is List) {
        if (value.isEmpty) {
          print('║ │${indentStr}$key: []');
        } else {
          print('║ │${indentStr}$key: [${value.length} items]');
          if (value[0] is Map) {
            for (int i = 0; i < value.length && i < 5; i++) {
              print('║ │${indentStr}  [$i]:');
              _printMapIndented(value[i] as Map<String, dynamic>, indent + 4,
                  maxDepth, currentDepth + 1);
            }
            if (value.length > 5) {
              print('║ │${indentStr}  ... y ${value.length - 5} elementos más');
            }
          } else {
            // Lista simple (strings, ints, etc)
            final preview = value.take(10).join(', ');
            if (value.length > 10) {
              print('║ │${indentStr}  $preview... y ${value.length - 10} más');
            } else {
              print('║ │${indentStr}  $preview');
            }
          }
        }
      } else if (value is Map) {
        print('║ │${indentStr}$key: {');
        _printMapIndented(value.cast<String, dynamic>(), indent + 2, maxDepth,
            currentDepth + 1);
        print('║ │${indentStr}}');
      } else {
        print('║ │${indentStr}$key: ${value.runtimeType} - $value');
      }
    });
  }

  /// Imprime el JSON raw de las participaciones
  static void printParticipacionesJson(List<Participacion> participaciones) {
    print('\n');
    print('╔════════════════════════════════════════════════════════════╗');
    print('║           📋 JSON RAW DE PARTICIPACIONES                   ║');
    print('╠════════════════════════════════════════════════════════════╣');

    final json = participaciones
        .map((p) => {
              'id': p.idParticipacion,
              'inscripcion_id': p.inscripcionId,
              'perfil_vol_id': p.perfilVolId,
              'proyecto_id': p.proyectoId,
              'usuario_id': p.usuarioId,
              'rol_asignado': p.rolAsignado,
              'horas_comprometidas_semana': p.horasComprometidasSemana,
              'estado': p.estado,
              'creado_en': p.creadoEn.toIso8601String(),
              'actualizado_en': p.actualizadoEn?.toIso8601String(),
            })
        .toList();

    final jsonStr = jsonEncode(json);
    print(jsonStr);

    print('╚════════════════════════════════════════════════════════════╝\n');
  }

  /// Compara participaciones y muestra un resumen
  static void printParticipacionesResumen(List<Participacion> participaciones) {
    print('\n');
    print('╔════════════════════════════════════════════════════════════╗');
    print('║        📈 RESUMEN DE PARTICIPACIONES                       ║');
    print('╠════════════════════════════════════════════════════════════╣');

    final estados = <String, int>{};
    int conInscripcion = 0;
    int conProyecto = 0;
    int conRol = 0;

    for (final p in participaciones) {
      // Contar por estado
      estados[p.estado] = (estados[p.estado] ?? 0) + 1;

      // Contar campos
      if (p.inscripcionId != null) conInscripcion++;
      if (p.proyecto != null) conProyecto++;
      if (p.rolAsignado != null) conRol++;
    }

    print('║ Total: ${participaciones.length}');
    print('║');

    print('║ 📊 Por Estado:');
    estados.forEach((estado, count) {
      print('║   • $estado: $count');
    });

    print('║');
    print('║ 📌 Datos Disponibles:');
    print('║   • Con inscripción: $conInscripcion/${participaciones.length}');
    print('║   • Con proyecto: $conProyecto/${participaciones.length}');
    print('║   • Con rol asignado: $conRol/${participaciones.length}');

    print('╚════════════════════════════════════════════════════════════╝\n');
  }
}
