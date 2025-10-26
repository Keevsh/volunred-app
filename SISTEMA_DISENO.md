# 🎨 Sistema de Diseño VolunRed

## Descripción
Este documento describe el sistema de diseño unificado de VolunRed, que garantiza consistencia visual en toda la aplicación.

## 📁 Archivos

### `app_colors.dart`
Define todos los colores usados en la aplicación.

**Colores principales:**
- `AppColors.primary` - Color principal verde oscuro (#0D4C3D)
- `AppColors.primaryLight` - Verde claro
- `AppColors.primaryDark` - Verde oscuro

**Gradientes:**
- `AppColors.gradientGreen` - Verde degradado
- `AppColors.gradientBlue` - Azul degradado
- `AppColors.gradientOrange` - Naranja degradado
- `AppColors.cardGradientLight` - Gradiente para cards

**Colores de estado:**
- `AppColors.success` - Verde de éxito
- `AppColors.error` - Rojo de error
- `AppColors.warning` - Naranja de advertencia
- `AppColors.info` - Azul informativo

### `app_styles.dart`
Define todas las constantes de diseño (tamaños, espaciados, bordes).

**Bordes redondeados:**
```dart
AppStyles.borderRadiusSmall    // 8.0
AppStyles.borderRadiusMedium   // 16.0
AppStyles.borderRadiusLarge    // 24.0
AppStyles.borderRadiusXLarge   // 32.0
```

**Espaciado:**
```dart
AppStyles.spacingSmall     // 8.0
AppStyles.spacingMedium    // 16.0
AppStyles.spacingLarge     // 24.0
AppStyles.spacingXLarge    // 32.0
```

**Tamaños de fuente:**
```dart
AppStyles.fontSizeSmall    // 12.0
AppStyles.fontSizeMedium   // 14.0
AppStyles.fontSizeBody     // 16.0
AppStyles.fontSizeTitle    // 24.0
AppStyles.fontSizeHeader   // 32.0
```

### `app_widgets.dart`
Widgets reutilizables con el estilo de VolunRed.

## 🔧 Uso

### Importación
```dart
import 'package:volunred_app/core/theme/theme.dart';
```

O importar componentes específicos:
```dart
import 'package:volunred_app/core/theme/app_colors.dart';
import 'package:volunred_app/core/theme/app_styles.dart';
import 'package:volunred_app/core/theme/app_widgets.dart';
```

### Ejemplos de Uso

#### 1. Card con Gradiente
```dart
AppWidgets.gradientCard(
  child: YourContent(),
  height: 200,
  gradientColors: AppColors.cardGradientLight,
)
```

#### 2. Botón con Gradiente
```dart
AppWidgets.gradientButton(
  onPressed: () {},
  text: 'Iniciar Sesión',
  icon: Icons.login,
  gradientColors: AppColors.primaryGradient,
)
```

#### 3. Campo de Texto Estilizado
```dart
AppWidgets.styledTextField(
  controller: _emailController,
  label: 'Email',
  hint: 'tu@email.com',
  prefixIcon: Icons.email_outlined,
  validator: (value) {
    if (value?.isEmpty ?? true) return 'Campo requerido';
    return null;
  },
)
```

#### 4. SnackBar con Estilo
```dart
AppWidgets.showStyledSnackBar(
  context: context,
  message: '¡Operación exitosa!',
  isError: false,
)
```

#### 5. Header de Página
```dart
AppWidgets.pageHeader(
  title: '¡Bienvenido! 👋',
  subtitle: 'Inicia sesión para continuar',
)
```

#### 6. Icono Decorativo
```dart
AppWidgets.decorativeIcon(
  icon: Icons.favorite,
  color: AppColors.iconRed,
  size: 44,
)
```

#### 7. Botón de Retroceso
```dart
AppWidgets.backButton(context)
```

### Uso de Colores
```dart
// Texto
Text(
  'Hola',
  style: TextStyle(color: AppColors.textPrimary),
)

// Contenedor
Container(
  color: AppColors.backgroundLight,
  child: ...
)

// Gradiente
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: AppColors.gradientGreen,
    ),
  ),
)
```

### Uso de Estilos
```dart
// Espaciado
SizedBox(height: AppStyles.spacingLarge)

// Bordes
Container(
  decoration: BoxDecoration(
    borderRadius: AppStyles.borderRadiusMediumAll,
  ),
)

// Fuentes
Text(
  'Título',
  style: TextStyle(fontSize: AppStyles.fontSizeTitle),
)
```

## 🎯 Ventajas

1. **Consistencia**: Todos los elementos visuales siguen el mismo estilo
2. **Mantenibilidad**: Cambios centralizados en un solo lugar
3. **Reutilización**: Widgets predefinidos listos para usar
4. **Escalabilidad**: Fácil agregar nuevos colores o estilos
5. **Legibilidad**: Código más limpio y comprensible

## 📝 Mejores Prácticas

1. **Siempre usar constantes** en lugar de valores hardcodeados
2. **No crear colores nuevos** sin agregarlos a `AppColors`
3. **Usar widgets predefinidos** cuando sea posible
4. **Mantener consistencia** en toda la aplicación
5. **Documentar** cualquier adición al sistema de diseño

## 🔄 Actualizar el Sistema

Para agregar nuevos colores:
1. Edita `app_colors.dart`
2. Agrega la nueva constante
3. Documenta su uso

Para agregar nuevos estilos:
1. Edita `app_styles.dart`
2. Agrega la nueva constante
3. Documenta su uso

Para agregar nuevos widgets:
1. Edita `app_widgets.dart`
2. Crea el nuevo widget estático
3. Documenta su uso con ejemplos

## 🌈 Paleta de Colores Principal

| Color | Hex | Uso |
|-------|-----|-----|
| Primary | #0D4C3D | Botones principales, enlaces |
| Primary Light | #1A6B56 | Hover states, variaciones |
| Success | #4CAF50 | Mensajes de éxito |
| Error | #E53935 | Mensajes de error |
| Warning | #FFA726 | Advertencias |
| Info | #29B6F6 | Información |

---

**Desarrollado para VolunRed App**
