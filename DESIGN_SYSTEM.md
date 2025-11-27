# Volunred Design System

> Versión inicial inspirada en la landing de referencia (azul, fondos claros/oscuro, cards grandes, tipografía fuerte).

---

## 1. Paleta de color Volunred

### 1.1. Colores base

- **Primary / Volunred Blue**  
  `#1976D2`  
  Uso: botones principales, gradientes, iconos destacados, pills de estado activo.

- **Primary Soft**  
  `#E3F2FD`  
  Uso: fondos suaves detrás de iconos, chips suaves, badges secundarios.

- **Primary Accent**  
  `#42A5F5`  
  Uso: segundo color del gradiente azul, acentos en gráficos o estados.

- **Background Light**  
  `#F5F7FA`  
  Uso: fondo general de pantallas (Scaffold background).

- **Surface / Card Light**  
  `#FFFFFF`  
  Uso: cards blancas sobre fondo claro.

- **Text Primary**  
  `#1A1A1A`  
  Uso: títulos fuertes, números, texto principal.

- **Text Secondary**  
  `#616161`  
  Uso: descripciones, subtítulos.

- **Text Muted**  
  `#9E9E9E`  
  Uso: texto de ayuda, estados neutros.

- **Success**  
  `#4CAF50`

- **Warning**  
  `#FF9800`

- **Error**  
  `#F44336`

### 1.2. Gradientes tipo Volunred

- **Gradient Azul Principal**  
  De `#1976D2` a `#42A5F5`  
  Uso: secciones clave ("Mis Tareas", banners principales, CTA grandes).

- **Gradient Azul Suave**  
  De `#E3F2FD` a `#BBDEFB`  
  Uso: énfasis suave, fondos de métricas secundarias.

---

## 2. Tipografía

> Basada en Material 3, pero con énfasis en títulos fuertes tipo landing.

- **Display / Hero Title**  
  Tamaño: 28–32  
  Peso: `w900`  
  Color: `Text Primary`  
  Uso: encabezados principales como "Mi Actividad", nombre de proyecto en hero.

- **Section Title**  
  Tamaño: 20–22  
  Peso: `w800`  
  Uso: títulos de secciones: "Mis Tareas", "Participando Actualmente", "Detalles del Proyecto".

- **Card Title**  
  Tamaño: 16–17  
  Peso: `w700`  
  Uso: títulos dentro de cards (nombre de tarea, nombre de proyecto en cards).

- **Body**  
  Tamaño: 14–15  
  Peso: `w400–w500`  
  Uso: descripciones generales.

- **Label / Chips**  
  Tamaño: 11–13  
  Peso: `w600–w700`  
  Uso: estado, etiquetas, textos dentro de pills.

---

## 3. Radiuses, sombras y espaciamiento

### 3.1. Bordes

- **Cards principales**: `BorderRadius.circular(24)`  
- **Cards secundarias / listas**: `BorderRadius.circular(20)`  
- **Chips / pills / botones redondos**: `BorderRadius.circular(16–20)` o `999` para pill completa.

### 3.2. Sombras

- **Card Elevation Suave**  
  - `blurRadius: 12–16`  
  - `offset: Offset(0, 4)`  
  - `color: Colors.black.withOpacity(0.06–0.08)`

- **Cards Destacadas (gradiente azul)**  
  - `blurRadius: 18–20`  
  - `offset: Offset(0, 8–10)`  
  - `color: primary.withOpacity(0.25–0.30)`

### 3.3. Espaciado

- Márgenes horizontales principales: **24 px**  
- Separación entre secciones: **20–24 px**  
- Padding interno de cards grandes: **20–24 px**

---

## 4. Componentes de UI Volunred

### 4.1. Hero Section (pantallas clave)

**Uso:** encabezado superior de "Mi Actividad", detalle de proyecto, home voluntario.

- Fondo: gradiente azul principal o fondo oscuro + gradiente.
- Contenido:
  - Título hero (Display / Hero Title).
  - Subtítulo corto explicando el contexto.
  - 1–2 métricas destacadas o CTA principal.
- Bordes: `BorderRadius.circular(24–32)` en la parte inferior.

### 4.2. Cards de Sección

Ejemplos: "Mis Tareas", "Participando Actualmente", "Detalles del Proyecto".

- Fondo blanco o gradiente azul según importancia.
- Bordes: 20–24 px.
- Sombra suave.
- Header de card:
  - Título sección (Section Title).
  - Texto auxiliar o CTA (ej: "Ver todas").

### 4.3. Cards de Lista (Tareas, Participaciones)

- Fondo: blanco.
- Bordes: 20 px.
- Sombra: suave (blur 12–16).
- Estructura:
  - Header: título + chip de estado.
  - Cuerpo: descripción corta.
  - Footer: fila de metadatos (proyecto, prioridad, fecha) sobre fondo gris muy claro.

### 4.4. Chips y Estados

- Filtros (ej: "Todas", "Pendientes", "En Progreso", "Completadas")
  - `AnimatedContainer` con fondo blanco cuando está inactivo y azul cuando está activo.
  - Texto bold cuando está seleccionado.
  - Sombra suave cuando está activo.

- Estados de tarea / participación
  - **Pendiente**: fondo `Warning` suave, texto `Warning` fuerte.
  - **En progreso**: fondo terciario (ej: `ColorScheme.tertiaryContainer`), texto `onTertiaryContainer`.
  - **Completada**: fondo `Primary Soft`, texto `Primary` u `onPrimaryContainer`.

### 4.5. Botón Primario Volunred

- Tipo pill (borderRadius 999 o 20).
- Fondo: `Primary` (o blanco sobre bloque azul).
- Texto: bold, 14–16 px.
- Usar versión glass (blanco semi-transparente) sobre gradientes azules.

---

## 5. Aplicación en pantallas actuales

### 5.1. Detalle de Proyecto Voluntario

- **Hero** con imagen o gradiente azul, bordes inferiores redondeados.
- Card principal blanca con:
  - Título (nombre de proyecto).
  - Badges: estado del proyecto + categorías.
  - Objetivo del proyecto (texto).
- Card "Detalles del Proyecto" con filas `_buildDetailRow` para:
  - Fecha de inicio.
  - Fecha de fin.
  - Ubicación.
- Bloque "Mis Tareas" con gradiente azul, CTA "Ver todas" y lista de tareas.

### 5.2. Mi Actividad

- Hero "Mi Actividad" con título grande y subtítulo.
- Dos cards de stats (Proyectos, Tareas) usando `_buildStatCard` con gradiente.
- Bloque "Mis Tareas" con gradiente azul similar al de detalle de proyecto.
- Cards de tareas, participaciones e inscripciones usando el mismo patrón de card blanca.

---

## 6. Próximos pasos sugeridos

- Extraer estos tokens de diseño a una capa de tema (`ThemeData` / `ColorScheme`) para reutilizarlos.
- Aplicar el mismo patrón de hero + secciones a:
  - Home voluntario (`VoluntarioDashboard`).
  - Exploración de proyectos.
  - Otras vistas clave (perfil, organizaciones).
