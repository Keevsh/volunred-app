# VolunRed App - Flutter

Aplicación móvil para la plataforma VolunRed construida con **Flutter**, **BLoC** y **Flutter Modular**.

## 🏗️ Arquitectura del Proyecto

```
lib/
├── core/                           # Núcleo compartido
│   ├── config/
│   │   └── api_config.dart        # Configuración de URLs y endpoints
│   ├── models/
│   │   ├── usuario.dart           # Modelo de Usuario
│   │   ├── perfil_voluntario.dart # Modelo de Perfil
│   │   ├── aptitud.dart           # Modelo de Aptitud
│   │   └── dto/                   # Data Transfer Objects
│   ├── repositories/
│   │   ├── auth_repository.dart         # Repositorio de autenticación
│   │   └── voluntario_repository.dart   # Repositorio de voluntarios
│   └── services/
│       ├── dio_client.dart        # Cliente HTTP con Dio
│       └── storage_service.dart   # Servicio de almacenamiento local
├── features/                      # Features organizados por dominio
│   ├── auth/                      # Módulo de Autenticación
│   │   ├── auth_module.dart
│   │   ├── bloc/
│   │   └── pages/
│   └── profile/                   # Módulo de Perfil
│       ├── profile_module.dart
│       ├── bloc/
│       └── pages/
└── modules/home/                  # Módulo Home
```

## 📦 Dependencias Principales

```yaml
dependencies:
  flutter_bloc: ^8.1.3     # State Management
  flutter_modular: ^5.0.3  # Navigation & DI
  dio: ^5.4.0              # HTTP Client
  shared_preferences: ^2.2.2  # Local Storage
```

## 🚀 Ejecutar la Aplicación

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en modo desarrollo
flutter run
```

## 🔧 Configuración del Backend

Edita `lib/core/config/api_config.dart`:

```dart
static const String baseUrl = 'http://localhost:3000';
```

> **Nota**: Para emulador Android usa `http://10.0.2.2:3000`

## 📱 Flujo de la Aplicación

1. **Login/Registro** → `/auth/`
2. **Crear Perfil** → `/profile/create`
3. **Seleccionar Aptitudes** → `/profile/aptitudes`
4. **Home** → `/home/`

## 🔐 Autenticación

El sistema usa JWT almacenado en SharedPreferences. El interceptor de Dio agrega automáticamente el token a cada request.

## 📚 Documentación Completa

Ver [DOCUMENTACION_API.md](DOCUMENTACION_API.md) para endpoints completos del backend.

**🚨 IMPORTANTE**: Ver [BACKEND_ERRORS_GUIDE.md](BACKEND_ERRORS_GUIDE.md) para errores críticos del backend que afectan la funcionalidad.

---

**Desarrollado con ❤️ usando Flutter**
