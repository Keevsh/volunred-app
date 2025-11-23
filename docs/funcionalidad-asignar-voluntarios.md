# Funcionalidad: Asignar Voluntarios a Tareas

## Implementación Completada

Se agregó la funcionalidad para que los **funcionarios** puedan asignar tareas a los **voluntarios que participan en el proyecto**.

---

## Cambios Realizados

### Archivo Modificado
- `lib/features/proyectos/pages/tarea_detail_page.dart`

### Funcionalidades Agregadas

#### 1. Carga de Participantes del Proyecto
- Al cargar una tarea (solo para funcionarios), se obtienen automáticamente los **participantes del proyecto** usando:
  ```dart
  funcionarioRepo.getParticipacionesByProyecto(tarea.proyectoId)
  ```
- Los participantes se almacenan en `_participantes` para usarlos en la asignación.

#### 2. Botón de Asignar Voluntario
- Se agregó un botón en el `AppBar` con ícono `Icons.person_add`.
- Solo visible para **funcionarios**.
- Al presionarlo, abre un diálogo de selección de voluntarios.

#### 3. Diálogo de Selección de Voluntarios
- Muestra una lista de **voluntarios disponibles** (participantes del proyecto que aún no están asignados a la tarea).
- Filtra automáticamente los voluntarios ya asignados comparando `perfil_vol_id`.
- Muestra:
  - Avatar con inicial del nombre
  - Nombre completo del voluntario
  - Email
- Al seleccionar un voluntario, se asigna automáticamente.

#### 4. Asignación de Voluntario
- Usa el endpoint del backend:
  ```
  POST /funcionarios/tareas/:tareaId/asignar-voluntario
  ```
- Envía:
  ```json
  {
    "perfil_vol_id": 123,
    "titulo": "Nombre de la tarea",
    "descripcion": "Descripción de la tarea"
  }
  ```
- Muestra mensaje de éxito o error.
- Recarga automáticamente los datos para mostrar el voluntario recién asignado.

---

## Flujo de Usuario (Funcionario)

1. **Ver detalle de tarea**: El funcionario navega a la página de detalle de una tarea.
2. **Ver voluntarios asignados**: En la sección "Voluntarios Asignados" puede ver quiénes ya están trabajando en la tarea.
3. **Asignar nuevo voluntario**: 
   - Presiona el botón `+` (person_add) en el AppBar.
   - Se abre un diálogo con la lista de voluntarios disponibles.
   - Selecciona un voluntario de la lista.
4. **Confirmación**: Se muestra un mensaje de éxito y la lista de asignados se actualiza automáticamente.

---

## Estructura de Datos

### Participación
```dart
Participacion {
  inscripcionId: int,
  inscripcion: {
    perfil_voluntario: {
      id_perfil_vol: int,
      usuario: {
        nombres: string,
        apellidos: string,
        email: string
      }
    }
  }
}
```

### Asignación de Tarea
```dart
AsignacionTarea {
  idAsignacion: int,
  tareaId: int,
  perfilVolId: int,
  estado: string,
  perfilVoluntario: {
    usuario: {
      nombres: string,
      apellidos: string
    }
  }
}
```

---

## Validaciones Implementadas

1. **Solo funcionarios** pueden asignar voluntarios.
2. **Filtrado automático**: No se muestran voluntarios ya asignados a la tarea.
3. **Validación de disponibilidad**: Si no hay voluntarios disponibles, se muestra un mensaje informativo.
4. **Manejo de errores**: Si falla la asignación, se muestra el error al usuario.

---

## Próximos Pasos Sugeridos

### Funcionalidades Adicionales
- [ ] Permitir **reasignar** o **cancelar** asignaciones existentes.
- [ ] Agregar **filtros** en el diálogo (por nombre, email, rol).
- [ ] Mostrar **estadísticas** del voluntario (tareas completadas, horas trabajadas).
- [ ] Agregar **confirmación** antes de asignar.
- [ ] Permitir asignar **múltiples voluntarios** a la vez.

### Mejoras de UX
- [ ] Agregar **búsqueda** en la lista de voluntarios.
- [ ] Mostrar **avatar real** del voluntario (si tiene foto de perfil).
- [ ] Indicar **disponibilidad** del voluntario (horas comprometidas vs disponibles).
- [ ] Agregar **notificación** al voluntario cuando se le asigna una tarea.

---

## Endpoint del Backend Utilizado

```
POST /funcionarios/tareas/:tareaId/asignar-voluntario
```

**Body:**
```json
{
  "perfil_vol_id": 123,
  "titulo": "string (opcional)",
  "descripcion": "string (opcional)",
  "fecha_asignacion": "YYYY-MM-DD (opcional)"
}
```

**Respuesta:**
```json
{
  "id_asignacion": 1,
  "tarea_id": 1,
  "perfil_vol_id": 123,
  "titulo": "string",
  "descripcion": "string",
  "estado": "asignada",
  "creado_en": "2024-01-01T00:00:00.000Z"
}
```

---

## Notas Técnicas

- Se usa `Participacion.inscripcion['perfil_voluntario']['id_perfil_vol']` para obtener el ID del perfil del voluntario.
- El backend valida automáticamente que el voluntario esté **aprobado** en la organización.
- No se permite duplicar asignaciones (misma tarea + mismo voluntario).
