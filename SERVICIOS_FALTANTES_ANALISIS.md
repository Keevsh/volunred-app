# 📊 Análisis de Servicios Implementados vs. Documentados

**Fecha de análisis:** 30 de Octubre de 2025  
**Total de endpoints documentados:** 100+  
**Total de repositorios implementados:** 3 (AuthRepository, AdminRepository, VoluntarioRepository)

---

## ✅ SERVICIOS IMPLEMENTADOS (35%)

### 1. ✅ Autenticación (100% completo)
**Archivo:** `auth_repository.dart`

| Endpoint | Método | Estado | Implementado |
|----------|--------|--------|--------------|
| `/auth/register` | POST | ✅ | `register()` |
| `/auth/login` | POST | ✅ | `login()` |
| `/auth/profile` | GET | ✅ | `getProfile()` |
| Logout local | - | ✅ | `logout()` |
| Verificación | - | ✅ | `isAuthenticated()` |
| Storage usuario | - | ✅ | `getStoredUser()` |

---

### 2. ✅ Gestión de Usuarios (60% completo)
**Archivo:** `admin_repository.dart`

| Endpoint | Método | Estado | Implementado |
|----------|--------|--------|--------------|
| `/perfiles/usuarios` | GET | ✅ | `getUsuarios()` con paginación |
| `/perfiles/usuarios/:id` | GET | ✅ | `getUsuarioById()` |
| `/perfiles/usuarios/:id` | PATCH | ✅ | `updateUsuario()` |
| `/perfiles/usuarios/:id` | DELETE | ✅ | `deleteUsuario()` |
| `/perfiles/usuarios` | POST | ❌ | **FALTA** `createUsuario()` |
| `/perfiles/usuarios/:id/cambiar-password` | PATCH | ❌ | **FALTA** `cambiarPassword()` |

---

### 3. ✅ Gestión de Roles (100% completo)
**Archivo:** `admin_repository.dart`

| Endpoint | Método | Estado | Implementado |
|----------|--------|--------|--------------|
| `/administracion/roles` | GET | ✅ | `getRoles()` |
| `/administracion/roles/:id` | GET | ✅ | `getRolById()` |
| `/administracion/roles` | POST | ✅ | `createRol()` |
| `/administracion/roles/:id` | PATCH | ✅ | `updateRol()` |
| `/administracion/roles/:id` | DELETE | ✅ | `deleteRol()` |
| `/administracion/roles/asignar-rol-usuario` | POST | ✅ | `asignarRol()` |
| `/administracion/roles/:id/permisos` | GET | ✅ | `getPermisosByRol()` |

---

### 4. ✅ Gestión de Permisos (70% completo)
**Archivo:** `admin_repository.dart`

| Endpoint | Método | Estado | Implementado |
|----------|--------|--------|--------------|
| `/administracion/permisos` | GET | ✅ | `getPermisos()` |
| `/administracion/roles/asignar-permisos` | POST | ✅ | `asignarPermisos()` |
| `/administracion/permisos/:id` | DELETE | ✅ | `deletePermiso()` |
| `/administracion/permisos/:id` | PATCH | ❌ | **FALTA** `updatePermiso()` |

---

### 5. ⚠️ Gestión de Módulos (50% completo)
**Archivo:** `admin_repository.dart`

| Endpoint | Método | Estado | Implementado |
|----------|--------|--------|--------------|
| `/administracion/modulos` | GET | ✅ | `getModulos()` |
| `/administracion/modulos/:id` | GET | ❌ | **FALTA** `getModuloById()` |
| `/administracion/modulos` | POST | ❌ | **FALTA** `createModulo()` |
| `/administracion/modulos/:id` | PATCH | ❌ | **FALTA** `updateModulo()` |
| `/administracion/modulos/:id` | DELETE | ❌ | **FALTA** `deleteModulo()` |

---

### 6. ⚠️ Gestión de Aplicaciones (50% completo)
**Archivo:** `admin_repository.dart`

| Endpoint | Método | Estado | Implementado |
|----------|--------|--------|--------------|
| `/administracion/aplicaciones` | GET | ✅ | `getAplicaciones()` |
| `/administracion/aplicaciones/:id` | GET | ❌ | **FALTA** `getAplicacionById()` |
| `/administracion/aplicaciones` | POST | ✅ | `createAplicacion()` |
| `/administracion/aplicaciones/:id` | PATCH | ❌ | **FALTA** `updateAplicacion()` |
| `/administracion/aplicaciones/:id` | DELETE | ❌ | **FALTA** `deleteAplicacion()` |

---

### 7. ⚠️ Gestión de Programas (50% completo)
**Archivo:** `admin_repository.dart`

| Endpoint | Método | Estado | Implementado |
|----------|--------|--------|--------------|
| `/administracion/programas` | GET | ✅ | `getProgramas()` |
| `/administracion/programas/:id` | GET | ❌ | **FALTA** `getProgramaById()` |
| `/administracion/programas` | POST | ✅ | `createPrograma()` |
| `/administracion/programas/:id` | PATCH | ❌ | **FALTA** `updatePrograma()` |
| `/administracion/programas/:id` | DELETE | ❌ | **FALTA** `deletePrograma()` |

---

### 8. ✅ Gestión de Aptitudes (100% completo)
**Archivos:** `admin_repository.dart`, `voluntario_repository.dart`

| Endpoint | Método | Estado | Implementado |
|----------|--------|--------|--------------|
| `/aptitudes` | GET | ✅ | `getAptitudes()` (ambos repositorios) |
| `/aptitudes/:id` | GET | ✅ | `getAptitudById()` |
| `/aptitudes` | POST | ✅ | `createAptitud()` |
| `/aptitudes/:id` | PATCH | ✅ | `updateAptitud()` |
| `/aptitudes/:id` | DELETE | ✅ | `deleteAptitud()` |
| `/aptitudes-voluntario` | POST | ✅ | `asignarAptitud()` |
| Múltiples aptitudes | - | ✅ | `asignarMultiplesAptitudes()` |

---

### 9. ⚠️ Gestión de Perfiles de Voluntarios (30% completo)
**Archivo:** `voluntario_repository.dart`

| Endpoint | Método | Estado | Implementado |
|----------|--------|--------|--------------|
| `/perfiles-voluntarios` | GET | ❌ | **FALTA** `getPerfiles()` |
| `/perfiles-voluntarios/:id` | GET | ❌ | **FALTA** `getPerfilById()` |
| `/perfiles-voluntarios` | POST | ✅ | `createPerfil()` |
| `/perfiles-voluntarios/:id` | PATCH | ❌ | **FALTA** `updatePerfil()` |
| `/perfiles-voluntarios/:id/aptitudes` | POST | ✅ | `asignarAptitud()` |
| Storage perfil | - | ✅ | `getStoredPerfil()` |

---

## ❌ SERVICIOS NO IMPLEMENTADOS (65%)

### 10. ❌ Gestión de Organizaciones (0%)
**NECESITA:** Crear `organizaciones_repository.dart`

| Endpoint | Método | Estado | Notas |
|----------|--------|--------|-------|
| `/configuracion/organizaciones` | GET | ❌ | Con filtros de búsqueda y paginación |
| `/configuracion/organizaciones/:id` | GET | ❌ | Con proyectos e inscripciones |
| `/configuracion/organizaciones` | POST | ❌ | Crear nueva organización |
| `/configuracion/organizaciones/:id` | PATCH | ❌ | Actualizar organización |
| `/configuracion/organizaciones/:id` | DELETE | ❌ | Eliminar organización |
| `/configuracion/organizaciones/:id/proyectos` | GET | ❌ | Proyectos de la organización |

**Modelo requerido:** `organizacion.dart` con:
- id_organizacion, nombre, nombre_corto, tipo, correo, telefono
- direccion, ciudad, descripcion, sitio_web, estado
- id_categoria, categoria, proyectos, inscripciones

---

### 11. ❌ Gestión de Categorías de Organizaciones (0%)
**NECESITA:** Agregar a `organizaciones_repository.dart`

| Endpoint | Método | Estado | Notas |
|----------|--------|--------|-------|
| `/configuracion/categorias-organizaciones` | GET | ❌ | Lista de categorías |
| `/configuracion/categorias-organizaciones` | POST | ❌ | Crear categoría |
| `/configuracion/categorias-organizaciones/:id` | PATCH | ❌ | Actualizar categoría |
| `/configuracion/categorias-organizaciones/:id` | DELETE | ❌ | Eliminar categoría |

**Modelo requerido:** `categoria_organizacion.dart`

---

### 12. ❌ Gestión de Proyectos (0%)
**NECESITA:** Crear `proyectos_repository.dart`

| Endpoint | Método | Estado | Notas |
|----------|--------|--------|-------|
| `/informacion/proyectos` | GET | ❌ | Con múltiples filtros y paginación |
| `/informacion/proyectos/:id` | GET | ❌ | Con tareas, participaciones, opiniones |
| `/informacion/proyectos` | POST | ❌ | Crear proyecto |
| `/informacion/proyectos/:id` | PATCH | ❌ | Actualizar proyecto |
| `/informacion/proyectos/:id` | DELETE | ❌ | Eliminar proyecto |
| `/informacion/proyectos/:id/estadisticas` | GET | ❌ | Estadísticas del proyecto |
| `/informacion/proyectos/:id/voluntarios` | GET | ❌ | Voluntarios del proyecto |

**Modelo requerido:** `proyecto.dart` con:
- id_proyecto, titulo, descripcion, objetivos
- fecha_inicio, fecha_fin, ubicacion, estado
- vacantes, vacantes_ocupadas, duracion_horas
- id_categoria, id_organizacion, categoria, organizacion
- tareas, participaciones, opiniones

---

### 13. ❌ Gestión de Categorías de Proyectos (0%)
**NECESITA:** Agregar a `proyectos_repository.dart`

| Endpoint | Método | Estado | Notas |
|----------|--------|--------|-------|
| `/informacion/categorias-proyectos` | GET | ❌ | Lista de categorías |
| `/informacion/categorias-proyectos` | POST | ❌ | Crear categoría |
| `/informacion/categorias-proyectos/:id` | PATCH | ❌ | Actualizar categoría |
| `/informacion/categorias-proyectos/:id` | DELETE | ❌ | Eliminar categoría |

**Modelo requerido:** `categoria_proyecto.dart`

---

### 14. ❌ Gestión de Tareas (0%)
**NECESITA:** Crear `tareas_repository.dart`

| Endpoint | Método | Estado | Notas |
|----------|--------|--------|-------|
| `/informacion/tareas` | GET | ❌ | Con filtros por proyecto y estado |
| `/informacion/tareas/:id` | GET | ❌ | Con asignaciones y evidencias |
| `/informacion/tareas` | POST | ❌ | Crear tarea |
| `/informacion/tareas/:id` | PATCH | ❌ | Actualizar tarea |
| `/informacion/tareas/:id` | DELETE | ❌ | Eliminar tarea |

**Modelo requerido:** `tarea.dart` con:
- id_tarea, nombre, descripcion, fecha_limite
- estado, prioridad, id_proyecto, proyecto
- asignaciones, evidencias

---

### 15. ❌ Gestión de Asignaciones de Tareas (0%)
**NECESITA:** Agregar a `tareas_repository.dart`

| Endpoint | Método | Estado | Notas |
|----------|--------|--------|-------|
| `/informacion/asignaciones-tareas` | GET | ❌ | Con múltiples filtros |
| `/informacion/asignaciones-tareas` | POST | ❌ | Asignar tarea a voluntario |
| `/informacion/asignaciones-tareas/:id` | PATCH | ❌ | Actualizar estado |
| `/informacion/asignaciones-tareas/:id` | DELETE | ❌ | Eliminar asignación |

**Modelo requerido:** `asignacion_tarea.dart`

---

### 16. ❌ Gestión de Evidencias (0%)
**NECESITA:** Crear `evidencias_repository.dart`

| Endpoint | Método | Estado | Notas |
|----------|--------|--------|-------|
| `/informacion/evidencias` | GET | ❌ | Con múltiples filtros |
| `/informacion/evidencias/:id` | GET | ❌ | Con archivos adjuntos |
| `/informacion/evidencias/:id/aprobar` | PATCH | ❌ | Aprobar evidencia |
| `/informacion/evidencias/:id/rechazar` | PATCH | ❌ | Rechazar evidencia |
| `/informacion/evidencias/:id` | DELETE | ❌ | Eliminar evidencia |

**Modelo requerido:** `evidencia.dart` con:
- id_evidencia, tarea_id, perfil_vol_id
- descripcion, estado, fecha_subida, fecha_revision
- comentarios_revision, tarea, perfilVoluntario, archivos

---

### 17. ❌ Gestión de Inscripciones (0%)
**NECESITA:** Crear `inscripciones_repository.dart`

| Endpoint | Método | Estado | Notas |
|----------|--------|--------|-------|
| `/informacion/inscripciones` | GET | ❌ | Con múltiples filtros y meta |
| `/informacion/inscripciones/:id` | GET | ❌ | Con perfil completo y proyectos |
| `/informacion/inscripciones/:id/aprobar` | PATCH | ❌ | Aprobar inscripción |
| `/informacion/inscripciones/:id/rechazar` | PATCH | ❌ | Rechazar inscripción |
| `/informacion/inscripciones/:id` | DELETE | ❌ | Eliminar inscripción |

**Modelo requerido:** `inscripcion.dart` con:
- id_inscripcion, usuario_id, organizacion_id
- fecha_inscripcion, estado, fecha_respuesta
- comentarios, usuario, organizacion

---

### 18. ❌ Gestión de Participaciones (0%)
**NECESITA:** Crear `participaciones_repository.dart`

| Endpoint | Método | Estado | Notas |
|----------|--------|--------|-------|
| `/informacion/participaciones` | GET | ❌ | Con filtros |
| `/informacion/participaciones` | POST | ❌ | Crear participación |
| `/informacion/participaciones/:id` | PATCH | ❌ | Actualizar horas |
| `/informacion/participaciones/:id/finalizar` | PATCH | ❌ | Finalizar participación |
| `/informacion/participaciones/:id` | DELETE | ❌ | Eliminar participación |

**Modelo requerido:** `participacion.dart`

---

### 19. ❌ Gestión de Opiniones (0%)
**NECESITA:** Crear `opiniones_repository.dart`

| Endpoint | Método | Estado | Notas |
|----------|--------|--------|-------|
| `/informacion/opiniones` | GET | ❌ | Con filtros |
| `/informacion/opiniones/:id` | GET | ❌ | Opinión específica |
| `/informacion/opiniones/:id` | DELETE | ❌ | Eliminar opinión |

**Modelo requerido:** `opinion.dart`

---

### 20. ❌ Gestión de Calificaciones (0%)
**NECESITA:** Crear `calificaciones_repository.dart`

| Endpoint | Método | Estado | Notas |
|----------|--------|--------|-------|
| `/informacion/calificaciones-proyectos` | GET | ❌ | Con filtros |
| `/informacion/calificaciones-proyectos` | POST | ❌ | Crear calificación |
| `/informacion/calificaciones-proyectos/:id` | PATCH | ❌ | Actualizar calificación |
| `/informacion/calificaciones-proyectos/:id` | DELETE | ❌ | Eliminar calificación |

**Modelo requerido:** `calificacion_proyecto.dart`

---

### 21. ❌ Gestión de Perfiles de Funcionarios (0%)
**NECESITA:** Crear `funcionarios_repository.dart`

| Endpoint | Método | Estado | Notas |
|----------|--------|--------|-------|
| `/perfiles/perfiles-funcionarios` | GET | ❌ | Con paginación |
| `/perfiles/perfiles-funcionarios/:id` | GET | ❌ | Perfil específico |
| `/perfiles/perfiles-funcionarios/:id` | PATCH | ❌ | Actualizar perfil |

**Modelo requerido:** `perfil_funcionario.dart`

---

### 22. ❌ Gestión de Experiencias (0%)
**NECESITA:** Crear `experiencias_repository.dart`

| Endpoint | Método | Estado | Notas |
|----------|--------|--------|-------|
| `/perfiles/experiencias-voluntario` | GET | ❌ | Con filtro por perfil |
| `/perfiles/experiencias-voluntario` | POST | ❌ | Crear experiencia |
| `/perfiles/experiencias-voluntario/:id` | PATCH | ❌ | Actualizar experiencia |
| `/perfiles/experiencias-voluntario/:id` | DELETE | ❌ | Eliminar experiencia |

**Modelo requerido:** `experiencia_voluntario.dart`

---

### 23. ❌ Bitácoras de Operaciones (0%)
**NECESITA:** Crear `bitacoras_repository.dart`

| Endpoint | Método | Estado | Notas |
|----------|--------|--------|-------|
| `/administracion/bitacoras-operaciones` | GET | ❌ | Con múltiples filtros y paginación |
| `/administracion/bitacoras-operaciones/:id` | GET | ❌ | Bitácora específica |
| `/administracion/bitacoras-operaciones/estadisticas` | GET | ❌ | Estadísticas de operaciones |

**Modelo requerido:** `bitacora_operacion.dart`

---

### 24. ❌ Bitácoras de Autores (0%)
**NECESITA:** Agregar a `bitacoras_repository.dart`

| Endpoint | Método | Estado | Notas |
|----------|--------|--------|-------|
| `/administracion/bitacoras-autores` | GET | ❌ | Con múltiples filtros |
| `/administracion/bitacoras-autores/usuario/:id` | GET | ❌ | Actividades por usuario |

**Modelo requerido:** `bitacora_autor.dart`

---

### 25. ❌ Reportes y Estadísticas (0%)
**NECESITA:** Crear `reportes_repository.dart`

| Endpoint | Método | Estado | Notas |
|----------|--------|--------|-------|
| `/reportes/general` | GET | ❌ | Reporte general del sistema |
| `/reportes/proyectos` | GET | ❌ | Reporte de proyectos con filtros |
| `/reportes/voluntarios` | GET | ❌ | Top voluntarios |
| `/reportes/inscripciones` | GET | ❌ | Reporte de inscripciones |
| `/reportes/organizaciones` | GET | ❌ | Reporte de organizaciones |
| `/reportes/exportar` | POST | ❌ | Exportar a Excel/PDF |

**Modelos requeridos:** DTOs específicos para reportes

---

## 📊 RESUMEN ESTADÍSTICO

### Repositorios Implementados: 3/15 (20%)
- ✅ `auth_repository.dart` - 100%
- ✅ `admin_repository.dart` - 70%
- ✅ `voluntario_repository.dart` - 30%

### Repositorios Faltantes: 12/15 (80%)
- ❌ `organizaciones_repository.dart`
- ❌ `proyectos_repository.dart`
- ❌ `tareas_repository.dart`
- ❌ `evidencias_repository.dart`
- ❌ `inscripciones_repository.dart`
- ❌ `participaciones_repository.dart`
- ❌ `opiniones_repository.dart`
- ❌ `calificaciones_repository.dart`
- ❌ `funcionarios_repository.dart`
- ❌ `experiencias_repository.dart`
- ❌ `bitacoras_repository.dart`
- ❌ `reportes_repository.dart`

### Endpoints Implementados por Categoría:
| Categoría | Implementados | Total | % |
|-----------|---------------|-------|---|
| Autenticación | 6/6 | 6 | 100% |
| Usuarios | 4/6 | 6 | 67% |
| Roles | 7/7 | 7 | 100% |
| Permisos | 3/4 | 4 | 75% |
| Módulos | 1/5 | 5 | 20% |
| Aplicaciones | 2/5 | 5 | 40% |
| Programas | 2/5 | 5 | 40% |
| Aptitudes | 7/7 | 7 | 100% |
| Perfiles Voluntarios | 3/6 | 6 | 50% |
| Organizaciones | 0/6 | 6 | 0% |
| Categorías Org. | 0/4 | 4 | 0% |
| Proyectos | 0/7 | 7 | 0% |
| Categorías Proy. | 0/4 | 4 | 0% |
| Tareas | 0/5 | 5 | 0% |
| Asignaciones | 0/4 | 4 | 0% |
| Evidencias | 0/5 | 5 | 0% |
| Inscripciones | 0/5 | 5 | 0% |
| Participaciones | 0/5 | 5 | 0% |
| Opiniones | 0/3 | 3 | 0% |
| Calificaciones | 0/4 | 4 | 0% |
| Perfiles Funcionarios | 0/3 | 3 | 0% |
| Experiencias | 0/4 | 4 | 0% |
| Bitácoras Operaciones | 0/3 | 3 | 0% |
| Bitácoras Autores | 0/2 | 2 | 0% |
| Reportes | 0/6 | 6 | 0% |

### **TOTAL GENERAL:** 35/120 endpoints = **29.2%**

---

## 🎯 PRIORIDADES DE IMPLEMENTACIÓN

### PRIORIDAD ALTA (Sistema básico funcional):
1. **Organizaciones** (repositorio + modelos + CRUD completo)
2. **Proyectos** (repositorio + modelos + CRUD completo)
3. **Inscripciones** (aprobar/rechazar solicitudes de voluntarios)
4. **Tareas** (asignación de tareas a voluntarios)
5. **Completar Usuarios** (crear usuario + cambiar contraseña)

### PRIORIDAD MEDIA (Gestión operativa):
6. **Participaciones** (registro de horas)
7. **Evidencias** (aprobación de trabajo voluntario)
8. **Asignaciones de Tareas** (gestión de asignaciones)
9. **Experiencias** (historial de voluntarios)
10. **Completar Módulos/Aplicaciones/Programas** (CRUD completo)

### PRIORIDAD BAJA (Features avanzadas):
11. **Opiniones y Calificaciones** (feedback del sistema)
12. **Perfiles de Funcionarios** (gestión de staff)
13. **Bitácoras** (auditoría del sistema)
14. **Reportes** (estadísticas y exportación)

---

## 📝 PRÓXIMOS PASOS RECOMENDADOS

1. **Completar AdminRepository:**
   - Agregar `createUsuario()`
   - Agregar `cambiarPassword()`
   - Agregar métodos CRUD faltantes para Módulos, Aplicaciones, Programas

2. **Completar VoluntarioRepository:**
   - Agregar `getPerfiles()`
   - Agregar `getPerfilById()`
   - Agregar `updatePerfil()`

3. **Crear modelos faltantes:**
   - `organizacion.dart`
   - `categoria_organizacion.dart`
   - `proyecto.dart`
   - `categoria_proyecto.dart`
   - `tarea.dart`
   - `asignacion_tarea.dart`
   - `evidencia.dart`
   - `inscripcion.dart`
   - `participacion.dart`
   - `opinion.dart`
   - `calificacion_proyecto.dart`
   - `perfil_funcionario.dart`
   - `experiencia_voluntario.dart`
   - `bitacora_operacion.dart`
   - `bitacora_autor.dart`

4. **Crear nuevos repositorios en orden de prioridad:**
   - `organizaciones_repository.dart` (ALTA)
   - `proyectos_repository.dart` (ALTA)
   - `inscripciones_repository.dart` (ALTA)
   - `tareas_repository.dart` (ALTA)
   - `participaciones_repository.dart` (MEDIA)
   - `evidencias_repository.dart` (MEDIA)
   - `experiencias_repository.dart` (MEDIA)
   - `funcionarios_repository.dart` (BAJA)
   - `opiniones_repository.dart` (BAJA)
   - `calificaciones_repository.dart` (BAJA)
   - `bitacoras_repository.dart` (BAJA)
   - `reportes_repository.dart` (BAJA)

5. **Actualizar ApiConfig.dart:**
   - Agregar constantes para todos los nuevos endpoints

6. **Crear DTOs en request_models.dart:**
   - Modelos de request para todos los nuevos endpoints

---

## 🚀 ESTIMACIÓN DE TIEMPO

- **Completar AdminRepository y VoluntarioRepository:** 4 horas
- **Crear modelos básicos (10 modelos):** 8 horas
- **Crear 4 repositorios de prioridad ALTA:** 16 horas
- **Crear 4 repositorios de prioridad MEDIA:** 12 horas
- **Crear 4 repositorios de prioridad BAJA:** 12 horas
- **Testing y ajustes:** 8 horas

**TOTAL ESTIMADO:** 60 horas (~2 semanas de trabajo)

---

**Nota:** Este análisis se basa en la documentación proporcionada con 100+ endpoints. El sistema actualmente tiene implementado aproximadamente el **29.2%** de la funcionalidad total documentada.
