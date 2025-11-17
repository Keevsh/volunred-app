# Documentación: Inscripciones, Participaciones y Tareas

Este documento resume el comportamiento esperado de los servicios relacionados con procesos de voluntariado en el backend NestJS. Incluye la lógica principal de negocio, las validaciones clave y las respuestas consumidas por el frontend.

---

## 1. Inscripciones (`InscripcionesService`)

**Ubicación:** `src/informacion/inscripciones/inscripciones.service.ts`

### Objetivo
Gestionar el flujo mediante el cual un usuario solicita integrarse como voluntario a una organización, enlazando opcionalmente su perfil de voluntario.

### Dependencias principales
- Repositorios TypeORM: `Inscripcion`, `Usuario`, `Organizacion`, `PerfilVoluntario`
- DTOs: `CreateInscripcioneDto`, `UpdateInscripcioneDto`
- Utilidades NestJS para manejo de excepciones (`NotFoundException`, `ConflictException`, `BadRequestException`, `InternalServerErrorException`)

### Flujo de creación (`create`)
1. **Validaciones previas**
   - Confirmar existencia del usuario (`usuario_id`).
   - Confirmar existencia de la organización (`organizacion_id`).
   - Si se envía `perfil_vol_id`, verificar que exista y pertenezca al usuario. Si no se suministra, intentar obtener el perfil activo del usuario.
2. **Prevención de duplicados**
   - Buscar inscripciones activas (estados `PENDIENTE` o `APROBADO`) del mismo usuario o perfil en la organización objetivo.
   - Si se encuentra una coincidencia, lanzar `ConflictException`.
3. **Normalización de estado**
   - Aceptar valores en minúsculas y convertirlos a mayúsculas.
   - Validar que el estado esté en `{ PENDIENTE, APROBADO, RECHAZADO, ELIMINADO }` (valores en MAYÚSCULAS en BD).
   - Estados válidos definidos en la entidad: enum `['PENDIENTE', 'APROBADO', 'RECHAZADO', 'ELIMINADO']`.
4. **Fecha de recepción**
   - Convertir `fecha_recepcion` a `Date`. Si no se provee, usar la fecha actual.
   - Rechazar fechas inválidas.
5. **Persistencia y respuesta**
   - Guardar la inscripción con datos normalizados.
   - Retornar la entidad con las relaciones cargadas (`usuario`, `organizacion`, `perfilVoluntario`) cuando sea posible.

### Operaciones disponibles
- `findAll`: lista inscripciones con estado distinto de `ELIMINADO`, incluyendo relaciones y ordenando por `creado_en DESC`.
- `findOne`: busca por `id_inscripcion`; lanza `NotFoundException` si no existe.
- `update`: revalida cambios en `usuario_id`, `perfil_vol_id`, `organizacion_id`; normaliza estado y exige `motivo_rechazo` al pasar a `RECHAZADO` (limpia el motivo al aprobar).
- `remove`: eliminación lógica (marca estado `ELIMINADO`).

### Endpoints y respuestas esperadas
| Método | Ruta | Respuesta exitosa | Errores comunes |
|--------|------|-------------------|-----------------|
| POST | `/informacion/inscripciones` | **201**: Inscripción creada con relaciones cargadas disponibles. | **400** datos inválidos; **404** recursos inexistentes; **409** duplicado; **500** error inesperado. |
| GET | `/informacion/inscripciones` | **200**: Lista de inscripciones activas (`estado != ELIMINADO`). | **401** JWT inválido o ausente. |
| GET | `/informacion/inscripciones/:id` | **200**: Inscripción con relaciones. | **404** Inscripción no encontrada. |
| PATCH | `/informacion/inscripciones/:id` | **200**: Inscripción actualizada. `motivo_rechazo` obligatorio si `estado -> RECHAZADO`. | **400** validaciones; **404** no encontrada. |
| DELETE | `/informacion/inscripciones/:id` | **200**: `{ message, id_inscripcion }` con estado `ELIMINADO`. | **404** no encontrada. |

---

## 2. Participaciones (`ParticipacionesService`)

**Ubicación:** `src/informacion/participaciones/participaciones.service.ts`

### Objetivo
Administrar el registro de participaciones de voluntarios en proyectos específicos. Una participación vincula una **inscripción aprobada** con un proyecto de esa organización.

### Dependencias principales
- Repositorios TypeORM: `Participacion`, `Inscripcion`, `Proyecto`
- DTOs: `CreateParticipacionDto`, `UpdateParticipacionDto`
- Enum de estados: `EstadoParticipacion`

### Flujo de creación (`create`)
1. Verifica que la inscripción (`inscripcion_id`) exista y esté en estado `APROBADO`.
2. Verifica que el proyecto (`proyecto_id`) exista.
3. **Validación de organización:** Verifica que el proyecto pertenezca a la misma organización de la inscripción.
4. Evita duplicados asegurando que no exista una participación para la misma combinación `inscripcion_id` + `proyecto_id`. Si existe, lanzar `ConflictException`.
5. Crear y guardar la participación retornando el registro con relaciones (`inscripcion`, `inscripcion.usuario`, `inscripcion.organizacion`).

### Operaciones disponibles
- `findAll`: devuelve participaciones con estado distinto de `ELIMINADA`, incluyendo relaciones.
- `findOne`: busca por `id_participacion`; lanza `NotFoundException` si no existe.
- `update`: aplica cambios parciales respetando validaciones del DTO.
- `remove`: eliminación lógica con `estado = EstadoParticipacion.ELIMINADA` y respuesta confirmatoria.

### Endpoints y respuestas esperadas
| Método | Ruta | Respuesta exitosa | Errores comunes |
|--------|------|-------------------|-----------------|
| POST | `/informacion/participaciones` | **201**: Participación creada con relaciones. | **400** validaciones; **401** JWT inválido; **404** inscripción/proyecto inexistente; **409** duplicado; **500** error inesperado. |
| GET | `/informacion/participaciones` | **200**: Participaciones (excluye `ELIMINADA`). | **401** no autorizado. |
| GET | `/informacion/participaciones/:id` | **200**: Participación con relaciones. | **404** no encontrada. |
| PATCH | `/informacion/participaciones/:id` | **200**: Participación actualizada. | **400** validaciones; **404** no encontrada. |
| DELETE | `/informacion/participaciones/:id` | **200**: `{ message, id_participacion }` con estado `ELIMINADA`. | **404** no encontrada. |

---

## 3. Tareas (`TareasService`)

**Ubicación:** `src/informacion/tareas/tareas.service.ts`

### Estado actual
- El servicio expone endpoints en Swagger, pero su implementación es temporal: cada método retorna cadenas estáticas.
- Falta la integración real con un repositorio TypeORM (`Tarea`) que permita persistir datos.

### Endpoints disponibles (versión actual)
| Método | Ruta | Estado actual |
|--------|------|----------------|
| POST | `/informacion/tareas` | Retorna `"This action adds a new tarea"` (sin persistencia).
| GET | `/informacion/tareas` | Retorna `"This action returns all tareas"`.
| GET | `/informacion/tareas/:id` | Retorna `"This action returns a #${id} tarea"`.
| PATCH | `/informacion/tareas/:id` | Retorna `"This action updates a #${id} tarea"`.
| DELETE | `/informacion/tareas/:id` | Retorna `"This action removes a #${id} tarea"`.

> ⚠️ **Nota:** Mientras no se implemente la lógica con el repositorio `Tarea`, estos endpoints no reflejan cambios reales en la base de datos.

### Entidad `Tarea`
- Campos principales: `id_tarea`, `proyecto_id`, `nombre`, `descripcion`, `prioridad`, `fecha_inicio`, `fecha_fin`, `estado`, `creado_en`.
- **Nota:** La entidad NO incluye `actualizado_en` en la implementación actual.
- Estados permitidos (enum): `activo`, `inactivo` (valores en minúsculas en BD).
- Prioridades permitidas: `baja`, `media`, `alta` (valores en minúsculas).
- Relaciones: `ManyToOne` con `Proyecto` (`tarea.proyecto`).

### DTOs
- `CreateTareaDto`: requiere `proyecto_id`, `nombre`, `fecha_inicio`; campos opcionales `descripcion`, `prioridad` (enum: `PrioridadTarea`), `fecha_fin`, `estado` (enum: `EstadoTarea`).
- `UpdateTareaDto`: `PartialType(CreateTareaDto)`, permite actualizaciones parciales.
- **Enums disponibles:**
  - `EstadoTarea`: `pendiente`, `en_progreso`, `completada`, `cancelada`
  - `PrioridadTarea`: `baja`, `media`, `alta`

### Próximos pasos sugeridos
1. Implementar el CRUD real en `TareasService` utilizando un repositorio TypeORM (`TareaRepository`).
2. Incorporar validaciones de negocio (ej. validar que el proyecto esté activo o en curso antes de crear tareas).
3. Considerar la asignación de tareas a voluntarios (`AsignacionesTareas`) y documentar su integración si aplica.

---

## Advertencias y discrepancias encontradas

### ⚠️ Inconsistencia en estados de Tarea
- **Entidad (`tarea.entity.ts`)**: define enum `['activo', 'inactivo']` con default `'activo'`.
- **DTO (`create-tarea.dto.ts`)**: usa enum `EstadoTarea` con valores `['pendiente', 'en_progreso', 'completada', 'cancelada']`.
- **Recomendación:** Unificar los enums entre entidad y DTO para evitar errores de validación.

### ⚠️ Campo `actualizado_en` faltante
- La entidad `Inscripcion` NO incluye el campo `actualizado_en` en su definición actual, aunque es común en otras entidades del sistema.
- Si se requiere auditoría completa, considerar agregar `@UpdateDateColumn()` a la entidad.

### ⚠️ Servicio de Tareas sin implementar
- `TareasService` retorna strings estáticos en todos sus métodos.
- El repositorio `Tarea` NO está inyectado en el servicio.
- Los endpoints están documentados en Swagger pero no funcionan con datos reales.

---

## Relaciones clave entre módulos
- **Inscripción** conecta `Usuario` ↔ `Organización`, con vínculo opcional a `PerfilVoluntario`.
  - Campos: `id_inscripcion`, `usuario_id`, `perfil_vol_id` (nullable), `organizacion_id`, `fecha_recepcion`, `estado`, `motivo_rechazo` (nullable), `creado_en`.
  - **Nota:** La entidad NO incluye `actualizado_en` en la implementación actual.
- **Participación** enlaza una `Inscripcion` APROBADA con un `Proyecto` de esa organización.
  - Campos: `id_participacion`, `inscripcion_id` (FK), `proyecto_id` (referencia), `rol_asignado`, `horas_comprometidas_semana`, `estado`, `creado_en`.
  - **Flujo:** Usuario → Inscripción (a Organización) → Participación (en Proyecto de esa Organización)
  - **Validación clave:** El proyecto debe pertenecer a la misma organización de la inscripción.
  - `proyecto_id` es una **referencia simple** (no FK con CASCADE), permitiendo flexibilidad si el proyecto cambia.
  - Estados válidos (enum): `programada`, `en_progreso`, `completado`, `ausente`, `eliminada`.
- **Tarea** agrupa actividades dentro de un `Proyecto`; la lógica completa está pendiente de implementación.
  - Estados válidos (enum): `activo`, `inactivo` (en la entidad actual, aunque el DTO usa `EstadoTarea` con valores diferentes).
