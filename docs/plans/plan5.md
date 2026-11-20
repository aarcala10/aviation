# Historia: Como viajero quiero seguir bajando en la lista de vuelos para ver más salidas sin cambiar de pantalla (#5)

Plataformas: iOS

## Criterios de aceptación
1. Dado un aeropuerto con más de 100 salidas, cuando llego al final de la lista, entonces se pide la página siguiente (`limit=100`, `offset` = 100, 200…) y sus vuelos se añaden a la lista, agrupados por día como los primeros.
2. Dado que se está cargando la página siguiente, cuando miro el final de la lista, entonces veo un `ProgressView()` como última fila, y no se lanza otra petición mientras tanto.
3. Dado que la última página trajo menos de 100 vuelos (contados antes de quitar los codeshares), cuando llego al final, entonces no se pide nada más y no hay fila de carga.
4. Dada una página que solo trae codeshares (100 vuelos sin ninguno nuevo que mostrar), cuando termina de cargar, entonces se pide la siguiente sin que yo tenga que hacer nada.
5. Dado que una página repite un vuelo que ya se ve (mismo `Flight.id`: los datos cambian entre peticiones), cuando se añade, entonces aparece una sola vez.
6. Dado que falla la carga de la página siguiente (sin conexión, cuota agotada…), cuando ocurre, entonces los vuelos ya cargados siguen en pantalla y la última fila muestra el mensaje de la causa (o «No se han podido cargar más salidas») y un botón «Reintentar» que vuelve a pedir esa misma página. VoiceOver anuncia el error una vez.
7. Dado que estoy en una página siguiente, cuando reintento la pantalla entera o se recarga, entonces se empieza de nuevo por la primera página, y una carga de página antigua que llegue tarde no toca la lista.
8. Dado que vuelvo del detalle de un vuelo, cuando aparece la lista, entonces conserva todas las páginas cargadas (no se recarga).

Asumido (corrígelo si no te encaja):
- Tamaño de página: 100, el máximo del plan gratuito. Cada página es una petición de la cuota mensual.
- Se sabe que no hay más páginas porque la API devuelve menos de 100 elementos. No se usa `pagination.total`. Si el total es justo un múltiplo de 100, se hace una petición extra que vuelve vacía, y es aceptable.
- La caché ya guarda cada página por su `offset` (clave `IATA-limit-offset`, TTL 5 min). No cambia.

## Fuera de alcance
- Pull-to-refresh y recarga automática de la lista.
- Precargar la página siguiente antes de llegar al final (se carga al aparecer la última fila).
- Mostrar el total de salidas o el número de página.
- Paginación en la búsqueda de aeropuertos.

## Tests (en orden, agrupados por capa)
Data: sin cambios. La caché ya separa las páginas por offset y eso ya lo prueba `flights_differentPage_callsRepository`.

### iOS unitarios — Domain (`GetDeparturesUseCase` con `MockFlightRepository`)
1. `departures_requestsPageAtOffset`: pide `limit: 100, offset: n` (sustituye a `departures_requestsFirstPageOfHundred`).
2. `departures_fullPage_hasNextOffset`: 100 elementos en bruto → `nextOffset = offset + 100`.
3. `departures_shortPage_hasNoNextOffset`: menos de 100 → `nextOffset == nil`.
4. `departures_fullPageOfCodeshares_stillHasNextOffset`: los 100 son codeshares → lista vacía, pero `nextOffset` sigue existiendo.

### iOS unitarios — Presentation (`FlightsViewModel`)
5. `loadMore_appendsNextPage` (criterio 1)
6. `loadMore_whileLoading_requestsOnce` (criterio 2)
7. `loadMore_lastPage_stopsRequesting` (criterio 3)
8. `loadMore_pageWithoutNewFlights_loadsTheNextOne` (criterio 4)
9. `loadMore_dropsFlightsAlreadyShown` (criterio 5)
10. `loadMore_failure_keepsFlightsAndShowsError` (criterio 6)
11. `loadMore_retryAfterFailure_requestsSamePage` (criterio 6)
12. `load_afterLoadMore_startsAgainFromFirstPage_andIgnoresLatePage` (criterio 7)

### iOS UI
Ninguno nuevo: es la misma pantalla y no un recorrido nuevo, y los ViewModels ya prueban todos los casos. Haría falta un fixture de 100 vuelos y otro para la página 2, y no compensa. El criterio 8 se comprueba a mano: lo cubre el `loadedAttempt` que ya existe.

## Hecho cuando
- [x] Los 12 tests están en verde junto con la suite completa (TDD por lotes). 2026-11-20, simulador iPhone 17 Pro: AviationTests 72/72 en 20 suites, `FlightsUITests` 2/2.
- [x] i18n: claves nuevas en `Localizable.xcstrings` → «No se han podido cargar más salidas», «Cargando más salidas» (etiqueta de VoiceOver de la fila de carga). «Reintentar» ya existe.
- [x] Diseño revisado en código (2026-11-20, `swiftui-pro`, `swiftui-expert-skill`, `ios-accessibility`): `ProgressView()` como última fila compartida (`pagingIndicator`) y mensaje de error centrado para AX5.
- [x] Fila de error vista en el simulador (2026-11-20, iPhone 17 Pro, test de UI temporal): tamaño por defecto y XXXL, mensaje en dos líneas centradas, botón completo, nada cortado. Fin de lista por defecto: la página 2 sigue a XX1099 en el mismo día, sin fila de carga.
- [x] Horizontal (2026-11-20, iPhone 17 Pro, claro, tests de UI temporales borrados): final de la lista tras la página 2 y fila de error con «Reintentar», sin cortes. El detalle en horizontal no se ha leído.
- [x] Píldora de estado en una línea con texto grande (commit 10bbade, `StatusBadge`: `.labelStyle(.titleAndIcon)` + `.fixedSize()`): en XXXL, fila de vuelo en claro y oscuro, «Programado» entero junto al icono, sin partir. AviationTests 72/72, FlightsPaginationUITests 1/1 y FlightsUITests 2/2 en verde.
- [ ] Modo oscuro de las filas nuevas (carga y error), la fila de carga con una petición en vuelo, la píldora de la cabecera del detalle en XXXL y el detalle en horizontal: sin comprobar.
- Criterio 8 cubierto por `FlightsPaginationUITests/testScrollingLoadsNextPageAndKeepsItAfterDetail` (commit 3aa1d49, fixture paginado `-uiTestPagedFixtures`); AviationUITests: FlightsPaginationUITests 1/1 y FlightsUITests 2/2 en verde.
- [ ] Accesibilidad: VoiceOver lee la fila de carga, anuncia el error de página una vez sin mover el foco, y el botón «Reintentar» es alcanzable.
- [x] Simulador con fixtures: página 2, vuelta del detalle (test de UI permanente) y error + reintentar (test temporal, borrado). Apuntado en `docs/manual-tests.md`.
- [ ] Prueba manual en el simulador con la API real (MAD tiene más de 100 salidas): sin hacer.

## Sugerencias
- La historia #4 sigue abierta (rama `feature/4-flight-detail`). Mejor cerrarla y mergearla antes de crear la rama de la #5 desde `main`.
- Cuota: con el plan gratuito, cada página cuesta una petición al mes. Se podría limitar a unas pocas páginas por sesión. No lo propongo para esta historia salvo que la cuota te preocupe.
