# Auditoría de arquitectura FACELY Android → iOS

Fuente de verdad revisada: `maxijones012/faceIdentifyAR`, branch `main`, estado observado en commit `02b86e94b717a41904980dfb64c3f5b6a67e50d2`.

## Estado Android actual

El README quedó atrasado respecto del código. `app/build.gradle.kts` informa versión `0.14.5` (versionCode 30). El proyecto usa Kotlin/Android nativo, Room, WorkManager, ML Kit, TensorFlow Lite, ONNX Runtime, AdMob y UMP.

### Módulos reales

- `data/`: Room, entidades, DAO y caché de proyecciones.
- `face/`: motores, modelos, similitud, búsqueda, agrupamiento, revisión, outliers y memoria de correcciones.
- `scanner/`: lectura de MediaStore, carga de bitmaps y análisis facial.
- `work/`: escaneo foreground/background, scheduling y backups.
- `backup/`: respaldo compacto y destino externo persistente.
- `security/`: bloqueo de sesión y biometría/dispositivo.
- `ads/`: AdMob y política de anuncios.
- `update/`: actualización Android propia.
- `ui/`: Personas, detalle, búsqueda, revisión, descartados, ajustes y actualizaciones.

## Base de datos Android

Room schema v3:

- `photos`: `mediaId` único, URI, nombre, fecha de modificación, fecha de análisis, cantidad de caras, versión de embedding.
- `faces`: `photoId`, bounding box, embedding BLOB, `clusterId`.
- `person_clusters`: etiqueta, fecha de creación y `discarded`.

Hay índices sobre `photoId` y `clusterId`. La migración 2→3 agrega `discarded` y el código evita expresamente `fallbackToDestructiveMigration`.

### Separación por motor

Android usa dos archivos Room distintos:

- FaceNet actual: `rostrolocal.db`
- UniFace/ArcFace experimental: `rostrolocal_experimental.db`

El port iOS conserva la separación desde ETAPA 1.

## Motores faciales

### FaceNet

- TFLite
- entrada RGB 160×160
- embedding 128D Float32
- estandarización por imagen: `(x - mean) / max(std, 1/sqrt(N))`
- salida L2-normalizada

### UniFace / ArcFace

- ONNX Runtime
- modelo `w600k_mbf.onnx`
- entrada RGB NCHW `[1,3,112,112]`
- normalización `(x - 127.5) / 127.5`
- embedding 512D L2-normalizado
- SHA-256 actual confirmado en Android: `9cc6e4a75f0e2bf0b1aed94578f144d15175f357bdc05e815e5c4a02b319eb4f`

El scanner Android además alinea ArcFace con landmarks de ojos y nariz. En iOS esto exige Vision con landmarks para reproducir el comportamiento; `VNDetectFaceRectanglesRequest` solo no alcanza para esa parte.

## EmbeddingCodec

Android serializa `Float32` little-endian. iOS debe conservar ese convenio para futura importación/exportación multiplataforma.

## Agrupamiento

`ClusterAssigner`:

- carga centroides de grupos del mismo `embeddingVersion`
- umbral automático: `0.78`
- exige margen mínimo contra el segundo candidato: `0.035`
- si hay empate o una corrección humana lo bloquea, crea un grupo nuevo
- actualiza el centroide acumulado en memoria durante el escaneo

`CorrectionMemory` guarda decisiones “no son la misma persona” localmente y las usa para bloquear reasignaciones contradictorias. También remapea reglas después de fusiones.

## Revisión de clusters

`ClusterReviewEngine` no fusiona automáticamente. Produce sugerencias para revisión humana.

- umbral base: `0.72`
- probable: `0.78`
- muy probable: `0.84`
- hasta 500 grupos usa comparación exacta
- con más grupos usa LSH: 10 tablas, 18 bits, Hamming 1
- límite aproximado: 400.000 pares evaluados
- usa poda temprana Cauchy-Schwarz
- mantiene caché de índice y sugerencias

La lógica debe portarse, no reemplazarse por un algoritmo genérico distinto.

## Outliers

`OutlierReviewEngine` propone caras atípicas sin moverlas automáticamente:

- mínimo 3 caras por grupo
- score débil absoluto `0.66`
- caída relativa respecto de mediana `0.10`
- máximo 12 candidatos
- respeta memoria de rostros confirmados como válidos

## Búsqueda facial — optimización crítica

Los commits recientes `0dbb143` y `d24fe5c` corrigen el problema de cargar todos los embeddings en RAM.

La implementación actual:

1. usa páginas por `face.id`
2. lote de 256
3. filtra grupos descartados
4. rechaza BLOB vacíos, demasiado grandes, no múltiplos de 4 o de dimensión incompatible
5. conserva solo el mejor score por cluster
6. aplica umbral `0.30`
7. recién al final carga las muestras/fotos de los mejores resultados

Esta estrategia es requisito obligatorio del port iOS.

## Personas y rendimiento

`AppDao.clusterSummaries()` precarga muestras por lotes de hasta 800 para evitar N+1 queries al construir la grilla. `PeopleActivity` además actualiza la pantalla en vivo durante escaneos sin depender de una nueva búsqueda manual.

En iOS se debe reproducir con consultas agregadas, proyecciones pequeñas, miniaturas PhotoKit y carga diferida en SwiftUI.

## Escaneo incremental

`FaceScanWorker` compara el estado actual de MediaStore con `photoScanStates()` y clasifica como pendiente si:

- la foto es nueva
- cambió la fecha de modificación
- cambió la versión del motor

Las fotos sin cambios y con la misma versión de motor no se reprocesan.

También elimina registros faltantes cuando tiene acceso completo, publica progreso/ETA, soporta pausa y aplica throttling según estado térmico.

## Background

Android usa WorkManager, contenido observado y foreground service. No tiene equivalente 1:1 en iOS.

Port correcto:

- escaneo foreground reanudable
- checkpoints frecuentes
- `BGProcessingTask` como oportunidad, no garantía
- retomar pendientes al abrir la app
- nunca prometer análisis ilimitado en segundo plano

## Backups

El respaldo Android actual está centrado en el motor FaceNet histórico y usa formato binario/gzip propio (formato 2). No conviene consumirlo directamente en iOS como si ya fuera un formato multiplataforma definitivo.

Se recomienda definir en una etapa posterior un `facely-backup` común versionado y agregar importadores explícitos sin destruir el índice Android.

## UI actual

La navegación Android actual incluye barra inferior con:

- Personas
- Buscar
- Analizar (acción central)
- Revisar
- Ajustes

El port SwiftUI debe mantener esa identidad visual oscura/cyan, pero con controles y navegación nativos de iOS. ETAPA 1 no expone botones falsos para funciones todavía no implementadas.

## Equivalencias Android → iOS

| Android | iOS nativo |
|---|---|
| MediaStore | PhotoKit / PHPhotoLibrary |
| ML Kit Face Detection | Vision |
| Room | SQLite3 con migraciones explícitas |
| WorkManager | Swift concurrency + BGTaskScheduler |
| BiometricPrompt | LocalAuthentication |
| RecyclerView | LazyVGrid / List |
| Bitmap/Canvas/Matrix | CGImage / CoreGraphics / vImage |
| SharedPreferences | UserDefaults o almacenamiento local versionado según criticidad |
| TFLite Android | TensorFlow Lite iOS inicialmente |
| ONNX Runtime Android | ONNX Runtime iOS inicialmente |

## Riesgos a vigilar

1. ArcFace necesita alineación equivalente con landmarks; no alcanza con crop rectangular.
2. PhotoKit limitado puede hacer que “foto eliminada” y “foto ya no autorizada” no sean lo mismo; no se debe borrar información a ciegas.
3. BackgroundTasks no garantiza continuidad larga.
4. Los dos motores jamás deben compartir clusters ni embeddings.
5. Búsqueda, grillas y revisión deben evitar cargas masivas de BLOB/imágenes.
6. El formato de backup Android actual no debe migrarse destructivamente.
7. Los IDs reales de AdMob iOS deben ser independientes y llegar por configuración/CI, no hardcodeados.

## Decisión ETAPA 1

Se usa SQLite3 nativo en iOS para tener control explícito del esquema, migraciones y consultas paginadas. El esquema inicial replica conceptualmente las tres entidades Android sin guardar fotografías completas en BLOB y crea archivos separados para FaceNet y ArcFace.
