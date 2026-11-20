# Historia: Como viajero quiero buscar un aeropuerto por nombre o código para encontrarlo sin conocer su código exacto.

Issue: #1 · Plataformas: iOS

> **Cambio de alcance (2026-11-19, decisión del usuario):** con la clave del usuario (plan gratuito de Aviationstack), `/v1/airports` devuelve `function_access_restricted` tanto por HTTP como por HTTPS. La búsqueda de aeropuertos pasa a una lista local incluida en la app (datos de OurAirports, dominio público); Aviationstack solo se usa para vuelos (historia #3 en adelante).

## Criterios de aceptación
1. Dado que abro la app, cuando el campo de búsqueda está vacío, entonces veo un estado inicial que me invita a buscar un aeropuerto.
2. Dado que escribo al menos 3 caracteres (por ejemplo "madrid" o "MAD"), cuando dejo de escribir 300 ms, entonces veo una lista de aeropuertos de la lista local de aeropuertos de la app (busca por nombre, ciudad o código IATA, sin distinguir mayúsculas ni tildes) con nombre, código IATA y país.
3. Dado que escribo menos de 3 caracteres, cuando dejo de escribir, entonces no se busca y se mantiene el estado inicial. **(asumido: un código IATA tiene 3 letras)**
4. Dado que hay una búsqueda en curso, cuando cambio el texto, entonces la petición anterior se cancela y nunca se muestran sus resultados, solo los de la última búsqueda.
5. Dado que la búsqueda no encuentra aeropuertos, cuando termina la búsqueda, entonces veo "Sin resultados para «texto»".
6. Dado que la lista local de aeropuertos no se puede cargar, cuando termina la búsqueda, entonces veo un mensaje de error comprensible, y al volver a escribir se reintenta. **(asumido: sin botón "Reintentar")**
7. Dado que mientras se busca, cuando la petición está en curso, entonces veo un indicador de carga.
8. Dado un PR contra `main`, cuando se abre o se actualiza, entonces GitHub Actions genera el proyecto y pasa los tests, y el PR no se puede mergear si fallan.

## Fuera de alcance
- Caché de resultados (historia #2).
- Tocar un aeropuerto para ver sus vuelos (historia #3). Las filas no navegan todavía.
- Paginación de los resultados de aeropuertos: se muestran como máximo 50 resultados de la lista local.
- Llamadas a la API de Aviationstack (aeropuertos no está en el plan gratuito); la clave y su configuración quedan listas para la historia #3.
- Persistencia, modo offline, multiidioma (la UI se escribe en español), tests de UI.

## Decisiones técnicas (una línea cada una)
- Proyecto con **xcodegen** (`project.yml`) y sin `.xcodeproj` en git: la CI ejecuta `brew install xcodegen && xcodegen generate`.
- API key (para la historia #3) en `Config/Secrets.xcconfig` (en `.gitignore`), pasada al Info.plist y leída con `Bundle.main`. En la CI, los tests no la necesitan porque no tocan la red real.
- Aeropuertos locales: `Aviation/Data/airports.json` generado desde OurAirports (dominio público), solo aeropuertos con código IATA; nombres de país con `Locale`.
- iOS 26, Swift 6 estricto, Swift Testing. Runner de CI `macos-26` con Xcode 26; si no está disponible, `macos-15` con la versión de Xcode más reciente que tenga.

## Tests (en orden, agrupados por capa)
### iOS unitarios — Domain (`SearchAirportsUseCase`, repositorio mock)
1. `search_trimsQueryBeforeCallingRepository`
2. `search_withLessThanThreeCharacters_returnsEmptyWithoutCallingRepository`
3. `search_propagatesRepositoryError`
### iOS unitarios — Data (`LocalAirportRepository`, JSON de prueba en AviationTests/Fixtures)
Por decisión del usuario sustituyen a los anteriores tests de Data (`AviationstackClientTests`).
4. `airports_matchesByIataCode`
5. `airports_matchesByNameOrCityIgnoringCaseAndDiacritics`
6. `airports_invalidData_throws`
### iOS unitarios — Presentation (`SearchViewModel`, caso de uso con repositorio mock)
7. `search_success_showsAirports`
8. `search_noResults_showsEmptyState`
9. `search_failure_showsError`
10. `search_shortQuery_staysIdle`
11. `search_cancelledSearch_doesNotOverwriteNewerResults`

## Paridad
| # | iOS |
|---|-----|
| 1–3 | ✅ |
| 4–6 | ✅ |
| 7–11 | ✅ |

## Hecho cuando
- [x] `AviationTests/Fixtures/airports.json` de prueba con 3–4 aeropuertos y `Aviation/Data/airports.json` con el dataset completo — 4007 aeropuertos (~273 KB), generado el 2026-11-19 desde OurAirports (dominio público); filtro: código IATA, tipo large/medium/small, scheduled_service=yes, uno por IATA
- [x] Textos en String Catalog `Localizable.xcstrings` (es): estado inicial, sin resultados, error, carga, y el anuncio de resultados con plural
- [x] Diseño según `docs/design.md`: AirportRow, estados vacíos, color y tipografía por tokens — revisado en código por swiftui-a11y-refactorer y visto en el simulador el 2026-11-19 (iPhone 17 Pro iOS 26.5, claro y oscuro: inicial, resultados, sin resultados, contraste correcto, nada cortado; iPhone 17e con AX5 en claro: fila vertical sin truncar). Horizontal visto en iPhone 17 Pro, modo oscuro (inicial y resultados con teclado abierto, nada cortado); sin comprobar horizontal con teclado cerrado ni en claro (opcional)
- [ ] Accesibilidad (checklist de `docs/design.md`): cada fila se lee como un único elemento ("Adolfo Suárez Madrid-Barajas, M A D, España"), códigos deletreados, Dynamic Type AX5 sin cortes, modos claro y oscuro — fila como un elemento con etiqueta «nombre, código deletreado, país» (`speechSpellsOutCharacters`), HStack→VStack en tamaños de accesibilidad, anuncios en resultados/error; AX5, claro y oscuro vistos en simulador; auditoría: 4 avisos, todos de elementos del sistema (botón de borrar del campo, barra de predicción del teclado); árbol de accesibilidad correcto. Pendiente solo VoiceOver (¿se lee «M A D» letra a letra?) (opcional: horizontal con teclado cerrado y en claro)
- [x] `.github/workflows/ci.yml` pasando en el PR y protección de rama en `main` que exige ese check — pasó en el PR sobre a4c2739 (5m39s) tras el cambio de alcance; protección de `main` exige `test`
- [x] README inicial: origen de los datos (lista local de OurAirports), cómo ejecutar, arquitectura, cancelación
- [x] README: origen y licencia del dataset de aeropuertos
- [x] Prueba manual en el simulador: escribir rápido "mad" → "madr" → "madrid" y ver solo los resultados de "madrid" — hecha el 2026-11-19 con un test de UI temporal (borrado, no commiteado), iPhone 17 Pro, iOS 26: termina con la lista de "madrid" (2 filas: CLQ y MAD); además la cubre `SearchViewModelTests/search_cancelledSearch_doesNotOverwriteNewerResults`

## Sugerencias
- Mínimo de 3 caracteres (criterio 3). Un código IATA tiene 3 letras; quitarlo es cambiar una constante.
- Debounce de 300 ms con `Task.sleep` dentro de `.task(id:)`, para no lanzar una búsqueda por cada tecla.
