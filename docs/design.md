# Diseño: Aviation

Sistema de diseño de la app. Lo genera `ui-ux-pro-max` (`--design-system` + `--stack swiftui` + `references/pro-rules.md`) y lo adapta a iOS nativo. Todas las pantallas lo siguen; `swiftui-a11y-refactorer` lo usa como checklist en la revisión.

## Dirección
- **Estilo:** minimalista / suizo, primero el contenido. Funcional, mucho espacio en blanco, alto contraste, jerarquía clara.
- **Nativo primero:** `List`, `NavigationStack`, `.searchable`, `ContentUnavailableView`, `LabeledContent`. Las barras de iOS 26 ya traen Liquid Glass: no se añade cristal propio.
- **Sin dependencias:** SF Pro y SF Symbols. No hay fuentes personalizadas, que romperían Dynamic Type y añadirían ficheros.

## Color (tokens en `Assets.xcassets`, con variante clara y oscura)
| Token | Claro | Oscuro | Uso |
|---|---|---|---|
| `AccentColor` | #1E3A8A | #8FB4FF | Tint global, códigos IATA, iconos de ruta |
| `Accent/Highlight` | #EA580C | #FB923C | Solo retrasos, el único acento cálido |
| Fondos | `Color(.systemGroupedBackground)` / `.secondarySystemGroupedBackground` | sistema | No se usa hex en las vistas |
| Texto | `.primary` / `.secondary` | sistema | Contraste ≥ 4.5:1 en los dos modos |

Estado del vuelo: **color + SF Symbol + texto**, nunca solo color.
| Estado | Símbolo | Color |
|---|---|---|
| Programado | `clock` | `.secondary` |
| En vuelo | `airplane` | `AccentColor` |
| Aterrizado | `airplane.arrival` | `.green` |
| Retrasado | `exclamationmark.circle` | `Accent/Highlight` |
| Cancelado | `xmark.circle` | `.red` |
| Desviado / incidente | `exclamationmark.triangle` | `.red` |

## Tipografía (solo estilos de texto, nunca `.system(size:)`)
| Rol | Estilo |
|---|---|
| Código IATA en la fila | `.title3.weight(.semibold)` + `.monospaced()` |
| Código IATA en la cabecera del detalle | `.largeTitle.weight(.bold)` + `.monospaced()` |
| Nombre principal | `.headline` |
| Línea secundaria (ciudad, país, aerolínea) | `.subheadline` + `.secondary` |
| Horas | `.body.monospacedDigit()` |
| Píldora de estado | `.caption.weight(.semibold)` |

## Espaciado y tamaños
- Ritmo de 4/8 pt: 4 · 8 · 12 · 16 · 24 · 32.
- Zona táctil ≥ 44×44 pt. Las filas de `List` ya la cumplen.
- Iconos: SF Symbols con `.symbolRenderingMode(.hierarchical)`, sin mezclar relleno y contorno en el mismo nivel.

## Componentes
- **AirportRow:** a la izquierda el código IATA en caja fija (`.frame(minWidth:)` escalado con `@ScaledMetric`, fondo `AccentColor.opacity(0.12)`, radio 8); a la derecha el nombre (`.headline`) y "Ciudad · País" (`.subheadline`).
- **FlightRow** (historia #3): número de vuelo y aerolínea; destino (IATA + nombre); hora programada; píldora de estado.
- **FlightDetail** (historia #4): cabecera con la ruta `MAD ✈︎ JFK` (códigos grandes y `airplane` entre ellos) y la píldora de estado; después, secciones agrupadas con `LabeledContent`: Salida (terminal, puerta, programada, estimada, retraso), Llegada (lo mismo) y Vuelo (aerolínea, número, fecha).
- **StatusBadge:** `Label(texto, systemImage:)` en una cápsula con fondo del color de estado al 15 % y texto del color pleno.
- **Estados vacíos:** `ContentUnavailableView`.
  - Inicial: «Busca un aeropuerto», `airplane.departure`, con la descripción «Escribe un nombre, una ciudad o un código IATA».
  - Sin resultados: `ContentUnavailableView.search(text:)`.
  - Error: `exclamationmark.triangle`, título corto y mensaje con la causa («Comprueba tu conexión», «Se ha agotado la cuota de la API»).
- **Carga:** `ProgressView("Buscando…")` centrado en la búsqueda; `ProgressView()` como última fila al paginar.

## Accesibilidad (obligatoria)
- Cada fila es un solo elemento: `.accessibilityElement(children: .combine)` con una etiqueta en orden natural («Adolfo Suárez Madrid-Barajas, M A D, España»).
- Códigos IATA/ICAO y números de vuelo con `.speechSpellsOutCharacters()`, para que VoiceOver diga «M A D» y no «mad».
- Los iconos decorativos que acompañan a un texto van con `.accessibilityHidden(true)`.
- Dynamic Type hasta AX5: con `dynamicTypeSize.isAccessibilitySize` las filas pasan de `HStack` a `VStack`. No se trunca información clave (`lineLimit` solo en textos secundarios).
- Reduce Motion: no hay animaciones propias; solo transiciones del sistema.
- Se comprueban los modos claro y oscuro por separado y los tamaños de iPhone SE, iPhone 17 Pro Max y horizontal.
- Los mensajes de estado se anuncian una vez (`AccessibilityNotification.Announcement`) cuando llegan resultados o un error, sin mover el foco.

## Formato
- Horas en la zona horaria del aeropuerto (dato de la API) con `Date.FormatStyle`, nunca en la del dispositivo.
- Todos los textos van en `Localizable.xcstrings` (es).

## Checklist antes de entregar cada pantalla
Contraste en los dos modos · Dynamic Type AX5 sin cortes · VoiceOver en orden visual y con etiquetas útiles · estado no indicado solo por color · zonas táctiles ≥ 44 pt · sin hex en las vistas · iPhone SE y horizontal.
