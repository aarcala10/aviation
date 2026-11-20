# Aviation

App iOS (SwiftUI) que busca aeropuertos en una lista local.

## Lista de aeropuertos
La búsqueda no usa red: lee `Aviation/Data/Airports/airports.json`, incluido en la app. Se generó el 2026-11-19 a partir de [OurAirports](https://ourairports.com/data/) (dominio público) con este filtro: `iata_code` no vacío, `type` en `large_airport`, `medium_airport` o `small_airport`, y `scheduled_service = yes`. Son 4007 aeropuertos (un JSON compacto `{n, c, i, k}`: nombre, ciudad, IATA y país ISO). El país se muestra en español con `Locale`.

## Clave de Aviationstack
La clave solo hará falta para los vuelos (historia #3); el plan gratuito no permite consultar aeropuertos. Para tenerla preparada: copia `Config/Secrets.example.xcconfig` a `Config/Secrets.xcconfig` (está en `.gitignore`) y pon tu clave en `AVIATIONSTACK_ACCESS_KEY`. Se pasa al Info.plist (`AviationstackAccessKey`). Sin clave la app compila y busca aeropuertos igual.

## Salidas de un aeropuerto
Al tocar un aeropuerto se piden sus salidas a `GET https://api.aviationstack.com/v1/flights?dep_iata=XXX&limit=100&offset=0` (solo la primera página). La hora de salida se muestra tal cual llega (HH:mm): la API manda la hora local del aeropuerto con un falso `+00:00`, así que no se convierte a ninguna zona horaria. Los vuelos con `flight.codeshared` no nulo (códigos compartidos) se ocultan para no repetir el vuelo operado.

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
- `Data`: `LocalAirportRepository` (lee y filtra la lista, sin distinguir mayúsculas ni acentos; primero el código IATA exacto, máximo 50 resultados) y `airports.json`.
- `Domain`: `Airport`, `AirportRepository`, `SearchAirportsUseCase` (recorta el texto y exige 3 caracteres) y `APIError`.
- `Presentation`: `SearchViewModel` (estados idle / loading / loaded / empty / failed) y las vistas.

## Cancelación
`SearchView` lanza la búsqueda en `.task(id: query)`: cada cambio de texto cancela la tarea anterior. La tarea espera 300 ms (`Task.sleep`, debounce) antes de buscar. Si la búsqueda ya estaba en curso, `SearchViewModel` comprueba `Task.isCancelled` tras el `await` y no escribe estado, así que nunca se muestran resultados de una búsqueda antigua.
