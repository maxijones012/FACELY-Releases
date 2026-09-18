# FACELY iOS

Port nativo de FACELY para iPhone. Este repositorio parte del comportamiento real de `maxijones012/faceIdentifyAR` y no reemplaza ni modifica la aplicación Android.

## Estado

**ETAPA 1 implementada localmente**

- SwiftUI, iOS 16+
- estructura modular inicial
- SQLite nativo (`SQLite3`)
- esquema `photos` / `faces` / `person_clusters`
- migraciones explícitas y no destructivas
- dos bases independientes desde el inicio:
  - `facely.db` para FaceNet
  - `facely_arcface.db` para UniFace / ArcFace
- tests de creación de esquema y separación de motores
- CI de GitHub Actions para build y tests en iOS Simulator
- sin funciones falsas: PhotoKit, Vision, embeddings, agrupamiento y búsqueda todavía pertenecen a etapas posteriores

## Generar el proyecto Xcode

```bash
brew install xcodegen
xcodegen generate
open FACELY.xcodeproj
```

## Identidad

- Nombre: FACELY
- Marca: SoftwareParaTodos
- Bundle ID inicial: `ar.com.rostrolocal.facely`
- Deployment target: iOS 16.0

## Principios mantenidos desde Android

- procesamiento facial local
- dos motores completamente separados
- no borrar datos mediante migraciones destructivas
- no guardar fotos completas dentro de SQLite
- preparar compatibilidad de formatos entre Android e iOS
