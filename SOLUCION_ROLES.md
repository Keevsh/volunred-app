# Solución: Asignación Automática de Roles

## 🔍 Problema Identificado

Según la documentación del backend:

1. **Al registrarse**: Usuario se crea con `id_rol: null`
2. **Al hacer login**: Backend devuelve el rol si está asignado
3. **El problema**: No hay asignación automática de rol basándose en `tipo_usuario`

### Respuesta del Backend en Registro:
```json
{
  "message": "Usuario registrado exitosamente",
  "usuario": {
    "id_usuario": 1,
    "id_rol": null,  // ❌ SIN ROL
    "rol": null
  }
}
```

## ✅ Solución Implementada en el Frontend

He modificado `register_page.dart` para que **después del registro**, automáticamente:

1. Detecta si el usuario no tiene rol (`id_rol: null`)
2. Mapea el `tipo_usuario` seleccionado a un `id_rol`:
   - `funcionario` → `id_rol: 2`
   - `voluntario` → `id_rol: 3`
3. Llama al endpoint `POST /administracion/roles/asignar-rol-usuario`
4. Recarga el perfil del usuario para obtener el rol actualizado
5. Redirige según el rol asignado

### Código Implementado:

```dart
if (state.usuario.idRol == null && _tipoUsuario != null) {
  print('⚠️ Usuario sin rol, asignando automáticamente...');
  
  // Mapear tipo_usuario a id_rol
  final idRol = _tipoUsuario == TipoUsuario.funcionario ? 2 : 3;
  
  final adminRepo = Modular.get<AdminRepository>();
  await adminRepo.asignarRol(
    AsignarRolRequest(
      idUsuario: state.usuario.idUsuario,
      idRol: idRol,
    ),
  );
  
  // Recargar usuario con rol actualizado
  final authRepo = Modular.get<AuthRepository>();
  final usuarioActualizado = await authRepo.getProfile();
  
  // Redirigir según el rol
  if (idRol == 2) {
    Modular.to.navigate('/profile/create-funcionario');
  } else {
    Modular.to.navigate('/profile/create');
  }
}
```

## 🚨 IMPORTANTE: Configurar Permisos en el Backend

Para que esto funcione, **el endpoint de asignar rol debe permitir auto-asignación** o:

### Opción 1: Backend Auto-Asigna Rol (RECOMENDADO)

Modificar el backend para que al registrarse con `tipo_usuario`, automáticamente asigne el rol:

```typescript
// En auth.service.ts o auth.controller.ts
async register(registerDto: RegisterDto) {
  const usuario = await this.usuariosService.create({
    ...registerDto,
    // Auto-asignar rol basándose en tipo_usuario
    id_rol: registerDto.tipo_usuario === 'funcionario' ? 2 : 3
  });
  
  return {
    message: 'Usuario registrado exitosamente',
    usuario,
    access_token: this.generateToken(usuario)
  };
}
```

### Opción 2: Endpoint Público para Auto-Asignación

Crear un endpoint especial que no requiera permisos de admin:

```typescript
// POST /auth/asignar-rol-inicial (sin protección de admin)
@Post('asignar-rol-inicial')
async asignarRolInicial(@Body() dto: { id_usuario: number, tipo_usuario: string }) {
  const idRol = dto.tipo_usuario === 'funcionario' ? 2 : 3;
  return this.usuariosService.asignarRol(dto.id_usuario, idRol);
}
```

### Opción 3: Asignación Manual (NO RECOMENDADO)

Si el backend no permite auto-asignación, tendrás que:
1. Registrar usuario
2. Hacer login como admin
3. Asignar rol manualmente desde el panel de admin
4. El usuario vuelve a hacer login

## 📊 Mapeo de Tipos a Roles

| Tipo Usuario | ID Rol | Nombre Rol | Descripción |
|--------------|--------|-----------|-------------|
| `funcionario` | 2 | funcionario | Gestiona proyectos/tareas/inscripciones |
| `voluntario` | 3 | voluntario | Acceso limitado, puede inscribirse |
| N/A (admin) | 1 | admin | Administrador completo |

## 🧪 Cómo Probar

### 1. Registrar un Usuario Funcionario

1. Abrir la app
2. Ir a Registro
3. **Paso 0**: Seleccionar "Soy Funcionario"
4. Completar datos personales
5. Completar credenciales
6. Completar info adicional
7. Hacer clic en "Registrarse"

**Logs esperados en consola:**
```
🎯 Registrando usuario con tipo: funcionario
✅ Usuario registrado: Juan Pérez
✅ ID Rol actual: null
✅ Tipo de usuario seleccionado: funcionario
⚠️ Usuario sin rol, asignando automáticamente...
✅ Rol 2 asignado correctamente
✅ Usuario actualizado con rol: funcionario
➡️ Redirigiendo a crear perfil de funcionario
```

### 2. Registrar un Usuario Voluntario

Mismo proceso, pero seleccionando "Soy Voluntario" en el paso 0.

**Logs esperados:**
```
🎯 Registrando usuario con tipo: voluntario
⚠️ Usuario sin rol, asignando automáticamente...
✅ Rol 3 asignado correctamente
✅ Usuario actualizado con rol: voluntario
➡️ Redirigiendo a crear perfil de voluntario
```

### 3. Verificar en el Backend

Después del registro, verificar en la base de datos:

```sql
SELECT id_usuario, nombres, apellidos, email, id_rol 
FROM usuarios 
WHERE email = 'test@volunred.com';
```

Debe mostrar:
```
id_usuario | nombres | apellidos | email              | id_rol
-----------|---------|-----------|-------------------|-------
5          | Juan    | Pérez     | test@volunred.com | 2
```

## ⚠️ Posibles Errores

### Error 1: 403 Forbidden al Asignar Rol

```
❌ Error al asignar rol: No tienes permisos para esta acción
```

**Causa**: El endpoint `/administracion/roles/asignar-rol-usuario` requiere permisos de admin.

**Solución**: Implementar Opción 1 o 2 del backend (ver arriba).

### Error 2: Usuario Sin Rol Después del Registro

**Causa**: El backend no guardó el `tipo_usuario` o no lo procesó.

**Verificar**:
```dart
print('✅ Tipo enviado al backend: ${_tipoUsuario?.value}');
// Debe mostrar: funcionario o voluntario
```

**Solución**: Verificar que el backend recibe y procesa el campo `tipo_usuario`.

### Error 3: Redirige Mal

**Causa**: El mapeo de `tipo_usuario` a `id_rol` está incorrecto.

**Verificar**:
```dart
final idRol = _tipoUsuario == TipoUsuario.funcionario ? 2 : 3;
print('🎯 ID Rol calculado: $idRol');
```

## 🔧 Alternativa: Asignación Manual Temporal

Si no puedes modificar el backend inmediatamente, puedes asignar roles manualmente:

### Opción A: Desde la Base de Datos

```sql
-- Asignar rol de funcionario
UPDATE usuarios SET id_rol = 2 WHERE email = 'funcionario@volunred.com';

-- Asignar rol de voluntario
UPDATE usuarios SET id_rol = 3 WHERE email = 'voluntario@volunred.com';

-- Asignar rol de admin
UPDATE usuarios SET id_rol = 1 WHERE email = 'admin@volunred.com';
```

### Opción B: Desde el Panel de Admin

1. Crear un usuario admin manualmente (BD):
   ```sql
   UPDATE usuarios SET id_rol = 1 WHERE email = 'admin@volunred.com';
   ```
2. Login como admin
3. Ir a Panel de Admin → Usuarios
4. Asignar rol a cada usuario

## 📝 Resumen

**Lo que está listo:**
- ✅ Frontend detecta usuarios sin rol
- ✅ Frontend intenta asignar rol automáticamente
- ✅ Frontend maneja errores si no tiene permisos
- ✅ Frontend redirige correctamente según el rol

**Lo que falta en el backend:**
- ❌ Auto-asignar rol basándose en `tipo_usuario` durante el registro
- ❌ O crear endpoint público para auto-asignación inicial

**Recomendación final:** Modifica el backend para que al registrarse, automáticamente asigne el rol basándose en el `tipo_usuario`. Es la solución más limpia y segura.
