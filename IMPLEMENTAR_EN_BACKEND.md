# 🚀 IMPLEMENTACIÓN BACKEND: Upload por Chunks

## 📋 Resumen
Necesitas agregar un endpoint en el backend para recibir videos/archivos grandes divididos en chunks (pedazos) de 1MB.

---

## 📁 Archivo 1: `src/informacion/archivos-digitales/archivos-digitales.controller.ts`

**AGREGAR este nuevo endpoint:**

```typescript
import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from 'src/auth/guards/jwt-auth.guard';
import { ArchivoDigitalesService } from './archivos-digitales.service';

@Controller('informacion/archivos-digitales')
@UseGuards(JwtAuthGuard)
export class ArchivoDigitalesController {
  constructor(private readonly service: ArchivoDigitalesService) {}

  // ✅ ENDPOINT EXISTENTE - NO TOCAR
  @Post()
  async subirArchivo(@Body() body: any) {
    return this.service.crearArchivoDigital(body);
  }

  // ✅✅ NUEVO ENDPOINT - AGREGAR ESTE ✅✅
  @Post('upload-chunk')
  async uploadChunk(
    @Body()
    body: {
      proyecto_id: number;
      chunk: string; // Parte del base64
      chunk_index: number; // Índice del chunk: 0, 1, 2...
      total_chunks: number; // Total de chunks
      nombre_archivo: string;
      mime_type: string;
      tipo_media?: string;
    },
  ) {
    return this.service.procesarChunk(body);
  }
}
```

---

## 📁 Archivo 2: `src/informacion/archivos-digitales/archivos-digitales.service.ts`

**AGREGAR estos dos elementos:**

### 1. Variable de clase (al inicio del service):

```typescript
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ArchivoDigital } from './entities/archivo-digital.entity';

@Injectable()
export class ArchivoDigitalesService {
  // ✅✅ AGREGAR ESTA LÍNEA ✅✅
  private chunksTemporales: { [key: string]: string[] } = {};

  constructor(
    @InjectRepository(ArchivoDigital)
    private readonly archivoRepository: Repository<ArchivoDigital>,
  ) {}

  // ... tus métodos existentes aquí ...
```

### 2. Nuevo método (al final del service):

```typescript
  // ✅✅ AGREGAR TODO ESTE MÉTODO ✅✅
  async procesarChunk(body: {
    proyecto_id: number;
    chunk: string;
    chunk_index: number;
    total_chunks: number;
    nombre_archivo: string;
    mime_type: string;
    tipo_media?: string;
  }) {
    const chunkKey = `${body.proyecto_id}_${body.nombre_archivo}`;
    
    console.log(`📦 Chunk ${body.chunk_index + 1}/${body.total_chunks} recibido para ${body.nombre_archivo}`);
    
    // Inicializar array si es el primer chunk
    if (!this.chunksTemporales[chunkKey]) {
      this.chunksTemporales[chunkKey] = new Array(body.total_chunks).fill('');
      console.log(`🆕 Iniciando upload: ${body.nombre_archivo} (${body.total_chunks} chunks)`);
    }

    // Guardar el chunk en su posición
    this.chunksTemporales[chunkKey][body.chunk_index] = body.chunk;

    // Contar cuántos chunks tenemos
    const chunksRecibidos = this.chunksTemporales[chunkKey].filter(c => c !== '').length;
    console.log(`📊 Progreso: ${chunksRecibidos}/${body.total_chunks} chunks`);

    // ¿Ya tenemos todos los chunks?
    if (this.chunksTemporales[chunkKey].every(c => c !== '')) {
      console.log(`✅ Todos los chunks recibidos. Ensamblando archivo...`);
      
      // Unir todos los chunks en un solo string base64
      const contenidoCompleto = this.chunksTemporales[chunkKey].join('');
      
      const sizeMB = (contenidoCompleto.length / 1024 / 1024).toFixed(2);
      console.log(`📦 Tamaño total: ${sizeMB} MB`);
      
      // Guardar en base de datos
      const archivo = this.archivoRepository.create({
        proyecto_id: body.proyecto_id,
        nombre_archivo: body.nombre_archivo,
        contenido_base64: contenidoCompleto,
        mime_type: body.mime_type,
        tipo_media: body.tipo_media || 'video',
      });

      const savedArchivo = await this.archivoRepository.save(archivo);

      // Limpiar memoria
      delete this.chunksTemporales[chunkKey];
      
      console.log(`✅ Archivo guardado: ID ${savedArchivo.id_archivo_digital}`);

      return {
        mensaje: 'Archivo completo subido exitosamente',
        archivo: savedArchivo,
        progreso: 100,
      };
    }

    // Si faltan chunks, devolver estado actual
    const progreso = Math.round((chunksRecibidos / body.total_chunks) * 100);
    
    return { 
      mensaje: `Chunk ${body.chunk_index + 1}/${body.total_chunks} recibido`,
      progreso,
      chunks_recibidos: chunksRecibidos,
      chunks_totales: body.total_chunks,
    };
  }
}
```

---

## 🔧 Pasos para Implementar

### 1. Abrir el proyecto backend
```bash
cd volunred-backend
```

### 2. Editar los archivos
- Abre `src/informacion/archivos-digitales/archivos-digitales.controller.ts`
- Agrega el método `uploadChunk` al final del controller

- Abre `src/informacion/archivos-digitales/archivos-digitales.service.ts`
- Agrega `private chunksTemporales: { [key: string]: string[] } = {};` al inicio
- Agrega el método `procesarChunk` al final

### 3. Verificar que compile
```bash
npm run build
```

### 4. Reiniciar el servidor
```bash
npm run start:dev
```

### 5. Probar el endpoint

**Request de prueba:**
```bash
POST http://localhost:3000/informacion/archivos-digitales/upload-chunk
Authorization: Bearer {tu_token_jwt}
Content-Type: application/json

{
  "proyecto_id": 1,
  "chunk": "iVBORw0KGgo...",
  "chunk_index": 0,
  "total_chunks": 3,
  "nombre_archivo": "video_test.mp4",
  "mime_type": "video/mp4",
  "tipo_media": "video"
}
```

**Response esperada (chunk intermedio):**
```json
{
  "mensaje": "Chunk 1/3 recibido",
  "progreso": 33,
  "chunks_recibidos": 1,
  "chunks_totales": 3
}
```

**Response esperada (último chunk):**
```json
{
  "mensaje": "Archivo completo subido exitosamente",
  "archivo": {
    "id_archivo_digital": 123,
    "nombre_archivo": "video_test.mp4",
    ...
  },
  "progreso": 100
}
```

---

## ✅ Verificación

Después de implementar, deberías ver en los logs:

```
📦 Chunk 1/6 recibido para video_proyecto_1234.mp4
🆕 Iniciando upload: video_proyecto_1234.mp4 (6 chunks)
📊 Progreso: 1/6 chunks
📦 Chunk 2/6 recibido para video_proyecto_1234.mp4
📊 Progreso: 2/6 chunks
...
📦 Chunk 6/6 recibido para video_proyecto_1234.mp4
📊 Progreso: 6/6 chunks
✅ Todos los chunks recibidos. Ensamblando archivo...
📦 Tamaño total: 8.54 MB
✅ Archivo guardado: ID 456
```

---

## 🎯 ¿Por qué esto resuelve el problema?

| Antes | Ahora |
|-------|-------|
| 1 request de 10 MB → **Error 413** ❌ | 10 requests de 1 MB → **Éxito** ✅ |
| Videos > 3.5 MB rechazados | Videos hasta 50+ MB aceptados |
| Usuario ve error | Usuario ve progreso |

---

## 📞 ¿Dudas?

Si algo no funciona, revisa:
1. ✅ ¿El endpoint está protegido con `@UseGuards(JwtAuthGuard)`?
2. ✅ ¿El entity `ArchivoDigital` tiene el campo `contenido_base64`?
3. ✅ ¿El servidor se reinició después de los cambios?
4. ✅ ¿El token JWT es válido?

---

## 🚀 Deploy a Producción

Después de probar en local:

```bash
git add .
git commit -m "feat: Agregar upload por chunks para archivos grandes"
git push
```

Vercel o tu hosting redeploy automáticamente.

---

**¡Listo!** Con esto tu backend podrá recibir videos grandes divididos en chunks. 🎉
