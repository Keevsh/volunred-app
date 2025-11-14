import 'dart:convert';

void main() {
  // Simular el código exacto que debería estar corriendo
  var fechaInicio = DateTime(2025, 11, 1);
  var fechaFin = DateTime(2026, 3, 31);

  var fechaInicioFormateada = fechaInicio.toUtc().toIso8601String().replaceAll(RegExp(r'\.\d+'), '');
  var fechaFinFormateada = fechaFin.toUtc().toIso8601String().replaceAll(RegExp(r'\.\d+'), '');

  print('Fecha inicio original: $fechaInicio');
  print('Fecha inicio UTC ISO: ${fechaInicio.toUtc().toIso8601String()}');
  print('Fecha inicio formateada: $fechaInicioFormateada');

  print('Fecha fin original: $fechaFin');
  print('Fecha fin UTC ISO: ${fechaFin.toUtc().toIso8601String()}');
  print('Fecha fin formateada: $fechaFinFormateada');

  var data = {
    'organizacion_id': 2,
    'categorias_ids': [1],
    'nombre': 'Reforestación Urbana 2025',
    'objetivo': 'Plantar 5000 árboles nativos en zonas urbanas de La Paz',
    'ubicacion': 'Zona Sur, La Paz',
    'fecha_inicio': fechaInicioFormateada,
    'fecha_fin': fechaFinFormateada,
    'estado': 'activo',
  };

  print('\nData que debería enviarse:');
  print(jsonEncode(data));
}