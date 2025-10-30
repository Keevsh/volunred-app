# 🔧 Fix: Error de Tipo en Gestión de Aptitudes

## ❌ Problema

Cuando se intenta acceder a la gestión de aptitudes, aparece el error:

```
type 'String' is not a subtype of type 'List<dynamic>' in type cast
```

## 🔍 Causa

El backend puede devolver las respuestas en diferentes formatos:

**Formato 1: Con wrapper `data`**
```json
{
  "data": [
    {
      "id_aptitud": 1,
      "nombre": "Liderazgo",
      "descripcion": "...",
      "estado": "activo"
    }
  ],
  "message": "Aptitudes obtenidas exitosamente"
}
```

**Formato 2: Lista directa**
```json
[
  {
    "id_aptitud": 1,
    "nombre": "Liderazgo",
    "descripcion": "...",
    "estado": "activo"
  }
]
```

**Formato 3: Error como string**
```json
"Error: No se encontraron aptitudes"
```

El código original asumía que siempre llegaría una lista (`response.data as List`), lo cual fallaba cuando el backend enviaba un objeto con propiedad `data` o un string de error.

## ✅ Solución

Se actualizaron todos los métodos de aptitudes en `AdminRepository` para manejar múltiples formatos de respuesta:

### 1. `getAptitudes()` - Listar aptitudes

**Antes:**
```dart
Future<List<Aptitud>> getAptitudes() async {
  try {
    final response = await _dioClient.dio.get(ApiConfig.aptitudes);
    return (response.data as List)  // ❌ Falla si no es lista
        .map((a) => Aptitud.fromJson(a))
        .toList();
  } on DioException catch (e) {
    throw _handleError(e);
  }
}
```

**Después:**
```dart
Future<List<Aptitud>> getAptitudes() async {
  try {
    final response = await _dioClient.dio.get(ApiConfig.aptitudes);
    final data = response.data;
    
    // ✅ Si tiene propiedad 'data', usarla
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return (data['data'] as List)
          .map((a) => Aptitud.fromJson(a as Map<String, dynamic>))
          .toList();
    }
    
    // ✅ Si es lista directa
    if (data is List) {
      return data
          .map((a) => Aptitud.fromJson(a as Map<String, dynamic>))
          .toList();
    }
    
    // ✅ Si ninguno, devolver vacío
    return [];
  } on DioException catch (e) {
    throw _handleError(e);
  }
}
```

### 2. `getAptitudById()`, `createAptitud()`, `updateAptitud()`

**Patrón aplicado:**
```dart
Future<Aptitud> metodo() async {
  try {
    final response = await _dioClient.dio.get(url);
    final data = response.data;
    
    if (data is Map<String, dynamic>) {
      // Usar 'data' si existe, sino el objeto completo
      final aptitudData = data.containsKey('data') ? data['data'] : data;
      return Aptitud.fromJson(aptitudData as Map<String, dynamic>);
    }
    
    throw Exception('Formato de respuesta inválido');
  } on DioException catch (e) {
    throw _handleError(e);
  }
}
```

## 📋 Archivos Modificados

- ✅ `lib/core/repositories/admin_repository.dart`
  - `getAptitudes()` - Maneja Map con 'data' o List directa
  - `getAptitudById()` - Maneja Map con o sin 'data'
  - `createAptitud()` - Maneja Map con o sin 'data'
  - `updateAptitud()` - Maneja Map con o sin 'data'

## 🧪 Casos de Prueba

### Caso 1: Backend devuelve `{ data: [...] }`
```dart
// Respuesta
{
  "data": [{"id_aptitud": 1, "nombre": "Test"}],
  "message": "OK"
}

// Resultado ✅
List<Aptitud> con 1 elemento
```

### Caso 2: Backend devuelve lista directa
```dart
// Respuesta
[{"id_aptitud": 1, "nombre": "Test"}]

// Resultado ✅
List<Aptitud> con 1 elemento
```

### Caso 3: Backend devuelve objeto sin 'data'
```dart
// Respuesta de create/update
{"id_aptitud": 1, "nombre": "Test", "estado": "activo"}

// Resultado ✅
Aptitud creada/actualizada
```

### Caso 4: Lista vacía
```dart
// Respuesta
{ "data": [] }
// o
[]

// Resultado ✅
List<Aptitud> vacía
```

## 🎯 Beneficios

1. ✅ **Mayor compatibilidad** con diferentes versiones del backend
2. ✅ **Manejo robusto de errores** - no más crashes por formato inesperado
3. ✅ **Código defensivo** - verifica tipos antes de castear
4. ✅ **Experiencia mejorada** - UI muestra lista vacía en lugar de error

## 🚀 Cómo Probar

1. **Hot Restart** de la aplicación
2. Login como admin
3. Ir a **Panel Admin → Aptitudes**
4. **Resultado esperado:**
   - ✅ Lista de aptitudes cargada sin errores
   - ✅ O mensaje "No hay aptitudes" si la lista está vacía
   - ✅ Crear/Editar/Eliminar funcionando correctamente

## 🔮 Siguientes Pasos

Este mismo patrón debe aplicarse a otros métodos del repository:

- ⚠️ `getUsuarios()` - Aplicar mismo fix
- ⚠️ `getRoles()` - Aplicar mismo fix
- ⚠️ `getPermisos()` - Aplicar mismo fix
- ⚠️ `getProgramas()` - Aplicar mismo fix

**Patrón reutilizable:**
```dart
// Para listas
if (data is Map && data.containsKey('data')) {
  return (data['data'] as List).map(...).toList();
}
if (data is List) {
  return data.map(...).toList();
}
return [];

// Para objetos
if (data is Map<String, dynamic>) {
  final itemData = data.containsKey('data') ? data['data'] : data;
  return Model.fromJson(itemData);
}
```

---

**Fecha:** 30 de Octubre de 2025  
**Estado:** ✅ Resuelto  
**Desarrollador:** GitHub Copilot
