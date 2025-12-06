# 🚨 ACTUALIZACIÓN NECESARIA EN BACKEND

## Problema
- ✅ Video comprimido exitosamente: **83.8% de reducción**
- ❌ Error 413 al subir: El payload base64 es **2.32 MB**
- 📊 Razón: Vercel tiene límite de ~1MB por defecto en requests

## Solución

### En el Backend (volunred-backend)

Actualiza `src/main.ts`:

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import * as express from 'express';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // ✅ AGREGAR ESTAS LÍNEAS (antes de habilitar CORS)
  app.use(express.json({ limit: '50mb' }));
  app.use(express.urlencoded({ limit: '50mb', extended: true }));

  app.enableCors();
  
  await app.listen(process.env.PORT || 3000);
}

bootstrap();
```

### Deploy

1. Haz commit de los cambios:
```bash
cd volunred-backend
git add src/main.ts
git commit -m "fix: Aumentar límite de request a 50MB para media uploads"
git push
```

2. Vercel redeploy automático o manual:
```bash
vercel deploy --prod
```

## Resultado Esperado

Con esta actualización:
- ✅ Videos comprimidos (~2-3 MB en base64) se subirán exitosamente
- ✅ Imágenes (hasta 5 MB) se subirán sin problemas
- ✅ PDFs y documentos funcionarán correctamente

## Límites Actualizados

| Archivo | Tamaño Original | Comprimido | Base64 | ¿Sube? |
|---------|-----------------|-----------|--------|--------|
| Video 60s | 10-15 MB | 2-3 MB | 2.7-4 MB | ✅ SÍ |
| Foto JPEG | 5 MB | 5 MB | 6.7 MB | ✅ SÍ |
| PDF 10p | 5 MB | 5 MB | 6.7 MB | ✅ SÍ |
| Audio 1m | 2 MB | 2 MB | 2.7 MB | ✅ SÍ |

