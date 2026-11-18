# Correcciones

Referencia de `SKILL.md`, seccion "Correcciones".

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
7. Commit propio, separado del de la tarea (asunto con prefijo `correct:`), segun la seccion "Commits" de `SKILL.md`. La fila nueva en `## Reglas impuestas` cambia las reglas de todo el equipo: llega a la rama por defecto solo a traves de un PR. Al cerrar la tarea, proponer abrirlo con `gh pr create` (accion externa: confirmar antes) y nombrar en el cuerpo cada regla agregada.

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
