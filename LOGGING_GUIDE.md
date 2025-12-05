# 📊 Guía de Logging de Participaciones

## 🎯 Objetivo
Ver los datos reales que trae el backend en la respuesta de participaciones, sin las imágenes base64 que contaminen la consola.

## 📍 ¿Dónde se implementó?

### 1. **ParticipationLogger** (`lib/core/utils/participation_logger.dart`)
Utility que contiene 3 métodos de logging principales:

```dart
// Imprime resumen con estadísticas
ParticipationLogger.printParticipacionesResumen(participaciones);

// Imprime detalles completos de cada participación
ParticipationLogger.printParticipaciones(participaciones);

// Imprime JSON limpio sin base64
ParticipationLogger.printParticipacionesJson(participaciones);
```

### 2. **FuncionarioDashboard** (`lib/features/home/widgets/funcionario_dashboard.dart`)
Se agregó logging automático al cargar datos:

```dart
final participaciones = await _repository.getParticipaciones();

// Imprimir datos de participaciones para debugging
ParticipationLogger.printParticipacionesResumen(participaciones);
ParticipationLogger.printParticipaciones(participaciones);
```

### 3. **SmartLogInterceptor** (`lib/core/services/dio_client.dart`)
Se mejoró el manejo de respuestas con base64 para mostrar estructura sin datos pesados.

## 🔍 Ejemplo de Output

### Resumen:
```
╔════════════════════════════════════════════════════════════╗
║        📈 RESUMEN DE PARTICIPACIONES                       ║
╠════════════════════════════════════════════════════════════╣
║ Total: 5
║
║ 📊 Por Estado:
║   • PROGRAMADA: 3
║   • EN_PROGRESO: 2
║
║ 📌 Datos Disponibles:
║   • Con inscripción: 5/5
║   • Con proyecto: 5/5
║   • Con rol asignado: 3/5
╚════════════════════════════════════════════════════════════╝
```

### Detalle Completo:
```
╔════════════════════════════════════════════════════════════╗
║           📊 PARTICIPACIONES DEL BACKEND                   ║
╠════════════════════════════════════════════════════════════╣
║ Total de participaciones: 5
║
║ ┌─ Participación #1 ─────────────────────────────
║ │ ID: 1
║ │ Estado: PROGRAMADA
║ │ Proyecto ID: 10
║ │ Inscripción ID: 5
║ │ Perfil Voluntario ID: 8
║ │ Usuario ID: 42
║ │ Rol Asignado: Coordinador
║ │ Horas/Semana: 12.5
║ │ Creado: 2024-12-04T10:30:00.000000
║ │ Actualizado: 2024-12-04T14:15:00.000000
║ │
║ │ 📋 Datos de Inscripción:
║ │    id_inscripcion: 5
║ │    perfil_vol_id: 8
║ │    organizacion_id: 2
║ │    fecha_recepcion: "2024-12-01T09:00:00Z"
║ │    estado: "aprobado"
║ │    creado_en: "2024-12-01T09:00:00Z"
║ │
║ │ 🎯 Datos del Proyecto:
║ │    id_proyecto: 10
║ │    nombre: "Proyecto de Limpieza"
║ │    descripcion: "Limpieza de playas..."
║ │    organizacion_id: 2
║ │    estado: "activo"
║ │    [...]
║ └────────────────────────────────────────────────
║
║ ┌─ Participación #2 ─────────────────────────────
║ │ ...
└─────────────────────────────────────────────────────────────
```

## 📋 Campos de Participación

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `idParticipacion` | int | ID único |
| `inscripcionId` | int? | ID de inscripción aprobada |
| `perfilVolId` | int? | ID del voluntario |
| `usuarioId` | int? | ID del usuario |
| `proyectoId` | int | ID del proyecto |
| `rolAsignado` | string? | Rol en el proyecto |
| `horasComprometidasSemana` | double? | Horas/semana |
| `estado` | string | PROGRAMADA, EN_PROGRESO, COMPLETADO, AUSENTE |
| `creadoEn` | DateTime | Fecha de creación |
| `actualizadoEn` | DateTime? | Última actualización |
| `inscripcion` | Map? | Datos de la inscripción |
| `proyecto` | Map? | Datos del proyecto |

## 🚀 Cómo usar

1. **Ejecuta la app normalmente**
2. **Navega al Funcionario Dashboard**
3. **Abre la consola de Flutter**
4. **Busca los bloques con `╔════` para ver los logs**

Los logs se imprimirán automáticamente cuando se carguen las participaciones.

## 💡 Ventajas

✅ **Sin base64**: Las imágenes base64 se filtran automáticamente  
✅ **Formateado**: Salida visual clara y organizada  
✅ **Completo**: Ve todos los campos de cada participación  
✅ **Automático**: No requiere cambios manuales  
✅ **Escalable**: Fácil de extender para otros modelos  

## 🔧 Personalización

Para agregar logging a otros endpoints, copia el patrón:

```dart
import '../../../core/utils/participation_logger.dart';

// En tu método de carga
final datos = await _repository.getTusDatos();
ParticipationLogger.printTusDatos(datos); // O el método que uses
```

O crea una extensión similar para otros modelos.
