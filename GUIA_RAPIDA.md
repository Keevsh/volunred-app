# 🚀 Guía Rápida - VolunRed Flutter App

## ✅ Lo que ya está implementado

### 1. **Arquitectura Base**
- ✅ BLoC para gestión de estado
- ✅ Flutter Modular para navegación e inyección de dependencias
- ✅ Estructura de carpetas por features (auth, profile, home)
- ✅ Repositorios para separar lógica de negocio
- ✅ Modelos de datos (Usuario, PerfilVoluntario, Aptitud)

### 2. **Autenticación**
- ✅ `LoginPage` - Iniciar sesión
- ✅ `RegisterPage` - Registro de usuarios
- ✅ `AuthBloc` - Gestión de estados de autenticación
- ✅ `AuthRepository` - Llamadas a la API
- ✅ Almacenamiento de JWT en SharedPreferences
- ✅ Interceptor automático para agregar token a requests

### 3. **Perfil de Voluntario**
- ✅ `CreateProfilePage` - Crear perfil (bio, disponibilidad)
- ✅ `SelectAptitudesPage` - Seleccionar aptitudes
- ✅ `ProfileBloc` - Gestión de estados de perfil
- ✅ `VoluntarioRepository` - Llamadas a la API

### 4. **Servicios**
- ✅ `DioClient` - Cliente HTTP configurado
- ✅ `AuthInterceptor` - Interceptor JWT automático
- ✅ `StorageService` - Persistencia local
- ✅ Manejo de errores HTTP

## 📋 Próximos Pasos

### 1. **Ejecutar el proyecto**

```bash
# Asegúrate de tener el backend corriendo en http://localhost:3000
fvm flutter run
```

### 2. **Configurar URL del Backend**

Si tu backend está en otra URL, edita:

**`lib/core/config/api_config.dart`**
```dart
static const String baseUrl = 'http://TU_IP:3000';
```

### 3. **Probar el Flujo Completo**

1. **Registrar usuario**
   - Abrir la app → Click "Regístrate"
   - Llenar formulario → Click "Registrarse"
   - Automáticamente navega a crear perfil

2. **Crear perfil de voluntario**
   - Llenar bio y disponibilidad
   - Click "Continuar"
   - Navega a selección de aptitudes

3. **Seleccionar aptitudes**
   - Seleccionar al menos una aptitud
   - Click "Guardar y Continuar"
   - Navega al Home

4. **Login**
   - Usar email y contraseña registrados
   - Automáticamente navega al Home

## 🛠️ Comandos Útiles

```bash
# Instalar dependencias
fvm flutter pub get

# Ejecutar análisis estático
fvm flutter analyze

# Ejecutar tests
fvm flutter test

# Limpiar build
fvm flutter clean

# Ejecutar en dispositivo específico
fvm flutter devices
fvm flutter run -d <device_id>

# Hot reload
# Mientras la app está corriendo, presiona 'r'

# Hot restart
# Mientras la app está corriendo, presiona 'R'
```

## 🐛 Debugging

### Ver logs en tiempo real

```bash
fvm flutter run --verbose
```

### Logs de HTTP (Dio)

Los logs de Dio están habilitados automáticamente en desarrollo:

```
[INFO] --> POST http://localhost:3000/auth/login
[INFO] {"email":"test@example.com","contrasena":"password123"}
[INFO] <-- 200 OK (120ms)
```

### Ver estado de BLoC

Agrega esto en `main.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

class SimpleBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('${bloc.runtimeType} $change');
  }
}

void main() {
  Bloc.observer = SimpleBlocObserver();
  runApp(ModularApp(module: AppModule(), child: const AppWidget()));
}
```

## 📱 Probando en Emulador Android

Si tu backend está en `localhost:3000`, debes cambiar la URL a:

**`lib/core/config/api_config.dart`**
```dart
static const String baseUrl = 'http://10.0.2.2:3000';
```

`10.0.2.2` es la IP especial que Android emulator usa para referirse al `localhost` de tu PC.

## 🎨 Personalizar Estilos

Edita `lib/app_widget.dart`:

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), // Cambia el color
  useMaterial3: true,
),
```

## 🔐 Gestión de Sesión

### Verificar si hay sesión activa

```dart
final authRepo = Modular.get<AuthRepository>();
final isAuth = await authRepo.isAuthenticated();

if (isAuth) {
  final usuario = await authRepo.getStoredUser();
  print(usuario.nombres);
}
```

### Cerrar sesión

```dart
BlocProvider.of<AuthBloc>(context).add(AuthLogoutRequested());
```

## 📊 Estructura de Navegación

```
/                      → AuthModule (login)
  /auth/
    /                  → LoginPage
    /register          → RegisterPage
  
  /profile/
    /create            → CreateProfilePage
    /aptitudes         → SelectAptitudesPage
  
  /home/
    /                  → HomePage
```

### Navegar entre pantallas

```dart
// Navegar a una ruta
Modular.to.navigate('/home/');

// Navegar y reemplazar (no volver atrás)
Modular.to.pushReplacementNamed('/home/');

// Navegar y agregar al stack
Modular.to.pushNamed('/profile/create');

// Volver atrás
Modular.to.pop();
```

## 🧩 Agregar Nuevas Features

### 1. Crear nueva feature

```bash
mkdir -p lib/features/nueva_feature/{bloc,pages}
```

### 2. Crear BLoC

```dart
// lib/features/nueva_feature/bloc/nueva_event.dart
abstract class NuevaEvent extends Equatable {}

// lib/features/nueva_feature/bloc/nueva_state.dart
abstract class NuevaState extends Equatable {}

// lib/features/nueva_feature/bloc/nueva_bloc.dart
class NuevaBloc extends Bloc<NuevaEvent, NuevaState> {
  NuevaBloc() : super(NuevaInitial());
}
```

### 3. Crear Módulo

```dart
// lib/features/nueva_feature/nueva_module.dart
class NuevaModule extends Module {
  @override
  List<Bind> get binds => [
    Bind.factory((i) => NuevaBloc()),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (_, __) => BlocProvider(
      create: (_) => Modular.get<NuevaBloc>(),
      child: const NuevaPa ge(),
    )),
  ];
}
```

### 4. Registrar en AppModule

```dart
ModuleRoute('/nueva', module: NuevaModule()),
```

## 🔄 Actualizar Datos en Tiempo Real

### Opción 1: Usar StreamBuilder con BLoC

```dart
BlocBuilder<ProfileBloc, ProfileState>(
  builder: (context, state) {
    if (state is AptitudesLoaded) {
      return ListView.builder(
        itemCount: state.aptitudes.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(state.aptitudes[index].nombre));
        },
      );
    }
    return CircularProgressIndicator();
  },
)
```

### Opción 2: BlocListener para acciones

```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthAuthenticated) {
      Modular.to.navigate('/home/');
    } else if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  child: YourWidget(),
)
```

## 🎯 Features Sugeridas para Implementar

- [ ] Recuperación de contraseña
- [ ] Perfil de usuario (editar datos)
- [ ] Listado de voluntariados disponibles
- [ ] Aplicar a voluntariados
- [ ] Chat entre voluntarios y organizaciones
- [ ] Notificaciones push
- [ ] Modo offline con sincronización
- [ ] Filtros y búsqueda avanzada
- [ ] Historial de voluntariados
- [ ] Sistema de puntos/badges
- [ ] Compartir en redes sociales

## 📞 Endpoints de la API

Ver el archivo con la documentación completa de la API que te proporcioné para referencia de todos los endpoints disponibles.

## 🆘 Problemas Comunes

### Error: "Target of URI doesn't exist"

**Solución**: Ejecuta `flutter pub get`

### Error de conexión

**Solución**: 
1. Verifica que el backend esté corriendo
2. En Android emulator usa `http://10.0.2.2:3000`
3. Revisa el firewall

### Estado no se actualiza

**Solución**: Asegúrate de usar `BlocBuilder` o `BlocListener`

### Token expirado

**Solución**: El interceptor limpia automáticamente el storage en errores 401

---

**¡Listo para desarrollar!** 🚀

Si tienes dudas, revisa el código de ejemplo en cada feature.
