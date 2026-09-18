# ETAPA 1 — resultado

Implementado:

- proyecto SwiftUI iOS 16+
- arquitectura de carpetas inicial
- `FaceEngineProfile` con FaceNet y ArcFace independientes
- SQLite3 nativo
- tablas `photos`, `faces`, `person_clusters`
- índices y claves foráneas
- migración v1 explícita y no destructiva
- UI de diagnóstico de infraestructura, sin simular funciones futuras
- unit tests iniciales
- GitHub Actions para generar proyecto, compilar Simulator y ejecutar tests

No implementado todavía (por diseño):

- PhotoKit
- Vision
- TFLite
- ONNX Runtime
- agrupamiento
- búsqueda facial
- Personas
- cámara
- biometría
- backup multiplataforma
- AdMob/UMP

Eso comienza en ETAPA 2 y posteriores.
