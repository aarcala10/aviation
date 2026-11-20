# Historia: Como viajero quiero ver el detalle de un vuelo para conocer su estado, terminal, puerta y horarios.

Issue: #4 · Plataformas: iOS

> El detalle se construye con los datos que ya trae la página de `/flights` de la lista (salida y llegada traen `terminal`, `gate`, `scheduled`, `estimated`, `actual` y `delay`). No se hace ninguna petición nueva: no gasta cuota y funciona con la caché de la #2.

## Criterios de aceptación
1. Dado que veo «Salidas de MAD» con vuelos, cuando toco una fila, entonces se abre el detalle de ese vuelo (título de la barra: el número de vuelo, p. ej. «AZ59»).
2. Dado que se abre el detalle, entonces la cabecera muestra la ruta `MAD ✈︎ FCO` (códigos grandes, `airplane` entre ellos) y la píldora de estado, con la misma regla que la lista (retrasado si hay `delay` > 0 y está programado o en vuelo; cancelado sigue cancelado).
3. Dado que se abre el detalle, entonces hay tres secciones con `LabeledContent` (según `docs/design.md`):
   - **Salida:** terminal, puerta, programada, estimada, retraso.
   - **Llegada:** terminal, puerta, programada, estimada, retraso.
   - **Vuelo:** aerolínea, número, fecha («viernes, 20 de noviembre», en UTC como las cabeceras de la lista).
4. Dado que la API manda las horas locales de cada aeropuerto con un falso `+00:00`, cuando se muestran, entonces salen tal cual llegan (HH:mm): la salida en hora de Madrid, la llegada en hora del destino.
5. Dado que un dato no llega (`null` o vacío: terminal, puerta, estimada…), cuando se muestra, entonces su valor es «—» y la fila sigue ahí (las secciones no cambian de forma). **(asumido)**
6. Dado que el retraso es `null` o 0, entonces se ve «—»; si es > 0, «25 min». **(asumido)**
7. Dado que un vuelo ha aterrizado con `arrival.delay` > 0, cuando se muestra su estado (lista y detalle), entonces la píldora dice «Aterrizado» con el símbolo `clock` en vez de `airplane.arrival`, sigue en verde y VoiceOver lee «Aterrizado con retraso». Si aterrizó sin retraso, la píldora no cambia. **(decisión del usuario, 2026-11-20)**
8. Dado que VoiceOver está activo, cuando se abre el detalle, entonces el foco cae en la cabecera, que se lee «Vuelo A Z 5 9. De Madrid a Roma. Retrasado.» (ciudades de `CityLookup`, si no el nombre del aeropuerto, si no el código; como en la #3), y cada `LabeledContent` se lee como un elemento («Puerta, B 12»; puertas y terminales deletreadas, horas sin cero inicial como en la fila). **(asumido)**

## Fuera de alcance
- Pedir el vuelo a la API ni refrescar el detalle (tirar para refrescar, actualización en vivo): los datos son los de la lista, con la caché de 5 minutos.
- Hora real (`actual`), pista (`*_runway`), cinta de equipajes, avión y posición en vivo (`live`, que en el plan gratuito llega `null`).
- Mostrar los códigos compartidos del vuelo operado.
- Navegar al detalle desde otro sitio que no sea la lista de salidas.

## Decisiones técnicas (una línea cada una)
- `Flight` gana campos opcionales: `originIATA`, `originName`, `departureTerminal`, `departureGate`, `estimatedTime`, `arrivalTerminal`, `arrivalGate`, `arrivalScheduledTime`, `arrivalEstimatedTime`, `arrivalDelayMinutes`, `originCity`. Opcionales para que una página ya guardada en la caché siga decodificando (durante ≤ 5 min mostrará «—»).
- `AviationstackFlightRepository` mapea esos campos con el mismo `localTime(_:)` que la hora de salida.
- **Domain:** no hay caso de uso nuevo; `GetDeparturesUseCase` también rellena `originCity` con `CityLookup`, como ya hace con el destino. `Flight.landedLate` (aterrizado y `arrivalDelayMinutes` > 0) vive junto a `status`, que no cambia.
- `FlightDetailViewModel` (Presentation) recibe un `Flight` y expone textos ya formateados («—», «25 min», fecha). Sin carga ni estados: no hay petición.
- Navegación con `NavigationLink(value: Flight)` + `.navigationDestination(for: Flight.self)` (`Flight` pasa a `Hashable`).
- Test de UI **(decisión del usuario)**: el argumento de lanzamiento `-uiTestFixtures` hace que `AviationApp` use un `FlightRepository` que lee `flights.json` del bundle de la app en vez de la red. El fixture se copia al bundle solo en Debug (`project.yml`).

## Tests (en orden, agrupados por capa)
### iOS unitarios — Domain (`GetDeparturesUseCase` con `MockFlightRepository`)
1. `departures_fillsOriginCity`
2. `landedLate_withArrivalDelay_isTrue`
3. `landedLate_withoutArrivalDelay_isFalse`
### iOS unitarios — Data (`AviationstackFlightRepository` con `flights.json`)
4. `departures_decodesDepartureDetails` (origen, terminal, puerta, estimada)
5. `departures_decodesArrivalDetails` (terminal, puerta, programada y estimada en hora local tal cual, retraso)
6. `departures_missingDetails_areNil` (`gate: null`, `estimated: null`)
### iOS unitarios — Presentation (`FlightDetailViewModel`)
7. `detail_showsRouteAndStatus`
8. `detail_showsDepartureAndArrivalValues`
9. `detail_missingValue_showsDash`
10. `detail_delay_showsMinutesOrDash`
11. `detail_date_isFormattedInUTC`
12. `detail_spokenHeader_usesCities`
### iOS UI (camino feliz)
13. `openFlight_showsDetail`: con `-uiTestFixtures`, busca "madrid", toca MAD, toca el primer vuelo y comprueba la barra «AZ59» y que existe la sección «Salida». Pasa en la CI sin clave y no gasta cuota.
14. `searchAndOpenAirport_showsDepartures` (de la #3) pasa a lanzarse con `-uiTestFixtures` y deja de gastar cuota en local. **(sugerencia aprobada)**

Nota: el test 13 se cambió con la aprobación del usuario (2026-11-20). Tocaba `app.cells.firstMatch`, que es la cabecera de sección de la fecha; ahora toca la celda que contiene «AZ59» (commit `548c5d6`).

## Paridad
| # | iOS |
|---|-----|
| 1–3 | ✅ |
| 4–6 | ✅ |
| 7–12 | ✅ |
| 13–14 | ✅ |

## Hecho cuando
- [x] `flights.json`: el vuelo operado tiene puerta y terminal en al menos un lado y `null` en otro, para los tests 4–6 y 9 (AZ59: puerta de salida B12, llegada estimada 08:55 y retraso de llegada 25)
- [x] `docs/design.md`: la tabla de estados añade «Aterrizado con retraso» → `clock`, `.green`
- [x] Textos: «Aterrizado con retraso» (etiqueta de accesibilidad de la píldora); además «Sin dato» como etiqueta hablada de «—»
- [x] Textos en `Localizable.xcstrings` (es): «Salida», «Llegada», «Vuelo», «Terminal», «Puerta», «Programada», «Estimada», «Retraso», «Aerolínea», «Número», «Fecha», «%lld min», «—», y la etiqueta hablada de la cabecera (la compilación no reescribe el catálogo)
- [x] Diseño según `docs/design.md` (componente **FlightDetail**): IATA en `.largeTitle.weight(.bold).monospaced()`, horas `.monospacedDigit()`, sin hex; revisado por `swiftui-a11y-refactorer` (con `swiftui-expert-skill`, `swiftui-pro` e `ios-accessibility`)
- [x] Accesibilidad (checklist de `docs/design.md`): cabecera un único elemento con rasgo de cabecera y foco al abrir; códigos, puertas y número deletreados; icono `airplane` oculto; AX5 sin cortes; claro y oscuro; horizontal. Hecho por código y revisión; AX5, oscuro y horizontal vistos en el simulador (2026-11-20); VoiceOver en el iPhone confirmado por el usuario (2026-11-20), salvo la frase «Aterrizado con retraso» (ver `docs/manual-tests.md`)
- [x] `FlightRow` sigue leyéndose igual (VoiceOver añade solo el rasgo de botón del `NavigationLink`): confirmado de oído por el usuario (2026-11-20)
- [x] El fixture no entra en el bundle de Release (`EXCLUDED_SOURCE_FILE_NAMES[config=Release]` en `Config/Base.xcconfig`; `ios-agent` lo comprobó con un build Release sin `flights.json`)
- [X] Prueba manual en el simulador con la clave real: abrir varios vuelos, uno retrasado y uno sin puerta

## Resultado (2026-11-20)
- Suite completa en el simulador iPhone 17 Pro: unitarios 60/60 en 20 suites (12 nuevos: `FlightDetailDomainTests` 3, `AviationstackFlightDetailTests` 3, `FlightDetailViewModelTests` 6); UI 3/3. 0 warnings de Swift.
- Queda un warning de proyecto de xcodebuild: «AviationTests/Fixtures is a member of multiple groups», porque el target de la app referencia `AviationTests/Fixtures/flights.json` (inocuo; la alternativa era duplicar el fixture).
- Rojo `11c1a89`: 10 de los 12 unitarios fallaron por expectativa; `departures_missingDetails_areNil` y `landedLate_withoutArrivalDelay_isFalse` pasaron (guardas de ausencia); el test de UI 13 falló en la barra «AZ59», como se esperaba. Verde `1e7b602`.
- Desviación de las decisiones técnicas: `originCity` es una clave no opcional, así que las páginas guardadas en la caché antes del cambio ya no decodifican y se piden de nuevo una vez (aceptable dentro de los 5 min de TTL).
- `FlightDate` es ahora un formateador compartido (movido de `FlightsView`) que usa el idioma de la app (es) en vez de la región del dispositivo.
- Revisión de `swiftui-a11y-refactorer`: aplicado «Sin dato» como etiqueta hablada de «—» y quitado `@Observable` de `FlightDetailViewModel` (sin estado mutable). Rechazado, con motivo: `@State` para el VM, cambiar el patrón `NavigationLink` + `accessibilityFocused` (es correcto) y abstraer el recorte de ceros iniciales duplicado en dos sitios.

## Sugerencias
- Aprobadas el 2026-11-20: aterrizado con retraso (criterio 7) y el test de la #3 con fixture (test 14).
