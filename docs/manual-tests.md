# Pruebas manuales

## Historia #1 — Buscar un aeropuerto por nombre o código

### Completadas el 2026-11-19
Ejecutadas con `xcodebuild test -only-testing:AviationTests` en el simulador iPhone 17 Pro: 11/11 en verde.

- [x] Estado inicial con menos de 3 caracteres, sin llamada a la API → `SearchViewModelTests/search_shortQuery_staysIdle`, `SearchAirportsUseCaseTests/search_withLessThanThreeCharacters_returnsEmptyWithoutCallingRepository`
- [x] La búsqueda se recorta antes de llamar → `SearchAirportsUseCaseTests/search_trimsQueryBeforeCallingRepository`
- [x] Lista con nombre, IATA y país → `SearchViewModelTests/search_success_showsAirports`, `AviationstackClientTests/airports_decodesFixtureIntoAirports`
- [x] Petición con `access_key` y `search` → `AviationstackClientTests/airports_buildsRequestWithAccessKeyAndSearch`
- [x] Sin resultados → `SearchViewModelTests/search_noResults_showsEmptyState`
- [x] Error de red / API (clave, cuota) → `SearchViewModelTests/search_failure_showsError`, `AviationstackClientTests/airports_apiErrorResponse_throwsAPIError`, `SearchAirportsUseCaseTests/search_propagatesRepositoryError`
- [x] Cancelación: una búsqueda anterior nunca pisa la última → `SearchViewModelTests/search_cancelledSearch_doesNotOverwriteNewerResults`

### Pendientes, prioridad 1 (funcionales, se prueban en el simulador)
Todas pendientes porque aún no hay clave de la API (`Config/Secrets.xcconfig`) y los tests de UI quedan fuera de alcance de esta historia.

- [ ] **Búsqueda rápida.** Con la clave puesta, abrir la app, escribir rápido "mad" → "madr" → "madrid". Se ve el indicador "Buscando…" mientras carga y, al terminar, solo los resultados de "madrid".
- [ ] **Diseño y modos.** AirportRow con el código en una caja con fondo de acento; estados inicial, sin resultados y error; en modo claro y oscuro; en iPhone SE, iPhone 17 Pro Max y en horizontal.
- [ ] **Dynamic Type AX5.** Ajustes → Accesibilidad → Tamaño de texto más grande, al máximo: la fila pasa a vertical y no se corta ni el nombre ni el código.
- [ ] **HTTPS.** Comprobar si HTTPS funciona con la clave del plan gratuito; si funciona, quitar la excepción de ATS de `project.yml`.

### Pendientes, prioridad 2 (VoiceOver, en un iPhone físico)
- [ ] **Fila.** Un solo elemento que se lee «Adolfo Suárez Madrid-Barajas, M A D, España».
- [ ] **Resultados.** Al llegar resultados se anuncia una vez «N aeropuertos encontrados» (singular con 1) sin mover el foco.
- [ ] **Error.** Al llegar un error se anuncia el mensaje una vez.
- [ ] **Estado inicial y campo de búsqueda.** El orden de lectura es título → descripción.
