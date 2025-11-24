# API Backend - Resumen para Frontend


## Implementación completada según requerimientos


Este documento resume todos los endpoints implementados para el módulo de gestión de tareas y evidencias.


---


## 1. Autenticación


### Obtener usuario actual
- **Endpoint**: `GET /me` (implementado en AuthModule)
- **Headers**: `Authorization: Bearer <token>` 
- **Respuesta**: Datos del usuario incluyendo `rol` (FUNCIONARIO | VOLUNTARIO)


---


## 2. Proyectos


### 2.1 Listar proyectos (Funcionarios)
- **Endpoint**: `GET /funcionarios/proyectos` 
- **Headers**: `Authorization: Bearer <token>` 
- **Respuesta**: Lista de proyectos de la organización del funcionario


### 2.2 Detalle de proyecto
- **Endpoint**: `GET /funcionarios/proyectos/:id` 
- **Respuesta**: Proyecto con tareas, categorías y organización


### 2.3 Crear proyecto
- **Endpoint**: `POST /funcionarios/proyectos` 
- **Body**:
```json
{
  "nombre": "string",
  "descripcion": "string",
  "estado": "activo | inactivo | finalizado",
  "fecha_inicio": "YYYY-MM-DD",
  "fecha_fin": "YYYY-MM-DD",
  "categorias_ids": [1, 2, 3]
}
```


### 2.4 Actualizar proyecto
- **Endpoint**: `PATCH /funcionarios/proyectos/:id` 
- **Body**: Campos a actualizar (parcial)


### 2.5 Eliminar proyecto
- **Endpoint**: `DELETE /funcionarios/proyectos/:id` 


---


## 3. Tareas - Funcionarios


### 3.1 Listar tareas de un proyecto
- **Endpoint**: `GET /funcionarios/proyectos/:proyectoId/tareas` 
- **Respuesta**: Lista de tareas del proyecto


### 3.2 Obtener tarea específica
- **Endpoint**: `GET /funcionarios/tareas/:id` 
- **Respuesta**: Detalle de la tarea


### 3.3 Crear tarea
- **Endpoint**: `POST /funcionarios/proyectos/:proyectoId/tareas` 
- **Body**:
```json
{
  "nombre": "string",
  "descripcion": "string",
  "prioridad": "baja | media | alta",
  "fecha_inicio": "YYYY-MM-DD",
  "fecha_fin": "YYYY-MM-DD",
  "estado": "pendiente | en_progreso | completada | cancelada"
}
```


### 3.4 Actualizar tarea
- **Endpoint**: `PATCH /funcionarios/tareas/:id` 
- **Body**: Campos a actualizar


### 3.5 Eliminar tarea
- **Endpoint**: `DELETE /funcionarios/tareas/:id` 


### 3.6 Asignar tarea a voluntario
- **Endpoint**: `POST /funcionarios/tareas/:tareaId/asignar-voluntario` 
- **Body**:
```json
{
  "perfil_vol_id": 123,
  "titulo": "string (opcional)",
  "descripcion": "string (opcional)",
  "fecha_asignacion": "YYYY-MM-DD (opcional)"
}
```


---


## 4. Asignaciones de Tareas - Funcionarios


### 4.1 Listar todas las asignaciones
- **Endpoint**: `GET /funcionarios/asignaciones-tareas` 
- **Respuesta**: Lista de asignaciones de la organización


### 4.2 Listar asignaciones de una tarea
- **Endpoint**: `GET /funcionarios/tareas/:tareaId/asignaciones` 
- **Respuesta**: Asignaciones de la tarea específica


### 4.3 Actualizar asignación
- **Endpoint**: `PATCH /funcionarios/asignaciones-tareas/:id` 
- **Body**:
```json
{
  "titulo": "string",
  "descripcion": "string",
  "fecha_asignacion": "YYYY-MM-DD"
}
```


### 4.4 Cambiar estado de asignación
- **Endpoint**: `PATCH /funcionarios/asignaciones-tareas/:id/estado` 
- **Body**:
```json
{
  "estado": "asignada | en_progreso | completada | cancelada"
}
```


### 4.5 Cancelar asignación
- **Endpoint**: `DELETE /funcionarios/asignaciones-tareas/:id` 
- **Nota**: Soft delete, marca como cancelada


---


## 5. Tareas - Voluntarios


### 5.1 Listar mis tareas
- **Endpoint**: `GET /voluntarios/my/tasks` 
- **Query Params**:
  - `estado` (opcional): `asignada | en_progreso | completada | cancelada` 
  - `proyectoId` (opcional): ID del proyecto
- **Respuesta**: Lista de tareas asignadas al voluntario con evidencias


### 5.2 Detalle de mi tarea
- **Endpoint**: `GET /voluntarios/my/tasks/:tareaId` 
- **Respuesta**: 
```json
{
  "id_asignacion": 1,
  "tarea": {
    "id_tarea": 1,
    "nombre": "string",
    "descripcion": "string",
    "estado": "string",
    "prioridad": "string",
    "fecha_inicio": "date",
    "fecha_fin": "date",
    "proyecto": {...}
  },
  "evidencias": [...]
}
```


### 5.3 Cambiar estado de mi tarea
- **Endpoint**: `PATCH /voluntarios/my/tasks/:tareaId/status` 
- **Body**:
```json
{
  "estado": "en_progreso | completada | pendiente",
  "comentario": "string (opcional)"
}
```
- **Validaciones**:
  - `pendiente` → `en_progreso` 
  - `en_progreso` → `completada` o `pendiente` 
  - No se puede cambiar desde `completada` o `cancelada` 


### 5.4 Subir evidencia
- **Endpoint**: `POST /voluntarios/my/tasks/:tareaId/evidences` 
- **Body**:
```json
{
  "tipo": "IMAGEN | VIDEO | DOCUMENTO | TEXTO",
  "descripcion": "string"
}
```
- **Nota**: Para subir archivos, usar multipart/form-data (pendiente implementar upload)


### 5.5 Listar evidencias de mi tarea
- **Endpoint**: `GET /voluntarios/my/tasks/:tareaId/evidences` 
- **Respuesta**: Lista de evidencias de la tarea


---


## 6. Evidencias (Endpoints generales)


### 6.1 Crear evidencia
- **Endpoint**: `POST /informacion/evidencias` 
- **Body**:
```json
{
  "asignacion_id": 123,
  "tarea_id": 456,
  "proyecto_id": 789,
  "tipo": "IMAGEN | VIDEO | DOCUMENTO | TEXTO",
  "descripcion": "string"
}
```


### 6.2 Listar todas las evidencias
- **Endpoint**: `GET /informacion/evidencias` 


### 6.3 Evidencias por asignación
- **Endpoint**: `GET /informacion/evidencias/asignacion/:asignacionId` 


### 6.4 Evidencias por tarea
- **Endpoint**: `GET /informacion/evidencias/tarea/:tareaId` 


### 6.5 Evidencias por proyecto
- **Endpoint**: `GET /informacion/evidencias/proyecto/:proyectoId` 


### 6.6 Detalle de evidencia
- **Endpoint**: `GET /informacion/evidencias/:id` 


### 6.7 Actualizar evidencia
- **Endpoint**: `PATCH /informacion/evidencias/:id` 


### 6.8 Eliminar evidencia
- **Endpoint**: `DELETE /informacion/evidencias/:id` 


---


## 7. Enums y Estados


### EstadoTarea
```typescript
enum EstadoTarea {
  PENDIENTE = 'pendiente',
  EN_PROGRESO = 'en_progreso',
  COMPLETADA = 'completada',
  CANCELADA = 'cancelada'
}
```


### EstadoAsignacion
```typescript
enum EstadoAsignacion {
  ASIGNADA = 'asignada',
  EN_PROGRESO = 'en_progreso',
  COMPLETADA = 'completada',
  CANCELADA = 'cancelada'
}
```


### PrioridadTarea
```typescript
enum PrioridadTarea {
  BAJA = 'baja',
  MEDIA = 'media',
  ALTA = 'alta'
}
```


---


## 9. Reglas de Negocio Implementadas


### Autorización por Rol


**FUNCIONARIO**:
- Crea/edita/elimina proyectos de su organización
- Crea/edita/asigna/cancela tareas
- Ve todas las tareas de proyectos de su organización
- Puede cambiar cualquier estado de tarea


**VOLUNTARIO**:
- Solo ve tareas donde está asignado
- Cambia estado de sus tareas siguiendo flujo:
  - `PENDIENTE` → `EN_PROGRESO` 
  - `EN_PROGRESO` → `COMPLETADA` o `PENDIENTE` 
- Sube evidencias solo a sus tareas
- No puede modificar tareas completadas o canceladas


### Validaciones Implementadas


1. **Asignaciones**:
   - Voluntario debe estar aprobado en la organización
   - No duplicar asignaciones (misma tarea + mismo voluntario)
   - Solo el voluntario asignado puede modificar su tarea


2. **Transiciones de Estado**:
   - Validación automática de flujo permitido
   - Cambios de estado se reflejan en la asignación


3. **Evidencias**:
   - Coherencia: asignación → tarea → proyecto
   - Solo el voluntario asignado puede subir evidencias


---


## 10. Estructura de Errores


Todos los endpoints retornan errores en formato estándar:


```json
{
  "statusCode": 400 | 401 | 403 | 404 | 500,
  "message": "Descripción del error",
  "error": "BadRequest | Unauthorized | Forbidden | NotFound | InternalServerError"
}
```


### Códigos HTTP comunes:
- `200`: OK
- `201`: Created
- `400`: Bad Request (validación fallida, transición no permitida)
- `401`: Unauthorized (sin token o token inválido)
- `403`: Forbidden (sin permisos para la operación)
- `404`: Not Found (recurso no existe)
- `500`: Internal Server Error


---


## 11. Pendientes para completar


### Subida de archivos
- Implementar multipart/form-data para imágenes/videos/documentos
- Integración con S3/Firebase Storage (opcional)
- Validación de tamaño y tipo de archivo


### Notificaciones (opcional)
- Al asignar tarea a voluntario
- Al cambiar estado de tarea
- Al subir nueva evidencia


### Filtros avanzados
- Búsqueda por texto en tareas
- Filtros por fecha, prioridad, estado
- Paginación en listados grandes


---


## 12. Notas Técnicas


- Todos los endpoints requieren autenticación JWT
- Las fechas se manejan en formato ISO 8601 (YYYY-MM-DD)
- Los IDs son numéricos (integers)
- El backend valida permisos automáticamente usando guards
- Soft delete en asignaciones (estado = 'cancelada')
- Hard delete en proyectos, tareas, evidencias e historial


---


## 13. Endpoints móviles para gestión de tareas y participantes


Esta sección mapea lo que pide el documento de frontend móvil (rutas genéricas como `/tasks`  y `/participants`) con los endpoints reales ya implementados en el backend.


### 13.1 Gestión de tareas (equivalente a `/tasks` )


- **Listar tareas** (`GET /tasks`)
  - **Backend real**:
    - `GET /funcionarios/proyectos/:proyectoId/tareas` → tareas de un proyecto específico.
    - `GET /informacion/tareas` → listado global de tareas (sin filtrar por organización/proyecto).


- **Ver detalle de tarea** (`GET /tasks/{taskId}`)
  - **Backend real**:
    - `GET /funcionarios/tareas/:id` → detalle de la tarea para funcionarios.
    - `GET /informacion/tareas/:id` → detalle general de tarea.
    - Para voluntarios con asignación: `GET /voluntarios/my/tasks/:tareaId` devuelve la asignación + detalle de la tarea + evidencias.


- **Crear tarea** (`POST /tasks`)
  - **Backend real**:
    - `POST /funcionarios/proyectos/:proyectoId/tareas` → crea una tarea dentro de un proyecto.
    - Internamente persiste en `informacion/tareas` usando `CreateTareaDto`.


- **Actualizar tarea** (`PUT/PATCH /tasks/{taskId}`)
  - **Backend real**:
    - `PATCH /funcionarios/tareas/:id` → actualiza una tarea existente.
    - `PATCH /informacion/tareas/:id` → actualización a nivel general (si se expone).


- **Eliminar/cancelar tarea** (`DELETE /tasks/{taskId}`)
  - **Backend real**:
    - `DELETE /funcionarios/tareas/:id` → elimina la tarea.


> Nota: Los filtros por estado, proyecto, fecha, etc. pueden implementarse sobre `GET /funcionarios/proyectos/:proyectoId/tareas` y/o `GET /informacion/tareas` añadiendo query params (`estado`, `fecha_inicio`, `fecha_fin`, `prioridad`, etc.). Esto aún no está estandarizado en el contrato, pero el backend ya soporta la estructura de datos necesaria.


### 13.2 Gestión de participantes/voluntarios (equivalente a `/participants` )


El documento de frontend habla de "participants"; en el backend se usan **perfiles de voluntarios**.


- **Listar participantes** (`GET /participants`)
  - **Backend real**:
    - `GET /perfiles/perfiles-voluntarios` → lista de perfiles de voluntarios, incluyendo datos de usuario y, si aplica, organización e inscripción.


- **Detalle de participante** (`GET /participants/{participantId}`)
  - **Backend real**:
    - `GET /perfiles/perfiles-voluntarios/:id` → detalle del perfil de voluntario.


> Nota: Si el frontend quiere llamar a `/participants`, puede hacer un simple **proxy/mapeo** en el API Gateway o en el cliente a `GET /perfiles/perfiles-voluntarios`.


### 13.3 Asignación de participantes a tareas


El documento propone rutas del estilo `/tasks/{taskId}/participants` . En el backend esto se modela como **asignaciones de tareas**.


- **Listar participantes asignados a una tarea** (`GET /tasks/{taskId}/participants`)
  - **Backend real** (funcionarios):
    - `GET /funcionarios/tareas/:tareaId/asignaciones` → lista de asignaciones de esa tarea, con información del voluntario.
  - **Backend real** (servicio base):
    - `GET /informacion/asignaciones-tareas` → se puede filtrar por `tarea_id` si se agrega query param.


- **Asignar uno o varios participantes a una tarea** (`POST /tasks/{taskId}/participants`)
  - **Backend real**:
    - `POST /funcionarios/tareas/:tareaId/asignar-voluntario` → crea una nueva asignación (`AsignacionTarea`) para un voluntario concreto.
    - Internamente usa `POST /informacion/asignaciones-tareas` con un `CreateAsignacionesTareaDto` que incluye `tarea_id`, `perfil_vol_id`, `titulo`, `descripcion`, `fecha_asignacion`, `estado`.
  - Para soportar **asignación múltiple** en un solo request, se podría definir un nuevo endpoint tipo `POST /funcionarios/tareas/:tareaId/asignar-voluntarios` que reciba `participantIds[]` y cree varias asignaciones. Actualmente no está implementado como batch, pero se puede llamar varias veces al endpoint actual.


- **Desasignar participante de una tarea** (`DELETE /tasks/{taskId}/participants/{participantId}`)
  - **Backend real**:
    - `DELETE /funcionarios/asignaciones-tareas/:id` → cancela (soft delete) una asignación específica.
  - Para desasignar usando solo `taskId` + `participantId` se podría añadir un endpoint extra, por ejemplo `DELETE /funcionarios/tareas/:tareaId/participants/:perfilVolId`, que busque la asignación y llame internamente al `DELETE` anterior. Este endpoint **no existe aún**, pero la lógica está cubierta a nivel de servicio.


- **Actualizar estado de un participante en una tarea** (`PATCH /tasks/{taskId}/participants/{participantId}`)
  - **Backend real**:
    - `PATCH /funcionarios/asignaciones-tareas/:id/estado` → cambia el `estado` de la asignación (`asignada | en_progreso | completada | cancelada`).
  - De nuevo, para usar únicamente `taskId` + `participantId` se podría agregar un endpoint de conveniencia que resuelva la asignación correspondiente.


### 13.4 Ver tareas asociadas a un participante


El documento propone `GET /participants/{participantId}/tasks` .


- **Backend real**:
  - Desde el lado del **voluntario autenticado**:
    - `GET /voluntarios/my/tasks` → lista de tareas donde el voluntario está asignado, con filtros opcionales `estado` y `proyectoId`.
  - Desde el lado de **funcionarios/administración**:
    - Se puede usar `GET /informacion/asignaciones-tareas` filtrando por `perfil_vol_id` (ya soportado a nivel de servicio) o exponer un endpoint más legible tipo `GET /funcionarios/voluntarios/:perfilVolId/tareas` (no existe aún, pero sería un wrapper de la query actual `findByVoluntario`).


### 13.5 Endpoints opcionales del documento de frontend


El documento de frontend menciona endpoints opcionales:


- `GET /tasks/{taskId}/candidates` 
- `POST /tasks/{taskId}/apply` 
- `PATCH /tasks/{taskId}/participants/{participantId}/role` 


**Estado actual en el backend:**


- No existen endpoints específicos con esa semántica.
- Se podría reutilizar la estructura de:
  - **Inscripciones** (`/informacion/inscripciones`) para modelar postulaciones/candidatos.
  - **Asignaciones de tareas** (`/informacion/asignaciones-tareas`) para el modelo consolidado de participantes aceptados.


**Sugerencia de diseño futuro (a nivel contrato):**


- `GET /tasks/{taskId}/candidates` → listar inscripciones o solicitudes de voluntarios a esa tarea.
- `POST /tasks/{taskId}/apply` → crear una "solicitud" vinculada al `perfil_vol_id` del voluntario autenticado.
- `PATCH /tasks/{taskId}/participants/{participantId}/role` → agregar un campo `rol` (por ejemplo `coordinator`, `volunteer`) a la entidad `AsignacionTarea` y exponerlo vía un nuevo endpoint de actualización parcial.


Estas extensiones no están implementadas todavía, pero son compatibles con el modelo actual de proyectos, tareas, perfiles de voluntarios y asignaciones.
