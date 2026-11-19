# Aviation

App iOS (SwiftUI) que busca aeropuertos con la API de [Aviationstack](https://aviationstack.com).

## API
Plan gratuito de Aviationstack, que solo sirve HTTP: la base es `http://api.aviationstack.com/v1` y `project.yml` añade una excepción de ATS limitada a `api.aviationstack.com`.

## Clave de la API
1. Copia `Config/Secrets.example.xcconfig` a `Config/Secrets.xcconfig` (está en `.gitignore`).
2. Pon tu clave en `AVIATIONSTACK_ACCESS_KEY`. Se pasa al Info.plist (`AviationstackAccessKey`) y se lee con `Bundle.main`.

Sin clave la app compila, pero la API responderá con error. Los tests no la necesitan.

## Ejecutar y probar
```
brew install xcodegen
xcodegen generate
open Aviation.xcodeproj   # Run
xcodebuild test -scheme Aviation -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
El `.xcodeproj` no está en git: se genera desde `project.yml`.

## Arquitectura
Un solo target con tres carpetas:
- `Data`: `AviationstackClient` (HTTP, decodificación, `APIError`).
- `Domain`: `Airport`, `AirportRepository`, `SearchAirportsUseCase` (recorta el texto y exige 3 caracteres).
- `Presentation`: `SearchViewModel` (estados idle / loading / loaded / empty / failed) y las vistas.

## Cancelación
`SearchView` lanza la búsqueda en `.task(id: query)`: cada cambio de texto cancela la tarea anterior. La tarea espera 300 ms (`Task.sleep`, debounce) antes de buscar. Si la petición ya estaba en curso, `SearchViewModel` comprueba `Task.isCancelled` tras el `await` y no escribe estado, así que nunca se muestran resultados de una búsqueda antigua.
