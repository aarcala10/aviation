# Historia: Como viajero quiero ver los vuelos que salen de un aeropuerto para saber qué sale desde allí.

Issue: #3 · Plataformas: iOS

> Comprobado el 2026-11-19 con la clave real (plan gratuito): `GET https://api.aviationstack.com/v1/flights?dep_iata=MAD` funciona por HTTPS. La respuesta real está en `AviationTests/Fixtures/flights.json`.

## Criterios de aceptación
1. Dado que he buscado "madrid", cuando toco la fila de MAD, entonces se abre la pantalla «Salidas de MAD» con un indicador de carga mientras se piden sus salidas a Aviationstack.
2. Dado que la petición termina con vuelos, cuando se muestra la lista, entonces cada fila enseña el número de vuelo y la aerolínea, el destino (código IATA y nombre del aeropuerto), la hora programada de salida (HH:mm) y una píldora de estado (color, símbolo y texto, según `docs/design.md`).
3. Dado que Aviationstack devuelve la hora local del aeropuerto con un falso `+00:00`, cuando se muestra la hora, entonces es la hora local del aeropuerto tal cual llega (un 05:55 de Madrid se ve como 05:55 con cualquier zona horaria del iPhone).
4. Dado que un vuelo llega varias veces como código compartido (`flight.codeshared` no es nulo), cuando se muestra la lista, entonces solo aparece el vuelo operado. **(decisión del usuario)**
5. Dado que un vuelo programado o en vuelo tiene `departure.delay` > 0, cuando se muestra su estado, entonces la píldora dice «Retrasado». Un vuelo cancelado sigue siendo «Cancelado» aunque tenga retraso. **(asumido)**
6. Dado que no hay salidas, cuando termina la petición, entonces veo «No hay salidas» en un `ContentUnavailableView`.
7. Dado que la petición falla, cuando termina, entonces veo un mensaje con la causa («Comprueba tu conexión», «Se ha agotado la cuota de la API», «La clave de la API no es válida» o un mensaje genérico) y un botón «Reintentar» que vuelve a pedir las salidas. **(asumido: botón, porque en esta pantalla no se escribe nada)**

### Añadidos decididos por el usuario el 2026-11-20 (después del primer plan)
8. Dado que la lista tiene vuelos, cuando se muestra, entonces va en secciones por fecha, la más reciente primero. Dentro de un día, la hora programada más temprana primero y, a igual hora, el orden de la API. Los vuelos sin fecha van en una última sección «Sin fecha». La cabecera de sección dice «viernes, 20 de noviembre», formateada en UTC para que el día no cambie con la zona horaria del iPhone, y tiene el rasgo de cabecera.
9. Dado que VoiceOver está activo, cuando se abre la pantalla, entonces el título se lee «Salidas de Madrid» (la ciudad, de la lista local de aeropuertos; si no, el nombre del aeropuerto y, si no, el código) mientras que en pantalla sigue «Salidas de MAD». La fila se lee «Vuelo A Z 5 9. ITA Airways. A Barcelona. Sale a las 5:55. Programado.»: el destino es la ciudad de la lista local mediante `CityLookup` (si no, el nombre de aeropuerto de la API), solo el número de vuelo se deletrea y la hora se dice sin el cero inicial («Sale a la 1:10» para la una). Las ciudades de los datos están en inglés («Rome», «London»).
10. Dado que se abre la pantalla, cambia el estado o se reintenta con éxito, entonces el foco de VoiceOver cae sin esperas: título como `Text` de cabecera arriba del contenido (`.toolbar(removing: .title)`, manteniendo `navigationTitle` para el nombre de la barra), `AccessibilityNotification.ScreenChanged().post()` al aparecer y en cada cambio de estado, el error se anuncia con prioridad alta y, tras «Reintentar» con éxito, el foco va a la primera fila de la primera sección (`@AccessibilityFocusState`).

## Fuera de alcance
- Caché (#2, que va después de esta historia; su plan está en `docs/plans/plan2.md`).
- Cargar más páginas (#5): aquí solo se pide la primera, con `limit=100&offset=0`. La API pagina con `limit`/`offset` y devuelve `pagination.total`. **(decisión del usuario, 2026-11-20: páginas de 100, porque la primera página de 20 de MAD eran todo códigos compartidos)**
- Detalle del vuelo (#4): las filas de vuelos todavía no navegan.
- Ordenar por fecha y hora ya **está en alcance** (decisión del usuario, 2026-11-20: secciones por fecha, criterio 8). Sigue fuera: filtrar por fecha y tirar para refrescar.
- Reorganizar los archivos en carpetas por funcionalidad (Domain/Airports, Flights, Shared; Data/...; Presentation/Search, Flights; tests en espejo): vive en una rama local aparte y será un cambio separado.

## Decisiones técnicas (una línea cada una)
- `GetDeparturesUseCase` en Domain, como `SearchAirportsUseCase` **(decisión del usuario)**: pide la página al `FlightRepository` y descarta los códigos compartidos (`Flight.isCodeshare`). `FlightsViewModel` depende del caso de uso. La regla de estado (retrasado/cancelado) vive en el modelo `Flight`.
- `AviationstackFlightRepository` en Data recibe el transporte inyectado (un cierre o un `URLSession` con `URLProtocol` de prueba), de modo que los tests nunca llaman a la red. La clave se lee de Info.plist (`AviationstackAccessKey`), como ya está preparado. Mapea `flight.codeshared != null` a `isCodeshare` y no filtra nada.
- Los mensajes de error de `SearchViewModel.message(for:)` se comparten con `FlightsViewModel`, cambiando solo el texto genérico.
- Cambio de 20 a 100 (2026-11-20): en la verificación en el simulador, la primera página de MAD con `limit=20` eran 20/20 códigos compartidos y, tras ocultarlos, la pantalla mostraba «No hay salidas». El usuario eligió `limit=100` y autorizó cambiar el test 1 (ahora `departures_requestsFirstPageOfHundred`). Una petición real con `limit=100` devolvió 28 vuelos operados y 72 códigos compartidos.

## Tests (en orden, agrupados por capa)
### iOS unitarios — Domain (`GetDeparturesUseCase` con `MockFlightRepository`, y `Flight`)
1. `departures_requestsFirstPageOfHundred`
2. `departures_skipsCodeshares`
3. `departures_propagatesRepositoryError`
4. `status_withDepartureDelay_isDelayed`
5. `status_cancelledWithDelay_staysCancelled`
### iOS unitarios — Data (`AviationstackFlightRepository`, `flights.json` y transporte de prueba)
6. `departures_requestsDepIataLimitOffsetAndAccessKeyOverHTTPS`
7. `departures_decodesFlights`
8. `departures_scheduledTime_isAirportLocalTime`
9. `departures_mapsCodeshared`
10. `departures_errorBody_throwsAPIError`
### iOS unitarios — Presentation (`FlightsViewModel`, caso de uso con `MockFlightRepository`)
11. `load_success_showsFlights`
12. `load_noFlights_showsEmptyState`
13. `load_failure_showsError`
14. `retry_afterFailure_loadsAgain`
### iOS UI (camino feliz)
15. `searchAndOpenAirport_showsDepartures`: busca "madrid", toca MAD y comprueba el título «Salidas de MAD». Solo comprueba la navegación, así que pasa en la CI sin clave. En local gasta una petición de la cuota por ejecución.

## Paridad
| # | iOS |
|---|-----|
| 1–5 | ✅ |
| 6–10 | ✅ |
| 11–14 | ✅ |
| 15 | ✅ |

## Hecho cuando
- [x] `AviationTests/Fixtures/flights.json`: la respuesta real (2 códigos compartidos de AZ59) más un vuelo operado añadido a mano, con retraso, para los tests 7–9
- [x] `MockFlightRepository` en `AviationTests/Support/`, con contador de llamadas (lo reutiliza la #2)
- [x] Textos en `Localizable.xcstrings` (es): «Salidas de %@», carga, «No hay salidas», «Reintentar», nombres de los estados y la etiqueta de accesibilidad de la fila
- [x] Diseño según `docs/design.md`: FlightRow, StatusBadge, horas con `.monospacedDigit()`, revisado por `swiftui-a11y-refactorer` (sin cambios). Modo oscuro y claro vistos con vuelos reales. Contraste: el texto de `StatusBadge` estaba por debajo de 4,5:1 en 6 de los 10 pares estado/apariencia (claro: secundario 2,95, verde 1,96, naranja 2,96, rojo 2,90; oscuro: rojo 4,23; WCAG sobre el tinte del 15 %). Corregido en el 78c29b6: el texto es `.primary`, el símbolo conserva el color y la cápsula el tinte; ahora todos los pares dan al menos 13:1 (verde «Aterrizado» 18,59 claro, 12,83 oscuro; no apareció en los datos reales, así que se cubre con los números)
- [x] Accesibilidad (checklist de `docs/design.md`):
  - [x] Cada fila es un único elemento («Vuelo A Z 5 9, ITA Airways, a Fiumicino F C O, 05:55, Programado»): por revisión de código
  - [x] El estado no depende solo del color (color + símbolo + texto): por revisión de código
  - [x] Se ve en AX5 sin cortes: captura en modo oscuro, la lista «Salidas de MAD» pasa a disposición vertical sin cortes ni solapes
  - [x] Se anuncia el error: anuncio con `AccessibilityNotification` (prioridad alta); falta oírlo en VoiceOver (iPhone físico, pendiente en `docs/manual-tests.md`)
  - [x] Frase de la fila y pausa tras el destino: confirmadas de oído por el usuario en el dispositivo; cabeceras de sección con el rasgo de cabecera, aprobadas por el usuario
  - [x] Foco de VoiceOver, sin confirmar en el dispositivo: que cae en el título al abrir la pantalla, en el estado de error y en la primera fila tras «Reintentar»
- [x] Secciones por fecha, ciudad hablada y frase de la fila (criterios 8 y 9), con tests `FlightSection`, `FlightsSections`, `FlightsSpokenCity`, `DestinationCity` y `LocalCityLookup`
- [x] Suites finales locales (2026-11-20, commit 0fb0bdf): 39 tests unitarios en 15 suites y 2 de UI, todo en verde, 0 warnings de Swift. De los 39, 14 son el lote TDD original, 11 son de la #1 y 14 se añadieron después (4 de regresión anteriores + `FlightSection` 4, `FlightsSections` 1, `FlightsSpokenCity` 1, `DestinationCity` 2, `LocalCityLookup` 2). `FlightsUITests` sigue encontrando la barra «Salidas de MAD»
- [x] El String Catalog ya no se reescribe en cada build: la clave de la etiqueta de la fila coincide con lo que extrae el compilador. Si cambia el texto de la etiqueta, hay que actualizar su clave en el catálogo en el mismo cambio
- [x] README: endpoint `/flights`, por qué la hora se muestra tal cual y que se ocultan los códigos compartidos
- [x] Prueba manual en el simulador con la clave real (2026-11-20): MAD muestra salidas sin duplicados y el error con «Reintentar» funciona.
  - Modo claro, tamaño por defecto, API real (una petición tras forzar un primer fallo): filas con vuelo, hora, aerolínea, destino y píldora; «Retrasado» y «Programado» legibles, nada cortado (~40 filas, 5 deslizamientos).
  - Modo oscuro y AX5: filas en vertical, sin cortes, píldora legible (p. ej. LH1117 Lufthansa a FRA, 06:05, «Retrasado»).
  - Error forzado con un argumento de lanzamiento temporal que hace lanzar `URLError.notConnectedToInternet` a la primera petición (gancho y test de UI temporales, revertidos, nunca commiteados): icono de aviso, «Error al cargar las salidas», «Comprueba tu conexión» y «Reintentar»; al tocarlo se carga la lista.
  - No visto: la píldora verde «Aterrizado» (no salió en los datos reales).
- Único pendiente: los chequeos de foco de VoiceOver en un iPhone físico.

## Sugerencias
- En la prueba manual, mirar si la API mezcla salidas de varios días. Si es así, mostrar la fecha en la fila o filtrar por hoy, en la #5 o en una historia nueva.
- Con páginas de 100 y la cuota del plan gratuito (unas 100 peticiones al mes), cada página cuesta una petición. Si se descartan los códigos compartidos, una página puede quedar con bastantes menos filas (la primera de 20 de MAD quedó en 0). Se puede revisar en la #5.
- Después de esta historia, rehacer `docs/plans/plan2.md` (caché) con los nombres reales: `FlightRepository` y `MockFlightRepository`.
