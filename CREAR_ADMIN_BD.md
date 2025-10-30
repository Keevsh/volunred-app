# Creación de Cuenta de Administrador

## ⚠️ IMPORTANTE

**El administrador NO se crea desde la aplicación**, solo desde la base de datos directamente.

### ¿Por qué?

- El **admin solo gestiona** el sistema (usuarios, roles, permisos, programas)
- **NO tiene perfil de voluntario** (sin experiencias, aptitudes, etc.)
- **NO se inscribe en proyectos**
- **NO necesita completar información de voluntario**

## 📋 Roles del Sistema

| ID | Nombre | Descripción | Se registra por app |
|----|--------|-------------|---------------------|
| 1 | admin | Administrador del sistema | ❌ Solo desde BD |
| 2 | funcionario | Gestiona proyectos/tareas | ✅ Sí |
| 3 | voluntario | Participa en proyectos | ✅ Sí |

## 🔧 Pasos para Crear Admin

### Opción 1: Desde SQL Directo

```sql
-- 1. Crear el usuario admin
INSERT INTO usuarios (
    nombres, 
    apellidos, 
    email, 
    password, 
    sexo, 
    tipo_usuario,
    id_rol,
    estado
) VALUES (
    'Administrador',
    'Sistema',
    'admin@volunred.com',
    -- Password hasheado (debe ser el hash de tu contraseña)
    '$2a$10$TU_HASH_AQUI',
    'Masculino',
    'admin',
    1,  -- id_rol: 1 = admin
    true
);

-- 2. Verificar que se creó correctamente
SELECT id_usuario, nombres, apellidos, email, id_rol, tipo_usuario
FROM usuarios
WHERE id_rol = 1;
```

### Opción 2: Crear Usuario Normal y Luego Asignar Rol

```sql
-- 1. Primero crea un usuario normal (puedes hacerlo desde la app)
-- Registrarse como "voluntario" o "funcionario"

-- 2. Luego actualiza el rol a admin
UPDATE usuarios 
SET id_rol = 1, tipo_usuario = 'admin'
WHERE email = 'admin@volunred.com';

-- 3. Verificar
SELECT id_usuario, nombres, apellidos, email, id_rol, rol.nombre as rol_nombre
FROM usuarios
LEFT JOIN roles AS rol ON usuarios.id_rol = rol.id_rol
WHERE id_rol = 1;
```

### Opción 3: Script de Inicialización

Crea un archivo `init-admin.sql`:

```sql
-- Crear rol admin si no existe
INSERT INTO roles (id_rol, nombre, descripcion, estado)
VALUES (1, 'admin', 'Administrador del sistema con acceso completo', true)
ON CONFLICT (id_rol) DO NOTHING;

-- Crear usuario admin
INSERT INTO usuarios (
    nombres, 
    apellidos, 
    email, 
    password,
    sexo,
    tipo_usuario,
    id_rol,
    estado,
    fecha_registro
) VALUES (
    'Admin',
    'VolunRed',
    'admin@volunred.com',
    -- Password: Admin123! (debes hashearlo)
    '$2a$10$YourHashedPasswordHere',
    'Otro',
    'admin',
    1,
    true,
    NOW()
)
ON CONFLICT (email) DO UPDATE 
SET id_rol = 1, tipo_usuario = 'admin';
```

## 🔐 Hashear la Contraseña

El backend usa bcrypt para hashear contraseñas. Tienes dos opciones:

### A. Usar Node.js

```javascript
const bcrypt = require('bcrypt');

async function hashPassword(password) {
  const hash = await bcrypt.hash(password, 10);
  console.log('Hash:', hash);
}

hashPassword('Admin123!');
// Resultado: $2a$10$TU_HASH_AQUI
```

### B. Usar un Servicio Online

1. Ir a: https://bcrypt-generator.com/
2. Ingresar contraseña: `Admin123!`
3. Rounds: `10`
4. Copiar el hash generado

### C. Desde el Backend (Recomendado)

Crea un endpoint temporal en tu backend:

```typescript
// En auth.controller.ts
@Post('hash-password')
async hashPassword(@Body('password') password: string) {
  const hash = await bcrypt.hash(password, 10);
  return { hash };
}
```

Luego desde Postman:
```
POST http://192.168.26.3:3000/auth/hash-password
Body: { "password": "Admin123!" }
```

**IMPORTANTE:** Elimina este endpoint después de crear el admin.

## 📝 Credenciales Sugeridas

```
Email: admin@volunred.com
Password: Admin123!
Nombres: Administrador
Apellidos: Sistema
```

## ✅ Verificar el Admin

### 1. Desde la Base de Datos

```sql
SELECT 
    u.id_usuario,
    u.nombres,
    u.apellidos,
    u.email,
    u.id_rol,
    r.nombre as rol_nombre,
    u.estado
FROM usuarios u
LEFT JOIN roles r ON u.id_rol = r.id_rol
WHERE u.id_rol = 1;
```

Debe mostrar:
```
id_usuario | nombres        | apellidos | email               | id_rol | rol_nombre | estado
-----------|----------------|-----------|---------------------|--------|------------|-------
1          | Administrador  | Sistema   | admin@volunred.com  | 1      | admin      | true
```

### 2. Desde la App

1. Abrir la app
2. Hacer login con las credenciales del admin
3. Verificar que aparece el **botón morado de Admin** en la página Home
4. Hacer clic en el botón
5. Debe aparecer el **Panel de Administración**

### 3. Verificar Permisos

Probar en el panel de admin:
- ✅ Ver lista de usuarios
- ✅ Asignar roles
- ✅ Ver y gestionar roles
- ✅ Asignar permisos
- ✅ Ver programas

## 🚫 Restricciones del Admin

El usuario admin **NO debe**:
- ❌ Tener perfil de voluntario
- ❌ Completar experiencias/aptitudes/idiomas
- ❌ Inscribirse en proyectos
- ❌ Ver página de "Mis Proyectos"
- ❌ Acceder a funcionalidades de voluntario

El admin **solo debe**:
- ✅ Gestionar usuarios (CRUD, asignar roles)
- ✅ Gestionar roles (CRUD)
- ✅ Asignar permisos (programas a roles)
- ✅ Ver información del sistema
- ✅ Gestionar módulos/aplicaciones/programas

## 🔄 Flujo de Usuarios en el Sistema

```
┌─────────────────┐
│  Registro App   │
└────────┬────────┘
         │
         ├─► Voluntario (id_rol: 3)
         │   └─► Crear perfil → Buscar proyectos → Inscribirse
         │
         └─► Funcionario (id_rol: 2)
             └─► Crear perfil → Crear proyectos → Gestionar

┌─────────────────┐
│  Base de Datos  │
└────────┬────────┘
         │
         └─► Admin (id_rol: 1)
             └─► Panel Admin → Gestionar todo
```

## 📌 Notas Finales

1. **Nunca crees admin desde la app** - Siempre desde BD
2. **El admin no tiene perfil** - Solo credenciales
3. **Un admin puede asignar roles** - A otros usuarios
4. **Puedes tener varios admins** - Todos con id_rol = 1
5. **Protege bien las credenciales** - Es acceso total al sistema

## 🆘 Troubleshooting

### No puedo hacer login como admin

```sql
-- Verificar que existe
SELECT * FROM usuarios WHERE email = 'admin@volunred.com';

-- Verificar que tiene rol admin
SELECT id_rol FROM usuarios WHERE email = 'admin@volunred.com';
-- Debe retornar: 1

-- Verificar que está activo
SELECT estado FROM usuarios WHERE email = 'admin@volunred.com';
-- Debe retornar: true
```

### No aparece el botón de admin

- Verificar en consola: `print('isAdmin: ${usuario.isAdmin}');`
- El getter `isAdmin` debe retornar `true`
- Revisa que `usuario.idRol == 1`

### Error al acceder al panel

- El endpoint `/administracion/*` debe permitir acceso a usuarios con rol admin
- Verificar permisos en el backend
- Revisar logs del servidor
