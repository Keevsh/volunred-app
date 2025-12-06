# Backend: Endpoint para Upload por Chunks

## Archivo: `src/informacion/archivos-digitales/archivos-digitales.controller.ts`

Agrega este endpoint:

```typescript
import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from 'src/auth/guards/jwt-auth.guard';
import { ArchivoDigitalesService } from './archivos-digitales.service';

@Controller('informacion/archivos-digitales')
@UseGuards(JwtAuthGuard)
export class ArchivoDigitalesController {
  constructor(private readonly service: ArchivoDigitalesService) {}

  // ✅ NUEVO: Endpoint para recibir chunks
  @Post('upload-chunk')
  async uploadChunk(
    @Body()
    body: {
      proyecto_id: number;
      chunk: string; // Parte del base64
      chunk_index: number; // Índice: 0, 1, 2...
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

## Archivo: `src/informacion/archivos-digitales/archivos-digitales.service.ts`

Agrega estos métodos:

```typescript
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ArchivoDigital } from './entities/archivo-digital.entity';

@Injectable()
export class ArchivoDigitalesService {
  // Almacenamiento temporal de chunks
  private chunksTemporales: { [key: string]: string[] } = {};

  constructor(
    @InjectRepository(ArchivoDigital)
    private readonly archivoRepository: Repository<ArchivoDigital>,
  ) {}

  async procesarChunk(body: any) {
    const chunkKey = `${body.proyecto_id}_${body.nombre_archivo}`;
    
    console.log(`📦 Recibiendo chunk ${body.chunk_index + 1}/${body.total_chunks} para ${body.nombre_archivo}`);
    
    // Inicializar array si no existe
    if (!this.chunksTemporales[chunkKey]) {
      this.chunksTemporales[chunkKey] = new Array(body.total_chunks).fill('');
      console.log(`🆕 Iniciando upload de archivo: ${body.nombre_archivo} (${body.total_chunks} chunks)`);
    }

    // Guardar chunk
    this.chunksTemporales[chunkKey][body.chunk_index] = body.chunk;

    // Verificar si ya tenemos todos los chunks
    const chunksRecibidos = this.chunksTemporales[chunkKey].filter(c => c !== '').length;
    console.log(`📊 Progreso: ${chunksRecibidos}/${body.total_chunks} chunks recibidos`);

    if (this.chunksTemporales[chunkKey].every(c => c !== '')) {
      console.log(`✅ Todos los chunks recibidos. Ensamblando archivo...`);
      
      // Unir todos los chunks
      const contenidoCompleto = this.chunksTemporales[chunkKey].join('');
      
      console.log(`📦 Tamaño total base64: ${(contenidoCompleto.length / 1024 / 1024).toFixed(2)} MB`);
      
      // Guardar en base de datos
      const archivo = this.archivoRepository.create({
        proyecto_id: body.proyecto_id,
        nombre_archivo: body.nombre_archivo,
        contenido_base64: contenidoCompleto,
        mime_type: body.mime_type,
        tipo_media: body.tipo_media || 'documento',
      });

      const saved = await this.archivoRepository.save(archivo);

      // Limpiar chunks temporales
      delete this.chunksTemporales[chunkKey];
      
      console.log(`✅ Archivo guardado exitosamente: ${body.nombre_archivo}`);

      return {
        mensaje: 'Archivo completo subido exitosamente',
        archivo: saved,
      };
    }

    // Si aún faltan chunks, devolver progreso
    return { 
      mensaje: `Chunk ${body.chunk_index + 1}/${body.total_chunks} recibido`,
      progreso: Math.round((chunksRecibidos / body.total_chunks) * 100),
      chunks_recibidos: chunksRecibidos,
      chunks_totales: body.total_chunks,
    };
  }
}
```

## Instrucciones:

1. Copia este código en tu backend
2. Haz commit y push
3. Reinicia el servidor local: `npm run start:dev`
4. Intenta subir el video nuevamente

Con esto, los videos grandes (>4MB) se dividirán en chunks de 1MB y se subirán uno por uno, evitando el error 413.
