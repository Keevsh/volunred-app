# Documentación API - VolunRed Backend

Esta documentación explica cómo manejar **inscripciones** (solicitudes de usuarios para unirse a organizaciones) y **participaciones** (registro de voluntarios en proyectos específicos) desde el frontend Flutter.

## Flujo General
1. **Usuario solicita unirse a una organización** → Crea una inscripción (estado `'pendiente'`).
2. **Organización aprueba/rechaza** → Actualiza la inscripción (estado `'aprobado'` o `'rechazado'`).
3. **Si aprobado, voluntario participa en proyectos** → Crea una participación (liga inscripción + proyecto).

## 1. Módulo de Inscripciones
Maneja solicitudes de usuarios para unirse a organizaciones.

### Crear una Inscripción
- **Endpoint**: `POST /informacion/inscripciones`
- **Campos requeridos**:
  - `usuario_id*` (number): ID del usuario.
  - `organizacion_id*` (number): ID de la organización.
- **Campos opcionales**:
  - `fecha_recepcion` (string): **NO enviar desde frontend** - El backend asigna automáticamente la fecha actual.
  - `estado` (string): `'pendiente'`, `'aprobado'`, `'rechazado'` (default `'pendiente'`).
  - `motivo_rechazo` (string): Solo si rechazado.

**Ejemplo Request (Flutter)**:
```dart
final inscripcionData = {
  'usuario_id': 3,
  'organizacion_id': 2,
  // 'fecha_recepcion': DateTime.now().toUtc().toIso8601String(), // NO enviar - el backend asigna automáticamente
  'estado': 'pendiente',
};

final response = await dio.post(
  'https://volunred-backend.vercel.app/informacion/inscripciones',
  data: inscripcionData,
  options: Options(headers: {'Authorization': 'Bearer $token'}),
);
```

**Respuesta Exitosa**: Inscripción creada con relaciones (usuario, organización).

### Obtener Inscripciones
- `GET /informacion/inscripciones`: Lista todas (excluye eliminadas).
- `GET /informacion/inscripciones/:id`: Una específica.

### Aprobar/Rechazar Inscripción
- **Endpoint**: `PATCH /informacion/inscripciones/:id`
- **Campos opcionales**:
  - `estado`: Cambiar a `'aprobado'` o `'rechazado'`.
  - `motivo_rechazo`: Requerido si rechazas.

**Ejemplo (Aprobar)**:
```dart
await dio.patch(
  'https://volunred-backend.vercel.app/informacion/inscripciones/1',
  data: {'estado': 'aprobado'},
  options: Options(headers: {'Authorization': 'Bearer $token'}),
);
```

**Ejemplo (Rechazar)**:
```dart
await dio.patch(
  'https://volunred-backend.vercel.app/informacion/inscripciones/1',
  data: {
    'estado': 'rechazado',
    'motivo_rechazo': 'No cumple requisitos.',
  },
  options: Options(headers: {'Authorization': 'Bearer $token'}),
);
```

### Eliminar Inscripción (Lógica)
- `DELETE /informacion/inscripciones/:id`: Marca como `'ELIMINADO'` (soft delete), no borra físicamente.

## 2. Módulo de Participaciones
Registra la participación de voluntarios en proyectos (requiere inscripción aprobada).

### Crear una Participación
- **Endpoint**: `POST /informacion/participaciones`
- **Campos requeridos**:
  - `inscripcion_id*` (number): ID de la inscripción aprobada.
  - `proyecto_id*` (number): ID del proyecto.
- **Campos opcionales**:
  - `rol_asignado` (string): Rol del voluntario (máx. 100 chars).
  - `estado` (string): `'programada'`, `'en_progreso'`, `'completado'`, `'ausente'` (default `'programada'`).
  - `horas_comprometidas_semana` (number): Horas/semana (0-168).

**Ejemplo Request (Flutter)**:
```dart
final participacionData = {
  'inscripcion_id': 1, // De la inscripción aprobada
  'proyecto_id': 1,
  'rol_asignado': 'Coordinador de campo',
  'estado': 'PROGRAMADA', // Enviar en mayúsculas
  'horas_comprometidas_semana': 8.5,
};

final response = await dio.post(
  'https://volunred-backend.vercel.app/informacion/participaciones',
  data: participacionData,
  options: Options(headers: {'Authorization': 'Bearer $token'}),
);
```

**Respuesta**: Participación creada con relaciones (inscripción, proyecto).

### Obtener Participaciones
- `GET /informacion/participaciones`: Lista todas (excluye eliminadas).
- `GET /informacion/participaciones/:id`: Una específica.

### Actualizar Participación
- `PATCH /informacion/participaciones/:id`: Actualiza campos como rol, horas, estado.

### Eliminar Participación (Lógica)
- `DELETE /informacion/participaciones/:id`: Marca como `'eliminada'` (soft delete), no borra físicamente.

## Flujo Completo para el Frontend
1. **Crear organización** (si no existe): `POST /configuracion/organizaciones`.
2. **Crear perfil de funcionario** (opcional): `POST /perfiles/perfiles-funcionarios`.
3. **Usuario solicita inscripción**: `POST /informacion/inscripciones`.
4. **Organización aprueba**: `PATCH /informacion/inscripciones/:id` con `estado: 'aprobado'`.
5. **Crear proyecto**: `POST /informacion/proyectos`.
6. **Registrar participación**: `POST /informacion/participaciones`.

## Validaciones y Errores Comunes
- **Inscripciones**:
  - Usuario y organización existen.
  - No duplicados activos/pendientes (409).
  - Fechas: ISO 8601 válido.
  - Estados: lowercase input, uppercase DB.

- **Participaciones**:
  - Inscripción y proyecto existen.
  - No duplicados por inscripción/proyecto (409).
  - Horas: 0-168.
  - Estado: Enviar en mayúsculas (PROGRAMADA, EN_PROGRESO, etc.).

- **Errores HTTP**:
  - 400: Datos inválidos.
  - 401: No autorizado.
  - 404: No encontrado.
  - 409: Conflicto.
  - 500: Error interno.

## Pruebas
- **Swagger**: `https://volunred-backend.vercel.app/api/docs`.
- **Local**: `npm run start:dev` → `http://localhost:3000`.
- **Fechas**: Usa `DateTime.toUtc().toIso8601String()`.

¡El backend está listo con eliminación lógica!