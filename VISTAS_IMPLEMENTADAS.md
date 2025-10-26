# 📱 Vistas Implementadas - VolunRed

## ✅ Estado de Implementación

### 🎨 Sistema de Diseño (100% Completo)
- ✅ **AppColors** - Paleta de colores centralizada
- ✅ **AppStyles** - Constantes de diseño (espaciado, fuentes, bordes)
- ✅ **AppWidgets** - Componentes reutilizables
- ✅ **SISTEMA_DISENO.md** - Documentación completa

---

## 🔐 Módulo de Autenticación

### 1. Welcome Page (`/`)
**Archivo:** `lib/features/auth/pages/welcome_page.dart`

**Estado:** ✅ Completado y estandarizado

**Características:**
- Carousel minimalista con 3 slides informativos
- Botones de "Iniciar Sesión" y "Registrarse"
- Diseño Apple-style con gradientes
- 100% usando sistema de diseño

**API Relacionada:** Ninguna (página estática)

---

### 2. Login Page (`/auth/`)
**Archivo:** `lib/features/auth/pages/login_page.dart`

**Estado:** ✅ Completado y estandarizado

**Características:**
- Formulario de email y contraseña
- Validación en tiempo real
- Botón "Olvidé mi contraseña"
- Link a página de registro
- Navegación a `/home/` después del login exitoso

**API Consumida:**
```
POST /auth/login
{
  "email": "usuario@example.com",
  "contrasena": "password123"
}
```

**Flujo:**
1. Usuario ingresa credenciales
2. AuthBloc envía AuthLoginRequested
3. AuthRepository.login() llama a la API
4. Guarda token y usuario en localStorage
5. Navega a `/home/`

---

### 3. Register Page (`/auth/register`)
**Archivo:** `lib/features/auth/pages/register_page.dart`

**Estado:** ✅ Completado y estandarizado (100%)

**Características:**
- Formulario multi-paso (3 pasos)
- Paso 1: Datos personales (nombres, apellidos)
- Paso 2: Credenciales (email, contraseña)
- Paso 3: Información adicional (teléfono, CI, sexo - opcional)
- Carousel animado en header mostrando progreso
- Validación de fortaleza de contraseña
- Todos los componentes usan AppWidgets
- Colores y espaciado completamente parametrizados

**API Consumida:**
```
POST /auth/register
{
  "nombres": "Juan",
  "apellidos": "Pérez",
  "email": "juan@example.com",
  "contrasena": "password123",
  "telefono": 78945612,      // opcional
  "ci": 9876543,             // opcional
  "sexo": "M"                // opcional
}
```

**Flujo:**
1. Usuario completa 3 pasos del formulario
2. AuthBloc envía AuthRegisterRequested
3. AuthRepository.register() llama a la API
4. Guarda token y usuario
5. Navega a `/profile/create` para crear perfil de voluntario

---

## 👤 Módulo de Perfil

### 4. Create Profile Page (`/profile/create`)
**Archivo:** `lib/features/profile/pages/create_profile_page.dart`

**Estado:** ✅ Completado (con estilos clásicos, pendiente actualización a sistema de diseño)

**Características:**
- Formulario para crear perfil de voluntario
- Campo bio (250 caracteres máx)
- Selección de disponibilidad (chips seleccionables)
- Opción de disponibilidad personalizada
- Indicador de progreso (Perfil → Aptitudes)
- Opción de omitir

**API Consumida:**
```
POST /perfiles-voluntarios
{
  "usuario_id": 1,
  "bio": "Estudiante apasionado por el voluntariado...",
  "disponibilidad": "Fines de semana",
  "estado": "activo"
}
```

**Flujo:**
1. Usuario completa bio y disponibilidad
2. ProfileBloc envía CreatePerfilRequested
3. VoluntarioRepository.createPerfil() llama a la API
4. Guarda perfil de voluntario
5. Navega a `/profile/aptitudes` para seleccionar aptitudes

---

### 5. Select Aptitudes Page (`/profile/aptitudes`)
**Archivo:** `lib/features/profile/pages/select_aptitudes_page.dart`

**Estado:** ⏳ Pendiente de revisión/actualización

**Características:**
- Lista de aptitudes disponibles
- Selección múltiple
- Asignación de aptitudes al perfil

**APIs Consumidas:**
```
GET /aptitudes
[
  {
    "id_aptitud": 1,
    "nombre": "Trabajo en equipo",
    "descripcion": "Capacidad para colaborar..."
  },
  ...
]

POST /aptitudes-voluntario
{
  "perfil_vol_id": 1,
  "aptitud_id": 3
}
```

**Flujo:**
1. Carga lista de aptitudes disponibles
2. Usuario selecciona aptitudes relevantes
3. Al confirmar, crea múltiples registros aptitud-voluntario
4. Navega a `/home/`

---

## 🏠 Módulo Home

### 6. Home Page (`/home/`)
**Archivo:** `lib/features/home/pages/home_page.dart`

**Estado:** ✅ Completado y estandarizado

**Características:**
- **Tab 1: Inicio**
  - AppBar con gradiente y saludo personalizado
  - Sección de estadísticas (Actividades y Horas)
  - Acciones rápidas (4 cards):
    - Buscar Actividades
    - Mis Experiencias → `/experiencias`
    - Notificaciones
    - Organizaciones
  - Lista de actividades recientes (vacía por ahora)

- **Tab 2: Actividades**
  - Lista de actividades del voluntario
  - Estado vacío por defecto

- **Tab 3: Perfil**
  - Avatar con inicial del usuario
  - Opciones:
    - Editar Perfil
    - Mis Aptitudes → `/profile/aptitudes`
    - Experiencias → `/experiencias`
    - Configuración
  - Botón de cerrar sesión

**Bottom Navigation Bar:**
- Inicio
- Actividades
- Perfil

**API Relacionadas:**
```
GET /auth/profile
{
  "id_usuario": 1,
  "nombres": "Juan",
  "apellidos": "Pérez",
  "email": "juan@example.com"
}
```

**Flujo:**
- Carga información del usuario desde storage
- Muestra datos del perfil
- Permite navegación a otras secciones
- Logout limpia storage y vuelve a `/auth/`

---

## 📝 Módulo Experiencias

### 7. Experiencias Page (`/experiencias`)
**Archivo:** `lib/features/experiencias/pages/experiencias_page.dart`

**Estado:** ✅ Completado y estandarizado

**Características:**
- Formulario para agregar experiencias de voluntariado
- Campos:
  - Organización (requerido)
  - Área (opcional)
  - Descripción (opcional, 500 caracteres máx)
  - Fecha de inicio (requerido, date picker)
  - Fecha de fin o checkbox "Trabajo actualmente aquí"
- Lista de experiencias agregadas
- Opción de eliminar experiencias
- Cards con diseño limpio y organizado

**API a Consumir (pendiente integración):**
```
POST /experiencias-voluntario
{
  "organizacion_id": 2,
  "area": "Educación y capacitación",
  "descripcion": "Apoyo en talleres de alfabetización digital...",
  "fecha_inicio": "2024-03-15",
  "fecha_fin": "2024-08-30"
}

GET /experiencias-voluntario
[
  {
    "id_experiencia": 1,
    "organizacion_id": 2,
    "area": "Educación",
    ...
  }
]
```

**Nota:** Actualmente funciona con datos locales (simulación). Falta integrar con BLoC y repositorio para persistir en backend.

---

## 📊 Resumen de Integración con API

| Endpoint | Vista | Estado |
|----------|-------|--------|
| `POST /auth/register` | Register Page | ✅ Integrado |
| `POST /auth/login` | Login Page | ✅ Integrado |
| `GET /auth/profile` | Home Page | ✅ Integrado |
| `POST /perfiles-voluntarios` | Create Profile | ✅ Integrado |
| `GET /aptitudes` | Select Aptitudes | ⏳ Revisar integración |
| `POST /aptitudes-voluntario` | Select Aptitudes | ⏳ Revisar integración |
| `POST /experiencias-voluntario` | Experiencias Page | ❌ Pendiente |
| `GET /experiencias-voluntario` | Experiencias Page | ❌ Pendiente |

---

## 🎯 Flujo Completo del Usuario

### 📝 Flujo de Registro:
```
1. Welcome Page (/)
2. Click "Registrarse" → Register Page (/auth/register)
3. Completa 3 pasos del formulario
4. API: POST /auth/register → Guarda token
5. Navega a Create Profile (/profile/create)
6. Completa perfil de voluntario
7. API: POST /perfiles-voluntarios
8. Navega a Select Aptitudes (/profile/aptitudes)
9. Selecciona aptitudes
10. API: POST /aptitudes-voluntario (múltiples)
11. Navega a Home (/home/)
```

### 🔐 Flujo de Login:
```
1. Welcome Page (/)
2. Click "Iniciar Sesión" → Login Page (/auth/)
3. Ingresa credenciales
4. API: POST /auth/login → Guarda token
5. Navega a Home (/home/)
```

### 🏠 Flujo en Home:
```
1. Home Page (/home/)
2. Ver estadísticas y actividades
3. Navegación:
   - Mis Experiencias → /experiencias
   - Mis Aptitudes → /profile/aptitudes
   - Configuración (pendiente)
   - Cerrar Sesión → /auth/
```

---

## 🎨 Consistencia de Diseño

### ✅ Páginas 100% Estandarizadas:
- ✅ Welcome Page
- ✅ Login Page
- ✅ Register Page (★ REFERENCIA)
- ✅ Home Page
- ✅ Experiencias Page

### ⏳ Páginas Pendientes de Actualización:
- ⏳ Create Profile Page (funcional, pero con estilos antiguos)
- ⏳ Select Aptitudes Page (requiere revisión)

### 🎨 Componentes del Sistema de Diseño Utilizados:

1. **AppColors:**
   - `primary`, `primaryGradient`
   - `success`, `error`, `warning`, `info`
   - `textPrimary`, `textSecondary`
   - `infoBackground`, `infoBorder`, `infoText`
   - `cardBackground`, `surface`, `border`

2. **AppStyles:**
   - `spacingSmall`, `spacingMedium`, `spacingLarge`, `spacingXLarge`
   - `fontSizeSmall`, `fontSizeBody`, `fontSizeTitle`, `fontSizeHeader`
   - `borderRadiusSmall`, `borderRadiusMedium`, `borderRadiusLarge`
   - `buttonHeightLarge`, `iconSizeMedium`, `iconSizeLarge`

3. **AppWidgets:**
   - `styledTextField()` - Campos de entrada consistentes
   - `gradientButton()` - Botones con gradiente y loading
   - `gradientCard()` - Cards con gradiente
   - `decorativeIcon()` - Íconos decorativos
   - `showStyledSnackBar()` - Mensajes de feedback
   - `pageHeader()` - Headers de página
   - `backButton()` - Botón de retroceso

---

## 🔄 Navegación entre Vistas

```
/                          → WelcomePage
/auth/                     → LoginPage
/auth/register             → RegisterPage
/profile/create            → CreateProfilePage
/profile/aptitudes         → SelectAptitudesPage
/home/                     → HomePage (con 3 tabs)
/experiencias              → ExperienciasPage
```

---

## ⚙️ Configuración de Rutas (AppModule)

**Archivo:** `lib/app_module.dart`

```dart
List<ModularRoute> get routes => [
  ChildRoute('/', child: (_, __) => const WelcomePage()),
  ModuleRoute('/auth', module: AuthModule()),
  ModuleRoute('/profile', module: ProfileModule()),
  ModuleRoute('/home', module: HomeModule()),
  ModuleRoute('/experiencias', module: ExperienciasModule()),
];
```

---

## 📦 Próximas Funcionalidades

### ⏳ En Desarrollo:
1. **Búsqueda de Actividades** - Vista para explorar oportunidades
2. **Detalle de Actividad** - Ver información completa y postularse
3. **Notificaciones** - Centro de notificaciones
4. **Organizaciones** - Directorio de organizaciones
5. **Configuración** - Ajustes de cuenta y preferencias

### 🔧 Mejoras Técnicas Pendientes:
1. Actualizar Create Profile Page a sistema de diseño
2. Revisar e integrar Select Aptitudes Page
3. Conectar Experiencias Page con backend (BLoC + Repository)
4. Implementar refresh tokens
5. Agregar manejo de errores 401 global
6. Implementar cache local para offline support

---

## 📱 Capturas de Pantalla de Referencia

### Diseño Minimalista Apple-Style:
- ✅ Colores suaves y profesionales
- ✅ Espaciado generoso
- ✅ Gradientes sutiles
- ✅ Bordes redondeados
- ✅ Transiciones suaves
- ✅ Iconos decorativos
- ✅ Sombras ligeras

### Características Visuales:
- Paleta de colores verde (#0D4C3D) como principal
- Gradientes: verde, azul, naranja, púrpura
- Tipografía clara y legible
- Cards con sombras sutiles
- Botones con gradiente y efectos hover
- Feedback visual inmediato (SnackBars)

---

## 🧪 Testing

### ⏳ Pendiente:
- Unit tests para BLoCs
- Widget tests para páginas
- Integration tests para flujos completos

---

**Última actualización:** 25 de Octubre, 2025  
**Desarrollado por:** Equipo VolunRed  
**Framework:** Flutter 3.35.7  
**Estado General:** 70% Completo
