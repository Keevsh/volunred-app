# 📝 Ejemplos de Código - VolunRed

## 🔐 Autenticación

### Registrar Usuario

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/models/dto/request_models.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_event.dart';

void registrarUsuario(BuildContext context) {
  BlocProvider.of<AuthBloc>(context).add(
    AuthRegisterRequested(
      RegisterRequest(
        nombres: "María",
        apellidos: "González",
        email: "maria@example.com",
        contrasena: "password123",
        telefono: 78945612,
        ci: 9876543,
        sexo: "F",
      ),
    ),
  );
}
```

### Login

```dart
void iniciarSesion(BuildContext context, String email, String password) {
  BlocProvider.of<AuthBloc>(context).add(
    AuthLoginRequested(
      LoginRequest(
        email: email,
        contrasena: password,
      ),
    ),
  );
}
```

### Verificar Autenticación

```dart
import 'package:flutter_modular/flutter_modular.dart';
import '../core/repositories/auth_repository.dart';

Future<void> verificarSesion() async {
  final authRepo = Modular.get<AuthRepository>();
  final isAuthenticated = await authRepo.isAuthenticated();
  
  if (isAuthenticated) {
    final usuario = await authRepo.getStoredUser();
    print('Usuario: ${usuario?.nombreCompleto}');
  } else {
    print('No hay sesión activa');
  }
}
```

### Logout

```dart
void cerrarSesion(BuildContext context) {
  BlocProvider.of<AuthBloc>(context).add(AuthLogoutRequested());
  Modular.to.navigate('/auth/');
}
```

---

## 👤 Perfil de Voluntario

### Crear Perfil

```dart
import '../features/profile/bloc/profile_bloc.dart';
import '../features/profile/bloc/profile_event.dart';

void crearPerfil(BuildContext context, int usuarioId) {
  BlocProvider.of<ProfileBloc>(context).add(
    CreatePerfilRequested(
      CreatePerfilVoluntarioRequest(
        usuarioId: usuarioId,
        bio: "Apasionado por el voluntariado ambiental",
        disponibilidad: "Fines de semana",
        estado: "activo",
      ),
    ),
  );
}
```

### Cargar Aptitudes

```dart
void cargarAptitudes(BuildContext context) {
  BlocProvider.of<ProfileBloc>(context).add(LoadAptitudesRequested());
}
```

### Asignar Aptitudes

```dart
void asignarAptitudes(BuildContext context, int perfilId, List<int> aptitudesIds) {
  BlocProvider.of<ProfileBloc>(context).add(
    AsignarAptitudesRequested(perfilId, aptitudesIds),
  );
}
```

---

## 🎨 Widgets con BLoC

### BlocBuilder - Reconstruir UI según estado

```dart
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is AuthAuthenticated) {
      return Text('Bienvenido ${state.usuario.nombres}');
    } else if (state is AuthUnauthenticated) {
      return const Text('Por favor inicia sesión');
    } else if (state is AuthError) {
      return Text('Error: ${state.message}');
    }
    return const SizedBox();
  },
)
```

### BlocListener - Ejecutar acciones según estado

```dart
BlocListener<ProfileBloc, ProfileState>(
  listener: (context, state) {
    if (state is PerfilCreated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil creado exitosamente')),
      );
      Modular.to.navigate('/profile/aptitudes');
    } else if (state is ProfileError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  child: YourChildWidget(),
)
```

### BlocConsumer - Combinar builder y listener

```dart
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    // Ejecutar acciones (navegación, snackbars)
    if (state is AuthAuthenticated) {
      Modular.to.navigate('/home/');
    }
  },
  builder: (context, state) {
    // Construir UI según estado
    if (state is AuthLoading) {
      return const CircularProgressIndicator();
    }
    return const LoginForm();
  },
)
```

---

## 🧭 Navegación

### Navegación Básica

```dart
// Ir a una ruta
Modular.to.navigate('/home/');

// Ir a ruta y reemplazar (no puede volver atrás)
Modular.to.pushReplacementNamed('/home/');

// Agregar al stack (puede volver atrás)
Modular.to.pushNamed('/profile/create');

// Volver atrás
Modular.to.pop();

// Volver con datos
Modular.to.pop({'resultado': 'success'});
```

### Navegación con Parámetros

```dart
// Enviar parámetros
Modular.to.pushNamed('/voluntariado/detalle', arguments: {'id': 123});

// Recibir parámetros
class DetallePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = Modular.args.data as Map<String, dynamic>;
    final id = args['id'];
    
    return Text('Voluntariado ID: $id');
  }
}
```

---

## 📦 Inyección de Dependencias

### Obtener Dependencia

```dart
// Desde cualquier lugar
final authRepo = Modular.get<AuthRepository>();
final voluntarioRepo = Modular.get<VoluntarioRepository>();
```

### Registrar Dependencias

```dart
// En app_module.dart
@override
List<Bind> get binds => [
  // Singleton (única instancia)
  Bind.singleton((i) => AuthRepository(i<DioClient>())),
  
  // Factory (nueva instancia cada vez)
  Bind.factory((i) => AuthBloc(i<AuthRepository>())),
  
  // Lazy Singleton (se crea cuando se solicita por primera vez)
  Bind.lazySingleton((i) => MiServicio()),
];
```

---

## 💾 Almacenamiento Local

### Guardar y Recuperar Datos

```dart
import '../core/services/storage_service.dart';

// Guardar string
await StorageService.saveString('user_name', 'Juan Pérez');

// Recuperar string
final name = await StorageService.getString('user_name');
print(name); // "Juan Pérez"

// Verificar si existe
final exists = await StorageService.containsKey('user_name');

// Eliminar
await StorageService.remove('user_name');

// Limpiar todo
await StorageService.clear();
```

### Guardar Objetos (JSON)

```dart
import 'dart:convert';

// Guardar objeto
final usuario = Usuario(...);
await StorageService.saveString(
  'usuario',
  jsonEncode(usuario.toJson()),
);

// Recuperar objeto
final userJson = await StorageService.getString('usuario');
if (userJson != null) {
  final usuario = Usuario.fromJson(jsonDecode(userJson));
  print(usuario.nombres);
}
```

---

## 🌐 Llamadas HTTP Directas

### Usando el Repositorio (Recomendado)

```dart
final authRepo = Modular.get<AuthRepository>();

try {
  final usuario = await authRepo.getProfile();
  print('Usuario: ${usuario.nombreCompleto}');
} catch (e) {
  print('Error: $e');
}
```

### Usando Dio Directamente

```dart
final dioClient = Modular.get<DioClient>();

try {
  final response = await dioClient.dio.get('/auth/profile');
  print(response.data);
} catch (e) {
  print('Error: $e');
}
```

---

## 🎯 Formularios

### Validación Simple

```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        decoration: const InputDecoration(labelText: 'Email'),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Campo requerido';
          }
          if (!value.contains('@')) {
            return 'Email inválido';
          }
          return null;
        },
      ),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Formulario válido
            print('Formulario válido');
          }
        },
        child: const Text('Enviar'),
      ),
    ],
  ),
)
```

---

## 📊 Listados Dinámicos

### ListView con BLoC

```dart
BlocBuilder<ProfileBloc, ProfileState>(
  builder: (context, state) {
    if (state is AptitudesLoaded) {
      return ListView.builder(
        itemCount: state.aptitudes.length,
        itemBuilder: (context, index) {
          final aptitud = state.aptitudes[index];
          return ListTile(
            title: Text(aptitud.nombre),
            subtitle: Text(aptitud.descripcion ?? ''),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Acción al tocar
            },
          );
        },
      );
    }
    return const CircularProgressIndicator();
  },
)
```

### ListView con Separadores

```dart
ListView.separated(
  itemCount: items.length,
  separatorBuilder: (context, index) => const Divider(),
  itemBuilder: (context, index) {
    return ListTile(title: Text(items[index]));
  },
)
```

---

## 🔔 Mostrar Mensajes

### SnackBar

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('Operación exitosa'),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 2),
  ),
);
```

### Dialog

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Confirmar'),
    content: const Text('¿Estás seguro?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: () {
          // Acción
          Navigator.pop(context);
        },
        child: const Text('Confirmar'),
      ),
    ],
  ),
);
```

---

## 🎨 Estilos y Temas

### Botones Personalizados

```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: const Text('Mi Botón'),
)
```

### Cards

```dart
Card(
  elevation: 4,
  margin: const EdgeInsets.all(16),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        const Text('Título', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Contenido del card'),
      ],
    ),
  ),
)
```

---

## 🔄 Refresh y Pull to Refresh

```dart
RefreshIndicator(
  onRefresh: () async {
    // Recargar datos
    BlocProvider.of<ProfileBloc>(context).add(LoadAptitudesRequested());
    await Future.delayed(const Duration(seconds: 1));
  },
  child: ListView(...),
)
```

---

## 📸 Imágenes

### Desde Assets

```dart
Image.asset('assets/images/logo.png', width: 100, height: 100)
```

### Desde URL

```dart
Image.network(
  'https://example.com/image.jpg',
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return const CircularProgressIndicator();
  },
  errorBuilder: (context, error, stackTrace) {
    return const Icon(Icons.error);
  },
)
```

---

## 🧪 Testing

### Test Unitario de BLoC

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';

void main() {
  group('AuthBloc', () {
    late AuthBloc authBloc;
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authBloc = AuthBloc(mockAuthRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    blocTest<AuthBloc, AuthState>(
      'emite [AuthLoading, AuthAuthenticated] cuando login es exitoso',
      build: () => authBloc,
      act: (bloc) => bloc.add(AuthLoginRequested(
        LoginRequest(email: 'test@example.com', contrasena: 'password123'),
      )),
      expect: () => [
        AuthLoading(),
        isA<AuthAuthenticated>(),
      ],
    );
  });
}
```

---

**¡Usa estos ejemplos como referencia rápida!** 📚
