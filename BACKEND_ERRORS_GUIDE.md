# 🚨 URGENTE: Error "Unknown column 'Inscripcion.fecha_recepcion' in 'field list'"

## ❌ Problema Actual Bloqueante
**Las inscripciones NO funcionan** debido a este error crítico del backend.

### Error
```
"Unknown column 'Inscripcion.fecha_recepcion' in 'field list'"
```

### Causa
El backend tiene el campo `fecha_recepcion` en la entidad `Inscripcion`, pero la columna NO existe en la base de datos porque la migración falló.

### ✅ Solución Backend (REQUERIDA INMEDIATAMENTE)
Ejecutar en la base de datos de producción:

```sql
-- 1. Limpiar datos inválidos que causaron el fallo de migración
UPDATE inscripciones SET fecha_recepcion = NULL WHERE fecha_recepcion = '0000-00-00';

-- 2. Agregar la columna manualmente
ALTER TABLE inscripciones ADD COLUMN fecha_recepcion DATE NULL;

-- 3. Ejecutar migraciones pendientes
npm run migration:run

-- 4. Verificar
DESCRIBE inscripciones;
```

### 🔧 Opción Temporal (Si no se puede acceder a BD)
Comentar el campo en la entidad backend:
```typescript
// En src/informacion/inscripciones/entities/inscripcion.entity.ts
// @Column({ type: 'date', nullable: true })
// fecha_recepcion?: Date;
```

---

# Error: "Data truncated for column 'estado' at row 1" - Guía de Solución

## Problema
Al crear participaciones en el backend de VolunRed, se produce el error:
```
"Data truncated for column 'estado' at row 1"
```

Este error indica que el valor que se está intentando insertar en la columna `estado` de la tabla `participaciones` no coincide con los valores permitidos por el enum definido en la base de datos.

## Problema Relacionado: "Unknown column 'Inscripcion.fecha_recepcion' in 'field list'"

### Error Actual
```
"Unknown column 'Inscripcion.fecha_recepcion' in 'field list'"
```

### Causa Raíz
El backend tiene la entidad `Inscripcion` con el campo `fecha_recepcion`, pero la columna no existe en la base de datos porque la migración falló.

### Solución Backend (URGENTE)
**Opción 1: Ejecutar la migración correctamente**
```bash
# 1. Limpiar datos inválidos
UPDATE inscripciones SET fecha_recepcion = NULL WHERE fecha_recepcion = '0000-00-00';

# 2. Ejecutar migración
npm run migration:run

# 3. Verificar que la columna existe
DESCRIBE inscripciones;
```

**Opción 2: Temporal - Remover campo del backend**
Si no se puede ejecutar la migración inmediatamente:
```typescript
// En src/informacion/inscripciones/entities/inscripcion.entity.ts
// Comentar o remover temporalmente:
@Column({ type: 'date', nullable: true })
fecha_recepcion?: Date;
```

### Solución Frontend (Ya aplicada)
El frontend ya NO envía `fecha_recepcion` para evitar el error hasta que el backend esté corregido. Esta solución se aplicó tanto en la creación de inscripciones por usuarios como por administradores.

## Causa Raíz
1. **Desincronización entre código y base de datos**: La entidad `Participacion` usa el enum `EstadoParticipacion`, pero la columna `estado` en la base de datos tenía valores de enum diferentes o un tipo incompatible.

2. **Migraciones no aplicadas**: Las migraciones de base de datos no se ejecutan automáticamente en Vercel. Deben ejecutarse manualmente en la base de datos de producción.

## Solución Implementada

### 1. Verificación del Enum
El enum `EstadoParticipacion` en `src/common/enums/estado.enum.ts` define:
```typescript
export enum EstadoParticipacion {
  PROGRAMADA = 'programada',
  EN_PROGRESO = 'en_progreso',
  COMPLETADO = 'completado',
  AUSENTE = 'ausente',
  ELIMINADA = 'eliminada',
}
```

### 2. Validación en DTO
El `CreateParticipacionDto` incluye validaciones apropiadas:
```typescript
@IsOptional()
@IsEnum(EstadoParticipacion)
@Transform(({ value }) => typeof value === 'string' ? value.toLowerCase() : value)
estado?: EstadoParticipacion;
```

### 3. Configuración de Entidad
La entidad `Participacion` define correctamente la columna:
```typescript
@Column({ type: 'enum', enum: EstadoParticipacion, default: EstadoParticipacion.PROGRAMADA })
estado: EstadoParticipacion;
```

### 4. Migración de Base de Datos
Se creó y ejecutó la migración `UpdateParticipacionesEstado` que actualiza la columna:
```sql
ALTER TABLE `participaciones` MODIFY COLUMN `estado` enum('programada', 'en_progreso', 'completado', 'ausente', 'eliminada') NOT NULL DEFAULT 'programada'
```

## Problema Relacionado: Fecha de Recepción en Inscripciones

### Antecedentes
Durante la resolución del problema de participaciones, se intentó ejecutar una migración automática que incluía cambios en la tabla `inscripciones`. Esta migración falló específicamente al intentar agregar la columna `fecha_recepcion`.

### Error Encontrado
```
Incorrect date value: '0000-00-00' for column 'fecha_recepcion' at row 1
```

### Análisis del Problema
1. **Columna `fecha_recepcion`**: Es un campo de tipo `date` en la entidad `Inscripcion` que representa la fecha en que se recibió la solicitud de inscripción.

2. **Validación en DTO**: En `CreateInscripcioneDto`, el campo es opcional y usa `@IsISO8601()` para validación:
   ```typescript
   @IsOptional()
   @IsISO8601()
   fecha_recepcion?: string;
   ```

3. **Manejo en Servicio**: Si no se proporciona `fecha_recepcion`, se usa la fecha actual:
   ```typescript
   let fechaRecepcion: Date;
   if (createInscripcioneDto.fecha_recepcion) {
     fechaRecepcion = new Date(createInscripcioneDto.fecha_recepcion);
   } else {
     fechaRecepcion = new Date(); // Fecha actual como fallback
   }
   ```

4. **Datos Existentes Inválidos**: La migración falló porque había registros existentes en la tabla `inscripciones` con fechas inválidas (`'0000-00-00'`), que MySQL no acepta como valores de fecha válidos.

### Solución para Fecha de Recepción
1. **Hacer la columna nullable** en la migración para evitar el error con datos existentes.
2. **Validar fechas** tanto en el DTO como en el servicio.
3. **Usar fecha actual como default** cuando no se proporciona.
4. **Frontend workaround**: No enviar `fecha_recepcion` desde el frontend hasta que la migración se aplique correctamente.

### Validación de Fecha de Recepción
```typescript
// En el servicio - validación adicional
if (isNaN(fechaRecepcion.getTime())) {
  throw new BadRequestException('La fecha de recepción proporcionada no es válida');
}
```

### Workaround para Frontend
Hasta que se aplique la migración correctamente, el frontend NO debe enviar el campo `fecha_recepcion`. El backend asignará automáticamente la fecha actual.

```typescript
// ❌ NO enviar desde frontend
const data = {
  usuario_id: 1,
  organizacion_id: 1,
  // fecha_recepcion: '2025-11-16T10:00:00.000Z', // NO enviar
  estado: 'pendiente'
};
```

### Ejemplo de Uso
```json
POST /inscripciones
{
  "usuario_id": 1,
  "organizacion_id": 1,
  "fecha_recepcion": "2025-11-16T10:00:00.000Z",  // Opcional - formato ISO 8601
  "estado": "pendiente"
}
```

Si no se proporciona `fecha_recepcion`, se usa automáticamente `new Date()`.

### Limpieza de Datos Existentes
Si encuentras fechas inválidas en la base de datos, puedes ejecutar consultas SQL para corregirlas:

```sql
-- Ver registros con fechas inválidas
SELECT * FROM inscripciones WHERE fecha_recepcion = '0000-00-00' OR fecha_recepcion IS NULL;

-- Actualizar fechas inválidas con la fecha de creación
UPDATE inscripciones
SET fecha_recepcion = creado_en
WHERE fecha_recepcion = '0000-00-00' OR fecha_recepcion IS NULL;
```

### Lección Aprendida
**Siempre verifica datos existentes antes de hacer una columna NOT NULL en migraciones.** MySQL rechaza fechas como `'0000-00-00'`, por lo que es mejor:
1. Hacer la columna nullable inicialmente
2. Limpiar datos inválidos
3. Luego hacerla NOT NULL si es necesario

## Mejores Prácticas para Manejo de Fechas

### 1. Validación Consistente
- Usa `@IsISO8601()` en DTOs para entrada de usuario
- Valida fechas en el servicio con `isNaN(fecha.getTime())`
- Proporciona valores por defecto sensatos

### 2. Tipos de Fecha en TypeORM
```typescript
// Para fechas completas (fecha + hora)
@Column({ type: 'datetime' })
fecha_completa: Date;

// Para fechas sin hora
@Column({ type: 'date' })
fecha_simple: Date;

// Para timestamps automáticos
@CreateDateColumn()
creado_en: Date;
```

### 3. Manejo de Timezones
- Almacena fechas en UTC en la base de datos
- Convierte a timezone del usuario en el frontend
- Usa `new Date()` para fechas actuales (ya está en UTC)

### 4. Migraciones Seguras
Antes de ejecutar migraciones que afectan fechas:
```sql
-- Verificar datos existentes
SELECT COUNT(*) FROM tabla WHERE fecha_columna IS NULL OR fecha_columna = '0000-00-00';

-- Backup de seguridad
CREATE TABLE tabla_backup AS SELECT * FROM tabla;
```

## Pasos para Aplicar la Solución

### En Desarrollo Local
1. **Ejecutar migraciones**:
   ```bash
   npm run migration:run
   ```

2. **Verificar build**:
   ```bash
   npm run build
   ```

### En Producción (Vercel + Railway)
1. **Conectar a la base de datos de producción** usando las variables de entorno de Vercel.

2. **Ejecutar la migración manualmente**:
   ```bash
   # Configurar variables de entorno de producción
   export DB_HOST=...
   export DB_PORT=...
   export DB_USERNAME=...
   export DB_PASSWORD=...
   export DB_DATABASE=...

   # Ejecutar migración
   npm run migration:run
   ```

3. **Redeploy en Vercel**:
   ```bash
   vercel --prod --force
   ```

## Validación de la Solución

### Test de Creación de Participación
```json
POST /participaciones
{
  "inscripcion_id": 1,
  "proyecto_id": 1,
  "estado": "PROGRAMADA",  // Se transforma automáticamente a minúsculas
  "rol_asignado": "Coordinador",
  "horas_comprometidas_semana": 8.5
}
```

**Respuesta esperada**:
```json
{
  "id_participacion": 1,
  "inscripcion_id": 1,
  "proyecto_id": 1,
  "estado": "programada",
  "rol_asignado": "Coordinador",
  "horas_comprometidas_semana": 8.5,
  "creado_en": "2025-11-16T...",
  "inscripcion": {...},
  "proyecto": {...}
}
```

## Prevención de Errores Futuros

### 1. Siempre Ejecutar Migraciones
- **Desarrollo**: Ejecutar `npm run migration:run` después de cambios en entidades.
- **Producción**: Aplicar migraciones manualmente antes del deploy.

### 2. Mantener Sincronización
- Usar enums de TypeScript para columnas de base de datos.
- Aplicar validaciones `@IsEnum()` en DTOs.
- Usar `@Transform()` para normalizar entrada de usuario.

### 3. Estrategia de Deploy
```bash
# 1. Ejecutar migraciones en producción
npm run migration:run

# 2. Verificar build
npm run build

# 3. Deploy
vercel --prod --force

# 4. Testear endpoints críticos
```

### 4. Monitoreo
- Implementar logging en servicios para capturar errores de BD.
- Configurar alertas para errores 500 relacionados con truncamiento de datos.

## Archivos Modificados
- `src/informacion/participaciones/entities/participacion.entity.ts`
- `src/informacion/participaciones/dto/create-participacion.dto.ts`
- `src/informacion/participaciones/participaciones.service.ts`
- `src/migrations/1763307781112-UpdateParticipacionesEstado.ts`

## Archivos Relacionados con Fechas
- `src/informacion/inscripciones/entities/inscripcion.entity.ts` - Define columna `fecha_recepcion`
- `src/informacion/inscripciones/dto/create-inscripcione.dto.ts` - Valida `fecha_recepcion` con `@IsISO8601()`
- `src/informacion/inscripciones/inscripciones.service.ts` - Maneja conversión y validación de fechas

## Conclusión
Este error se resolvió actualizando la definición de la columna `estado` en la base de datos para que coincida con el enum `EstadoParticipacion`. La clave es mantener la sincronización entre el código TypeScript y el esquema de la base de datos, especialmente en entornos de producción donde las migraciones no se ejecutan automáticamente.

**Lecciones adicionales sobre fechas:**
- Las migraciones automáticas pueden fallar con datos existentes inválidos
- MySQL rechaza fechas como `'0000-00-00'`
- Siempre valida datos existentes antes de modificar columnas a NOT NULL
- Proporciona valores por defecto sensatos para fechas opcionales
- Usa `@IsISO8601()` para validación consistente de entrada de fechas