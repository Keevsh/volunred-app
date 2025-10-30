# Solución Error 400 - Crear Perfil Voluntario

## 🐛 Problema Detectado

Estás recibiendo dos errores al crear el perfil:
1. **Error HTTP 400**: "Bad Request" - El servidor rechaza la petición
2. **Error de Tipo**: "type list dynamic is not a subtype of string" - Problema de conversión de datos

## ✅ Cambios Realizados

### 1. Logs de Diagnóstico en `voluntario_repository.dart`
- Agregué logs detallados que muestran:
  - 📤 Datos enviados al servidor
  - 📥 Respuesta recibida del servidor
  - ❌ Detalles del error (si ocurre)

### 2. Manejo de `disponibilidad` como Array o String
- Actualicé `PerfilVoluntario.fromJson()` para manejar `disponibilidad` que puede venir como:
  - **String**: `"lunes, martes, miércoles"`
  - **Array**: `["lunes", "martes", "miércoles"]` → Se convierte a string

### 3. Mejora en Manejo de Errores 400
- Ahora extrae mensajes específicos del backend
- Muestra arrays de errores de validación
- Imprime detalles completos en consola

## 🔍 Pasos para Diagnosticar

### 1. Ejecuta la App en Modo Debug
```powershell
cd c:\Users\kevin\Tesis\volunred_app
flutter run
```

### 2. Intenta Crear un Perfil
Cuando crees el perfil, verás en la consola:
- Los datos que se están enviando
- La respuesta exacta del servidor
- El mensaje de error específico

### 3. Revisa los Logs
Busca estos símbolos en la consola:
- 📤 = Datos enviados
- 📥 = Respuesta del servidor
- ❌ = Error ocurrido
- 🔍 = Detalles del error

## 🎯 Posibles Causas del Error 400

### Causa 1: Usuario Ya Tiene Perfil
**Síntoma**: "Ya tienes un perfil de voluntario"
**Solución**: 
- Elimina el perfil existente desde el backend
- O usa otro usuario

### Causa 2: `usuario_id` Inválido
**Síntoma**: "usuario no encontrado" o "usuario_id es requerido"
**Solución**:
- Verifica que el token de autenticación es válido
- Asegúrate de estar logueado correctamente

### Causa 3: Campo `estado` Inválido
**Síntoma**: "estado debe ser 'activo' o 'inactivo'"
**Solución**:
- Ya está hardcodeado como `'activo'` en el request

### Causa 4: Campo `disponibilidad` Mal Formateado
**Síntoma**: Error de validación en `disponibilidad`
**Solución**:
- Ahora se envía como string concatenada con comas
- El modelo puede recibir array y lo convierte a string

### Causa 5: Campos Requeridos Faltantes
**Síntoma**: "campo X es requerido"
**Solución**: Revisa la documentación de la API para ver qué campos son obligatorios

## 🔧 Verificaciones Adicionales

### 1. Verifica el Token de Autenticación
```dart
// En create_profile_page.dart, línea 60-70
final authRepo = Modular.get<AuthRepository>();
final usuario = await authRepo.getStoredUser();
print('👤 Usuario: ${usuario?.idUsuario}'); // Agrega este log
```

### 2. Verifica el Endpoint
```dart
// En api_config.dart
static const String perfilesVoluntarios = '/perfiles-voluntarios';
```
- Debe coincidir con el backend
- Prueba en Postman: `POST http://192.168.26.3:3000/perfiles-voluntarios`

### 3. Verifica el Formato del Request
Según la documentación, el request debe ser:
```json
{
  "usuario_id": 1,
  "bio": "texto opcional",
  "disponibilidad": "lunes, martes, miércoles",
  "estado": "activo"
}
```

## 📋 Ejemplo de Request Correcto

```dart
CreatePerfilVoluntarioRequest(
  usuarioId: 1,              // ID del usuario autenticado
  bio: "Mi biografía",        // Opcional
  disponibilidad: "lunes, martes", // Opcional, formato string
  estado: 'activo',          // Requerido
)
```

## 🧪 Prueba Directa con Postman

Para verificar que el backend funciona:

```http
POST http://192.168.26.3:3000/perfiles-voluntarios
Content-Type: application/json
Authorization: Bearer TU_TOKEN_AQUI

{
  "usuario_id": 1,
  "bio": "Prueba desde Postman",
  "disponibilidad": "lunes, martes",
  "estado": "activo"
}
```

## 📝 Qué Hacer Ahora

1. **Ejecuta la app** con los nuevos logs
2. **Intenta crear un perfil**
3. **Copia los logs** de la consola (especialmente los que empiezan con 📤, 📥, ❌)
4. **Comparte los logs** conmigo para identificar el problema exacto

## 🎨 Ejemplo de Logs Esperados

### Si Todo Va Bien:
```
📤 Enviando request: {usuario_id: 1, bio: Mi bio, disponibilidad: lunes, martes, estado: activo}
📥 Respuesta del servidor: {id_perfil_voluntario: 1, usuario_id: 1, bio: Mi bio, ...}
📥 Tipo de respuesta: _InternalLinkedHashMap<String, dynamic>
```

### Si Hay Error:
```
❌ DioException: Bad Request
❌ Response: {message: [usuario_id debe ser un número, estado es requerido], error: Bad Request, statusCode: 400}
❌ Status Code: 400
🔍 Error Response Data: {...}
🔍 Error Response Type: _InternalLinkedHashMap<String, dynamic>
```

## 💡 Tip Final

Si el error persiste, el problema probablemente está en:
1. **El backend** rechazando la petición por validación
2. **El formato de los datos** no coincide con lo esperado
3. **El usuario** no existe o el token expiró

Los logs te dirán exactamente qué está fallando.
