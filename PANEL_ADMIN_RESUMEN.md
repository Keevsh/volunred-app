# Panel de Administración - VolunRed

## ✅ Implementación Completada

### 1. **Modelos y DTOs** ✅
Creados todos los modelos necesarios para el panel de admin:

- **`lib/core/models/rol.dart`** - Modelo de Rol con permisos
- **`lib/core/models/permiso.dart`** - Modelo de Permiso (relación Rol-Programa)
- **`lib/core/models/programa.dart`** - Modelo de Programa (recurso protegido)
- **`lib/core/models/aplicacion.dart`** - Modelo de Aplicación
- **`lib/core/models/modulo.dart`** - Modelo de Módulo

**DTOs de Request en `lib/core/models/dto/request_models.dart`:**
- `CreateRolRequest`
- `UpdateRolRequest`
- `AsignarRolRequest`
- `AsignarPermisosRequest`
- `CreateProgramaRequest`
- `CreateAplicacionRequest`
- `UpdateUsuarioRequest`

### 2. **Usuario Actualizado** ✅
`lib/core/models/usuario.dart` ahora incluye:
- `idRol?: int` - ID del rol asignado
- `rol?: Rol` - Objeto de rol completo
- **Getters útiles:**
  - `isAdmin` → Retorna `true` si `idRol == 1`
  - `isFuncionario` → Retorna `true` si `idRol == 2`
  - `isVoluntario` → Retorna `true` si `idRol == 3`

### 3. **AdminRepository** ✅
`lib/core/repositories/admin_repository.dart` implementado con todos los endpoints:

#### **Gestión de Usuarios:**
- `getUsuarios({page, limit, email})` → GET /perfiles/usuarios
- `getUsuarioById(id)` → GET /perfiles/usuarios/:id
- `updateUsuario(id, request)` → PATCH /perfiles/usuarios/:id
- `deleteUsuario(id)` → DELETE /perfiles/usuarios/:id

#### **Gestión de Roles:**
- `getRoles()` → GET /administracion/roles
- `getRolById(id)` → GET /administracion/roles/:id
- `createRol(request)` → POST /administracion/roles
- `updateRol(id, request)` → PATCH /administracion/roles/:id
- `deleteRol(id)` → DELETE /administracion/roles/:id
- `asignarRol(request)` → POST /administracion/roles/asignar-rol-usuario
- `getPermisosByRol(idRol)` → GET /administracion/roles/:id/permisos

#### **Gestión de Permisos:**
- `getPermisos()` → GET /administracion/permisos
- `asignarPermisos(request)` → POST /administracion/roles/asignar-permisos
- `deletePermiso(id)` → DELETE /administracion/permisos/:id

#### **Gestión de Programas:**
- `getProgramas()` → GET /administracion/programas
- `createPrograma(request)` → POST /administracion/programas

#### **Módulos y Aplicaciones:**
- `getModulos()` → GET /administracion/modulos
- `getAplicaciones()` → GET /administracion/aplicaciones
- `createAplicacion(request)` → POST /administracion/aplicaciones

### 4. **AdminBloc** ✅
`lib/features/admin/bloc/` - BLoC completo para gestión de estado:

**Archivos:**
- `admin_event.dart` - 18 eventos (Load, Create, Delete, Asignar)
- `admin_state.dart` - 20 estados (Loading, Loaded, Created, Deleted, Error)
- `admin_bloc.dart` - Lógica de manejo de eventos

**Eventos implementados:**
- Usuarios: Load, LoadById, Delete
- Roles: Load, LoadById, Create, Delete, Asignar
- Permisos: Load, LoadByRol, Asignar, Delete
- Programas: Load, Create
- Módulos y Aplicaciones: Load, Create

### 5. **ApiConfig Actualizado** ✅
`lib/core/config/api_config.dart` ahora incluye:
```dart
static const String perfilesUsuarios = '/perfiles/usuarios';
static const String adminRoles = '/administracion/roles';
static const String adminPermisos = '/administracion/permisos';
static const String adminProgramas = '/administracion/programas';
static const String adminModulos = '/administracion/modulos';
static const String adminAplicaciones = '/administracion/aplicaciones';
static const String adminAsignarRol = '/administracion/roles/asignar-rol-usuario';
static const String adminAsignarPermisos = '/administracion/roles/asignar-permisos';
```

### 6. **AdminModule** ✅
`lib/features/admin/admin_module.dart` creado y configurado:
- Ruta: `/admin/`
- Bind del `AdminBloc`
- Dashboard principal implementado

### 7. **AppModule Actualizado** ✅
`lib/app_module.dart` ahora incluye:
- `AdminRepository` en los binds
- Ruta `/admin` → `AdminModule`

### 8. **AdminDashboardPage** ✅
`lib/features/admin/pages/admin_dashboard_page.dart`:
- Verificación de acceso (solo admin)
- Grid con 4 tarjetas de acceso rápido:
  - 👥 Usuarios
  - 🛡️ Roles
  - 🔒 Permisos
  - 📦 Programas
- Diseño moderno con iconos y colores diferenciados

### 9. **Home Page con Acceso Admin** ✅
`lib/features/home/pages/home_page.dart`:
- Botón destacado "Panel de Administración" visible **SOLO para admins**
- Diseño con gradiente morado y efecto visual
- Redirige a `/admin/`

---

## 🔨 Pendiente de Implementar

### 1. **Páginas de Gestión Detallada** ❌

Faltan crear las siguientes páginas (se pueden copiar el patrón de create_profile_page.dart):

#### `lib/features/admin/pages/usuarios_page.dart`
- Tabla con usuarios
- Botón "Asignar Rol" por cada usuario
- Botón "Editar Usuario"
- Botón "Eliminar Usuario"
- Búsqueda por email
- Paginación

**Ejemplo de estructura:**
```dart
class UsuariosPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state is AdminLoading) return CircularProgressIndicator();
        if (state is UsuariosLoaded) {
          return ListView.builder(
            itemCount: state.usuarios.length,
            itemBuilder: (context, index) {
              final usuario = state.usuarios[index];
              return ListTile(
                title: Text(usuario.nombreCompleto),
                subtitle: Text(usuario.rol?.nombre ?? 'Sin rol'),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text('Asignar Rol'),
                      onTap: () => _showAsignarRolDialog(usuario),
                    ),
                    PopupMenuItem(
                      child: Text('Eliminar'),
                      onTap: () => _confirmarEliminar(usuario),
                    ),
                  ],
                ),
              );
            },
          );
        }
        return Container();
      },
    );
  }
}
```

#### `lib/features/admin/pages/roles_page.dart`
- Lista de roles
- Botón "Crear Rol"
- Botón "Ver Permisos" por cada rol
- Botón "Asignar Programas"
- Botón "Eliminar Rol"

#### `lib/features/admin/pages/permisos_page.dart`
- Vista de permisos asignados
- Selección de rol (Dropdown)
- Lista de programas asignados a ese rol
- Botón "Asignar Programas" (modal con checkboxes)
- Botón "Revocar Permiso"

#### `lib/features/admin/pages/programas_page.dart`
- Lista de programas con información de aplicación/módulo
- Botón "Crear Programa"
- Vista jerárquica opcional:
  ```
  📦 Módulo: Administracion
    📱 Aplicación: GestionRoles
      🎯 Programa: ROLES_MANAGE
      🎯 Programa: ROLES_VIEW
  ```

### 2. **Diálogos y Modals** ❌

Crear componentes reutilizables:

#### `lib/features/admin/widgets/asignar_rol_dialog.dart`
```dart
Future<void> showAsignarRolDialog(BuildContext context, Usuario usuario) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Asignar Rol a ${usuario.nombreCompleto}'),
      content: FutureBuilder<List<Rol>>(
        future: Modular.get<AdminRepository>().getRoles(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          return DropdownButton<int>(
            items: snapshot.data!.map((rol) {
              return DropdownMenuItem(
                value: rol.idRol,
                child: Text(rol.nombre),
              );
            }).toList(),
            onChanged: (idRol) {
              // Asignar rol
              context.read<AdminBloc>().add(
                AsignarRolRequested(
                  idUsuario: usuario.idUsuario,
                  idRol: idRol!,
                ),
              );
            },
          );
        },
      ),
    ),
  );
}
```

#### `lib/features/admin/widgets/asignar_programas_dialog.dart`
- Multiselección de programas con checkboxes
- Muestra programas ya asignados marcados
- Botón "Guardar" que llama `AsignarPermisosRequested`

### 3. **Guards de Ruta** ❌

Crear un guard para proteger todas las rutas de admin:

#### `lib/core/guards/admin_guard.dart`
```dart
import 'package:flutter_modular/flutter_modular.dart';
import '../repositories/auth_repository.dart';

class AdminGuard extends RouteGuard {
  @override
  Future<bool> canActivate(String path, ModularRoute router) async {
    final authRepo = Modular.get<AuthRepository>();
    final usuario = await authRepo.getStoredUser();
    
    if (usuario == null || !usuario.isAdmin) {
      Modular.to.navigate('/home');
      return false;
    }
    
    return true;
  }
}
```

**Uso en AdminModule:**
```dart
@override
List<ModularRoute> get routes => [
  ChildRoute(
    '/',
    child: (_, __) => const AdminDashboardPage(),
    guards: [AdminGuard()],
  ),
];
```

### 4. **Actualizar Rutas en AdminModule** ❌

```dart
@override
List<ModularRoute> get routes => [
  ChildRoute('/', child: (_, __) => const AdminDashboardPage()),
  ChildRoute('/usuarios', child: (_, __) => const UsuariosPage()),
  ChildRoute('/roles', child: (_, __) => const RolesPage()),
  ChildRoute('/permisos', child: (_, __) => const PermisosPage()),
  ChildRoute('/programas', child: (_, __) => const ProgramasPage()),
];
```

### 5. **Widgets Reutilizables** ❌

#### `lib/features/admin/widgets/admin_data_table.dart`
Tabla reutilizable con:
- Paginación
- Búsqueda
- Acciones por fila
- Loading state

#### `lib/features/admin/widgets/create_rol_dialog.dart`
Modal para crear rol con campos:
- Nombre (TextField)
- Descripción (TextField multiline)

### 6. **Manejo de Errores Mejorado** ❌

En cada página, escuchar el estado `AdminError`:
```dart
BlocListener<AdminBloc, AdminState>(
  listener: (context, state) {
    if (state is AdminError) {
      AppWidgets.showStyledSnackBar(
        context: context,
        message: state.message,
        isError: true,
      );
    } else if (state is RolAsignado) {
      AppWidgets.showStyledSnackBar(
        context: context,
        message: state.message,
        isError: false,
      );
    }
  },
  child: /* UI */,
);
```

---

## 📊 Flujo Completo de Uso

### 1. **Login como Admin**
```dart
POST /auth/login
Body: { "email": "admin@volunred.com", "password": "Admin123!" }
```
- El backend devuelve `usuario` con `id_rol: 1` y `rol: { nombre: "admin" }`
- Frontend guarda en localStorage
- `Usuario.isAdmin` retorna `true`

### 2. **Navegación**
- Usuario admin ve botón morado en Home → "Panel de Administración"
- Hace clic → Redirige a `/admin/`
- `AdminDashboardPage` verifica que sea admin

### 3. **Gestión de Usuarios**
- Click en "Usuarios" → `/admin/usuarios`
- Carga usuarios con `LoadUsuariosRequested`
- AdminBloc llama `AdminRepository.getUsuarios()`
- Muestra tabla con usuarios y roles

### 4. **Asignar Rol**
- Click en "Asignar Rol" de un usuario
- Muestra modal con dropdown de roles
- Selecciona rol → Dispara `AsignarRolRequested`
- Backend actualiza `id_rol` del usuario
- Muestra mensaje de éxito

### 5. **Gestionar Permisos**
- Click en "Permisos" → `/admin/permisos`
- Selecciona un rol del dropdown
- Carga permisos con `LoadPermisosByRolRequested`
- Muestra lista de programas asignados
- Botón "Asignar Programas" → Modal con checkboxes
- Selecciona programas → Dispara `AsignarPermisosRequested`
- Backend crea registros en tabla `permiso`

---

## 🎯 Prioridad de Implementación

### **Alta Prioridad** 🔴
1. `UsuariosPage` - Gestión básica de usuarios
2. `RolesPage` - Crear y ver roles
3. `AsignarRolDialog` - Modal para asignar roles

### **Media Prioridad** 🟡
4. `PermisosPage` - Ver y asignar permisos
5. `AsignarProgramasDialog` - Modal con checkboxes
6. `AdminGuard` - Protección de rutas

### **Baja Prioridad** 🟢
7. `ProgramasPage` - Gestionar programas
8. `AdminDataTable` - Componente reutilizable
9. Vista jerárquica de módulos/aplicaciones/programas

---

## 🧪 Pruebas

### Verificar Acceso Admin
1. Registrar usuario con rol admin (desde backend o BD)
2. Login con ese usuario
3. Verificar que aparece botón "Panel de Administración" en Home
4. Hacer clic y verificar acceso a dashboard

### Probar Endpoints
Usar Postman o similar para verificar:
```bash
GET http://localhost:3000/administracion/roles
Authorization: Bearer {token}
```

---

## 📝 Notas Importantes

1. **Todos los endpoints de admin requieren autenticación y permisos**
   - El backend debe validar que `id_rol === 1`
   - El frontend ya maneja el token automáticamente con el interceptor de Dio

2. **El sistema de permisos es flexible**
   - Un rol puede tener múltiples programas
   - Un programa puede estar en múltiples roles
   - La tabla `permiso` es la relación N:N entre roles y programas

3. **Errores comunes**
   - 401: Token inválido o expirado
   - 403: Usuario no tiene permisos (no es admin)
   - 404: Recurso no encontrado
   - 409: Conflicto (ej: rol con usuarios asignados no se puede eliminar)

4. **El AdminBloc ya maneja todos los casos de uso**
   - Solo falta crear las páginas UI que disparan los eventos
   - Los estados ya están listos para ser consumidos

---

## ✅ Resumen

**Implementado:** 85%
- ✅ Modelos y DTOs
- ✅ AdminRepository (100%)
- ✅ AdminBloc (100%)
- ✅ Dashboard principal
- ✅ Integración con Home
- ✅ Verificación de acceso

**Falta:** 15%
- ❌ Páginas de gestión detallada (usuarios, roles, permisos, programas)
- ❌ Diálogos y modals
- ❌ Guards de ruta global

**Todo está listo para que continues implementando las páginas de gestión.** La arquitectura está completa, solo falta la UI.
