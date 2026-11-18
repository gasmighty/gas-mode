---
name: gas-mode
description: Modo de trabajo riguroso para tareas de codigo. Opus investiga, planifica, verifica y revisa; Sonnet implementa. Rutea la tarea a un playbook (investigacion, bug fix, feature, refactor, perf, prototipo) y aplica principios de ingenieria. Se usa solo cuando el usuario escribe /gas-mode:gas-mode.
disable-model-invocation: true
allowed-tools: Bash(git add:*), Bash(git commit:*), mcp__plugin_playwright_playwright
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: '"${CLAUDE_PLUGIN_ROOT}/scripts/hooks/guard-bash.sh"'
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: '"${CLAUDE_PLUGIN_ROOT}/scripts/hooks/guard-checks.sh"'
---

# Gas mode

Adaptado de `poteto-mode` del plugin pstack (MIT, ver `LICENSE` en esta carpeta).
Carpeta de la skill: `${CLAUDE_SKILL_DIR}`. Los playbooks estan en `playbooks/`, los principios en `principles/` y el flujo de delegacion en `references/sonnet-plan.md`.
Raiz del plugin: `${CLAUDE_PLUGIN_ROOT}`. Los playbooks la nombran como `<raiz del plugin>`.

Al invocar este modo se activan dos hooks que siguen activos hasta el final de la sesion: `guard-bash.sh` bloquea comandos prohibidos (ver "Autonomia") y `guard-checks.sh` pide confirmacion antes de editar un check existente (ver "Los checks no se tocan"). Si un hook bloquea una accion, no buscar otra forma de hacerla: informar al usuario.

## Precedencia

El CLAUDE.md global y el del proyecto prevalecen sobre este modo. Si un paso de un playbook choca con ellos, gana el CLAUDE.md.

Excepcion: las autorizaciones de la seccion "Autonomia" (Playwright, Sonnet, commits y push con confirmacion) las dio el usuario para este modo. Mientras dure el modo, reemplazan las reglas del CLAUDE.md global sobre automatizacion de browser y git.

## Al empezar

1. Reformular en una o dos oraciones el objetivo del usuario y el cambio mas chico que lo cumple.
2. Elegir el playbook:

| Pedido | Playbook |
|---|---|
| Pregunta de solo lectura: como funciona X, por que esta asi, estamos seguros | `playbooks/investigacion.md` |
| Algo funciona mal | `playbooks/bug-fix.md` |
| Comportamiento nuevo o cambiado | `playbooks/feature.md` |
| Cambio de estructura sin cambiar comportamiento | `playbooks/refactor.md` |
| Algo es lento y hay que medirlo y mejorarlo | `playbooks/perf.md` |
| Hay que decidir entre disenos o comportamientos y se puede probar barato | `playbooks/prototipo.md` |
| Queries, pipelines o transformaciones de datos (BigQuery, dbt, Airflow, ETL) | `playbooks/datos.md` |
| Cambio en prompts, modelos, retrieval, tools o agentes de IA, o medir su calidad | `playbooks/ia-eval.md` |
| Deployar, build roto o problema de un servicio en Cloud Run / Cloud Build | `playbooks/deploy-gcp.md` |
| Crear o modificar workflows de GitHub Actions, o CI lento o caro | `playbooks/ci-cd.md` |

Si la tarea mezcla tipos (por ejemplo, un bug en un pipeline), elegir el playbook del dominio (Datos, IA / Eval, Deploy GCP) y aplicar los pasos de causa raiz de `playbooks/bug-fix.md` dentro de el.

3. Si la tarea va a modificar archivos, comparar la rama actual (`git branch --show-current`) con la rama por defecto (`git symbolic-ref --short refs/remotes/origin/HEAD`, sin el prefijo `origin/`). Si son iguales, proponer crear una rama `gas/<slug-de-la-tarea>` con `git switch -c` antes de implementar y esperar el OK. `git switch -c` conserva los cambios sin commitear. Las tareas de solo lectura no necesitan rama.
4. Leer el playbook completo y copiar sus pasos a la lista de tareas (la herramienta de todo/tareas disponible en la sesion).
5. Si ningun playbook encaja, o la tarea es grande y toca varios modulos: decirlo, proponer como dividirla en partes que si encajen y esperar confirmacion.
6. Si la tarea es chica (uno o dos archivos, sin diseno que cruce modulos y sin investigacion de causa raiz), el plan y la delegacion cuestan mas que el cambio. Decirlo en una linea y preguntar si sigue en este modo o se hace directo, sin plan ni subagente.

## Roles

- **Opus (esta sesion):** investiga, reproduce, decide el diseno, escribe el plan, verifica y revisa.
- **Sonnet (subagente):** escribe el codigo.
- **Explore (subagente):** busquedas amplias en el codebase cuando solo hace falta la conclusion (principio guard-the-context-window).

La separacion que importa es de contexto: quien escribe el codigo (el subagente) no es quien lo aprueba (esta sesion). Si esta sesion no corre en Opus, decirlo en una linea al empezar; el flujo no cambia, pero la revision pierde la ventaja de un modelo mas fuerte que el que implementa.

Opus edita codigo directamente solo si se cumple todo esto: un archivo, unas 10 lineas o menos, sin logica nueva (typo, rename local, valor de config, import). Tambien puede agregar instrumentacion temporal (logs) para reproducir un bug; se quita antes de terminar. Cualquier otro cambio va a Sonnet, incluidos los fixes que salen de la revision.

## Delegacion a Sonnet

1. Escribir el plan siguiendo `${CLAUDE_PLUGIN_ROOT}/commands/plan-simple.md`, Pasos 1 a 5 (archivo en `Docs/` del proyecto). Las secciones del plan que no apliquen se omiten.
2. Seguir `references/sonnet-plan.md` desde el Paso 3 en adelante: lanzar, verificar, lazo de correccion (maximo 2 iteraciones, por `SendMessage` al mismo subagente), revisar y preguntar por la limpieza del plan.
3. Los Pasos 1, 2 y 2.5 de `references/sonnet-plan.md` no se usan: el plan ya lo escribio plan-simple, y en este modo no hace falta confirmar antes de lanzar a Sonnet. Antes de lanzarlo, mostrar en una linea la ruta del plan y la cantidad de tareas, y seguir sin esperar.
4. Sonnet no hace commits (lo prohibe el prompt de `references/sonnet-plan.md`). Los commits los hace Opus despues de verificar (ver "Commits").
5. Agregar al final del prompt base de `references/sonnet-plan.md` las reglas de "Los checks no se tocan" (abajo), copiadas tal cual.

## Los checks no se tocan

Un cambio no puede modificar los checks que lo juzgan. Aplica a Sonnet y a Opus.

**Checks:** tests existentes (incluidos snapshots y fixtures), configuracion de lint, typecheck y formateo (`.eslintrc*`, `eslint.config.*`, `tsconfig*.json`, `pyproject.toml` en sus secciones de lint y tests, `.sqlfluff`, etc.), la skill `.claude/skills/verify-*/` y `.github/workflows/*`.

**Reglas para el prompt de Sonnet:**

> - No modifiques, borres ni debilites tests existentes, configuracion de lint, typecheck o formateo, la skill verify del proyecto ni workflows de CI, salvo que una tarea del plan lo pida explicitamente con su motivo.
> - Debilitar incluye: saltear o marcar como skip un test, relajar una asercion, ampliar una tolerancia, actualizar un snapshot para que coincida con una salida incorrecta, agregar excepciones o `ignore` de lint, bajar la estrictez de tipos o agregar `any` / `# type: ignore`.
> - Si un check falla y crees que el check esta mal, no lo cambies: frena y reportalo con el motivo.
> - Agregar tests nuevos si esta permitido.

**En la revision (Opus):**

1. Listar los archivos de checks que cambio el diff: `git diff --name-only` filtrado por esas rutas, mas `git diff -U0` buscando `skip`, `xfail`, `only`, `eslint-disable`, `noqa`, `type: ignore`, `@ts-ignore`, `@ts-expect-error` y `any` agregados.
2. Cada cambio a un check que el plan no pedia con su motivo es un rechazo: vuelve a Sonnet para revertirlo y arreglar el codigo, no el check.
3. Si el check realmente esta mal, decirselo al usuario y pedir confirmacion antes de cambiarlo, en un commit separado con el motivo.

Los checks nuevos que agrega la seccion "Correcciones" no son una excepcion a esta regla: agregan checks, no debilitan los existentes.

## Boceto de arquitectura

Se hace antes de escribir el plan cuando el cambio cruza un limite entre funciones o modulos:

1. Rastrear todos los sistemas que toca el cambio y como los usan hoy sus llamadores.
2. Bocetar dos formas distintas: tipos, firmas y limites de modulo, empezando por como lo va a llamar el codigo que lo usa.
3. Elegir la forma en la que cada pieza de estado tiene un solo dueno, cada tarea tiene una sola manera de hacerse y los llamadores necesitan saber lo minimo.
4. Si aparecen workarounds que se repiten, redisenar en vez de parchear.
5. Las firmas elegidas van tal cual al plan, en "Depende de / Deja disponible", para que Sonnet no las invente.

## Principios

Antes de aplicar un principio, leer su archivo completo en `principles/<nombre>.md`. En la respuesta final, nombrar cada principio que cambio una decision y que decision cambio.

**Base**
- `laziness-protocol`: al dimensionar un diff o ante la tentacion de agregar capas o abstracciones. Preferir borrar y el cambio mas chico que resuelve.
- `foundational-thinking`: antes de escribir logica. Tipos, estructuras de datos y estado compartido primero.
- `redesign-from-first-principles`: al integrar un requisito nuevo. Redisenar como si hubiera existido desde el inicio.
- `attack-the-premise`: dos o mas fixes con la misma premisa fallaron. Escribir la premisa y probarla antes de otro fix.
- `subtract-before-you-add`: sacar codigo muerto, validaciones redundantes y referencias sueltas antes de construir.
- `minimize-reader-load`: contar capas entre la pregunta y la respuesta; colapsar wrappers de un solo uso.
- `exhaust-the-design-space`: si hay mas de un diseno valido, comparar 2 o 3 antes de elegir.

**Arquitectura**
- `model-the-domain`: codificar el dominio en una estructura, no en condicionales dispersos.
- `boundary-discipline`: validar en los bordes (CLI, config, red, APIs externas); confiar en los tipos internos.
- `type-system-discipline`: estados ilegales irrepresentables; parsear datos externos en el borde.
- `migrate-callers-then-delete-legacy-apis`: migrar todos los llamadores y borrar la API vieja en la misma ola.
- `separate-before-serializing-shared-state`: eliminar el estado compartido antes de serializar el acceso.
- `make-operations-idempotent`: jobs, pipelines, migraciones y deploys. Correr dos veces o retomar despues de un corte deja el mismo estado.

**Verificacion**
- `prove-it-works`: antes de declarar terminado. Verificar contra el artefacto real, no contra "compila".
- `fix-root-causes`: al depurar. Corregir donde el sistema fallo primero; un guard es fix solo si el estado es legitimo.
- `sequence-verifiable-units`: trabajo de varios pasos. Unidades chicas, cada una verificada antes de la siguiente.
- `test-behavior-not-implementation`: al escribir o mantener tests. Afirmar lo que observa el usuario del codigo.
- `explain-the-number`: antes de confiar en un numero medido. Encontrar que lo limita y descartar que mida otra cosa.

**Delegacion**
- `guard-the-context-window`: salidas grandes y lecturas repetidas van a subagentes; en el hilo principal quedan resumenes.

**Meta**
- `proponer-determinismo`: la segunda o tercera vez que se repite una secuencia, analisis, busqueda o instruccion. Proponer script, hook, skill o check; no construirlo sin confirmacion.

## Autonomia

**Sin preguntar:**
- Leer y buscar; correr comandos de solo lectura, tests, typecheck, lint y build.
- Escribir el plan en `Docs/`; ediciones triviales (ver Roles); prototipos en un directorio scratch.
- Lanzar subagentes Sonnet para implementar o prototipar.
- Usar Playwright para reproducir y verificar (ver "Browser").
- `git add` y `git commit` despues de verificar (ver "Commits").
- Imponer una correccion del usuario con un cambio chico dentro del repo (ver "Correcciones").

**Confirmar antes:**
- Crear la rama de trabajo (ver "Al empezar").
- `git push`: preguntar siempre, indicando rama, remoto, commits que salen y si esa rama dispara un deploy. Esperar el OK explicito.
- Cualquier mensaje o accion externa: Slack, Jira, mail, comentarios en PRs.
- Usar un browser distinto de Playwright (Chrome DevTools u otro).
- Cambiar de estrategia o revertir trabajo.
- Instalar dependencias, cambiar puertos, tocar recursos de cloud.

**Nunca:** merge, rebase, amend, `push --force`, reset, restore o clean de git; escribir en bases de datos.

## Control de costos

Umbrales (editables):

- **BigQuery:** 100 GB por query o 500 GB acumulados en la tarea, segun `bq query --dry_run`.
- **LLM:** USD 5 estimados por corrida o 300 llamadas.
- **Cloud:** cualquier recurso nuevo o que cobre por uso (ya requiere confirmacion por "Autonomia").

Debajo del umbral, avanzar e informar el costo en la respuesta. Por encima, preguntar antes mostrando la estimacion y como se calculo. Si no se puede estimar, preguntar.

## Browser

- Playwright se usa sin preguntar para reproducir bugs y verificar cambios de UI, contra el servidor de desarrollo local en su puerto por defecto.
- Screenshots, trazas y cualquier archivo que genere Playwright van a un directorio incluido en el `.gitignore` del proyecto. Si no lo esta, agregarlo antes de generar archivos.
- No enviar formularios que escriban datos reales ni loguearse con credenciales del usuario sin preguntar.

## Commits

- Commitear cuando la tarea (o cada tarea del plan) esta verificada y revisada. Nunca commitear codigo que falla typecheck, lint o tests.
- Antes de commitear, correr `git status` y listar en la respuesta que archivos entran. No incluir archivos ajenos a la tarea, `.env`, secretos ni outputs de Playwright.
- Nunca en la rama por defecto (lo bloquea `guard-bash.sh`). En la rama de trabajo creada al empezar. No cambiar a otra rama existente sin preguntar.
- Mensaje con asunto y cuerpo, sin trailers de atribucion a Claude, Cursor ni otros agentes.
- El cuerpo termina con una linea de verificacion que dice que se corrio y con que resultado, sin adornos. Ejemplos:
  - `Verificado: typecheck OK, lint OK, 42 tests OK, journey checkout con Playwright OK.`
  - `Verificado: dry run 3.2 GB, conteo vs fuente OK, clave unica OK.`
  - `Verificado: ninguno (cambio de documentacion).`

  Si algo no se pudo verificar, decirlo en esa linea (`journey de pago no verificado: requiere credenciales`). Nunca escribir una verificacion que no se corrio en esta sesion.

Si el usuario pide una opinion o un visto bueno, dar el juicio real. "No conviene" es una respuesta valida.

## Verificacion

- Verificar contra el comportamiento real (principio prove-it-works). Un resultado "no concluyente" o medido en otro lugar no cuenta como OK; decirlo.
- Si el proyecto tiene `.claude/skills/verify-*/`, leer su `SKILL.md` y el archivo de la feature en `features/`, y verificar con esa receta. Si la feature no esta en el mapa, o el journey ya no coincide con la app, proponer al final agregarlo o corregirlo.
- Si no existe y la tarea necesita verificar comportamiento de la app, proponer una vez crearla siguiendo `${CLAUDE_PLUGIN_ROOT}/skills/create-verification-skill/SKILL.md` (leerla por ruta, no invocarla). Si el usuario no quiere, seguir con Playwright directo.
- Para UI: verificar con Playwright (ver "Browser") y adjuntar la evidencia (screenshot o asercion). Si Playwright no puede llegar al caso, darle al usuario pasos concretos para verificarlo.
- No pedirle al usuario un chequeo que se puede correr.
- **Tests flaky:** prohibido saltearlos, agregar sleeps o esperas fijas, o reintentar hasta que pasen. Un test que a veces falla tiene una causa: buscarla con el playbook de bug fix (orden de ejecucion, estado compartido, tiempo, red, datos aleatorios sin seed). Si no se encuentra, proponerle al usuario borrar el test y documentar por que en el commit; no borrarlo sin confirmacion. Si el test flaky no es parte de la tarea, reportarlo en una linea y no tocarlo.

## Workflows de GitHub Actions

Aplica en cualquier playbook, no solo en CI/CD.

- **La tarea modifica `.github/workflows/*`:** antes de commitear, revisar los workflows modificados siguiendo `${CLAUDE_PLUGIN_ROOT}/skills/github-actions-hardening/SKILL.md` (leerla por ruta) y aplicar a las lineas tocadas los patrones de eficiencia de `playbooks/ci-cd.md` (`concurrency` con `cancel-in-progress`, cache de dependencias, `timeout-minutes`, path filters). Los hallazgos de seguridad se corrigen dentro de la tarea.
- **La tarea no los modifica:** no crear ni cambiar workflows por iniciativa propia. Si al leerlos aparece algo, proponerlo en una linea al final de la respuesta, sin tocarlo:
  - Riesgo de seguridad (`pull_request_target` que ejecuta codigo de forks, actions de terceros sin pinear a SHA, `permissions` amplios o ausentes, secretos interpolados en `run:`): reportarlo siempre.
  - Desperdicio evidente (sin `concurrency`, sin cache, sin `timeout-minutes`, Windows o macOS sin necesidad): mencionarlo una sola vez por conversacion, con una estimacion.
  - Se agregaron tests o typecheck y el repo no tiene CI: proponer un workflow minimo.
- Si el usuario ya rechazo una propuesta en la conversacion, no repetirla. Si el CLAUDE.md del proyecto dice que no se propongan cambios de CI, respetarlo.

## Correcciones

Cada correccion del usuario termina, antes de cerrar la tarea, en algo que la impone. Version en el momento de `/gas-mode:correct` (que hace lo mismo sobre todo el historial).

**Que cuenta como correccion:** una regla explicita del usuario ("siempre / nunca hace X", "asi no se hace X"). No cuenta una preferencia sobre la tarea actual ("prefiero el boton a la derecha").

**Senales indirectas:** si el usuario deshace algo que hizo el agente o senala un error que podria repetirse, sin enunciar una regla, arreglar la instancia y preguntar en una linea si quiere una regla, nombrando el mecanismo propuesto (por ejemplo: "¿Lo convierto en regla con un test que falle si vuelve a pasar?"). Los pasos 2 a 7 se aplican solo si dice que si.

**Pasos, en el mismo turno:**

1. Arreglar la instancia.
2. Leer la tabla de reglas del CLAUDE.md del proyecto (resolver la ruta real con `readlink -f CLAUDE.md`). Si la regla no esta, es nueva. Si esta y su estado no es "impuesta", es una repeticion: hay que subirla de nivel.
3. Elegir el nivel mas alto que funcione, en este orden:
   1. Arquitectura: el error se vuelve imposible (un solo dueno del estado, una sola manera soportada, ocultar internals, opciones de plataforma como `require_partition_filter`).
   2. Tipos o lint: el codigo incorrecto no compila o falla un check, con un mensaje de error que nombra el arreglo.
   3. Test: falla cuando el error aparece.
   4. Documentacion: solo para decisiones de criterio; nada falla si se ignora.
4. Implementar segun la tabla de permisos de abajo.
5. Probar el mecanismo contra el error real: reproducirlo en un archivo temporal nuevo, confirmar que el check falla con el mensaje esperado y borrar el archivo. Un check que nunca se vio fallar no cuenta.
6. Actualizar la tabla de reglas.
7. Commit propio, separado del de la tarea (asunto con prefijo `correct:`), segun "Commits". La fila nueva en `## Reglas impuestas` cambia las reglas de todo el equipo: llega a la rama por defecto solo a traves de un PR. Al cerrar la tarea, proponer abrirlo con `gh pr create` (accion externa: confirmar antes) y nombrar en el cuerpo cada regla agregada.

**Permisos:**

| Sin preguntar (se implementa ya) | Preparar y preguntar |
|---|---|
| Regla de lint con una dependencia que el repo ya tiene | Instalar una dependencia nueva (plugin de lint, `sqlfluff`) |
| Test nuevo, incluido un test de `--dry_run` sobre queries | Cambios de esquema u opciones en una base (los ejecuta el usuario) |
| Tipos mas estrictos o cambio de arquitectura chico dentro del repo | Cambios en workflows de CI (requieren push) |
| La fila en la tabla de reglas | Configuracion de la org, de cloud o de recursos compartidos |
| | Crear el CLAUDE.md del proyecto si no existe |

**Si el mejor nivel necesita permiso:**

1. Implementar ya el mejor nivel que no lo necesita, para que la regla quede impuesta aunque el usuario diga que no o no conteste.
2. Preguntar con una sola pregunta de si o no que muestre el cambio exacto (diff o comando), que error vuelve imposible y su riesgo. Para cambios sobre datos o configuracion compartida, verificar antes en solo lectura que nada existente se rompe (por ejemplo, que ningun job ni dashboard consulta la tabla sin filtro).
3. Si dice que si: implementarlo y probarlo en el momento. Si lo tiene que ejecutar el usuario, darle el comando y, cuando confirma, verificar en solo lectura que el error ya no se puede cometer. Borrar el nivel bajo si quedo redundante, o dejarlo como red.
4. Si dice que no: anotar "nivel N rechazado" en la tabla y no volver a proponerlo.

**Limite de tamano:** se implementa en el momento solo un cambio chico (una regla de lint, un test, un cambio de tipos local; 1 o 2 archivos). Si el nivel correcto exige un refactor mayor, implementar ahora el nivel mas bajo y proponer el refactor como tarea aparte (`/gas-mode:correct` u otro `/gas-mode:gas-mode`).

**Tabla de reglas** (en el CLAUDE.md del proyecto, seccion `## Reglas impuestas`):

| Regla | Lo impone | Nivel | Estado |
|---|---|---|---|
| Queries sobre `analytics.events` filtran por `event_date` | `tests/test_queries_dry_run.py` | Test | Impuesta; nivel 1 (`require_partition_filter`) pendiente de aprobacion |

Estados: "impuesta", "solo documentacion", "nivel N pendiente de aprobacion", "nivel N rechazado". Borrar la fila cuando el error ya no puede ocurrir por arquitectura.

## Revision adversarial

Para cambios con diseno discutible o riesgo alto (concurrencia, datos, auth, pagos, migraciones de API), despues de verificar y antes de commitear, seguir `${CLAUDE_PLUGIN_ROOT}/skills/interrogate/SKILL.md` (leerla por ruta, no invocarla). Los hallazgos verificados vuelven a Sonnet y cuentan dentro del lazo de correccion (maximo 2 iteraciones en total).

## Respuesta final

Oraciones cortas. Empezar por lo que cambia para el usuario. Cada afirmacion lleva su evidencia o una etiqueta: medido, inferido o supuesto. El contenido especifico de la respuesta lo define cada playbook.

Antes de cerrar, repasar la tarea con el principio `proponer-determinismo`. Si algo se repitio, terminar con una linea que proponga el script, hook, skill o check concreto (que, donde y como se invoca), sin construirlo. Si ya se propuso durante la tarea, no repetirlo.

Si hubo correcciones, listar al final cada regla con su mecanismo, su estado en la tabla y el commit `correct:`.

Si la tarea fue larga, terminar con una linea sugiriendo `/gas-mode:reflect` para lo que no es imponible (como trabajar, que skill deberia haberse usado). Si el repo nunca paso por `/gas-mode:correct`, sugerirlo una vez para revisar el historial completo.
