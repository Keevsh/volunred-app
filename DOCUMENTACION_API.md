# 📖 Documentación API Backend - VolunRed

## 🌐 Configuración

**URL Base:** `http://localhost:3000`  
**Swagger Docs:** `http://localhost:3000/api/docs`

> Para Android Emulator usa: `http://10.0.2.2:3000`

---

## 🔐 AUTENTICACIÓN

### 1. Registro (Sign Up)

**Endpoint:** `POST /auth/register`  
**Auth:** No requiere token

#### Request:
```json
{
  "nombres": "Juan",
  "apellidos": "Pérez",
  "email": "juan@example.com",
  "contrasena": "password123",
  "telefono": 12345678,
  "ci": 1234567,
  "sexo": "M"
}
```

#### Response (201):
```json
{
  "message": "Usuario registrado exitosamente",
  "usuario": {
    "id_usuario": 1,
    "nombres": "Juan",
    "apellidos": "Pérez",
    "email": "juan@example.com"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

### 2. Login

**Endpoint:** `POST /auth/login`  
**Auth:** No requiere token

#### Request:
```json
{
  "email": "juan@example.com",
  "contrasena": "password123"
}
```

#### Response (200):
```json
{
  "message": "Login exitoso",
  "usuario": {
    "id_usuario": 1,
    "nombres": "Juan",
    "apellidos": "Pérez",
    "email": "juan@example.com"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

### 3. Obtener Perfil

**Endpoint:** `GET /auth/profile`  
**Auth:** ✅ Requiere Token JWT

#### Headers:
```
Authorization: Bearer {access_token}
```

#### Response (200):
```json
{
  "id_usuario": 1,
  "nombres": "Juan",
  "apellidos": "Pérez",
  "email": "juan@example.com",
  "telefono": 12345678,
  "ci": 1234567,
  "sexo": "M",
  "creado_en": "2025-10-24T12:00:00.000Z"
}
```

---

## 👤 PERFILES VOLUNTARIOS

### 1. Crear Perfil de Voluntario

**Endpoint:** `POST /perfiles-voluntarios`  
**Auth:** ✅ Requiere Token JWT

#### Request:
```json
{
  "usuario_id": 1,
  "bio": "Estudiante interesado en proyectos ambientales",
  "disponibilidad": "Fines de semana",
  "estado": "activo"
}
```

#### Response (201):
```json
{
  "id_perfil_voluntario": 1,
  "bio": "Estudiante interesado en proyectos ambientales",
  "disponibilidad": "Fines de semana",
  "estado": "activo",
  "usuario_id": 1
}
```

---

### 2. Listar Perfiles

**Endpoint:** `GET /perfiles-voluntarios`  
**Auth:** ✅ Requiere Token JWT

#### Response (200):
```json
[
  {
    "id_perfil_voluntario": 1,
    "bio": "...",
    "disponibilidad": "Fines de semana",
    "estado": "activo",
    "usuario_id": 1
  }
]
```

---

### 3. Obtener Perfil por ID

**Endpoint:** `GET /perfiles-voluntarios/:id`  
**Auth:** ✅ Requiere Token JWT

---

### 4. Actualizar Perfil

**Endpoint:** `PATCH /perfiles-voluntarios/:id`  
**Auth:** ✅ Requiere Token JWT

---

## 🎯 APTITUDES

### 1. Listar Aptitudes

**Endpoint:** `GET /aptitudes`  
**Auth:** ✅ Requiere Token JWT

#### Response (200):
```json
[
  {
    "id_aptitud": 1,
    "nombre": "Trabajo en equipo",
    "descripcion": "Capacidad para colaborar efectivamente",
    "estado": "activo",
    "creado_en": "2025-10-24T14:30:00.000Z"
  },
  {
    "id_aptitud": 2,
    "nombre": "Liderazgo",
    "descripcion": "Habilidad para guiar y motivar",
    "estado": "activo"
  }
]
```

---

### 2. Asignar Aptitud a Voluntario

**Endpoint:** `POST /aptitudes-voluntario`  
**Auth:** ✅ Requiere Token JWT

#### Request:
```json
{
  "perfil_vol_id": 1,
  "aptitud_id": 3
}
```

#### Response (201):
```json
{
  "id_aptitud_vol": 1,
  "perfil_vol_id": 1,
  "aptitud_id": 3
}
```

---

### 3. Obtener Aptitudes de un Voluntario

**Endpoint:** `GET /aptitudes-voluntario/voluntario/:id`  
**Auth:** ✅ Requiere Token JWT

---

## 📋 EXPERIENCIAS VOLUNTARIO

### 1. Agregar Experiencia

**Endpoint:** `POST /experiencias-voluntario`  
**Auth:** ✅ Requiere Token JWT

#### Request:
```json
{
  "organizacion_id": 2,
  "area": "Educación y capacitación",
  "descripcion": "Apoyo en talleres de alfabetización digital",
  "fecha_inicio": "2024-03-15",
  "fecha_fin": "2024-08-30"
}
```

---

### 2. Listar Experiencias

**Endpoint:** `GET /experiencias-voluntario`  
**Auth:** ✅ Requiere Token JWT

---

## 🏢 USUARIOS

### 1. Listar Usuarios

**Endpoint:** `GET /usuarios`  
**Auth:** ✅ Requiere Token JWT

---

### 2. Obtener Usuario por ID

**Endpoint:** `GET /usuarios/:id`  
**Auth:** ✅ Requiere Token JWT

---

### 3. Actualizar Usuario

**Endpoint:** `PATCH /usuarios/:id`  
**Auth:** ✅ Requiere Token JWT

---

## ❌ Códigos de Error

| Código | Descripción | Acción |
|--------|-------------|--------|
| 200 | OK | Todo correcto |
| 201 | Created | Recurso creado |
| 400 | Bad Request | Datos inválidos |
| 401 | Unauthorized | Token inválido/expirado |
| 404 | Not Found | Recurso no encontrado |
| 409 | Conflict | Email duplicado |
| 500 | Server Error | Error del servidor |

---

## 🔑 Token JWT

- **Duración:** 1 año (365 días)
- **Storage:** SharedPreferences con clave `access_token`
- **Header:** `Authorization: Bearer {token}`
- **Manejo:** El interceptor de Dio lo agrega automáticamente

### Expiración del Token

Cuando el token expira (error 401):
1. El interceptor limpia automáticamente el storage
2. El usuario es redirigido a login
3. Debe iniciar sesión nuevamente

---

## 🚀 Flujo Completo de Registro

```
1. POST /auth/register
   ↓
2. Guardar access_token y usuario en storage
   ↓
3. POST /perfiles-voluntarios (crear perfil)
   ↓
4. GET /aptitudes (obtener lista)
   ↓
5. POST /aptitudes-voluntario (asignar aptitudes)
   ↓
6. Navegar a Home
```

---

## 🧪 Testing con cURL

### Registro
```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"nombres":"Juan","apellidos":"Pérez","email":"juan@example.com","contrasena":"password123"}'
```

### Login
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"juan@example.com","contrasena":"password123"}'
```

### Crear Perfil (con token)
```bash
curl -X POST http://localhost:3000/perfiles-voluntarios \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"usuario_id":1,"bio":"Bio","disponibilidad":"Fines de semana","estado":"activo"}'
```

---

## 📚 Recursos Adicionales

- **Swagger UI:** http://localhost:3000/api/docs
- **Postman Collection:** (Importar desde Swagger)

---

_Documentación completa del backend VolunRed_
