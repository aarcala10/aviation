# Aviation

iOS SwiftUI app that searches airports and their departing flights with the Aviationstack API. Layers: Data / Domain / Presentation (folders in one app target). Plan visual: https://claude.ai/artifact/7e8i3Tr43gfZfvXjGdXnFg

## Workflow (backlog / story / pair)

- Plataformas: ios
- Backlog: GitHub Issues (label `story`), tablero https://github.com/users/aarcala10/projects/2
- Backend: ninguno
- iOS: . (project.yml, xcodegen)   # test: xcodebuild test -scheme Aviation -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:AviationTests/<Suite>/<test>
- Git: GitHub (https://github.com/aarcala10/aviation), rama main; PR por historia, CI de GitHub Actions con tests obligatorios antes de mergear
- Repos: ninguno (todo se commitea en la raíz)
- Tests iOS: unitarios AviationTests, UI ninguno, dobles AviationTests/Support/
- Esquemas: ninguno
- Modelos auto-story: orquesta Opus 5.5; `ios-agent` con `model: "sonnet"` (Sonnet 5.5) para programar; formato con Haiku.

## Reglas de cada historia
- **Tests por capa, en todas las historias:** Domain (casos de uso con repositorios mock), Data (comportamiento de la caché, uso y expiración, cuando la historia tenga caché; si no, lo que tenga su capa Data) y Presentation (ViewModels). Si una historia no tiene alguna capa (p. ej. la #4 sin Data), el plan lo dice en una línea.
- **TDD por lotes:** en rojo se escriben todos los tests de la historia de una vez; en verde se implementa todo y se ejecuta la suite completa una sola vez, corrigiendo hasta que esté verde. Nada de ciclos test → probar → test → probar.
- **Diseño:** toda pantalla sigue `docs/design.md` (generado con `ui-ux-pro-max`). El briefing de `ios-agent` y de `swiftui-a11y-refactorer` lo incluye, y su checklist forma parte del "Hecho cuando".
