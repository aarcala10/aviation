# Historia: Como viajero quiero que volver a ver los vuelos de un aeropuerto que acabo de consultar sea instantáneo para no esperar a la red ni gastar cuota de la API.

Issue: #2 · Plataformas: iOS · Depende de #3 (cerrada el 2026-11-20).

> **Cambio de alcance (2026-11-19, decisión del usuario):** la issue pedía caché de la búsqueda de aeropuertos, pero desde #1 esa búsqueda es local e instantánea (no usa red ni cuota). La caché pasa a las salidas de Aviationstack, que es donde están la espera y la cuota.
>
> **Revisado el 2026-11-20 contra el código de #3:** `FlightRepository.departures(from:limit:offset:)` ya recibe la página, `MockFlightRepository` ya cuenta llamadas y «Reintentar» vuelve a pasar por el repositorio.

## Criterios de aceptación
1. Dado que he visto los vuelos que salen de MAD hace menos de 5 minutos, cuando vuelvo atrás y los abro otra vez, entonces veo la misma lista al momento, sin hacer otra petición a Aviationstack.
2. Dado que han pasado 5 minutos o más desde que los cargué, cuando los abro otra vez, entonces se hace una petición nueva y veo la lista actualizada.
3. Dado que tengo en caché los vuelos de MAD, cuando abro los de BCN, entonces se piden a Aviationstack (cada aeropuerto tiene su entrada).
4. Dado que la petición de vuelos ha fallado, cuando pulso «Reintentar» o vuelvo a abrir ese aeropuerto, entonces se intenta de nuevo contra la red (los errores no se guardan).
5. Dado que vi los vuelos de MAD hace menos de 5 minutos y cierro la app del todo, cuando la vuelvo a abrir y entro en MAD, entonces los veo al momento sin petición: la caché se guarda en disco con SwiftData. **(decisión del usuario, 2026-11-20)**
6. Dado que la entrada de MAD ha caducado, cuando se piden y llegan los vuelos nuevos, entonces sustituyen a la entrada anterior (una sola entrada por petición, nunca duplicadas).
7. Dado que el almacén de SwiftData no se puede abrir (p. ej. corrupto), cuando arranca la app, entonces funciona igual sin caché, pidiendo siempre a la red. **(asumido)**

## Fuera de alcance
- Caché de la búsqueda de aeropuertos (ya es local).
- Modo offline: si la petición falla no se enseña una entrada caducada, se enseña el error como hoy. **(asumido)**
- «Tirar para refrescar» para saltarse la caché.
- Migraciones de esquema: es la primera versión del modelo.
- Juntar en una sola dos peticiones simultáneas al mismo aeropuerto.
- Límite de entradas o limpieza de las caducadas: hay una por aeropuerto consultado y pesan poco; una caducada se sobrescribe al volver a pedirla.
- Cambios de pantalla: no hay vista nueva ni textos nuevos, así que `docs/design.md`, i18n y accesibilidad no aplican.

## Decisiones técnicas (una línea cada una)
- `CachedFlightRepository`: un `@ModelActor` en Data que implementa `FlightRepository` envolviendo otro. Recibe el `ModelContainer`, el repositorio real y `now: () -> Date` (los tests controlan el tiempo); `static let ttl: TimeInterval = 300`.
- Modelo SwiftData `CachedDepartures` (Data): `@Attribute(.unique) key` = IATA + `limit` + `offset` (las páginas de #5 nunca devuelven la primera por error), `fetchedAt: Date` y `flights: Data` con la página en JSON. `Flight` y `FlightStatus` pasan a `Codable`; no se replica `Flight` como `@Model`.
- Guarda la página tal como la da el repositorio; el filtro de códigos compartidos y las ciudades siguen en `GetDeparturesUseCase`.
- `AviationApp` crea el `ModelContainer` en disco; si falla, usa `AviationstackFlightRepository.live(...)` sin envolver (criterio 7). Los tests usan `ModelConfiguration(isStoredInMemoryOnly: true)`.

## Tests (en orden, agrupados por capa)
### iOS unitarios — Domain
Sin cambios: la caché no añade reglas al caso de uso de #3.
### iOS unitarios — Data (`CachedFlightRepositoryTests`, con `MockFlightRepository` y reloj inyectado)
1. `flights_withinTTL_returnsCachedWithoutCallingRepository`
2. `flights_afterTTL_callsRepositoryAgain` (exactamente 5 min ya cuenta como caducado)
3. `flights_differentAirport_callsRepository`
4. `flights_differentPage_callsRepository` (mismo IATA, otro `offset`)
5. `flights_failure_isNotCached`
6. `flights_newRepositoryOnSameContainer_returnsCached` (simula reabrir la app: otra instancia sobre el mismo contenedor)
7. `flights_afterTTL_replacesEntry` (tras refrescar hay una sola entrada y es la nueva)
### iOS unitarios — Presentation
Sin cambios: el ViewModel de #3 no sabe que existe la caché.
### iOS UI
Ninguno: no hay recorrido nuevo.

## Paridad
| # | iOS |
|---|-----|
| 1–7 | ✅ |

## Hecho cuando
- [x] `AviationApp` usa `CachedFlightRepository` alrededor del repositorio real, con un `ModelContainer` en disco y sin caché si no abre
- [x] README: sección de la caché de vuelos (SwiftData en disco, por petición, TTL de 5 min, sobrevive a cerrar la app, los errores no se guardan)
- [x] `docs/manual-tests.md`: sección de la historia #2
- [x] Prueba manual en el simulador: abrir los vuelos de MAD, volver atrás y abrirlos otra vez, y verlos al momento sin indicador de carga; cerrar la app del todo, reabrirla antes de 5 min y ver lo mismo. Hecha el 2026-11-20 en el simulador iPhone 17 Pro contra la API real, con un test de UI temporal (borrado, no commiteado; ~2 peticiones): abrir MAD, volver y reabrir (primera fila en menos de 1 s, sin «Cargando salidas…»), cerrar la app del todo, reabrir y entrar en MAD (lo mismo). Capturas de los tres pasos con los mismos vuelos.

## Sugerencias
- Cambiar el título y la descripción de la issue #2 al nuevo alcance (sigue diciendo «Repetir una búsqueda reciente»), p. ej. «Volver a ver las salidas de un aeropuerto es instantáneo (caché)».
