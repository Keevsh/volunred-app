# 📱 Interfaz de Upload con Progreso - Vista Previa

## 🎨 Diálogo de Progreso

### Estado 1: Comprimiendo (0%)
```
┌────────────────────────────────────┐
│  🔵 Procesando video...            │
├────────────────────────────────────┤
│                                    │
│  ▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░  0%   │
│                                    │
│  Comprimiendo video...             │
│                                    │
└────────────────────────────────────┘
```

### Estado 2: Subiendo chunks (45%)
```
┌────────────────────────────────────┐
│  🔵 Procesando video...            │
├────────────────────────────────────┤
│                                    │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░  45%  │
│                                    │
│  Subiendo: 45%                     │
│  Subiendo en chunks de 1 MB        │
│                                    │
└────────────────────────────────────┘
```

### Estado 3: Completado (100%)
```
┌────────────────────────────────────┐
│  🔵 ¡Listo!                        │
├────────────────────────────────────┤
│                                    │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  100% │
│                                    │
│  ✅ Video subido exitosamente      │
│                                    │
└────────────────────────────────────┘
```

---

## 🔄 Flujo Completo de UI

```
┌─────────────────────────────┐
│  Proyecto: Limpieza Playa   │
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐   │
│  │📷│ │🎥│ │📄│ │📊│   │
│  └───┘ └───┘ └───┘ └───┘   │
│  Fotos Videos Docs  Todo   │
└─────────────────────────────┘
             │
             ▼ Usuario toca "Videos"
┌─────────────────────────────┐
│  Videos                     │
│  ┌──────┐ ┌──────┐         │
│  │ 🎥   │ │ 🎥   │         │
│  │video1│ │video2│         │
│  └──────┘ └──────┘         │
│                             │
│  [+ Subir Video]            │◄── Usuario toca aquí
└─────────────────────────────┘
             │
             ▼
┌─────────────────────────────┐
│  Subir Video                │
│                             │
│  ⚠️ Límite: 20 MB           │
│                             │
│  ✅ Compresión automática:  │
│  • 720p                     │
│  • Calidad inteligente      │
│  • Audio de buena calidad   │
│                             │
│  💡 Tip: Máximo 60 seg      │
│                             │
│  [Cancelar]  [Seleccionar]  │◄── Usuario confirma
└─────────────────────────────┘
             │
             ▼ Selecciona video de 50 MB
┌─────────────────────────────┐
│  🔵 Procesando video...     │
│  ━━━━━━━━━━░░░░░░░░  40%   │
│  Subiendo: 40%              │
│  Chunks de 1 MB             │
└─────────────────────────────┘
             │ (progreso en tiempo real)
             ▼ 40% → 50% → 60% → ... → 100%
┌─────────────────────────────┐
│  🔵 ¡Listo!                 │
│  ━━━━━━━━━━━━━━━━━  100%   │
│  ✅ Video subido OK         │
└─────────────────────────────┘
             │ (cierra automáticamente)
             ▼
┌─────────────────────────────┐
│ 🟢 Snackbar:                │
│ ✅ Video subido exitosamente│
└─────────────────────────────┘
             │
             ▼ Galería recarga
┌─────────────────────────────┐
│  Videos                     │
│  ┌──────┐ ┌──────┐ ┌──────┐│
│  │ 🎥   │ │ 🎥   │ │ 🎥   ││◄── Video nuevo aparece
│  │video1│ │video2│ │video3││
│  └──────┘ └──────┘ └──────┘│
└─────────────────────────────┘
```

---

## 🎯 Mejoras de UX Implementadas

### Antes ❌
- Sin indicador de progreso
- Usuario no sabía si estaba funcionando
- Si tardaba, parecía congelado
- Solo "Comprimiendo..." sin detalles
- Error 413 sin explicación clara

### Ahora ✅
- **Barra de progreso visual** con porcentaje
- **Mensajes claros** en cada etapa:
  - "Comprimiendo video..." (al inicio)
  - "Subiendo: X%" (durante chunks)
  - "✅ Video subido exitosamente" (al final)
- **Información adicional**: "Subiendo en chunks de 1 MB"
- **No cancelable durante upload** (evita chunks incompletos)
- **Cierre automático** cuando llega a 100%
- **Snackbar de confirmación** verde

---

## 🎨 Colores y Diseño

```dart
// Barra de progreso
LinearProgressIndicator(
  value: _uploadProgress / 100,  // 0.0 a 1.0
  minHeight: 8,
  backgroundColor: Colors.grey[200],  // Fondo gris claro
  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),  // Azul
)

// Título dinámico
Text(
  _uploadProgress < 100 ? 'Procesando video...' : '¡Listo!',
  style: Theme.of(context).textTheme.bodyLarge,
)

// Mensaje de progreso
Text(
  _uploadProgress == 0
    ? 'Comprimiendo video...'
    : _uploadProgress < 100
      ? 'Subiendo: $_uploadProgress%'
      : '✅ Video subido exitosamente',
)
```

---

## 📊 Ejemplo Real con Tiempos

### Video de 45 segundos, 1080p, 45 MB

```
00:00  Usuario selecciona video
       └─► Muestra advertencia
       
00:02  Usuario confirma "Seleccionar Video"
       └─► Abre selector de archivos
       
00:05  Usuario elige video de 45 MB
       └─► Cierra selector
       └─► Muestra diálogo "Procesando video... 0%"
       
00:06  Comienza compresión
       └─► "Comprimiendo video..."
       
00:15  Compresión completa (45 MB → 8.5 MB)
       └─► Comienza conversión a base64
       
00:17  Conversión completa (8.5 MB → 11.3 MB base64)
       └─► Detecta que 11.3 MB > 4 MB
       └─► Divide en 12 chunks
       └─► "Subiendo: 0%"
       
00:18  Sube chunk 1/12
       └─► "Subiendo: 8%"
       
00:19  Sube chunk 2/12
       └─► "Subiendo: 17%"
       
00:20  Sube chunk 3/12
       └─► "Subiendo: 25%"
       
...    (continúa subiendo)
       
00:28  Sube chunk 12/12
       └─► "Subiendo: 100%"
       └─► "✅ Video subido exitosamente"
       
00:29  Backend ensambla chunks
       └─► Guarda en base de datos
       └─► Devuelve respuesta de éxito
       
00:30  Diálogo se cierra automáticamente
       └─► Muestra Snackbar verde
       └─► Recarga galería
       └─► Video aparece en lista
```

**Tiempo total**: ~30 segundos (depende de velocidad de internet)

---

## 🔍 Detalles Técnicos de la Barra

### Implementación del Diálogo

```dart
showDialog(
  context: context,
  barrierDismissible: false,  // ← No se puede cerrar tocando afuera
  builder: (context) => StatefulBuilder(  // ← Permite setState dentro
    builder: (context, setDialogState) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cloud_upload, color: Colors.blue),
          SizedBox(width: 12),
          Text(_uploadProgress < 100 ? 'Procesando...' : '¡Listo!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de progreso
          LinearProgressIndicator(
            value: _uploadProgress / 100,  // ← Actualiza dinámicamente
            minHeight: 8,
          ),
          SizedBox(height: 16),
          // Mensaje
          Text(
            _uploadProgress == 0
              ? 'Comprimiendo video...'
              : _uploadProgress < 100
                ? 'Subiendo: $_uploadProgress%'
                : '✅ Video subido exitosamente',
          ),
          // Info adicional
          if (_uploadProgress > 0 && _uploadProgress < 100)
            Text('Subiendo en chunks de 1 MB'),
        ],
      ),
    ),
  ),
);
```

### Actualización del Progreso

```dart
await mediaService.subirVideoAlProyecto(
  // ... otros parámetros
  onProgress: (progreso) {  // ← Callback desde MediaService
    setState(() {  // ← Actualiza el estado
      _uploadProgress = progreso;  // ← 0, 8, 17, 25, ..., 100
    });
  },
);
```

### Cierre Automático

```dart
// En MediaService, después del último chunk:
if (onProgress != null) {
  onProgress(100);  // ← Envía 100%
}

// En el widget:
await Future.delayed(Duration(milliseconds: 500));  // ← Espera 0.5s
Navigator.pop(context);  // ← Cierra el diálogo
```

---

## 🎬 Video Demo (Simulado)

```
┌─────────────────────────────────────────┐
│  📱 ProyectoMediaPage                   │
│  ┌─────────────────────────────────┐   │
│  │ Videos                          │   │
│  │ ┌────┐ ┌────┐                   │   │
│  │ │ 🎥 │ │ 🎥 │                   │   │
│  │ └────┘ └────┘                   │   │
│  │                                 │   │
│  │ [+ Subir Video]                 │◄──┐
│  └─────────────────────────────────┘   │ 1. Usuario toca
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ Subir Video                     │   │
│  │ ⚠️ Límite: 20 MB                │   │
│  │ ✅ Compresión automática        │   │
│  │ [Cancelar] [Seleccionar]        │◄──┤ 2. Usuario confirma
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 🔵 Procesando video...          │   │
│  │ ━━━━━━━━━━━━━━━━░░  85%        │◄──┤ 3. Progreso visible
│  │ Subiendo: 85%                   │   │
│  │ Chunks de 1 MB                  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ ✅ Video subido exitosamente    │◄──┘ 4. Confirmación
│  └─────────────────────────────────┘
│
└─────────────────────────────────────────┘
```

---

*Documentación de Interfaz - 6 de diciembre de 2025*
